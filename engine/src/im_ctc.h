/* Greedy CTC decoding and UTF-8 helpers, shared by im_asr.c and its tests (engine/test/test_captions.c). */
#ifndef IM_CTC_H
#define IM_CTC_H

#include <stddef.h>

/* The best token of each frame, repeats merged, blanks dropped, joined into text: a token's U+2581 is a space,
 * tokens written <...> are left out, spaces are trimmed and never doubled. logits: [frames, ntok]. tokens: ntok
 * strings. Writes out as im_asr_transcribe; returns the length in bytes. */
int im_ctc_decode(const float *logits, int frames, int ntok, int blank, const char *const *tokens, char *out,
                  size_t cap);

/* The largest length <= n that ends on a UTF-8 character boundary of s. */
size_t im_utf8_fit(const char *s, size_t n);

#endif
