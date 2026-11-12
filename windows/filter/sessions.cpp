#include "sessions.h"

#include <atomic>
#include <cmath>
#include <cstring>
#include <cstdio>

// {6c1f3a52-9d0e-4b7a-a7c4-5a1e0d2b8f31}
const GUID IM_VOLUME_CONTEXT = {0x6c1f3a52, 0x9d0e, 0x4b7a, {0xa7, 0xc4, 0x5a, 0x1e, 0x0d, 0x2b, 0x8f, 0x31}};

namespace {

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
// Windows calls these on its own threads. They never register or unregister anything (not allowed from inside a
// session callback): the main loop does that in Sessions::scan.
class SessionEvents final : public Unknown<SessionEvents, IAudioSessionEvents> {
  public:
    explicit SessionEvents(Sessions *owner) : owner_(owner) {}
    void detach() { owner_.store(nullptr); }

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
        if (Sessions *o = owner_.load()) o->on_volume(this, v, ctx);
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
        if (Sessions *o = owner_.load()) o->on_gone(this);
    }
    std::atomic<Sessions *> owner_;
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
    mode_ = mode;
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
        if (tracked_[k].dead) {
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

void Sessions::on_session(IAudioSessionControl *ctl) {
    std::lock_guard<std::recursive_mutex> l(mu_);
    apply(ctl, false); // lowered now; watched from the next scan (main loop)
    SetEvent(wake);
}

// One session: lowered (ATTENUATE) or given its stored level back (RESTORE_ONLY). With track (main loop only),
// the session is also watched for the user's volume changes and its end.
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
    Com<ISimpleAudioVolume> vol;
    if (FAILED(ctl->QueryInterface(__uuidof(ISimpleAudioVolume), reinterpret_cast<void **>(vol.put())))) return;

    // the same session seen again (scan): only check its level
    Tracked *t = nullptr;
    for (auto &x : tracked_) {
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
    auto it = store_.find(id);
    if (mode_ == RESTORE_ONLY) {
        if (it != store_.end()) {
            HRESULT hr = vol->SetMasterVolume(it->second, &IM_VOLUME_CONTEXT);
            if (log) log("sessions: pid %lu %s, level %.4f -> %.4f: %s", (unsigned long)pid, state_name(st), cur,
                         it->second, SUCCEEDED(hr) ? "given back" : im_hr(hr).c_str());
            if (SUCCEEDED(hr)) {
                store_.erase(it);
                save();
            }
        }
        return;
    }

    // the user's level: the stored one (we lowered this app before, maybe in an earlier run that Windows
    // remembered), else what the session has now
    float user;
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
    float want = user * att_;
    if (std::fabs(cur - want) > want * 0.01f + 1e-9f) {
        HRESULT hr = vol->SetMasterVolume(want, &IM_VOLUME_CONTEXT);
        // experiment: does the meter tell a session that plays from one that only records (loopback)?
        UINT meter_ch = 99;
        float meter_peak = -1;
        Com<IAudioMeterInformation> meter;
        if (SUCCEEDED(ctl->QueryInterface(__uuidof(IAudioMeterInformation), reinterpret_cast<void **>(meter.put())))) {
            meter->GetMeteringChannelCount(&meter_ch);
            meter->GetPeakValue(&meter_peak);
        }
        if (log) log("sessions: pid %lu %s, level %.4f -> %.6f (user %.4f)%s%s, meter %u ch peak %.6f",
                     (unsigned long)pid, state_name(st), cur, want, user, track ? "" : ", from the notification",
                     SUCCEEDED(hr) ? "" : im_hr(hr).c_str(), meter_ch, meter_peak);
    }

    if (!t && track) {
        Tracked n;
        n.ctl.p = c2.p;
        c2.p = nullptr; // moved
        n.vol.p = vol.p;
        vol.p = nullptr;
        n.id = id;
        n.pid = pid;
        n.events = new SessionEvents(this);
        if (FAILED(n.ctl->RegisterAudioSessionNotification(n.events))) {
            n.events->Release();
            n.events = nullptr;
        }
        tracked_.push_back(std::move(n));
    }
}

// The user (or the app itself) changed a lowered app's volume: that is the user's new level, lowered again.
void Sessions::on_volume(SessionEvents *s, float v, LPCGUID ctx) {
    if (ctx && IsEqualGUID(*ctx, IM_VOLUME_CONTEXT)) return;
    std::lock_guard<std::recursive_mutex> l(mu_);
    if (mode_ != ATTENUATE) return;
    for (auto &t : tracked_) {
        if (t.events != s || t.dead) continue;
        if (v > att_ * 1.5f) store_[t.id] = v; // else: someone set it near zero; keep the level we knew
        save();
        t.vol->SetMasterVolume(store_[t.id] * att_, &IM_VOLUME_CONTEXT);
        return;
    }
}

// Keeps its stored level: Windows remembers the lowered one for the app's next run.
void Sessions::on_gone(SessionEvents *s) {
    std::lock_guard<std::recursive_mutex> l(mu_);
    for (auto &t : tracked_)
        if (t.events == s) t.dead = true;
    SetEvent(wake);
}

void Sessions::restore_all() {
    std::lock_guard<std::recursive_mutex> l(mu_);
    mode_ = RESTORE_ONLY;
    for (auto &t : tracked_) {
        auto it = store_.find(t.id);
        if (!t.dead && it != store_.end()) {
            HRESULT hr = t.vol->SetMasterVolume(it->second, &IM_VOLUME_CONTEXT);
            if (log) log("sessions: pid %lu given back %.4f: %s", (unsigned long)t.pid, it->second,
                         SUCCEEDED(hr) ? "ok" : im_hr(hr).c_str());
            if (SUCCEEDED(hr)) store_.erase(it);
        }
        drop(t);
    }
    tracked_.clear();
    save();
    scan(); // sessions not tracked yet (started a moment ago)
}

void Sessions::lower_all() {
    std::lock_guard<std::recursive_mutex> l(mu_);
    mode_ = ATTENUATE;
    scan();
}

int Sessions::lowered() const {
    std::lock_guard<std::recursive_mutex> l(mu_);
    return mode_ == ATTENUATE ? (int)tracked_.size() : 0;
}

int Sessions::pending() const {
    std::lock_guard<std::recursive_mutex> l(mu_);
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
