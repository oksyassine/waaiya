/* waaiya-blur.exe on Windows (blur_sys.h): a thread reads stdin (pipes cannot be waited on), the worker wakes the
 * main thread with an event, and the main thread's wait also returns for window messages: the overlay's windows
 * belong to it (windows/blur/overlay.cpp pumps them in its dispatch). */
#include "blur_sys.h"

#include <windows.h>

#include <stdio.h>
#include <string.h>

volatile int ib_quit;

static HANDLE wake_ev, in_ev;
static CRITICAL_SECTION in_mu;
static char in_buf[8192];
static size_t in_len;
static int in_eof;

static DWORD WINAPI stdin_reader(LPVOID arg) {
    (void)arg;
    HANDLE h = GetStdHandle(STD_INPUT_HANDLE);
    char buf[512];
    for (;;) {
        DWORD k = 0;
        BOOL ok = ReadFile(h, buf, sizeof buf, &k, NULL);
        EnterCriticalSection(&in_mu);
        if (!ok || k == 0) {
            in_eof = 1; /* the app is gone (pipe closed) */
        } else {
            if (in_len + k > sizeof in_buf) in_len = 0; /* nobody reads: drop, as an overlong line */
            memcpy(in_buf + in_len, buf, k);
            in_len += k;
        }
        LeaveCriticalSection(&in_mu);
        SetEvent(in_ev);
        if (!ok || k == 0) return 0;
    }
}

static BOOL WINAPI on_console(DWORD type) {
    (void)type;
    ib_quit = 1;
    SetEvent(wake_ev);
    return TRUE;
}

int ib_sys_init(void) {
    /* covers drawn in physical pixels on every monitor, whatever its scaling */
    SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
    wake_ev = CreateEventW(NULL, FALSE, FALSE, NULL);
    in_ev = CreateEventW(NULL, FALSE, FALSE, NULL);
    InitializeCriticalSection(&in_mu);
    SetConsoleCtrlHandler(on_console, TRUE);
    HANDLE th = CreateThread(NULL, 0, stdin_reader, NULL, 0, NULL);
    if (!wake_ev || !in_ev || !th) return 0;
    CloseHandle(th);
    return 1;
}

void ib_sys_wake(void) { SetEvent(wake_ev); }

void ib_sys_drain(void) { ResetEvent(wake_ev); }

int ib_sys_wait(int cap_fd, int ov_fd, int timeout_ms, int *stdin_ready) {
    (void)cap_fd;
    (void)ov_fd;
    HANDLE hs[2] = {in_ev, wake_ev};
    *stdin_ready = 0;
    /* QS_ALLINPUT: window messages (display changes, the overlay's own) end the wait too */
    DWORD w = MsgWaitForMultipleObjectsEx(2, hs, (DWORD)timeout_ms, QS_ALLINPUT, MWMO_INPUTAVAILABLE);
    if (w == WAIT_FAILED) return -1;
    EnterCriticalSection(&in_mu);
    *stdin_ready = in_len > 0 || in_eof;
    LeaveCriticalSection(&in_mu);
    return 0;
}

long ib_sys_read_stdin(char *buf, size_t cap) {
    EnterCriticalSection(&in_mu);
    long r;
    if (in_len > 0) {
        size_t k = in_len < cap ? in_len : cap;
        memcpy(buf, in_buf, k);
        memmove(in_buf, in_buf + k, in_len - k);
        in_len -= k;
        r = (long)k;
    } else {
        r = in_eof ? 0 : -1;
    }
    LeaveCriticalSection(&in_mu);
    return r;
}

static double ft_ms(FILETIME f) { return (double)(((unsigned long long)f.dwHighDateTime << 32) | f.dwLowDateTime) / 1e4; }

double ib_sys_cpu_ms(void) {
    FILETIME c, e, k, u;
    if (!GetProcessTimes(GetCurrentProcess(), &c, &e, &k, &u)) return 0;
    return ft_ms(k) + ft_ms(u);
}

double ib_sys_thread_cpu_ms(void) {
    FILETIME c, e, k, u;
    if (!GetThreadTimes(GetCurrentThread(), &c, &e, &k, &u)) return 0;
    return ft_ms(k) + ft_ms(u);
}

void ib_sys_exe_dir(char *out, size_t cap) {
    wchar_t w[MAX_PATH * 4];
    DWORD n = GetModuleFileNameW(NULL, w, (DWORD)(sizeof w / sizeof *w));
    out[0] = 0;
    if (n == 0 || n >= sizeof w / sizeof *w) return;
    w[n] = 0;
    wchar_t *slash = wcsrchr(w, L'\\');
    if (slash) *slash = 0;
    if (!WideCharToMultiByte(CP_UTF8, 0, w, -1, out, (int)cap, NULL, NULL)) out[0] = 0;
}

void ib_sys_sleep_ms(int ms) { Sleep((DWORD)ms); }
