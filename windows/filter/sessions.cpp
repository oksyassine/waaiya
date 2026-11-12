#include "sessions.h"

#include <atomic>
#include <cmath>
#include <cstring>
#include <cwctype>
#include <cstdio>

// {6c1f3a52-9d0e-4b7a-a7c4-5a1e0d2b8f31}
const GUID IM_VOLUME_CONTEXT = {0x6c1f3a52, 0x9d0e, 0x4b7a, {0xa7, 0xc4, 0x5a, 0x1e, 0x0d, 0x2b, 0x8f, 0x31}};

namespace {

// IAudioMeterInformation (endpointvolume.h): MinGW only declares it.
const IID IID_ImMeter = {0xC02216F6, 0x8C67, 0x4B5B, {0x9D, 0x00, 0xD0, 0x08, 0xE7, 0x3E, 0x00, 0x64}};
struct ImMeter : public IUnknown {
    virtual HRESULT STDMETHODCALLTYPE GetPeakValue(float *peak) = 0;
    virtual HRESULT STDMETHODCALLTYPE GetMeteringChannelCount(UINT *count) = 0;
    virtual HRESULT STDMETHODCALLTYPE GetChannelsPeakValues(UINT32 count, float *peaks) = 0;
    virtual HRESULT STDMETHODCALLTYPE QueryHardwareSupport(DWORD *mask) = 0;
};

const char *state_name(AudioSessionState s) {
    return s == AudioSessionStateActive ? "active" : (s == AudioSessionStateInactive ? "inactive" : "expired");
}

template <class Self, class... Ifaces> class Unknown : public Ifaces... {
  public:
    STDMETHODIMP_(ULONG) AddRef() override { return (ULONG)InterlockedIncrement(&refs_); }
    STDMETHODIMP_(ULONG) Release() override {
        LONG r = InterlockedDecrement(&refs_);
        if (r == 0) delete static_cast<Self *>(this);
        return (ULONG)r;
    }
    virtual ~Unknown() = default;

  private:
    LONG refs_ = 1;
};

} // namespace

// Volume changes and the end of one session.
//
// Windows calls these (and SessionWatch) on its own threads, possibly while holding locks of its own that the main
// thread's calls into the audio service also need. So a callback never waits for the main thread's lock (mu_): it
// carries its session's identifier and volume, takes only the store's lock (never held during an audio call), and
// leaves registering, unregistering and the session list to the main loop (Sessions::scan). A first version took
// mu_ here and hung on a real PC after a stop and a start.
class SessionEvents final : public Unknown<SessionEvents, IAudioSessionEvents> {
  public:
    SessionEvents(Sessions *owner, std::wstring id, DWORD pid, ISimpleAudioVolume *vol)
        : id(std::move(id)), pid(pid), owner_(owner) {
        vol_.p = vol;
        vol->AddRef();
    }
    void detach() { owner_.store(nullptr); }
    const std::wstring id;
    const DWORD pid;
    std::atomic<bool> dead{false}; // the session ended; unwatched by the next scan

    STDMETHODIMP QueryInterface(REFIID riid, void **out) override {
        if (riid == __uuidof(IUnknown) || riid == __uuidof(IAudioSessionEvents)) {
            *out = static_cast<IAudioSessionEvents *>(this);
            AddRef();
            return S_OK;
        }
        *out = nullptr;
        return E_NOINTERFACE;
    }
    STDMETHODIMP OnSimpleVolumeChanged(float v, BOOL, LPCGUID ctx) override {
        if (ctx && IsEqualGUID(*ctx, IM_VOLUME_CONTEXT)) return S_OK; // ours
        if (Sessions *o = owner_.load()) o->on_volume(id, vol_.p, v);
        return S_OK;
    }
    STDMETHODIMP OnStateChanged(AudioSessionState st) override {
        if (st == AudioSessionStateExpired) gone();
        return S_OK;
    }
    STDMETHODIMP OnSessionDisconnected(AudioSessionDisconnectReason) override {
        gone();
        return S_OK;
    }
    STDMETHODIMP OnDisplayNameChanged(LPCWSTR, LPCGUID) override { return S_OK; }
    STDMETHODIMP OnIconPathChanged(LPCWSTR, LPCGUID) override { return S_OK; }
    STDMETHODIMP OnChannelVolumeChanged(DWORD, float[], DWORD, LPCGUID) override { return S_OK; }
    STDMETHODIMP OnGroupingParamChanged(LPCGUID, LPCGUID) override { return S_OK; }

  private:
    void gone() {
        dead.store(true);
        if (Sessions *o = owner_.load()) SetEvent(o->wake);
    }
    std::atomic<Sessions *> owner_;
    Com<ISimpleAudioVolume> vol_;
};

// New sessions on one output.
class SessionWatch final : public Unknown<SessionWatch, IAudioSessionNotification> {
  public:
    explicit SessionWatch(Sessions *owner) : owner_(owner) {}
    void detach() { owner_.store(nullptr); }
    STDMETHODIMP QueryInterface(REFIID riid, void **out) override {
        if (riid == __uuidof(IUnknown) || riid == __uuidof(IAudioSessionNotification)) {
            *out = static_cast<IAudioSessionNotification *>(this);
            AddRef();
            return S_OK;
        }
        *out = nullptr;
        return E_NOINTERFACE;
    }
    // Lowered right here, in Windows' notification, not later in the main loop: every millisecond until then the
    // new app is heard unfiltered (the main loop also mutes our output when it hears a session at full level).
    STDMETHODIMP OnSessionCreated(IAudioSessionControl *ctl) override {
        Sessions *o = owner_.load();
        if (o && ctl) o->on_session(ctl);
        return S_OK;
    }

  private:
    std::atomic<Sessions *> owner_;
};

// Outputs plugged in or enabled: their sessions must be lowered too.
class DeviceWatch final : public Unknown<DeviceWatch, IMMNotificationClient> {
  public:
    explicit DeviceWatch(HANDLE wake) : wake_(wake) {}
    STDMETHODIMP QueryInterface(REFIID riid, void **out) override {
        if (riid == __uuidof(IUnknown) || riid == __uuidof(IMMNotificationClient)) {
            *out = static_cast<IMMNotificationClient *>(this);
            AddRef();
            return S_OK;
        }
        *out = nullptr;
        return E_NOINTERFACE;
    }
    STDMETHODIMP OnDeviceStateChanged(LPCWSTR, DWORD) override { return poke(); }
    STDMETHODIMP OnDeviceAdded(LPCWSTR) override { return poke(); }
    STDMETHODIMP OnDeviceRemoved(LPCWSTR) override { return poke(); }
    STDMETHODIMP OnDefaultDeviceChanged(EDataFlow, ERole, LPCWSTR) override { return poke(); }
    STDMETHODIMP OnPropertyValueChanged(LPCWSTR, const PROPERTYKEY) override { return S_OK; }

  private:
    HRESULT poke() {
        SetEvent(wake_);
        return S_OK;
    }
    HANDLE wake_;
};

Sessions::Sessions(float att, std::wstring store_path, DWORD self_pid)
    : att_(att), store_path_(std::move(store_path)), self_(self_pid) {}

Sessions::~Sessions() {
    std::lock_guard<std::recursive_mutex> l(mu_);
    mode_.store(RESTORE_ONLY); // a callback still running does nothing more
    for (auto &t : tracked_) drop(t);
    tracked_.clear();
    for (auto &o : outputs_) {
        if (o.watch) {
            o.watch->detach();
            o.mgr->UnregisterSessionNotification(o.watch);
            o.watch->Release();
        }
    }
    outputs_.clear();
    if (device_watch_) {
        devices_->UnregisterEndpointNotificationCallback(device_watch_);
        device_watch_->Release();
    }
    CloseHandle(wake);
}

void Sessions::drop(Tracked &t) {
    if (t.events) {
        t.events->detach();
        if (t.ctl) t.ctl->UnregisterAudioSessionNotification(t.events);
        t.events->Release();
        t.events = nullptr;
    }
}

HRESULT Sessions::start(Mode mode) {
    std::lock_guard<std::recursive_mutex> l(mu_);
    mode_.store(mode);
    load();
    HRESULT hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr, CLSCTX_ALL, __uuidof(IMMDeviceEnumerator),
                                  reinterpret_cast<void **>(devices_.put()));
    if (FAILED(hr)) {
        error_ = "audio service: " + im_hr(hr);
        return hr;
    }
    device_watch_ = new DeviceWatch(wake);
    devices_->RegisterEndpointNotificationCallback(device_watch_);
    add_outputs();
    return S_OK;
}

// Every active output's session manager, each watched for new sessions; the sessions already there are applied.
void Sessions::add_outputs() {
    Com<IMMDeviceCollection> all;
    if (FAILED(devices_->EnumAudioEndpoints(eRender, DEVICE_STATE_ACTIVE, all.put()))) return;
    UINT n = 0;
    all->GetCount(&n);
    for (UINT i = 0; i < n; i++) {
        Com<IMMDevice> dev;
        if (FAILED(all->Item(i, dev.put()))) continue;
        LPWSTR idw = nullptr;
        if (FAILED(dev->GetId(&idw))) continue;
        std::wstring id = idw;
        CoTaskMemFree(idw);
        bool known = false;
        for (auto &o : outputs_) known = known || o.id == id;
        if (known) continue;
        Output o;
        o.id = id;
        if (FAILED(dev->Activate(__uuidof(IAudioSessionManager2), CLSCTX_ALL, nullptr,
                                 reinterpret_cast<void **>(o.mgr.put()))))
            continue;
        // Windows sends new-session notifications only after the session list was asked for once
        Com<IAudioSessionEnumerator> e;
        o.mgr->GetSessionEnumerator(e.put());
        o.watch = new SessionWatch(this);
        if (FAILED(o.mgr->RegisterSessionNotification(o.watch))) {
            o.watch->Release();
            o.watch = nullptr;
        }
        int count = 0;
        if (e) e->GetCount(&count);
        for (int k = 0; k < count; k++) {
            Com<IAudioSessionControl> c;
            if (SUCCEEDED(e->GetSession(k, c.put()))) apply(c.p, true);
        }
        outputs_.push_back(std::move(o));
    }
}

void Sessions::scan() {
    std::lock_guard<std::recursive_mutex> l(mu_);
    if (!devices_) return;
    // sessions that ended (marked by their callback): unwatched here, outside Windows' callbacks
    for (size_t k = 0; k < tracked_.size();) {
        if (tracked_[k].events && tracked_[k].events->dead.load()) {
            drop(tracked_[k]);
            tracked_.erase(tracked_.begin() + (long)k);
        } else {
            k++;
        }
    }
    add_outputs();
    for (auto &o : outputs_) {
        Com<IAudioSessionEnumerator> e;
        if (FAILED(o.mgr->GetSessionEnumerator(e.put()))) continue;
        int count = 0;
        e->GetCount(&count);
        for (int k = 0; k < count; k++) {
            Com<IAudioSessionControl> c;
            if (SUCCEEDED(e->GetSession(k, c.put()))) apply(c.p, true);
        }
    }
}

// In Windows' notification thread: lowered (or given back) at once, without the main lock; watched from the next
// scan (main loop).
void Sessions::on_session(IAudioSessionControl *ctl) {
    apply(ctl, false);
    SetEvent(wake);
}

// One session: lowered (ATTENUATE) or given its stored level back (RESTORE_ONLY). With track (main loop only, mu_
// held), the session is also watched for the user's volume changes and its end. Without (a notification), only
// the store's lock is taken.
void Sessions::apply(IAudioSessionControl *ctl, bool track) {
    Com<IAudioSessionControl2> c2;
    if (FAILED(ctl->QueryInterface(__uuidof(IAudioSessionControl2), reinterpret_cast<void **>(c2.put())))) return;
    AudioSessionState st = AudioSessionStateInactive;
    if (SUCCEEDED(c2->GetState(&st)) && st == AudioSessionStateExpired) return;
    DWORD pid = 0;
    c2->GetProcessId(&pid); // fails (AUDCLNT_S_NO_SINGLE_PROCESS) for some shared sessions: pid stays 0
    if (pid == self_ && pid != 0) return; // our own output
    LPWSTR idw = nullptr;
    if (FAILED(c2->GetSessionIdentifier(&idw)) || !idw) return;
    std::wstring id = idw;
    CoTaskMemFree(idw);
    if (left_alone(id)) return;
    Com<ISimpleAudioVolume> vol;
    if (FAILED(ctl->QueryInterface(__uuidof(ISimpleAudioVolume), reinterpret_cast<void **>(vol.put())))) return;

    // the same session seen again (scan): only check its level
    Tracked *t = nullptr;
    for (auto &x : track ? tracked_ : no_tracked_) {
        IUnknown *a = nullptr, *b = nullptr;
        x.ctl->QueryInterface(__uuidof(IUnknown), reinterpret_cast<void **>(&a));
        c2->QueryInterface(__uuidof(IUnknown), reinterpret_cast<void **>(&b));
        bool same = a == b;
        if (a) a->Release();
        if (b) b->Release();
        if (same) {
            t = &x;
            break;
        }
    }

    float cur = 1.0f;
    vol->GetMasterVolume(&cur);
    if (mode_.load() == RESTORE_ONLY) {
        give_back(vol.p, id, pid, st, cur);
        return;
    }

    // Every session is lowered at once, playing or not: a new app is lowered in Windows' notification, before its
    // first sound. The meter cannot tell an app that plays from one that only records the speakers (a recorder's
    // meter shows what it records after its own volume): recorders are lowered too, so they record the originals
    // at -80 dB while filtering is on, unless they are on the leave-alone list.
    lower(vol.p, id, pid, st, cur, track);

    if (!t && track) {
        Tracked n;
        n.ctl.p = c2.p;
        c2.p = nullptr; // moved
        n.vol.p = vol.p;
        vol.p = nullptr;
        n.id = id;
        n.pid = pid;
        n.events = new SessionEvents(this, id, pid, n.vol.p);
        if (FAILED(n.ctl->RegisterAudioSessionNotification(n.events))) {
            n.events->Release();
            n.events = nullptr;
        }
        tracked_.push_back(std::move(n));
    }
}

// The user (or the app itself) changed a lowered app's volume: that is the user's new level, lowered again.
// (Notification thread: the store's lock only.)
void Sessions::on_volume(const std::wstring &id, ISimpleAudioVolume *vol, float v) {
    if (mode_.load() != ATTENUATE) return;
    float user;
    {
        std::lock_guard<std::mutex> l(store_mu_);
        if (v > att_ * 1.5f || !store_.count(id)) store_[id] = v > att_ * 1.5f ? v : 1.0f;
        // else: someone set it near zero; keep the level we knew
        user = store_[id];
        save();
    }
    vol->SetMasterVolume(user * att_, &IM_VOLUME_CONTEXT);
}

// Lowers one session to att x the user's level; the user's level is the stored one (we lowered this app before,
// maybe in an earlier run that Windows remembered), else what the session has now.
void Sessions::lower(ISimpleAudioVolume *vol, const std::wstring &id, DWORD pid, AudioSessionState st, float cur,
                     bool track) {
    float user;
    {
        std::lock_guard<std::mutex> l(store_mu_);
        auto it = store_.find(id);
        if (it != store_.end()) {
            user = it->second;
        } else if (cur <= att_ * 1.01f && cur > 0) {
            user = 1.0f; // lowered by us in a run whose store was lost: no level of the user's to go back to but full
        } else {
            user = cur;
        }
        if (it == store_.end() || it->second != user) {
            store_[id] = user;
            save();
        }
    }
    float want = user * att_;
    if (std::fabs(cur - want) <= want * 0.01f + 1e-9f) return;
    HRESULT hr = vol->SetMasterVolume(want, &IM_VOLUME_CONTEXT);
    if (log) log("sessions: pid %lu %s, level %.4f -> %.6f (user %.4f)%s%s", (unsigned long)pid, state_name(st), cur,
                 want, user, track ? "" : ", from the notification", SUCCEEDED(hr) ? "" : im_hr(hr).c_str());
}

// Gives a session its stored level back, if it has one (the store's lock only, not during the audio call).
void Sessions::give_back(ISimpleAudioVolume *vol, const std::wstring &id, DWORD pid, AudioSessionState st, float cur) {
    float v;
    {
        std::lock_guard<std::mutex> l(store_mu_);
        auto it = store_.find(id);
        if (it == store_.end()) return;
        v = it->second;
    }
    HRESULT hr = vol->SetMasterVolume(v, &IM_VOLUME_CONTEXT);
    if (log) log("sessions: pid %lu %s, level %.4f -> %.4f: %s", (unsigned long)pid, state_name(st), cur, v,
                 SUCCEEDED(hr) ? "given back" : im_hr(hr).c_str());
    if (FAILED(hr)) return;
    std::lock_guard<std::mutex> l(store_mu_);
    store_.erase(id);
    save();
}

void Sessions::restore_all() {
    std::lock_guard<std::recursive_mutex> l(mu_);
    mode_.store(RESTORE_ONLY);
    for (auto &t : tracked_) {
        if (!(t.events && t.events->dead.load())) {
            float cur = 1.0f;
            t.vol->GetMasterVolume(&cur);
            give_back(t.vol.p, t.id, t.pid, AudioSessionStateActive, cur);
        }
        drop(t);
    }
    tracked_.clear();
    scan(); // sessions not tracked yet (started a moment ago)
}

void Sessions::lower_all() {
    std::lock_guard<std::recursive_mutex> l(mu_);
    mode_.store(ATTENUATE);
    scan();
}

// The identifier names the program: "...|\\Device\\HarddiskVolume3\\...\\obs64.exe%b{...}".
bool Sessions::left_alone(const std::wstring &id) const {
    std::wstring low = id;
    for (auto &ch : low) ch = (wchar_t)towlower(ch);
    for (const auto &name : leave_alone)
        if (low.find(L"\\" + name + L"%b") != std::wstring::npos) return true;
    return false;
}

int Sessions::lowered() const {
    std::lock_guard<std::recursive_mutex> l(mu_);
    int n = 0;
    for (auto &t : tracked_) n += !(t.events && t.events->dead.load());
    return mode_.load() == ATTENUATE ? n : 0;
}

std::string Sessions::meters() const {
    std::lock_guard<std::recursive_mutex> l(mu_);
    std::string s;
    for (auto &t : tracked_) {
        if (t.events && t.events->dead.load()) continue;
        Com<ImMeter> m;
        UINT ch = 0;
        float peak = -1;
        AudioSessionState st = AudioSessionStateInactive;
        t.ctl->GetState(&st);
        if (SUCCEEDED(t.ctl->QueryInterface(IID_ImMeter, reinterpret_cast<void **>(m.put())))) {
            m->GetMeteringChannelCount(&ch);
            m->GetPeakValue(&peak);
        }
        char b[128];
        snprintf(b, sizeof b, "%spid %lu %s %uch peak %.6f", s.empty() ? "" : ", ", (unsigned long)t.pid,
                 state_name(st), ch, peak);
        s += b;
    }
    return s;
}

int Sessions::pending() const {
    std::lock_guard<std::mutex> l(store_mu_);
    return (int)store_.size();
}

std::string Sessions::last_error() const {
    std::lock_guard<std::recursive_mutex> l(mu_);
    return error_;
}

// store: one line per session, "<level>\t<identifier>", UTF-8, written to a temporary file and renamed
void Sessions::save() {
    std::wstring tmp = store_path_ + L".tmp";
    FILE *f = _wfopen(tmp.c_str(), L"wb");
    if (!f) return;
    for (auto &kv : store_) fprintf(f, "%.6f\t%s\n", kv.second, im_utf8(kv.first.c_str()).c_str());
    bool ok = fflush(f) == 0;
    fclose(f);
    if (ok) MoveFileExW(tmp.c_str(), store_path_.c_str(), MOVEFILE_REPLACE_EXISTING);
}

void Sessions::load() {
    std::lock_guard<std::mutex> l(store_mu_);
    store_.clear();
    FILE *f = _wfopen(store_path_.c_str(), L"rb");
    if (!f) return;
    char line[4096];
    while (fgets(line, sizeof line, f)) {
        char *tab = strchr(line, '\t');
        if (!tab) continue;
        *tab = 0;
        char *end = tab + 1 + strlen(tab + 1);
        while (end > tab + 1 && (end[-1] == '\n' || end[-1] == '\r')) *--end = 0;
        float v = (float)atof(line);
        if (v > 0 && v <= 1.0f && tab[1]) store_[im_wide(tab + 1)] = v;
    }
    fclose(f);
}
