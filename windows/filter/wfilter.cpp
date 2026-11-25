// waaiya-filter.exe: Waaiya's always-on sound filter for Windows 10 2004+ / 11. No driver, no admin rights.
//
//   waaiya-filter run [--bypass] [--model F] [--detector F] [--settings F] [--dir D] [--log-stderr]
//                     [--leave-alone NAME.exe ...]   programs never lowered (they record the speakers: OBS)
//   waaiya-filter stop        the running filter gives every app its level back (and keeps giving back the levels
//                             of apps that are not running when they next play), or, with none running, that is
//                             done here
//   waaiya-filter restore     only give back stored levels, as apps show up; exits once none is left
//   waaiya-filter status      prints the state file (state.json) and whether a filter process holds it
//   waaiya-filter autostart   at login, from the Microsoft Store package's startup task (desktop/msix): filters
//                             when the app's "Start at login" is on (the file <dir>\autostart), else only gives
//                             back levels still stored (the computer was turned off while filtering), else exits
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
// mute_women_singing, keep_singing (the voice_v1 model, swapped in while running with no gap) and filter_off_apps
// (apps heard unfiltered: not lowered and not captured; then one capture per app instead of one of everything, see
// capture_plan). State: %LOCALAPPDATA%\Waaiya\filter\state.json, rewritten twice a second, with the apps that have a
// sound session ("apps") for the app's "Fix mistakes" list.
#include "../common/wasapi.h"
#include "sessions.h"

#include <appmodel.h>
#include <avrt.h>
#include <shlobj.h>
#include <tlhelp32.h>

#include <algorithm>
#include <atomic>
#include <cmath>
#include <cstdarg>
#include <cstdio>
#include <cstring>
#include <cwctype>
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
    bool keep_singing = false;  // keep_singing: the voice_v1 model (a test)
    std::vector<std::wstring> off_apps; // filter_off_apps: "chrome.exe,spotify.exe", heard unfiltered (lower case)

    bool same(const Settings &o) const {
        return stereo == o.stereo && hold_silence == o.hold_silence && women_singing == o.women_singing &&
               keep_singing == o.keep_singing && off_apps == o.off_apps;
    }
};

// A JSON string value ("" when missing or not a string); \" \\ \/ \uXXXX (BMP) understood.
std::string json_str_value(const std::string &s, const char *key) {
    std::string k = std::string("\"") + key + "\"";
    size_t p = s.find(k);
    if (p == std::string::npos) return "";
    p = s.find(':', p + k.size());
    if (p == std::string::npos) return "";
    p++;
    while (p < s.size() && (s[p] == ' ' || s[p] == '\t' || s[p] == '\r' || s[p] == '\n')) p++;
    if (p >= s.size() || s[p] != '"') return "";
    std::string v;
    for (p++; p < s.size() && s[p] != '"'; p++) {
        if (s[p] != '\\' || p + 1 >= s.size()) {
            v += s[p];
            continue;
        }
        char c = s[++p];
        if (c == 'u' && p + 4 < s.size()) {
            unsigned cp = (unsigned)strtoul(s.substr(p + 1, 4).c_str(), nullptr, 16);
            p += 4;
            if (cp < 0x80) v += (char)cp;
            else if (cp < 0x800) { v += (char)(0xC0 | (cp >> 6)); v += (char)(0x80 | (cp & 0x3F)); }
            else { v += (char)(0xE0 | (cp >> 12)); v += (char)(0x80 | ((cp >> 6) & 0x3F)); v += (char)(0x80 | (cp & 0x3F)); }
        } else {
            v += c == 'n' ? '\n' : (c == 't' ? '\t' : c);
        }
    }
    return v;
}

// "Chrome.exe, spotify.exe" -> {"chrome.exe", "spotify.exe"}; only file names ending in .exe count
std::vector<std::wstring> exe_list(const std::string &csv) {
    std::vector<std::wstring> out;
    std::wstring w = im_wide(csv.c_str()), cur;
    auto add = [&] {
        size_t a = cur.find_first_not_of(L" \t"), b = cur.find_last_not_of(L" \t");
        if (a != std::wstring::npos) {
            std::wstring n = cur.substr(a, b - a + 1);
            for (auto &ch : n) ch = (wchar_t)towlower(ch);
            if (n.size() > 4 && n.compare(n.size() - 4, 4, L".exe") == 0 && n.find(L'\\') == std::wstring::npos &&
                std::find(out.begin(), out.end(), n) == out.end())
                out.push_back(n);
        }
        cur.clear();
    };
    for (wchar_t ch : w) {
        if (ch == L',' || ch == L'\n') add();
        else cur += ch;
    }
    add();
    std::sort(out.begin(), out.end());
    return out;
}

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
    st.keep_singing = json_bool(s, "keep_singing", st.keep_singing);
    st.off_apps = exe_list(json_str_value(s, "filter_off_apps"));
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
    bool keep_singing = false; // the running engine is the keep-singing model
    int captures = -1;         // -1: one capture of every app; else one per app (apps left unfiltered), how many
    int silent = 0;            // apps that cannot be captured apart from one left unfiltered: kept silent
    std::string apps = "[]";   // the apps with a sound session now: [{"exe":"chrome.exe","name":"Google Chrome"}]
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
    std::string out = buf;
    char more[160];
    snprintf(more, sizeof more, ",\"keep_singing\":%s,\"captures\":%d,\"silent\":%d,\"apps\":",
             s.keep_singing ? "true" : "false", s.captures, s.silent);
    out.insert(out.size() - 2, std::string(more) + s.apps); // before the closing "}\n"
    std::wstring p = dir + L"\\state.json", tmp = p + L".tmp";
    FILE *f = _wfopen(tmp.c_str(), L"wb");
    if (!f) return;
    fputs(out.c_str(), f);
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
    HANDLE cap_event = CreateEventW(nullptr, FALSE, FALSE, nullptr); // shared by every capture
    UINT32 out_frames = 0;
    std::wstring out_id;
    std::string out_name;
    bool running = false;

    // Apps left unfiltered (filter_off_apps): Windows' process loopback leaves out one process tree only (ours), so
    // then each other app gets a capture of its own (include mode, its process tree) and the captures are mixed.
    struct App {
        DWORD pid = 0;
        Com<IAudioClient> client;
        Com<IAudioCaptureClient> cap;
        std::vector<float> fifo; // gained samples not mixed yet
        double last = -1e9;      // when it last delivered (ms)
    };
    bool multi = false;
    std::vector<App> apps;

    ~Audio() { CloseHandle(cap_event); }

    // A capture of [pid]'s process tree: "" or what failed.
    std::string open_app(DWORD pid) {
        App a;
        a.pid = pid;
        HRESULT hr;
        WAVEFORMATEX fmt = im_float_format(RATE, CH);
        const DWORD conv = AUDCLNT_STREAMFLAGS_AUTOCONVERTPCM | AUDCLNT_STREAMFLAGS_SRC_DEFAULT_QUALITY;
        if (FAILED(hr = im_activate_process_loopback(pid, false, a.client.put()))) return "activate: " + im_hr(hr);
        if (FAILED(hr = a.client->Initialize(AUDCLNT_SHAREMODE_SHARED,
                                             AUDCLNT_STREAMFLAGS_LOOPBACK | AUDCLNT_STREAMFLAGS_EVENTCALLBACK | conv,
                                             200000, 0, &fmt, nullptr)))
            return "format: " + im_hr(hr);
        if (FAILED(hr = a.client->SetEventHandle(cap_event))) return "event: " + im_hr(hr);
        if (FAILED(hr = a.client->GetService(__uuidof(IAudioCaptureClient), reinterpret_cast<void **>(a.cap.put()))))
            return "service: " + im_hr(hr);
        if (FAILED(hr = a.client->Start())) return "start: " + im_hr(hr);
        apps.push_back(std::move(a));
        return "";
    }

    void close_app(size_t k) {
        if (apps[k].client) apps[k].client->Stop();
        apps.erase(apps.begin() + (long)k);
    }

    void close() {
        if (cap_client) cap_client->Stop();
        if (out_client) out_client->Stop();
        while (!apps.empty()) close_app(apps.size() - 1);
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

    // "" on success, else what failed. [per_app]: no capture here, one per app (sync_captures)
    std::string open(bool per_app) {
        close();
        multi = per_app;
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

        if (per_app) {
            if (FAILED(hr = out_client->Start())) return "output start: " + im_hr(hr);
            running = true;
            return "";
        }
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

std::vector<std::wstring> g_leave_alone; // --leave-alone NAME.exe (repeatable)
bool g_test_hang = false;                 // tests: the main loop stops once the audio runs (the watchdog must act)

// ---- Windows closing the filter. Before it updates or removes the Store package, Windows asks every window of the
// package's processes to close (WM_QUERYENDSESSION, then WM_ENDSESSION, with ENDSESSION_CLOSEAPP), then ends them;
// a process without a window is ended at once (seen on a PC: uninstalling while filtering left every app at -80 dB
// for good, nothing being left to give the levels back). So the filter has a hidden window: on that message the main
// loop gives the levels back before Windows ends the process. After an update, Windows starts the filter again
// with the same arguments (RegisterApplicationRestart, measured: about when the new version is in place), and it
// lowers the apps again. Signing out or shutting down (no ENDSESSION_CLOSEAPP) changes nothing: the levels stay
// stored, given back or filtered again at the next login.
HANDLE g_closing = CreateEventW(nullptr, TRUE, FALSE, nullptr); // set by the window: give the levels back now
HANDLE g_closed = CreateEventW(nullptr, TRUE, FALSE, nullptr);  // set by the main loop: done
std::atomic<bool> g_lowering{false};                            // the main loop holds levels lowered

LRESULT CALLBACK closing_proc(HWND h, UINT m, WPARAM w, LPARAM l) {
    switch (m) {
    case WM_QUERYENDSESSION:
        return TRUE;
    case WM_ENDSESSION:
        if (w && (l & ENDSESSION_CLOSEAPP) && g_lowering.load()) {
            SetEvent(g_closing);
            WaitForSingleObject(g_closed, 5000); // Windows ends the process once this returns
        }
        return 0;
    case WM_CLOSE: // Windows sends it after WM_ENDSESSION: nothing more to do, and the window stays
        return 0;
    }
    return DefWindowProcW(h, m, w, l);
}

DWORD WINAPI closing_window(LPVOID) {
    WNDCLASSW wc = {};
    wc.lpfnWndProc = closing_proc;
    wc.hInstance = GetModuleHandleW(nullptr);
    wc.lpszClassName = L"WaaiyaFilter";
    RegisterClassW(&wc);
    // top-level and never shown: a message-only window (HWND_MESSAGE) is not asked
    if (!CreateWindowExW(WS_EX_TOOLWINDOW, wc.lpszClassName, L"Waaiya filter", WS_POPUP, 0, 0, 0, 0, nullptr, nullptr,
                         wc.hInstance, nullptr))
        return 1;
    MSG msg;
    while (GetMessageW(&msg, nullptr, 0, 0) > 0) DispatchMessageW(&msg);
    return 0;
}

// After a package update, Windows starts this program again with the arguments it has now (never after a crash, a
// hang or a restart of the computer: the app and the startup task handle those).
void restart_after_update(bool on) {
    if (!on) {
        UnregisterApplicationRestart();
        return;
    }
    const wchar_t *c = GetCommandLineW();
    bool quoted = *c == L'"';
    for (c += quoted; *c && (quoted ? *c != L'"' : *c != L' '); c++) {}
    if (*c == L'"') c++;
    while (*c == L' ') c++;
    if (wcslen(c) < RESTART_MAX_CMD_LINE)
        RegisterApplicationRestart(c, RESTART_NO_CRASH | RESTART_NO_HANG | RESTART_NO_REBOOT);
}

// ---- watchdog: the main loop ticks at least every 0.5 s. Stuck for 10 s, the process ends itself: Windows keeps
// the apps lowered (silent, fail-closed) and the app or a new start takes over (a stuck filter would otherwise hold
// the single-instance lock and make every Start fail).
std::atomic<long long> g_tick{0};

DWORD WINAPI watchdog(LPVOID) {
    for (;;) {
        Sleep(2000);
        long long last = g_tick.load();
        if (last != 0 && unix_ms() - last > 10000) {
            logf("watchdog: the main loop has been stuck for %lld s; ending (apps stay lowered until Start or Stop)",
                 (unix_ms() - last) / 1000);
            TerminateProcess(GetCurrentProcess(), 3);
        }
    }
}

// state.json: its pid and time ("t"), 0 when unreadable
void read_state_head(const std::wstring &dir, unsigned long *pid, long long *t) {
    *pid = 0;
    *t = 0;
    FILE *f = _wfopen((dir + L"\\state.json").c_str(), L"rb");
    if (!f) return;
    char buf[2048] = "";
    size_t k = fread(buf, 1, sizeof buf - 1, f);
    buf[k] = 0;
    fclose(f);
    const char *p = strstr(buf, "\"pid\":"), *q = strstr(buf, "\"t\":");
    if (p) *pid = strtoul(p + 6, nullptr, 10);
    if (q) *t = strtoll(q + 4, nullptr, 10);
}

bool state_fresh(const std::wstring &dir) {
    unsigned long pid;
    long long t;
    read_state_head(dir, &pid, &t);
    return unix_ms() - t < 5000;
}

// Ends [pid] if it is a waaiya-filter.exe (never another program that got the same pid) of this login session.
bool end_filter_pid(DWORD pid) {
    if (pid == 0 || pid == GetCurrentProcessId()) return false;
    DWORD mine = 0, theirs = 1;
    ProcessIdToSessionId(GetCurrentProcessId(), &mine);
    if (!ProcessIdToSessionId(pid, &theirs) || theirs != mine) return false;
    HANDLE h = OpenProcess(PROCESS_TERMINATE | SYNCHRONIZE | PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
    if (!h) return false;
    wchar_t name[MAX_PATH] = L"";
    DWORD n = MAX_PATH;
    bool ours = false;
    if (QueryFullProcessImageNameW(h, 0, name, &n)) {
        std::wstring s = name;
        for (auto &ch : s) ch = (wchar_t)towlower(ch);
        ours = s.size() >= 17 && s.compare(s.size() - 17, 17, L"waaiya-filter.exe") == 0;
    }
    if (ours) {
        TerminateProcess(h, 3);
        WaitForSingleObject(h, 3000);
    }
    CloseHandle(h);
    return ours;
}

// The process holding the lock has not written its state for over 5 s (it rewrites it at least every 2 s): it is
// stuck. Ended, so that this one can take over. The state may name a process that is gone: an older run's state,
// left by a filter that hung before writing its own (seen on a PC: a 0.2.10 filter hung for a week behind a state
// that said "stopped"). Then the lock's holder is one of the other waaiya-filter.exe of this session, none of which
// answers (the caller asked them first): they are ended.
bool end_stuck(const std::wstring &dir) {
    unsigned long pid;
    long long t;
    read_state_head(dir, &pid, &t);
    if (unix_ms() - t < 5000) return false;
    if (end_filter_pid(pid)) return true;
    bool any = false;
    HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (snap == INVALID_HANDLE_VALUE) return false;
    PROCESSENTRY32W e = {};
    e.dwSize = sizeof e;
    for (BOOL ok = Process32FirstW(snap, &e); ok; ok = Process32NextW(snap, &e)) {
        if (_wcsicmp(e.szExeFile, L"waaiya-filter.exe") == 0 && end_filter_pid(e.th32ProcessID)) {
            logf("ended a waaiya-filter.exe that held the lock without writing its state (pid %lu)",
                 (unsigned long)e.th32ProcessID);
            any = true;
        }
    }
    CloseHandle(snap);
    return any;
}

struct Paths {
    std::wstring dir;      // %LOCALAPPDATA%\Waaiya\filter
    std::wstring settings; // %APPDATA%\Waaiya\settings.json
    std::wstring store;    // <dir>\levels.txt
    std::wstring model, detector;
    std::wstring singing; // keep singing (voice_v1): its path even when not bundled (then the engine fails: silence)
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
    p.singing = bundled(L"models\\voice\\v3\\voice_v1_fp16.onnx");
    if (p.singing.empty()) p.singing = exe_dir() + L"\\models\\voice\\v3\\voice_v1_fp16.onnx";
    return p;
}

// ---- apps left unfiltered: which processes get a capture of their own
//
// Windows' process loopback captures a process with all the processes it started (its tree). Waaiya's own output
// must never be captured (it would be filtered again, in a loop) and an app left unfiltered must not be captured
// either (it plays at full level: it would come out a second time, x 1e4). So a lowered app is captured only if its
// tree holds neither: Explorer, which started most programs, Waaiya included, is not captured, and its own sounds
// stay silent (fail-closed). An app inside a captured tree is heard through that tree's capture.
struct CapturePlan {
    std::vector<DWORD> capture; // one capture each
    std::vector<DWORD> silent;  // lowered, but their tree holds Waaiya or an app left unfiltered
};

CapturePlan capture_plan(const std::vector<DWORD> &lowered, const Sessions &ses,
                         const std::vector<std::wstring> &leave_alone) {
    struct Proc {
        DWORD parent;
        std::wstring exe;
    };
    std::vector<std::pair<DWORD, Proc>> procs;
    HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (snap != INVALID_HANDLE_VALUE) {
        PROCESSENTRY32W e = {};
        e.dwSize = sizeof e;
        for (BOOL ok = Process32FirstW(snap, &e); ok; ok = Process32NextW(snap, &e)) {
            std::wstring exe = e.szExeFile;
            for (auto &ch : exe) ch = (wchar_t)towlower(ch);
            procs.push_back({e.th32ProcessID, {e.th32ParentProcessID, exe}});
        }
        CloseHandle(snap);
    }
    auto parent_of = [&](DWORD pid) -> DWORD {
        for (auto &p : procs)
            if (p.first == pid) return p.second.parent == pid ? 0 : p.second.parent;
        return 0;
    };
    auto ancestors = [&](DWORD pid) {
        std::vector<DWORD> a;
        for (DWORD q = parent_of(pid); q && a.size() < 64 && std::find(a.begin(), a.end(), q) == a.end();
             q = parent_of(q))
            a.push_back(q);
        return a;
    };
    // every process whose tree holds Waaiya or an app left unfiltered
    std::vector<DWORD> blocked;
    auto block = [&](DWORD pid) {
        blocked.push_back(pid);
        for (DWORD a : ancestors(pid)) blocked.push_back(a);
    };
    block(GetCurrentProcessId());
    for (auto &p : procs)
        if (ses.is_off(p.second.exe) ||
            std::find(leave_alone.begin(), leave_alone.end(), p.second.exe) != leave_alone.end())
            block(p.first);
    // parents first, so that a child inside a captured tree is not captured twice
    std::vector<std::pair<size_t, DWORD>> order;
    for (DWORD pid : lowered) order.push_back({ancestors(pid).size(), pid});
    std::sort(order.begin(), order.end());
    CapturePlan plan;
    for (auto &o : order) {
        DWORD pid = o.second;
        bool inside = false;
        for (DWORD a : ancestors(pid)) inside = inside || std::find(plan.capture.begin(), plan.capture.end(), a) != plan.capture.end();
        if (inside) continue;
        if (std::find(blocked.begin(), blocked.end(), pid) != blocked.end()) plan.silent.push_back(pid);
        else plan.capture.push_back(pid);
    }
    return plan;
}

// The app's name as Windows shows it (the program's description: "Google Chrome"), else its file name; cached.
std::string app_name(DWORD pid, const std::wstring &exe) {
    static std::vector<std::pair<std::wstring, std::string>> cache;
    for (auto &c : cache)
        if (c.first == exe) return c.second;
    std::string name;
    HANDLE h = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
    if (h) {
        wchar_t path[MAX_PATH * 2];
        DWORD n = MAX_PATH * 2;
        if (QueryFullProcessImageNameW(h, 0, path, &n)) {
            DWORD dummy = 0, size = GetFileVersionInfoSizeW(path, &dummy);
            std::vector<BYTE> info(size);
            struct Lang {
                WORD lang, cp;
            } *langs = nullptr;
            UINT len = 0;
            if (size && GetFileVersionInfoW(path, 0, size, info.data()) &&
                VerQueryValueW(info.data(), L"\\VarFileInfo\\Translation", reinterpret_cast<void **>(&langs), &len) &&
                len >= sizeof(Lang)) {
                wchar_t q[64];
                swprintf(q, 64, L"\\StringFileInfo\\%04x%04x\\FileDescription", langs[0].lang, langs[0].cp);
                wchar_t *desc = nullptr;
                UINT dl = 0;
                if (VerQueryValueW(info.data(), q, reinterpret_cast<void **>(&desc), &dl) && desc && dl > 1)
                    name = im_utf8(desc);
            }
        }
        CloseHandle(h);
    }
    while (!name.empty() && name.back() == ' ') name.pop_back();
    if (name.empty()) name = im_utf8(exe.substr(0, exe.size() > 4 ? exe.size() - 4 : exe.size()).c_str());
    cache.push_back({exe, name});
    return name;
}

// ---- the engine: created here or on a helper thread (keep singing switched while filtering: the other model loads
// while this one keeps filtering, then they swap between two hops)
im_engine *create_engine(const std::string &model, const std::string &detector, char *err, size_t n) {
    im_config cfg = {};
    cfg.model_path = model.c_str();
    cfg.channels = CH;
    cfg.sample_rate = RATE;
    cfg.threads = 1;
    cfg.mono_mix = 0; // always built for stereo, so "mono" (the default) can switch both ways live
    cfg.detector_path = detector.empty() ? nullptr : detector.c_str();
    im_engine *e = nullptr;
    im_engine_create(&cfg, &e, err, n);
    return e;
}

struct EngineLoad {
    std::string model, detector;
    bool singing = false;
    im_engine *eng = nullptr;
    char err[512] = "";
    HANDLE thread = nullptr;
};

DWORD WINAPI load_engine(LPVOID arg) {
    auto *l = static_cast<EngineLoad *>(arg);
    l->eng = create_engine(l->model, l->detector, l->err, sizeof l->err);
    return 0;
}

// Restore-only: gives stored levels back as their apps show up, until none is left (or a new run asks to quit).
int restore_loop(Sessions &ses, const Paths &p, HANDLE quit) {
    State st;
    st.state = "restoring";
    st.engine = "";
    while (ses.pending() > 0) {
        g_tick.store(unix_ms());
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
        if (w == WAIT_TIMEOUT && end_stuck(p.dir)) w = WaitForSingleObject(mtx, 3000); // abandoned: ours now
        if (w == WAIT_TIMEOUT) {
            fprintf(stderr, "waaiya-filter: already running\n");
            return 0;
        }
    }
    ResetEvent(stop);
    ResetEvent(quit);
    open_log(p.dir);
    if (w == WAIT_ABANDONED) logf("run: the previous filter ended without stopping; taking over");
    g_tick.store(unix_ms());
    CloseHandle(CreateThread(nullptr, 0, watchdog, nullptr, 0, nullptr));
    CloseHandle(CreateThread(nullptr, 0, closing_window, nullptr, 0, nullptr));

    Sessions ses(ATT, p.store, GetCurrentProcessId());
    ses.log = logf;
    ses.leave_alone = g_leave_alone;
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
    ses.set_off(set.off_apps);

    // the engine: the default model, or keep singing's (a test). A model that does not load is silent (fail-closed).
    std::string model8 = im_utf8(p.model.c_str()), sing8 = im_utf8(p.singing.c_str()), det8 = im_utf8(p.detector.c_str());
    bool singing = set.keep_singing;
    char err[512] = "";
    im_engine *eng = create_engine(singing ? sing8 : model8, det8, err, sizeof err);
    State st;
    st.bypass = bypass;
    if (!eng) {
        logf("engine: out of memory");
        return 1;
    }
    std::string load_err = err; // why the model did not load
    auto apply_settings = [&](const Settings &s) {
        st.mono = im_engine_set_mono(eng, s.stereo ? 0 : 1) == 1;
        st.women_singing = s.women_singing;
        st.keep_singing = singing;
        im_engine_set_policy(eng, s.women_singing ? (IM_POLICY_MUTE_FEMALE_SINGING | IM_POLICY_FAIL_CLOSED) : 0);
        if (im_engine_failed(eng)) {
            st.engine = std::string("model not loaded, ") + load_err;
            return;
        }
        st.engine = s.women_singing && im_engine_detector_error(eng)[0]
                        ? std::string("detector not loaded, ") + im_engine_detector_error(eng)
                        : "ok";
    };
    apply_settings(set);
    logf("engine: %s%s", st.engine.c_str(), singing ? " (keep singing)" : "");
    im_engine_set_enabled(eng, bypass ? 0 : 1);
    EngineLoad *loading = nullptr; // the other model, loading on a helper thread
    auto finish_loading = [&] {    // waits for it and frees it (stop, close)
        if (!loading) return;
        WaitForSingleObject(loading->thread, INFINITE);
        CloseHandle(loading->thread);
        if (loading->eng) im_engine_destroy(loading->eng);
        delete loading;
        loading = nullptr;
    };
    g_lowering.store(true);
    restart_after_update(true);
    bool closing = false; // Windows closes the filter (package update or removal)
    int hop = im_engine_hop(eng); // read again when the engine is swapped

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
    double audio_since = 0, fail_since = 0, retry_at = 0, leak_until = 0, state_at = 0, cpu0 = cpu_ms(), wall0 = now_ms();
    double plan_at = 0, apps_at = 0; // per-app captures looked at again; the app list rewritten
    bool restored = false; // hold_silence off and failing: levels given back
    int exit_code = 0;
    std::vector<DWORD> silent_logged;                   // per-app: silent apps already in the log
    std::vector<std::pair<DWORD, double>> failed_caps;  // per-app: captures that did not open, retried after a while

    // per-app captures: the lowered apps' trees, each captured once (capture_plan); a capture that cannot open
    // leaves that app silent (it is lowered) and is tried again 10 s later
    auto sync_captures = [&](double t) {
        plan_at = t + 2000;
        CapturePlan plan = capture_plan(ses.pids(), ses, g_leave_alone);
        for (size_t k = 0; k < au.apps.size();) {
            if (std::find(plan.capture.begin(), plan.capture.end(), au.apps[k].pid) == plan.capture.end()) {
                logf("capture: app pid %lu no longer captured", (unsigned long)au.apps[k].pid);
                au.close_app(k);
            } else {
                k++;
            }
        }
        for (DWORD pid : plan.capture) {
            bool have = false;
            for (auto &a : au.apps) have = have || a.pid == pid;
            auto f = std::find_if(failed_caps.begin(), failed_caps.end(), [&](auto &x) { return x.first == pid; });
            if (have || (f != failed_caps.end() && t < f->second)) continue;
            std::string e = au.open_app(pid);
            if (e.empty()) {
                logf("capture: app pid %lu captured", (unsigned long)pid);
                if (f != failed_caps.end()) failed_caps.erase(f);
            } else {
                logf("capture: app pid %lu: %s (kept silent)", (unsigned long)pid, e.c_str());
                if (f != failed_caps.end()) f->second = t + 10000;
                else failed_caps.push_back({pid, t + 10000});
            }
        }
        for (DWORD pid : plan.silent)
            if (std::find(silent_logged.begin(), silent_logged.end(), pid) == silent_logged.end()) {
                logf("capture: pid %lu kept silent: it started Waaiya or an app heard unfiltered", (unsigned long)pid);
                silent_logged.push_back(pid);
            }
        st.captures = (int)au.apps.size();
        st.silent = (int)plan.silent.size();
    };

    for (;;) {
        g_tick.store(unix_ms());
        if (g_test_hang && au.running) {
            logf("test: the main loop stops here (--test-hang)");
            for (;;) Sleep(1000);
        }
        double t = now_ms();
        // (re)open the audio when it is not running (start, a lost device, the audio service restarted)
        if (!au.running && t >= retry_at) {
            std::string e = au.open(!set.off_apps.empty());
            if (e.empty()) {
                logf("audio: playing to \"%s\" (output buffer %u frames)%s", au.out_name.c_str(), au.out_frames,
                     au.multi ? ", one capture per app (apps left unfiltered)" : "");
                st.captures = -1;
                st.silent = 0;
                if (au.multi) sync_captures(t);
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

        HANDLE hs[6];
        int nh = 0;
        hs[nh++] = stop;
        hs[nh++] = ses.wake;
        int i_close = nh;
        hs[nh++] = g_closing;
        int i_set = setwatch != INVALID_HANDLE_VALUE ? nh : -1;
        if (i_set >= 0) hs[nh++] = setwatch;
        int i_cap = au.running ? nh : -1;
        if (i_cap >= 0) hs[nh++] = au.cap_event;
        w = WaitForMultipleObjects((DWORD)nh, hs, FALSE, au.running ? 200 : 500);
        t = now_ms();

        if (w == WAIT_OBJECT_0) { // stop: levels back, then restore-only for the apps not running now
            logf("stop: giving the levels back");
            break;
        }
        if (w == WAIT_OBJECT_0 + (DWORD)i_close) {
            logf("Windows is closing the filter (the app is being updated or removed): giving the levels back");
            closing = true;
            break;
        }
        if (w == WAIT_OBJECT_0 + 1) {
            ses.scan();
            // the default output changed (headphones plugged in): play there
            if (au.running && au.default_id() != au.out_id) {
                logf("audio: default output changed");
                au.close();
                retry_at = 0;
            } else if (au.running && au.multi) {
                sync_captures(t); // a new app (lowered already): captured
            }
        }
        if (i_set >= 0 && w == WAIT_OBJECT_0 + (DWORD)i_set) {
            FindNextChangeNotification(setwatch);
            Settings ns = read_settings(p.settings);
            if (!ns.same(set)) {
                logf("settings: stereo %d, women_singing %d, hold_silence %d, keep_singing %d, %zu app(s) unfiltered",
                     ns.stereo, ns.women_singing, ns.hold_silence, ns.keep_singing, ns.off_apps.size());
                bool off_changed = ns.off_apps != set.off_apps;
                set = ns;
                apply_settings(set);
                if (off_changed) {
                    ses.set_off(set.off_apps); // their levels back, or lowered again
                    silent_logged.clear();
                    failed_caps.clear();
                    if (au.running && au.multi != !set.off_apps.empty()) {
                        logf("capture: %s", set.off_apps.empty() ? "back to one capture of every app"
                                                                 : "one capture per app from now");
                        au.close();
                        retry_at = 0;
                    } else if (au.running && au.multi) {
                        sync_captures(t);
                    }
                }
            }
        }
        // keep singing switched: the other model loads on a helper thread while this one keeps filtering
        if (set.keep_singing != singing && !loading) {
            loading = new EngineLoad;
            loading->model = set.keep_singing ? sing8 : model8;
            loading->detector = det8;
            loading->singing = set.keep_singing;
            loading->thread = CreateThread(nullptr, 0, load_engine, loading, 0, nullptr);
            logf("engine: keep singing %s, loading the model", set.keep_singing ? "on" : "off");
            if (!loading->thread) {
                delete loading;
                loading = nullptr;
            }
        }
        if (loading && WaitForSingleObject(loading->thread, 0) == WAIT_OBJECT_0) {
            CloseHandle(loading->thread);
            if (loading->eng) { // between two hops: the new engine takes over
                im_engine *old = eng;
                eng = loading->eng;
                singing = loading->singing;
                load_err = loading->err;
                apply_settings(set);
                im_engine_set_enabled(eng, bypass ? 0 : 1);
                im_engine_destroy(old);
                if (im_engine_hop(eng) != hop) { // another hop size: start the queue again (a moment of silence)
                    hop = im_engine_hop(eng);
                    in.clear();
                }
                logf("engine: %s%s", st.engine.c_str(), singing ? " (keep singing)" : " (default model)");
            } else {
                logf("engine: out of memory loading the other model; the running one goes on");
            }
            delete loading;
            loading = nullptr;
        }

        if (au.running && au.multi) {
            // ---- one capture per app -> gain -> mixed -> engine
            if (t >= plan_at) sync_captures(t);
            for (size_t k = 0; k < au.apps.size();) {
                Audio::App &a = au.apps[k];
                UINT32 n = 0;
                HRESULT chr = S_OK;
                float peak = 0;
                while (SUCCEEDED(chr = a.cap->GetNextPacketSize(&n)) && n > 0) {
                    BYTE *data = nullptr;
                    UINT32 frames = 0;
                    DWORD flags = 0;
                    if (FAILED(chr = a.cap->GetBuffer(&data, &frames, &flags, nullptr, nullptr))) break;
                    const float *src = reinterpret_cast<const float *>(data);
                    bool silent = (flags & AUDCLNT_BUFFERFLAGS_SILENT) != 0 || !src;
                    size_t base = a.fifo.size();
                    a.fifo.resize(base + (size_t)frames * CH);
                    for (size_t j = 0; j < (size_t)frames * CH; j++) {
                        float x = silent ? 0.0f : src[j];
                        float m = std::fabs(x);
                        if (m > peak) peak = m;
                        a.fifo[base + j] = x * (1.0f / ATT);
                    }
                    a.cap->ReleaseBuffer(frames);
                    a.last = t;
                }
                if (peak > st.cap_peak) st.cap_peak = peak;
                if (peak > LEAK_RAW) {
                    // louder than a lowered app: in this tree, an app not lowered (yet), or one left unfiltered that
                    // started inside it. Never played amplified; the plan is made again.
                    if (t >= leak_until) {
                        st.leaks++;
                        logf("leak: app pid %lu capture peak %.5f; sessions and captures looked at again",
                             (unsigned long)a.pid, peak);
                    }
                    leak_until = t + LEAK_HOLD_MS;
                    plan_at = 0;
                    SetEvent(ses.wake);
                }
                if (FAILED(chr)) { // the app ended (or its capture broke): looked at again by the next plan
                    logf("capture: app pid %lu: %s", (unsigned long)a.pid, im_hr(chr).c_str());
                    au.close_app(k);
                    plan_at = 0;
                    continue;
                }
                k++;
            }
            // mixed as far as every capture that delivers lately has samples (they share the audio engine's clock);
            // a capture silent for 80 ms (its app plays nothing) holds nobody back
            size_t mix = SIZE_MAX;
            for (auto &a : au.apps)
                if (!a.fifo.empty() || t - a.last < 80) mix = std::min(mix, a.fifo.size() / CH);
            if (mix != SIZE_MAX && mix > 0) {
                size_t base = in.size();
                in.resize(base + mix * CH, 0.0f);
                for (auto &a : au.apps) {
                    size_t take = std::min(mix * CH, a.fifo.size());
                    for (size_t j = 0; j < take; j++) in[base + j] += a.fifo[j];
                    a.fifo.erase(a.fifo.begin(), a.fifo.begin() + (long)take);
                }
                st.cap_frames += mix;
            }
            for (auto &a : au.apps) // a capture ahead of the others by over 100 ms: its oldest samples go
                if (a.fifo.size() / CH > (size_t)RATE / 10) {
                    size_t drop = a.fifo.size() - (size_t)RATE / 50 * CH;
                    a.fifo.erase(a.fifo.begin(), a.fifo.begin() + (long)drop);
                    st.dropped += drop / CH;
                }
        }
        if (au.running && !au.multi) {
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
        }
        if (au.running) {
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
            if (pad == 0 && !out.empty()) {
                // ran dry (at the start, before the first hop came in, or after a stall): a cushion of silence
                // first, so the next writes land ahead of the device again instead of just in time
                st.underruns++;
                UINT32 cushion = RATE * RENDER_TARGET_MS / 1000;
                BYTE *sb = nullptr;
                if (cushion < au.out_frames && SUCCEEDED(au.out->GetBuffer(cushion, &sb))) {
                    au.out->ReleaseBuffer(cushion, AUDCLNT_BUFFERFLAGS_SILENT);
                    pad = cushion;
                }
            }
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

        if (t >= apps_at) { // the apps with sound now, for the app's "Fix mistakes" list
            apps_at = t + 2000;
            std::string j = "[";
            for (auto &a : ses.apps())
                j += (j.size() > 1 ? "," : "") + std::string("{\"exe\":") + json_str(im_utf8(a.first.c_str())) +
                     ",\"name\":" + json_str(app_name(a.second, a.first)) + "}";
            st.apps = j + "]";
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
            if (au.running && t - audio_since < 2000) logf("sessions: %s", ses.meters().c_str());
            st.cap_peak = st.out_peak = 0;
        }
    }

    au.close();
    if (mm) AvRevertMmThreadCharacteristics(mm);
    if (setwatch != INVALID_HANDLE_VALUE) FindCloseChangeNotification(setwatch);
    ses.restore_all();
    g_lowering.store(false);
    if (closing) {
        // state "stopped": the app shows the filter off (not "stopped because of an error") until it runs again
        st.state = "stopped";
        st.pending = ses.pending();
        write_state(p.dir, st);
        logf("closing: levels given back, %d stored for apps not running", ses.pending());
        // Ends here, by itself (not ended by Windows: seen on a PC, a program Windows had to end after a removal was
        // started again from its deleted folder when the app was installed again, with an error window). The
        // levels of apps not running stay stored: after an update the filter started again keeps them.
        im_engine_destroy(eng);
        ReleaseMutex(mtx);
        SetEvent(g_closed); // after an update, Windows starts the filter again
        return 0;
    } else {
        restart_after_update(false); // stopped by the user: not started again after an update
    }
    finish_loading(); // a model still loading (keep singing switched just before the stop)
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
            // only a fresh state answers: an old one may say "stopped" while a stuck filter holds the lock
            if ((strstr(buf, "\"restoring\"") || strstr(buf, "\"stopped\"")) && state_fresh(p.dir)) {
                CloseHandle(mtx);
                return 0;
            }
        }
        CloseHandle(mtx);
        // it did not answer: stuck (no state for over 5 s) -> ended, and the levels given back below
        if (!end_stuck(p.dir)) return 0;
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

// At login the app starts too, hidden: only its icon next to the clock, where filtering is turned on and off
// (desktop/windows/runner/tray.cpp). It is <package>\waaiya_desktop.exe, one folder above this program's (engine).
void start_app_in_tray() {
    wchar_t self[MAX_PATH * 2];
    DWORD n = GetModuleFileNameW(nullptr, self, (DWORD)(sizeof self / sizeof *self));
    std::wstring app(self, n);
    for (int up = 0; up < 2; up++) {
        size_t k = app.find_last_of(L'\\');
        if (k == std::wstring::npos) return;
        app.resize(k);
    }
    app += L"\\waaiya_desktop.exe";
    if (!exists(app)) return;
    std::wstring cmd = L"\"" + app + L"\" --tray";
    STARTUPINFOW si = {};
    si.cb = sizeof si;
    PROCESS_INFORMATION pi = {};
    if (!CreateProcessW(app.c_str(), &cmd[0], nullptr, nullptr, FALSE, 0, nullptr, nullptr, &si, &pi)) {
        logf("autostart: the app did not start (error %lu)", GetLastError());
        return;
    }
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
}

// The Store package's startup task runs at every login (the package cannot add a Run value): the app's "Start at
// login" is the file <dir>\autostart there.
int cmd_autostart(const Paths &p) {
    if (exists(p.dir + L"\\autostart")) {
        start_app_in_tray();
        return cmd_run(p, false, false);
    }
    WIN32_FILE_ATTRIBUTE_DATA a;
    if (GetFileAttributesExW(p.store.c_str(), GetFileExInfoStandard, &a) && (a.nFileSizeLow | a.nFileSizeHigh))
        return cmd_run(p, false, true);
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
                    "[--log-stderr]\n       waaiya-filter stop | restore | status | autostart [--dir D]\n");
}

} // namespace

// Running from the Microsoft Store package (it has a package identity)
bool packaged() {
    UINT32 n = 0;
    return GetCurrentPackageFullName(&n, nullptr) != APPMODEL_ERROR_NO_PACKAGE;
}

int wmain(int argc, wchar_t **argv) {
    // the package's startup task passes "autostart" (uap10:Parameters); without it, a packaged start with no
    // command is that task too
    static wchar_t autostart_cmd[] = L"autostart";
    wchar_t *fallback[] = {argv[0], autostart_cmd, nullptr};
    if (argc < 2 && packaged()) {
        argc = 2;
        argv = fallback;
    }
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
        else if (a == L"--test-hang") g_test_hang = true;
        else if (a == L"--leave-alone" && v) {
            std::wstring n = argv[++i];
            for (auto &ch : n) ch = (wchar_t)towlower(ch);
            g_leave_alone.push_back(n);
        }
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
    else if (cmd == L"autostart") r = cmd_autostart(p);
    else {
        usage();
        r = 2;
    }
    CoUninitialize();
    return r;
}
