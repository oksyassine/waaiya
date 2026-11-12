// waaiya-wtest.exe: audio tool for the Windows CI tests (windows/test/audio_test.py). Not shipped.
//
//   waaiya-wtest tone [--seconds S] [--freq F] [--level L]
//       plays an instrument-like tone (harmonics of F) from this process's own audio session; prints "pid N", then
//       "playing" once Windows takes the samples
//   waaiya-wtest capture --out FILE [--seconds S] [--pid P --include|--exclude]
//       records 48 kHz float stereo: by default what the default output plays (endpoint loopback, after every
//       app's session volume: what the user hears), or process P's sound (process loopback); prints the level
//   waaiya-wtest volume --pid P [--set V] [--wait S]
//       prints (or sets) the session volume of process P on every output; waits up to S seconds for a session
#include "../common/wasapi.h"

#include <cmath>
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

namespace {

constexpr int RATE = 48000, CH = 2;
constexpr double kPi = 3.14159265358979323846;

double level_db(const std::vector<float> &x) {
    double s = 0;
    for (float v : x) s += (double)v * v;
    double rms = x.empty() ? 0 : std::sqrt(s / (double)x.size());
    return rms > 0 ? 20 * std::log10(rms) : -INFINITY;
}

int tone(double seconds, double freq, double level) {
    Com<IMMDeviceEnumerator> devs;
    Com<IMMDevice> dev;
    Com<IAudioClient> ac;
    Com<IAudioRenderClient> rc;
    HRESULT hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr, CLSCTX_ALL, __uuidof(IMMDeviceEnumerator),
                                  reinterpret_cast<void **>(devs.put()));
    if (SUCCEEDED(hr)) hr = devs->GetDefaultAudioEndpoint(eRender, eConsole, dev.put());
    if (SUCCEEDED(hr)) hr = dev->Activate(__uuidof(IAudioClient), CLSCTX_ALL, nullptr, reinterpret_cast<void **>(ac.put()));
    WAVEFORMATEX fmt = im_float_format(RATE, CH);
    if (SUCCEEDED(hr))
        hr = ac->Initialize(AUDCLNT_SHAREMODE_SHARED,
                            AUDCLNT_STREAMFLAGS_AUTOCONVERTPCM | AUDCLNT_STREAMFLAGS_SRC_DEFAULT_QUALITY, 2000000, 0,
                            &fmt, nullptr);
    UINT32 frames = 0;
    if (SUCCEEDED(hr)) hr = ac->GetBufferSize(&frames);
    if (SUCCEEDED(hr)) hr = ac->GetService(__uuidof(IAudioRenderClient), reinterpret_cast<void **>(rc.put()));
    if (FAILED(hr)) {
        fprintf(stderr, "tone: %s\n", im_hr(hr).c_str());
        return 1;
    }
    printf("pid %lu\n", (unsigned long)GetCurrentProcessId());
    fflush(stdout);
    // harmonics 1..8 with 1/h amplitude, a slow tremolo so it is not perfectly stationary (like an instrument note)
    double ph = 0, amp_norm = 0;
    for (int h = 1; h <= 8; h++) amp_norm += 1.0 / h;
    long long n = 0, total = (long long)(seconds * RATE);
    bool started = false;
    while (n < total) {
        UINT32 pad = 0;
        if (FAILED(ac->GetCurrentPadding(&pad))) return 1;
        UINT32 want = frames - pad;
        if (want > 0) {
            BYTE *b = nullptr;
            if (FAILED(rc->GetBuffer(want, &b))) return 1;
            float *f = reinterpret_cast<float *>(b);
            for (UINT32 i = 0; i < want; i++, n++) {
                double s = 0;
                for (int h = 1; h <= 8; h++) s += std::sin(h * ph) / h;
                double trem = 1.0 + 0.2 * std::sin(2 * kPi * 3.0 * (double)n / RATE);
                float v = (float)(level * trem * s / amp_norm);
                f[2 * i] = v;
                f[2 * i + 1] = v;
                ph += 2 * kPi * freq / RATE;
                if (ph > 2 * kPi) ph -= 2 * kPi;
            }
            rc->ReleaseBuffer(want, 0);
        }
        if (!started) {
            ac->Start();
            started = true;
            printf("playing\n");
            fflush(stdout);
        }
        Sleep(20);
    }
    Sleep(300);
    ac->Stop();
    return 0;
}

int capture(const wchar_t *out, double seconds, DWORD pid, bool include) {
    Com<IAudioClient> ac;
    HRESULT hr;
    WAVEFORMATEX fmt = im_float_format(RATE, CH);
    const DWORD conv = AUDCLNT_STREAMFLAGS_AUTOCONVERTPCM | AUDCLNT_STREAMFLAGS_SRC_DEFAULT_QUALITY;
    if (pid) {
        hr = im_activate_process_loopback(pid, !include, ac.put());
        if (SUCCEEDED(hr))
            hr = ac->Initialize(AUDCLNT_SHAREMODE_SHARED, AUDCLNT_STREAMFLAGS_LOOPBACK | conv, 2000000, 0, &fmt, nullptr);
    } else {
        Com<IMMDeviceEnumerator> devs;
        Com<IMMDevice> dev;
        hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr, CLSCTX_ALL, __uuidof(IMMDeviceEnumerator),
                              reinterpret_cast<void **>(devs.put()));
        if (SUCCEEDED(hr)) hr = devs->GetDefaultAudioEndpoint(eRender, eConsole, dev.put());
        if (SUCCEEDED(hr)) hr = dev->Activate(__uuidof(IAudioClient), CLSCTX_ALL, nullptr, reinterpret_cast<void **>(ac.put()));
        if (SUCCEEDED(hr))
            hr = ac->Initialize(AUDCLNT_SHAREMODE_SHARED, AUDCLNT_STREAMFLAGS_LOOPBACK | conv, 2000000, 0, &fmt, nullptr);
    }
    Com<IAudioCaptureClient> cc;
    if (SUCCEEDED(hr)) hr = ac->GetService(__uuidof(IAudioCaptureClient), reinterpret_cast<void **>(cc.put()));
    if (SUCCEEDED(hr)) hr = ac->Start();
    if (FAILED(hr)) {
        fprintf(stderr, "capture: %s\n", im_hr(hr).c_str());
        return 1;
    }
    std::vector<float> data;
    size_t want = (size_t)(seconds * RATE) * CH;
    // endpoint loopback sends nothing while nothing plays: time it by the clock, filling the gaps with silence
    ULONGLONG t0 = GetTickCount64();
    while (data.size() < want) {
        Sleep(10);
        UINT32 n = 0;
        while (SUCCEEDED(cc->GetNextPacketSize(&n)) && n > 0) {
            BYTE *b = nullptr;
            UINT32 fr = 0;
            DWORD flags = 0;
            if (FAILED(cc->GetBuffer(&b, &fr, &flags, nullptr, nullptr))) break;
            const float *f = reinterpret_cast<const float *>(b);
            for (UINT32 i = 0; i < fr * CH; i++) data.push_back((flags & AUDCLNT_BUFFERFLAGS_SILENT) ? 0.0f : f[i]);
            cc->ReleaseBuffer(fr);
        }
        size_t by_clock = (size_t)((GetTickCount64() - t0) / 1000.0 * RATE) * CH;
        if (by_clock > data.size() + RATE / 5 * CH) data.resize(by_clock, 0.0f); // > 200 ms behind: silence
    }
    ac->Stop();
    data.resize(want);
    FILE *f = _wfopen(out, L"wb");
    if (!f) return 1;
    fwrite(data.data(), sizeof(float), data.size(), f);
    fclose(f);
    printf("level %.2f dBFS\n", level_db(data));
    return 0;
}

int volume(DWORD pid, bool set, float v, double wait_s) {
    Com<IMMDeviceEnumerator> devs;
    if (FAILED(CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr, CLSCTX_ALL, __uuidof(IMMDeviceEnumerator),
                                reinterpret_cast<void **>(devs.put()))))
        return 1;
    ULONGLONG until = GetTickCount64() + (ULONGLONG)(wait_s * 1000);
    do {
        int found = 0;
        float first = -1;
        Com<IMMDeviceCollection> all;
        devs->EnumAudioEndpoints(eRender, DEVICE_STATE_ACTIVE, all.put());
        UINT n = 0;
        if (all) all->GetCount(&n);
        for (UINT i = 0; i < n; i++) {
            Com<IMMDevice> d;
            Com<IAudioSessionManager2> m;
            Com<IAudioSessionEnumerator> e;
            if (FAILED(all->Item(i, d.put())) ||
                FAILED(d->Activate(__uuidof(IAudioSessionManager2), CLSCTX_ALL, nullptr, reinterpret_cast<void **>(m.put()))) ||
                FAILED(m->GetSessionEnumerator(e.put())))
                continue;
            int c = 0;
            e->GetCount(&c);
            for (int k = 0; k < c; k++) {
                Com<IAudioSessionControl> s;
                Com<IAudioSessionControl2> s2;
                Com<ISimpleAudioVolume> sv;
                DWORD p = 0;
                if (FAILED(e->GetSession(k, s.put())) ||
                    FAILED(s->QueryInterface(__uuidof(IAudioSessionControl2), reinterpret_cast<void **>(s2.put()))) ||
                    FAILED(s2->GetProcessId(&p)) || p != pid ||
                    FAILED(s->QueryInterface(__uuidof(ISimpleAudioVolume), reinterpret_cast<void **>(sv.put()))))
                    continue;
                if (set) sv->SetMasterVolume(v, nullptr);
                else if (first < 0) sv->GetMasterVolume(&first);
                found++;
            }
        }
        if (found) {
            if (!set) printf("%.6f\n", first);
            return 0;
        }
        Sleep(200);
    } while (GetTickCount64() < until);
    fprintf(stderr, "volume: process %lu has no audio session\n", (unsigned long)pid);
    return 4;
}

} // namespace

int wmain(int argc, wchar_t **argv) {
    if (argc < 2) return 2;
    CoInitializeEx(nullptr, COINIT_MULTITHREADED);
    std::wstring cmd = argv[1];
    double seconds = 5, freq = 220, level = 0.3, wait_s = 0;
    DWORD pid = 0;
    bool include = true, set = false;
    float v = 1;
    const wchar_t *out = nullptr;
    for (int i = 2; i < argc; i++) {
        std::wstring a = argv[i];
        const wchar_t *val = i + 1 < argc ? argv[i + 1] : L"";
        if (a == L"--seconds") seconds = _wtof(argv[++i]);
        else if (a == L"--freq") freq = _wtof(argv[++i]);
        else if (a == L"--level") level = _wtof(argv[++i]);
        else if (a == L"--pid") pid = (DWORD)_wtol(argv[++i]);
        else if (a == L"--include") include = true;
        else if (a == L"--exclude") include = false;
        else if (a == L"--out") out = argv[++i];
        else if (a == L"--wait") wait_s = _wtof(argv[++i]);
        else if (a == L"--set") {
            set = true;
            v = (float)_wtof(val);
            i++;
        } else {
            fprintf(stderr, "wtest: unknown argument\n");
            return 2;
        }
    }
    int r = 2;
    if (cmd == L"tone") r = tone(seconds, freq, level);
    else if (cmd == L"capture" && out) r = capture(out, seconds, pid, include);
    else if (cmd == L"volume" && pid) r = volume(pid, set, v, wait_s);
    CoUninitialize();
    return r;
}
