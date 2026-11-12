// waaiya-filter.exe: Waaiya's always-on sound filter for Windows 10 2004+ / 11. No driver, no admin rights.
//
//   waaiya-filter run [--bypass] [--model F] [--detector F] [--settings F] [--dir D] [--log-stderr]
//   waaiya-filter stop        the running filter gives every app its level back (and keeps giving back the levels
//                             of apps that are not running when they next play), or, with none running, that is
//                             done here
//   waaiya-filter restore     only give back stored levels, as apps show up; exits once none is left
//   waaiya-filter status      prints the state file (state.json) and whether a filter process holds it
//
// How it works (reports/desktop_windows_macos_scope.md, route C2): every other app's audio session is turned down
// to 1e-4 (-80 dB) of the user's level (sessions.cpp), so the original is practically silent; one process-loopback
// capture of every process but ours reads their mix, still in float, which is multiplied by 1e4, filtered by the
// engine (engine/src/im_engine.c) and played to the default output. Windows applies the device volume after the
// capture, so the volume keys work as before.
//
// Fail-closed: the lowered levels are kept by Windows, also when this process dies: then apps are silent until
// the filter runs again or is stopped (the app's Stop gives the levels back). A sound that reaches the capture
// louder than a lowered app can (an app not lowered yet) is never played amplified: the output is silent while it
// lasts and the sessions are looked at again ("leaks" in the state).
//
// Settings: the app's settings.json (%APPDATA%\Waaiya), read again when it changes: audio_stereo, hold_silence,
// mute_women_singing. State: %LOCALAPPDATA%\Waaiya\filter\state.json, rewritten twice a second.
#include "../common/wasapi.h"
#include "sessions.h"

#include <avrt.h>
#include <shlobj.h>

#include <algorithm>
#include <atomic>
#include <cmath>
#include <cstdarg>
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

extern "C" {
#include "im_engine.h"
}

namespace {

constexpr int RATE = 48000;
constexpr int CH = 2;
constexpr float ATT = 1e-4f;               // lowered sessions: -80 dB
constexpr float LEAK_RAW = 2.5e-4f;        // capture peak no lowered app can reach (2.5x full scale after the gain)
constexpr double LEAK_HOLD_MS = 300;       // output silent this long after a leak
constexpr int RENDER_TARGET_MS = 20;       // output queue kept around this (the engine's look-ahead comes on top)
constexpr int RENDER_MAX_MS = 80;          // above this, the oldest samples are dropped (clock drift)
constexpr double FAIL_RESTORE_MS = 3000;   // hold_silence off: levels given back after failing this long

const wchar_t *MUTEX_NAME = L"Local\\WaaiyaFilter";
const wchar_t *STOP_NAME = L"Local\\WaaiyaFilterStop";  // stop: give the levels back
const wchar_t *QUIT_NAME = L"Local\\WaaiyaFilterQuit";  // a restore-only instance makes way for a new run

double now_ms() {
    static LARGE_INTEGER f = [] {
        LARGE_INTEGER x;
        QueryPerformanceFrequency(&x);
        return x;
    }();
    LARGE_INTEGER c;
    QueryPerformanceCounter(&c);
    return (double)c.QuadPart * 1000.0 / (double)f.QuadPart;
}

long long unix_ms() {
    FILETIME ft;
    GetSystemTimeAsFileTime(&ft);
    ULARGE_INTEGER u;
    u.LowPart = ft.dwLowDateTime;
    u.HighPart = ft.dwHighDateTime;
    return (long long)(u.QuadPart / 10000ULL) - 11644473600000LL;
}

std::wstring known_folder(REFKNOWNFOLDERID id) {
    PWSTR p = nullptr;
    std::wstring s;
    if (SUCCEEDED(SHGetKnownFolderPath(id, 0, nullptr, &p))) s = p;
    CoTaskMemFree(p);
    return s;
}

std::wstring exe_dir() {
    wchar_t buf[MAX_PATH * 2];
    DWORD n = GetModuleFileNameW(nullptr, buf, (DWORD)(sizeof buf / sizeof *buf));
    std::wstring s(buf, n);
    size_t k = s.find_last_of(L"\\/");
    return k == std::wstring::npos ? L"." : s.substr(0, k);
}

bool exists(const std::wstring &p) { return GetFileAttributesW(p.c_str()) != INVALID_FILE_ATTRIBUTES; }

// The first of <exe dir>\<rel>, <exe dir>\..\<rel> that exists ("" if none).
std::wstring bundled(const std::wstring &rel) {
    std::wstring d = exe_dir();
    for (const std::wstring &c : {d + L"\\" + rel, d + L"\\..\\" + rel})
        if (exists(c)) return c;
    return L"";
}

// ---- log: <dir>\filter.log, cut to its last part when it grows past 512 KiB

FILE *g_log = nullptr;
bool g_log_stderr = false;

void logf(const char *fmt, ...) {
    char msg[1024];
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(msg, sizeof msg, fmt, ap);
    va_end(ap);
    SYSTEMTIME t;
    GetLocalTime(&t);
    char line[1200];
    snprintf(line, sizeof line, "%04d-%02d-%02d %02d:%02d:%02d.%03d %s\n", t.wYear, t.wMonth, t.wDay, t.wHour,
             t.wMinute, t.wSecond, t.wMilliseconds, msg);
    if (g_log) {
        fputs(line, g_log);
        fflush(g_log);
    }
    if (g_log_stderr) {
        fputs(line, stderr);
        fflush(stderr);
    }
}

void open_log(const std::wstring &dir) {
    std::wstring p = dir + L"\\filter.log";
    WIN32_FILE_ATTRIBUTE_DATA a;
    if (GetFileAttributesExW(p.c_str(), GetFileExInfoStandard, &a) && a.nFileSizeLow > 512 * 1024) {
        FILE *f = _wfopen(p.c_str(), L"rb");
        std::string tail;
        if (f) {
            fseek(f, -128 * 1024, SEEK_END);
            char buf[4096];
            size_t k;
            while ((k = fread(buf, 1, sizeof buf, f)) > 0) tail.append(buf, k);
            fclose(f);
        }
        f = _wfopen(p.c_str(), L"wb");
        if (f) {
            size_t nl = tail.find('\n');
            if (nl != std::string::npos) fwrite(tail.data() + nl + 1, 1, tail.size() - nl - 1, f);
            fclose(f);
        }
    }
    g_log = _wfopen(p.c_str(), L"ab");
}

// ---- settings (the app's settings.json: only three booleans are read; a missing key keeps its default)

struct Settings {
    bool stereo = false;        // audio_stereo (default mono)
    bool hold_silence = true;   // hold_silence
    bool women_singing = false; // mute_women_singing
};

bool json_bool(const std::string &s, const char *key, bool def) {
    std::string k = std::string("\"") + key + "\"";
    size_t p = s.find(k);
    if (p == std::string::npos) return def;
    p = s.find(':', p + k.size());
    if (p == std::string::npos) return def;
    p++;
    while (p < s.size() && (s[p] == ' ' || s[p] == '\t' || s[p] == '\r' || s[p] == '\n')) p++;
    if (s.compare(p, 4, "true") == 0) return true;
    if (s.compare(p, 5, "false") == 0) return false;
    return def;
}

Settings read_settings(const std::wstring &path) {
    Settings st;
    FILE *f = _wfopen(path.c_str(), L"rb");
    if (!f) return st;
    std::string s;
    char buf[4096];
    size_t k;
    while ((k = fread(buf, 1, sizeof buf, f)) > 0) s.append(buf, k);
    fclose(f);
    st.stereo = json_bool(s, "audio_stereo", st.stereo);
    st.hold_silence = json_bool(s, "hold_silence", st.hold_silence);
    st.women_singing = json_bool(s, "mute_women_singing", st.women_singing);
    return st;
}

// ---- state file

struct State {
    const char *state = "starting"; // starting | filtering | failing | restoring | stopped
    std::string engine = "starting"; // ok | model not loaded, ... | detector not loaded, ... | starting
    std::string error;
    std::string device;
    int lowered = 0, pending = 0;
    unsigned long leaks = 0, underruns = 0, dropped = 0;
    unsigned long long cap_frames = 0, out_frames = 0; // since the audio opened
    float cap_peak = 0, out_peak = 0;                  // over the last state period (raw capture, before the gain)
    double delay_ms = 0, cpu = 0;
    bool mono = true, women_singing = false, bypass = false;
};

std::string json_str(const std::string &s) {
    std::string o = "\"";
    for (unsigned char c : s) {
        if (c == '"' || c == '\\') {
            o += '\\';
            o += (char)c;
        } else if (c < 0x20) {
            char b[8];
            snprintf(b, sizeof b, "\\u%04x", c);
            o += b;
        } else {
            o += (char)c;
        }
    }
    return o + "\"";
}

void write_state(const std::wstring &dir, const State &s) {
    char buf[2048];
    snprintf(buf, sizeof buf,
             "{\"pid\":%lu,\"t\":%lld,\"state\":\"%s\",\"engine\":%s,\"error\":%s,\"device\":%s,\"lowered\":%d,"
             "\"pending\":%d,\"leaks\":%lu,\"underruns\":%lu,\"dropped\":%lu,\"delay_ms\":%.1f,\"cpu\":%.1f,"
             "\"cap_frames\":%llu,\"out_frames\":%llu,\"cap_peak\":%.7f,\"out_peak\":%.5f,"
             "\"mono\":%s,\"women_singing\":%s,\"bypass\":%s}\n",
             (unsigned long)GetCurrentProcessId(), unix_ms(), s.state, json_str(s.engine).c_str(),
             json_str(s.error).c_str(), json_str(s.device).c_str(), s.lowered, s.pending, s.leaks, s.underruns,
             s.dropped, s.delay_ms, s.cpu, s.cap_frames, s.out_frames, s.cap_peak, s.out_peak, s.mono ? "true" : "false", s.women_singing ? "true" : "false",
             s.bypass ? "true" : "false");
    std::wstring p = dir + L"\\state.json", tmp = p + L".tmp";
    FILE *f = _wfopen(tmp.c_str(), L"wb");
    if (!f) return;
    fputs(buf, f);
    fclose(f);
    MoveFileExW(tmp.c_str(), p.c_str(), MOVEFILE_REPLACE_EXISTING);
}

double cpu_ms() {
    FILETIME c, e, k, u;
    GetProcessTimes(GetCurrentProcess(), &c, &e, &k, &u);
    auto ms = [](FILETIME f) { return (double)(((unsigned long long)f.dwHighDateTime << 32) | f.dwLowDateTime) / 1e4; };
    return ms(k) + ms(u);
}

// ---- audio: one capture (every process but ours) and one output (the default device)

struct Audio {
    Com<IMMDeviceEnumerator> devices;
    Com<IAudioClient> cap_client;
    Com<IAudioCaptureClient> cap;
    Com<IAudioClient> out_client;
    Com<IAudioRenderClient> out;
    HANDLE cap_event = CreateEventW(nullptr, FALSE, FALSE, nullptr);
    UINT32 out_frames = 0;
    std::wstring out_id;
    std::string out_name;
    bool running = false;

    ~Audio() { CloseHandle(cap_event); }

    void close() {
        if (cap_client) cap_client->Stop();
        if (out_client) out_client->Stop();
        cap.reset();
        cap_client.reset();
        out.reset();
        out_client.reset();
        out_id.clear();
        running = false;
    }

    std::wstring default_id() {
        Com<IMMDevice> d;
        if (!devices || FAILED(devices->GetDefaultAudioEndpoint(eRender, eConsole, d.put()))) return L"";
        LPWSTR id = nullptr;
        std::wstring s;
        if (SUCCEEDED(d->GetId(&id))) s = id;
        CoTaskMemFree(id);
        return s;
    }

    // "" on success, else what failed
    std::string open() {
        close();
        HRESULT hr;
        if (!devices &&
            FAILED(hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr, CLSCTX_ALL,
                                         __uuidof(IMMDeviceEnumerator), reinterpret_cast<void **>(devices.put()))))
            return "audio service: " + im_hr(hr);
        WAVEFORMATEX fmt = im_float_format(RATE, CH);

        // output: the default device, our format converted by Windows
        Com<IMMDevice> dev;
        if (FAILED(hr = devices->GetDefaultAudioEndpoint(eRender, eConsole, dev.put()))) return "no output: " + im_hr(hr);
        LPWSTR id = nullptr;
        if (SUCCEEDED(dev->GetId(&id))) out_id = id;
        CoTaskMemFree(id);
        out_name = im_device_name(dev.p);
        if (FAILED(hr = dev->Activate(__uuidof(IAudioClient), CLSCTX_ALL, nullptr,
                                      reinterpret_cast<void **>(out_client.put()))))
            return "output: " + im_hr(hr);
        const DWORD conv = AUDCLNT_STREAMFLAGS_AUTOCONVERTPCM | AUDCLNT_STREAMFLAGS_SRC_DEFAULT_QUALITY;
        if (FAILED(hr = out_client->Initialize(AUDCLNT_SHAREMODE_SHARED, conv | AUDCLNT_STREAMFLAGS_NOPERSIST,
                                               (REFERENCE_TIME)RENDER_MAX_MS * 2 * 10000, 0, &fmt, nullptr)))
            return "output format: " + im_hr(hr);
        out_client->GetBufferSize(&out_frames);
        if (FAILED(hr = out_client->GetService(__uuidof(IAudioRenderClient), reinterpret_cast<void **>(out.put()))))
            return "output: " + im_hr(hr);

        // capture: every process except this one (our output is not captured again)
        if (FAILED(hr = im_activate_process_loopback(GetCurrentProcessId(), true, cap_client.put())))
            return "capture (Windows 10 2004 or newer needed): " + im_hr(hr);
        if (FAILED(hr = cap_client->Initialize(AUDCLNT_SHAREMODE_SHARED,
                                               AUDCLNT_STREAMFLAGS_LOOPBACK | AUDCLNT_STREAMFLAGS_EVENTCALLBACK | conv,
                                               200000, 0, &fmt, nullptr)))
            return "capture format: " + im_hr(hr);
        if (FAILED(hr = cap_client->SetEventHandle(cap_event))) return "capture: " + im_hr(hr);
        if (FAILED(hr = cap_client->GetService(__uuidof(IAudioCaptureClient), reinterpret_cast<void **>(cap.put()))))
            return "capture: " + im_hr(hr);

        // a little silence first, so the output does not run dry while the first hops come in
        BYTE *buf = nullptr;
        UINT32 pre = RATE * RENDER_TARGET_MS / 1000;
        if (pre < out_frames && SUCCEEDED(out->GetBuffer(pre, &buf))) out->ReleaseBuffer(pre, AUDCLNT_BUFFERFLAGS_SILENT);
        if (FAILED(hr = out_client->Start())) return "output start: " + im_hr(hr);
        if (FAILED(hr = cap_client->Start())) return "capture start: " + im_hr(hr);
        running = true;
        return "";
    }
};

// ---- commands

struct Paths {
    std::wstring dir;      // %LOCALAPPDATA%\Waaiya\filter
    std::wstring settings; // %APPDATA%\Waaiya\settings.json
    std::wstring store;    // <dir>\levels.txt
    std::wstring model, detector;
};

Paths default_paths() {
    Paths p;
    std::wstring local = known_folder(FOLDERID_LocalAppData), roaming = known_folder(FOLDERID_RoamingAppData);
    p.dir = local + L"\\Waaiya\\filter";
    SHCreateDirectoryExW(nullptr, p.dir.c_str(), nullptr);
    p.settings = roaming + L"\\Waaiya\\settings.json";
    p.store = p.dir + L"\\levels.txt";
    p.model = bundled(L"models\\dfn3\\dfn3_stream_int8.onnx");
    p.detector = bundled(L"models\\detector\\detector_v1.onnx");
    return p;
}

// Restore-only: gives stored levels back as their apps show up, until none is left (or a new run asks to quit).
int restore_loop(Sessions &ses, const Paths &p, HANDLE quit) {
    State st;
    st.state = "restoring";
    st.engine = "";
    while (ses.pending() > 0) {
        st.pending = ses.pending();
        write_state(p.dir, st);
        HANDLE hs[2] = {ses.wake, quit};
        DWORD w = WaitForMultipleObjects(2, hs, FALSE, 2000);
        if (w == WAIT_OBJECT_0 + 1) break;
        ses.scan();
    }
    st.state = "stopped";
    st.pending = ses.pending();
    write_state(p.dir, st);
    logf("restore: done, %d level(s) still stored", st.pending);
    return 0;
}

int cmd_run(const Paths &p, bool bypass, bool restore_only) {
    // one filter at a time; a restore-only instance makes way
    HANDLE mtx = CreateMutexW(nullptr, FALSE, MUTEX_NAME);
    HANDLE quit = CreateEventW(nullptr, FALSE, FALSE, QUIT_NAME);
    HANDLE stop = CreateEventW(nullptr, FALSE, FALSE, STOP_NAME);
    DWORD w = WaitForSingleObject(mtx, 0);
    if (w == WAIT_TIMEOUT) {
        if (restore_only) return 0; // a filter or a restorer runs: it gives the levels back itself
        // a running restorer quits (SetEvent on QUIT); a running filter does not listen to QUIT
        SetEvent(quit);
        w = WaitForSingleObject(mtx, 3000);
        if (w == WAIT_TIMEOUT) {
            fprintf(stderr, "waaiya-filter: already running\n");
            return 0;
        }
    }
    ResetEvent(stop);
    ResetEvent(quit);
    open_log(p.dir);

    Sessions ses(ATT, p.store, GetCurrentProcessId());
    ses.log = logf;
    HRESULT hr = ses.start(restore_only ? Sessions::RESTORE_ONLY : Sessions::ATTENUATE);
    if (FAILED(hr)) {
        logf("sessions: %s", ses.last_error().c_str());
        State st;
        st.state = "failing";
        st.error = ses.last_error();
        write_state(p.dir, st);
        return 1;
    }
    if (restore_only) {
        logf("restore: %d level(s) to give back", ses.pending());
        int r = restore_loop(ses, p, quit);
        ReleaseMutex(mtx);
        return r;
    }

    logf("run: model %s, detector %s%s", im_utf8(p.model.c_str()).c_str(),
         p.detector.empty() ? "none" : im_utf8(p.detector.c_str()).c_str(), bypass ? ", bypass (tests)" : "");
    Settings set = read_settings(p.settings);

    // the engine: always built for stereo, so "mono" (the default) can switch both ways live
    std::string model8 = im_utf8(p.model.c_str()), det8 = im_utf8(p.detector.c_str());
    im_config cfg = {};
    cfg.model_path = model8.c_str();
    cfg.channels = CH;
    cfg.sample_rate = RATE;
    cfg.threads = 1;
    cfg.mono_mix = 0;
    cfg.detector_path = det8.empty() ? nullptr : det8.c_str();
    char err[512] = "";
    im_engine *eng = nullptr;
    im_engine_create(&cfg, &eng, err, sizeof err);
    State st;
    st.bypass = bypass;
    if (!eng) {
        logf("engine: out of memory");
        return 1;
    }
    if (im_engine_failed(eng)) st.engine = std::string("model not loaded, ") + err; // silence (fail-closed)
    else if (set.women_singing && im_engine_detector_error(eng)[0])
        st.engine = std::string("detector not loaded, ") + im_engine_detector_error(eng);
    else st.engine = "ok";
    logf("engine: %s", st.engine.c_str());
    auto apply_settings = [&](const Settings &s) {
        st.mono = im_engine_set_mono(eng, s.stereo ? 0 : 1) == 1;
        st.women_singing = s.women_singing;
        im_engine_set_policy(eng, s.women_singing ? (IM_POLICY_MUTE_FEMALE_SINGING | IM_POLICY_FAIL_CLOSED) : 0);
        if (im_engine_failed(eng)) return;
        st.engine = s.women_singing && im_engine_detector_error(eng)[0]
                        ? std::string("detector not loaded, ") + im_engine_detector_error(eng)
                        : "ok";
    };
    apply_settings(set);
    im_engine_set_enabled(eng, bypass ? 0 : 1);
    const int hop = im_engine_hop(eng);

    // settings.json changes (the app writes a temporary file and renames it)
    std::wstring sdir = p.settings.substr(0, p.settings.find_last_of(L'\\'));
    SHCreateDirectoryExW(nullptr, sdir.c_str(), nullptr);
    HANDLE setwatch = FindFirstChangeNotificationW(sdir.c_str(), FALSE,
                                                   FILE_NOTIFY_CHANGE_LAST_WRITE | FILE_NOTIFY_CHANGE_FILE_NAME);

    DWORD task = 0;
    HANDLE mm = AvSetMmThreadCharacteristicsW(L"Pro Audio", &task);

    Audio au;
    std::vector<float> in, out, raw(4096 * CH);
    in.reserve(RATE * CH);
    out.reserve(RATE * CH);
    double quiet_at = 0, audio_since = 0, fail_since = 0, retry_at = 0, leak_until = 0, state_at = 0, cpu0 = cpu_ms(), wall0 = now_ms();
    bool restored = false; // hold_silence off and failing: levels given back
    int exit_code = 0;

    for (;;) {
        double t = now_ms();
        // (re)open the audio when it is not running (start, a lost device, the audio service restarted)
        if (!au.running && t >= retry_at) {
            std::string e = au.open();
            if (e.empty()) {
                logf("audio: playing to \"%s\" (output buffer %u frames)", au.out_name.c_str(), au.out_frames);
                audio_since = t;
                st.cap_frames = st.out_frames = 0;
                st.error.clear();
                st.device = au.out_name;
                fail_since = 0;
                in.clear();
                out.clear();
                im_engine_reset(eng);
                if (restored) { // came back after the levels were given back: lower them again
                    ses.lower_all();
                    restored = false;
                }
            } else {
                if (st.error != e) logf("audio: %s", e.c_str());
                st.error = e;
                if (fail_since == 0) fail_since = t;
                retry_at = t + 2000;
            }
        }
        st.state = au.running ? "filtering" : "failing";
        if (!au.running && !set.hold_silence && !restored && fail_since > 0 && t - fail_since > FAIL_RESTORE_MS) {
            // the user wants the normal sound back when filtering stops by itself
            logf("audio failing for %.0f s, hold_silence off: levels given back", (t - fail_since) / 1000);
            ses.restore_all();
            restored = true;
        }

        HANDLE hs[5];
        int nh = 0;
        hs[nh++] = stop;
        hs[nh++] = ses.wake;
        int i_set = setwatch != INVALID_HANDLE_VALUE ? nh : -1;
        if (i_set >= 0) hs[nh++] = setwatch;
        int i_cap = au.running ? nh : -1;
        if (i_cap >= 0) hs[nh++] = au.cap_event;
        w = WaitForMultipleObjects((DWORD)nh, hs, FALSE, au.running ? 50 : 500);
        t = now_ms();
        if (t >= quiet_at) { // sessions that play nothing yet: lowered as soon as they do
            quiet_at = t + 50;
            ses.poll_quiet();
        }

        if (w == WAIT_OBJECT_0) { // stop: levels back, then restore-only for the apps not running now
            logf("stop: giving the levels back");
            break;
        }
        if (w == WAIT_OBJECT_0 + 1) {
            ses.scan();
            // the default output changed (headphones plugged in): play there
            if (au.running && au.default_id() != au.out_id) {
                logf("audio: default output changed");
                au.close();
                retry_at = 0;
            }
        }
        if (i_set >= 0 && w == WAIT_OBJECT_0 + (DWORD)i_set) {
            FindNextChangeNotification(setwatch);
            Settings ns = read_settings(p.settings);
            if (ns.stereo != set.stereo || ns.women_singing != set.women_singing || ns.hold_silence != set.hold_silence) {
                logf("settings: stereo %d, women_singing %d, hold_silence %d", ns.stereo, ns.women_singing,
                     ns.hold_silence);
                set = ns;
                apply_settings(set);
            }
        }

        if (au.running) {
            // ---- capture -> gain -> engine
            UINT32 n = 0;
            HRESULT chr = S_OK;
            while (SUCCEEDED(chr = au.cap->GetNextPacketSize(&n)) && n > 0) {
                BYTE *data = nullptr;
                UINT32 frames = 0;
                DWORD flags = 0;
                if (FAILED(chr = au.cap->GetBuffer(&data, &frames, &flags, nullptr, nullptr))) break;
                const float *src = reinterpret_cast<const float *>(data);
                bool silent = (flags & AUDCLNT_BUFFERFLAGS_SILENT) != 0 || !src;
                float peak = 0;
                size_t base = in.size();
                in.resize(base + (size_t)frames * CH);
                for (size_t k = 0; k < (size_t)frames * CH; k++) {
                    float x = silent ? 0.0f : src[k];
                    float a = std::fabs(x);
                    if (a > peak) peak = a;
                    in[base + k] = x * (1.0f / ATT);
                }
                au.cap->ReleaseBuffer(frames);
                st.cap_frames += frames;
                if (peak > st.cap_peak) st.cap_peak = peak;
                if (peak > LEAK_RAW) {
                    // louder than any lowered app: an app not lowered (yet). Never played amplified.
                    if (t >= leak_until) {
                        st.leaks++;
                        logf("leak: capture peak %.5f (lowered apps stay under %.5f); sessions looked at again", peak,
                             ATT);
                    }
                    leak_until = t + LEAK_HOLD_MS;
                    SetEvent(ses.wake);
                }
            }
            if (FAILED(chr)) {
                logf("capture: %s", im_hr(chr).c_str());
                au.close();
                retry_at = t + 500;
                continue;
            }
            size_t nh2 = in.size() / ((size_t)hop * CH);
            if (nh2 > 0) {
                size_t len = nh2 * (size_t)hop * CH;
                size_t base = out.size();
                out.resize(base + len);
                im_engine_process_hops_interleaved(eng, in.data(), out.data() + base, (int)nh2);
                in.erase(in.begin(), in.begin() + (long)len);
                bool mute = t < leak_until;
                for (size_t k = base; k < base + len; k++) {
                    float y = mute ? 0.0f : out[k];
                    out[k] = y > 1.0f ? 1.0f : (y < -1.0f ? -1.0f : y);
                }
            }

            // ---- output
            UINT32 pad = 0;
            HRESULT rhr = au.out_client->GetCurrentPadding(&pad);
            if (FAILED(rhr)) {
                logf("output: %s", im_hr(rhr).c_str());
                au.close();
                retry_at = t + 500;
                continue;
            }
            if (pad == 0 && !out.empty()) st.underruns++;
            size_t have = out.size() / CH;
            size_t maxq = (size_t)RATE * RENDER_MAX_MS / 1000;
            if (have + pad > maxq) { // drift: the capture runs faster than the output
                size_t drop = have + pad - (size_t)RATE * RENDER_TARGET_MS / 1000;
                if (drop > have) drop = have;
                out.erase(out.begin(), out.begin() + (long)(drop * CH));
                st.dropped += drop;
                have -= drop;
            }
            UINT32 space = au.out_frames - pad;
            UINT32 wr = (UINT32)std::min<size_t>(have, space);
            BYTE *buf = nullptr;
            if (wr > 0) {
                HRESULT ghr = au.out->GetBuffer(wr, &buf);
                if (SUCCEEDED(ghr)) {
                    for (size_t k = 0; k < (size_t)wr * CH; k++) {
                        float a = std::fabs(out[k]);
                        if (a > st.out_peak) st.out_peak = a;
                    }
                    memcpy(buf, out.data(), (size_t)wr * CH * sizeof(float));
                    au.out->ReleaseBuffer(wr, 0);
                    out.erase(out.begin(), out.begin() + (long)wr * CH);
                    st.out_frames += wr;
                } else if (st.out_frames == 0) {
                    logf("output: GetBuffer(%u): %s", wr, im_hr(ghr).c_str());
                }
            }
            st.delay_ms = (im_engine_aligned_latency(eng) + (double)pad + (double)out.size() / CH) * 1000.0 / RATE;
        }

        if (t >= state_at) {
            state_at = t + 500;
            st.lowered = ses.lowered();
            st.pending = ses.pending();
            double c = cpu_ms();
            if (t - wall0 > 1000) {
                st.cpu = 100.0 * (c - cpu0) / (t - wall0);
                cpu0 = c;
                wall0 = t;
            }
            write_state(p.dir, st);
            if (au.running && t - audio_since < 5000)
                logf("audio: %llu frames in (peak %.7f), %llu out (peak %.4f), %lu underruns, queue %zu", st.cap_frames,
                     st.cap_peak, st.out_frames, st.out_peak, st.underruns, out.size() / CH);
            st.cap_peak = st.out_peak = 0;
        }
    }

    au.close();
    if (mm) AvRevertMmThreadCharacteristics(mm);
    if (setwatch != INVALID_HANDLE_VALUE) FindCloseChangeNotification(setwatch);
    ses.restore_all();
    im_engine_destroy(eng);
    logf("stopped: %d level(s) to give back when their apps play again", ses.pending());
    exit_code = restore_loop(ses, p, quit);
    ReleaseMutex(mtx);
    return exit_code;
}

int cmd_stop(const Paths &p) {
    HANDLE mtx = OpenMutexW(SYNCHRONIZE, FALSE, MUTEX_NAME);
    if (mtx) {
        HANDLE stop = OpenEventW(EVENT_MODIFY_STATE, FALSE, STOP_NAME);
        if (stop) {
            SetEvent(stop);
            CloseHandle(stop);
        }
        // the filter gives the levels back, then keeps running only to give back those of apps not running now
        for (int i = 0; i < 50; i++) {
            Sleep(100);
            FILE *f = _wfopen((p.dir + L"\\state.json").c_str(), L"rb");
            char buf[512] = "";
            if (f) {
                size_t k = fread(buf, 1, sizeof buf - 1, f);
                buf[k] = 0;
                fclose(f);
            }
            if (strstr(buf, "\"restoring\"") || strstr(buf, "\"stopped\"")) break;
        }
        CloseHandle(mtx);
        return 0;
    }
    // no filter running (it crashed, or the computer restarted while filtering): a restorer in the background
    // gives back what it can now and the rest as those apps play again
    wchar_t self[MAX_PATH * 2];
    GetModuleFileNameW(nullptr, self, (DWORD)(sizeof self / sizeof *self));
    std::wstring cmd = L"\"" + std::wstring(self) + L"\" restore --dir \"" + p.dir + L"\"";
    STARTUPINFOW si = {};
    si.cb = sizeof si;
    PROCESS_INFORMATION pi = {};
    if (!CreateProcessW(nullptr, &cmd[0], nullptr, nullptr, FALSE, DETACHED_PROCESS | CREATE_NO_WINDOW, nullptr,
                        nullptr, &si, &pi)) {
        fprintf(stderr, "waaiya-filter: cannot start the restorer (error %lu)\n", GetLastError());
        return 1;
    }
    WaitForSingleObject(pi.hProcess, 1500); // the levels of running apps are back within this
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    return 0;
}

int cmd_status(const Paths &p) {
    HANDLE mtx = OpenMutexW(SYNCHRONIZE, FALSE, MUTEX_NAME);
    bool alive = mtx != nullptr;
    if (mtx) CloseHandle(mtx);
    FILE *f = _wfopen((p.dir + L"\\state.json").c_str(), L"rb");
    char buf[4096] = "";
    if (f) {
        size_t k = fread(buf, 1, sizeof buf - 1, f);
        buf[k] = 0;
        fclose(f);
    }
    printf("process: %s\n%s", alive ? "running" : "none", buf[0] ? buf : "{}\n");
    return 0;
}

void usage() {
    fprintf(stderr, "usage: waaiya-filter run [--bypass] [--model F] [--detector F] [--settings F] [--dir D] "
                    "[--log-stderr]\n       waaiya-filter stop | restore | status [--dir D]\n");
}

} // namespace

int wmain(int argc, wchar_t **argv) {
    if (argc < 2) {
        usage();
        return 2;
    }
    CoInitializeEx(nullptr, COINIT_MULTITHREADED);
    Paths p = default_paths();
    bool bypass = false;
    std::wstring cmd = argv[1];
    for (int i = 2; i < argc; i++) {
        std::wstring a = argv[i];
        const wchar_t *v = i + 1 < argc ? argv[i + 1] : nullptr;
        if (a == L"--bypass") bypass = true;
        else if (a == L"--log-stderr") g_log_stderr = true;
        else if (a == L"--model" && v) p.model = argv[++i];
        else if (a == L"--detector" && v) p.detector = argv[++i];
        else if (a == L"--settings" && v) p.settings = argv[++i];
        else if (a == L"--dir" && v) {
            p.dir = argv[++i];
            SHCreateDirectoryExW(nullptr, p.dir.c_str(), nullptr);
            p.store = p.dir + L"\\levels.txt";
        } else {
            usage();
            return 2;
        }
    }
    int r;
    if (cmd == L"run") r = cmd_run(p, bypass, false);
    else if (cmd == L"restore") r = cmd_run(p, false, true);
    else if (cmd == L"stop") r = cmd_stop(p);
    else if (cmd == L"status") r = cmd_status(p);
    else {
        usage();
        r = 2;
    }
    CoUninitialize();
    return r;
}
