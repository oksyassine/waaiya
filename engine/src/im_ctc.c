/* Greedy CTC decoding and UTF-8 helpers (im_ctc.h). No ONNX Runtime here: the tests use it on its own. */
#include "im_ctc.h"

#include <string.h>

size_t im_utf8_fit(const char *s, size_t n) {
    /* step back over continuation bytes (10xxxxxx) so the cut falls before a character's first byte */
    size_t len = strlen(s);
    if (n >= len) return len;
    while (n > 0 && ((unsigned char)s[n] & 0xC0) == 0x80) n--;
    return n;
}

/* appends s to out (len bytes used, cap total); returns 0 when out is full */
static int put(char *out, size_t cap, size_t *len, const char *s, size_t n) {
    if (*len + 1 >= cap) return 0;
    size_t room = cap - 1 - *len;
    if (n > room) {
        /* cut on a character boundary (s[room] exists: room < n) */
        size_t k = room;
        while (k > 0 && ((unsigned char)s[k] & 0xC0) == 0x80) k--;
        memcpy(out + *len, s, k);
        *len += k;
        out[*len] = 0;
        return 0;
    }
    memcpy(out + *len, s, n);
    *len += n;
    out[*len] = 0;
    return 1;
}

int im_ctc_decode(const float *logits, int frames, int ntok, int blank, const char *const *tokens, char *out,
                  size_t cap) {
    if (!out || cap == 0) return 0;
    out[0] = 0;
    size_t len = 0;
    int prev = -1, space = 0;     /* space: a word break is pending (written before the next text) */
    for (int t = 0; t < frames; t++) {
        const float *row = logits + (size_t)t * (size_t)ntok;
        int best = 0;
        for (int v = 1; v < ntok; v++)
            if (row[v] > row[best]) best = v;
        if (best == prev) continue;
        prev = best;
        if (best == blank || !tokens[best]) continue;
        const char *s = tokens[best];
        size_t sl = strlen(s);
        if (sl >= 2 && s[0] == '<' && s[sl - 1] == '>') continue;
        /* U+2581 is E2 96 81 */
        while (*s) {
            if ((unsigned char)s[0] == 0xE2 && (unsigned char)s[1] == 0x96 && (unsigned char)s[2] == 0x81) {
                space = 1, s += 3;
            } else if (*s == ' ') {
                space = 1, s++;
            } else {
                const char *e = s;
                while (*e && *e != ' ' && !((unsigned char)e[0] == 0xE2 && (unsigned char)e[1] == 0x96 &&
                                            (unsigned char)e[2] == 0x81))
                    e++;
                if (space && len > 0 && !put(out, cap, &len, " ", 1)) return (int)len;
                space = 0;
                if (!put(out, cap, &len, s, (size_t)(e - s))) return (int)len;
                s = e;
            }
        }
    }
    return (int)len;
}
