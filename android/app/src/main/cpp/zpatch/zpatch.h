#ifndef WAAIYA_ZPATCH_H
#define WAAIYA_ZPATCH_H
#include <stddef.h>
/* 0 on success; -1 with a message in err (and no output file left behind). */
int zpatch_apply(const char *old_path, const char *patch_path, const char *out_path, long long out_size,
                 char *err, size_t errlen);
#endif
