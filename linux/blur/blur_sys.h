/* im-blur's main loop (im_blur.c) is shared by Linux and Windows; what differs is here:
 *   blur_sys_posix.c        Linux: poll() on stdin, the worker's wake pipe and the backends' fds; signals
 *   windows/blur/sys_win.c  Windows: a thread reads stdin; the main thread waits on events and pumps the
 *                           overlay windows' messages (they belong to it) */
#ifndef IM_BLUR_SYS_H
#define IM_BLUR_SYS_H

#include <stddef.h>

/* Quit flag: set by a signal / console event, or by the main loop. */
extern volatile int ib_quit;

/* Signals or console events, stdin non-blocking (or its reader thread), the worker's wake channel. 0 = failed. */
int ib_sys_init(void);
/* Worker -> main: something is done. Any thread. */
void ib_sys_wake(void);
/* Main: clears the wake channel. */
void ib_sys_drain(void);
/* Waits up to timeout_ms for stdin, a wake, or the backends' fds (-1: none; Windows: window messages instead).
 * *stdin_ready = 1 when stdin has data or ended. Returns -1 on a fatal error. */
int ib_sys_wait(int cap_fd, int ov_fd, int timeout_ms, int *stdin_ready);
/* Reads what stdin has: > 0 bytes, 0 end of input (the app is gone), -1 nothing now. */
long ib_sys_read_stdin(char *buf, size_t cap);
/* Process CPU time (user + system), ms. */
double ib_sys_cpu_ms(void);
/* This thread's CPU time, ms. */
double ib_sys_thread_cpu_ms(void);
/* The folder of this program (UTF-8), "" if unknown. */
void ib_sys_exe_dir(char *out, size_t cap);
/* Sleeps ms milliseconds. */
void ib_sys_sleep_ms(int ms);

#endif
