/* no-network.so: a test shim (LD_PRELOAD) that refuses every internet socket (IPv4, IPv6, raw packets) and logs
 * who asked, to $WAAIYA_NET_LOG. linux/test_no_network.sh runs the filter and detector paths under it to check the
 * privacy claim that they never use the network ("nothing is sent"). Local sockets (AF_UNIX: the sound server,
 * the display) are allowed. */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

#ifndef AF_PACKET
#define AF_PACKET 17
#endif

static void note(const char *what, int domain) {
    const char *path = getenv("WAAIYA_NET_LOG");
    char exe[256] = "?";
    ssize_t n = readlink("/proc/self/exe", exe, sizeof exe - 1);
    if (n > 0) exe[n] = 0;
    char line[512];
    int len = snprintf(line, sizeof line, "%s: %s(domain %d) refused\n", exe, what, domain);
    int fd = path ? open(path, O_WRONLY | O_CREAT | O_APPEND, 0644) : 2;
    if (fd >= 0) {
        if (write(fd, line, (size_t)len) < 0) { /* nothing more to do */ }
        if (fd != 2) close(fd);
    }
}

static int internet(int domain) { return domain == AF_INET || domain == AF_INET6 || domain == AF_PACKET; }

int socket(int domain, int type, int protocol) {
    if (internet(domain)) {
        note("socket", domain);
        errno = EACCES;
        return -1;
    }
    int (*real)(int, int, int) = (int (*)(int, int, int))dlsym(RTLD_NEXT, "socket");
    return real ? real(domain, type, protocol) : (errno = ENOSYS, -1);
}

int socketpair(int domain, int type, int protocol, int sv[2]) {
    if (internet(domain)) {
        note("socketpair", domain);
        errno = EACCES;
        return -1;
    }
    int (*real)(int, int, int, int *) = (int (*)(int, int, int, int *))dlsym(RTLD_NEXT, "socketpair");
    return real ? real(domain, type, protocol, sv) : (errno = ENOSYS, -1);
}
