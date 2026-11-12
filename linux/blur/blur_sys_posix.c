/* im-blur on Linux: poll(), a self-pipe for the worker, signals (blur_sys.h). */
#define _GNU_SOURCE
#include "blur_sys.h"

#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <poll.h>
#include <signal.h>
#include <stdio.h>
#include <string.h>
#include <sys/resource.h>
#include <time.h>
#include <unistd.h>

volatile int ib_quit;
static int wake_pipe[2] = {-1, -1};

static void on_signal(int s) {
    (void)s;
    ib_quit = 1;
}

int ib_sys_init(void) {
    signal(SIGPIPE, SIG_IGN);
    struct sigaction sa;
    memset(&sa, 0, sizeof sa);
    sa.sa_handler = on_signal;
    sigaction(SIGTERM, &sa, NULL);
    sigaction(SIGINT, &sa, NULL);
    sigaction(SIGHUP, &sa, NULL);
    fcntl(0, F_SETFL, fcntl(0, F_GETFL) | O_NONBLOCK);
    return pipe2(wake_pipe, O_NONBLOCK | O_CLOEXEC) == 0;
}

void ib_sys_wake(void) {
    char one = 1;
    if (write(wake_pipe[1], &one, 1) < 0) { /* full pipe: main wakes anyway */ }
}

void ib_sys_drain(void) {
    char drain[64];
    while (read(wake_pipe[0], drain, sizeof drain) > 0) {}
}

int ib_sys_wait(int cap_fd, int ov_fd, int timeout_ms, int *stdin_ready) {
    struct pollfd pf[4];
    int np = 0;
    pf[np++] = (struct pollfd){0, POLLIN, 0};
    pf[np++] = (struct pollfd){wake_pipe[0], POLLIN, 0};
    if (cap_fd >= 0) pf[np++] = (struct pollfd){cap_fd, POLLIN, 0};
    if (ov_fd >= 0 && ov_fd != cap_fd) pf[np++] = (struct pollfd){ov_fd, POLLIN, 0};
    *stdin_ready = 0;
    if (poll(pf, (nfds_t)np, timeout_ms) < 0) return errno == EINTR ? 0 : -1;
    *stdin_ready = pf[0].revents != 0;
    return 0;
}

long ib_sys_read_stdin(char *buf, size_t cap) {
    ssize_t k = read(0, buf, cap);
    if (k == 0) return 0;
    return k < 0 ? -1 : (long)k;
}

double ib_sys_cpu_ms(void) {
    struct rusage ru;
    getrusage(RUSAGE_SELF, &ru);
    return (ru.ru_utime.tv_sec + ru.ru_stime.tv_sec) * 1e3 + (ru.ru_utime.tv_usec + ru.ru_stime.tv_usec) / 1e3;
}

double ib_sys_thread_cpu_ms(void) {
    struct timespec c;
    clock_gettime(CLOCK_THREAD_CPUTIME_ID, &c);
    return c.tv_sec * 1e3 + c.tv_nsec / 1e6;
}

void ib_sys_exe_dir(char *out, size_t cap) {
    char exe[PATH_MAX];
    ssize_t k = readlink("/proc/self/exe", exe, sizeof exe - 1);
    out[0] = 0;
    if (k <= 0) return;
    exe[k] = 0;
    char *slash = strrchr(exe, '/');
    if (slash) *slash = 0;
    snprintf(out, cap, "%s", exe);
}

void ib_sys_sleep_ms(int ms) { usleep((useconds_t)ms * 1000); }
