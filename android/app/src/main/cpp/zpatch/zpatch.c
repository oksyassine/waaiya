/* Waaiya's update patcher: rebuilds a new APK from the installed one and a zstd "--patch-from" patch.
 * One-shot decode into a memory-mapped output file, the old APK memory-mapped as the prefix: no large heap
 * buffer, whatever the APK size. The caller checks the result's SHA-256 before anything uses it. */
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>
#define ZSTD_STATIC_LINKING_ONLY
#include "../zstd/zstd.h"
#include "zpatch.h"

static int fail(char *err, size_t n, const char *what, const char *detail) {
    if (err && n) snprintf(err, n, "%s: %s", what, detail ? detail : strerror(errno));
    return -1;
}

static void *map_read(const char *path, size_t *len) {
    int fd = open(path, O_RDONLY | O_CLOEXEC);
    if (fd < 0) return NULL;
    struct stat st;
    if (fstat(fd, &st) != 0 || st.st_size <= 0) { close(fd); return NULL; }
    void *p = mmap(NULL, (size_t)st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
    close(fd);
    if (p == MAP_FAILED) return NULL;
    *len = (size_t)st.st_size;
    return p;
}

int zpatch_apply(const char *old_path, const char *patch_path, const char *out_path, long long out_size,
                 char *err, size_t errlen) {
    if (out_size <= 0 || (unsigned long long)out_size > (1ULL << 30))
        return fail(err, errlen, "size", "the new file's size must be between 1 byte and 1 GiB");
    size_t old_len = 0, patch_len = 0;
    void *old = map_read(old_path, &old_len);
    if (!old) return fail(err, errlen, "old", NULL);
    void *patch = map_read(patch_path, &patch_len);
    if (!patch) { munmap(old, old_len); return fail(err, errlen, "patch", NULL); }

    unsigned long long content = ZSTD_getFrameContentSize(patch, patch_len);
    if (content != (unsigned long long)out_size) {
        munmap(old, old_len); munmap(patch, patch_len);
        return fail(err, errlen, "patch", "its frame does not announce the expected size");
    }
    int fd = open(out_path, O_RDWR | O_CREAT | O_TRUNC | O_CLOEXEC, 0600);
    if (fd < 0) { munmap(old, old_len); munmap(patch, patch_len); return fail(err, errlen, "out", NULL); }
    if (ftruncate(fd, (off_t)out_size) != 0) {
        close(fd); munmap(old, old_len); munmap(patch, patch_len); return fail(err, errlen, "out", NULL);
    }
    void *out = mmap(NULL, (size_t)out_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (out == MAP_FAILED) {
        close(fd); munmap(old, old_len); munmap(patch, patch_len); return fail(err, errlen, "out map", NULL);
    }

    int rc = 0;
    ZSTD_DCtx *dctx = ZSTD_createDCtx();
    if (!dctx) { rc = fail(err, errlen, "zstd", "out of memory"); goto done; }
    /* One-shot decoding uses the output buffer as history: the frame's window (= the APK size, which can be larger
     * than the streaming default of 128 MiB) costs no extra memory. */
    size_t r = ZSTD_DCtx_setParameter(dctx, ZSTD_d_windowLogMax, sizeof(void *) == 4 ? ZSTD_WINDOWLOG_MAX_32 : 30);
    if (!ZSTD_isError(r)) r = ZSTD_DCtx_refPrefix(dctx, old, old_len);
    if (!ZSTD_isError(r)) r = ZSTD_decompressDCtx(dctx, out, (size_t)out_size, patch, patch_len);
    if (ZSTD_isError(r)) rc = fail(err, errlen, "zstd", ZSTD_getErrorName(r));
    else if (r != (size_t)out_size) rc = fail(err, errlen, "zstd", "short output");
    else if (msync(out, (size_t)out_size, MS_SYNC) != 0) rc = fail(err, errlen, "out sync", NULL);
    ZSTD_freeDCtx(dctx);
done:
    munmap(out, (size_t)out_size);
    close(fd);
    munmap(old, old_len);
    munmap(patch, patch_len);
    if (rc != 0) unlink(out_path);
    return rc;
}
