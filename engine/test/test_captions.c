/* Live captions without a model (im_captions.h): a stand-in recogniser that counts the "words" (bursts of sound)
 * it is given, and synthetic speech made of such bursts. Checks lines and pauses, partial lines, the cut of a long
 * line at a pause (no word lost or doubled), short clicks, 48 kHz input (decimation), failures, reset, and the CTC
 * decoding and UTF-8 cuts (im_ctc.h).
 * Usage: test-captions */
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "im_captions.h"
#include "im_ctc.h"

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

static int fails;
#define CHECK(c, ...) do { if (c) { printf("ok: "); printf(__VA_ARGS__); printf("\n"); } \
                           else { printf("FAIL: "); printf(__VA_ARGS__); printf("\n"); fails++; } } while (0)

/* ---- synthetic speech: words are 0.3 s bursts of a voiced sound, a quiet hiss between them ---- */

typedef struct { float *x; long n, cap; int rate; long words; unsigned seed; } signal;

static float noise(signal *s) {
    s->seed = s->seed * 1103515245u + 12345u;
    return ((float)((s->seed >> 9) & 0xFFFF) / 65535.0f - 0.5f);
}

static void grow(signal *s, long add) {
    if (s->n + add <= s->cap) return;
    while (s->n + add > s->cap) s->cap = s->cap ? s->cap * 2 : 1 << 16;
    s->x = realloc(s->x, sizeof(float) * (size_t)s->cap);
}

static void quiet(signal *s, double sec) {
    long m = (long)(sec * s->rate);
    grow(s, m);
    for (long i = 0; i < m; i++) s->x[s->n++] = 0.0002f * noise(s);   /* about -80 dBFS */
}

static void word(signal *s, double sec) {
    long m = (long)(sec * s->rate);
    grow(s, m);
    for (long i = 0; i < m; i++) {
        double t = (double)i / s->rate, v = 0;
        for (int h = 1; h <= 6; h++) v += sin(2 * M_PI * 150.0 * h * t) / h;
        double env = sin(M_PI * (double)i / m);
        s->x[s->n++] = (float)(0.15 * env * v) + 0.0002f * noise(s);
    }
    s->words++;
}

/* words separated by short gaps (inside a sentence) */
static void sentence(signal *s, int words) {
    for (int i = 0; i < words; i++) {
        word(s, 0.3);
        quiet(s, 0.15);
    }
}

/* ---- the stand-in recogniser ---- */

typedef struct {
    int calls, fail_next;
    long max_n;
    double rms;          /* of the last audio */
} counter;

/* "كلمة" once per burst: 20 ms levels above -35 dBFS, rising edges at least 100 ms apart */
static int count_words(void *user, const float *x, int n, char *out, size_t cap) {
    counter *c = user;
    c->calls++;
    if (n > c->max_n) c->max_n = n;
    double tot = 0;
    for (int i = 0; i < n; i++) tot += (double)x[i] * x[i];
    c->rms = sqrt(tot / (n > 0 ? n : 1));
    if (c->fail_next) { c->fail_next = 0; return -1; }
    int words = 0, loud = 0, since = 1000;
    for (int f = 0; f + 320 <= n; f += 320) {
        double e = 0;
        for (int i = 0; i < 320; i++) e += (double)x[f + i] * x[f + i];
        int l = 10 * log10(e / 320 + 1e-12) > -35;
        if (l && !loud && since >= 5) { words++; since = 0; }
        loud = l;
        since++;
    }
    size_t len = 0;
    out[0] = 0;
    for (int w = 0; w < words; w++) {
        const char *s = w ? " كلمة" : "كلمة";
        size_t sl = strlen(s);
        if (len + sl + 1 > cap) break;
        memcpy(out + len, s, sl + 1);
        len += sl;
    }
    return (int)len;
}

static int words_in(const char *s) {
    int n = 0;
    for (const char *p = s; (p = strstr(p, "كلمة")); p += 1) n++;
    return n;
}

typedef struct { int finals, words, partials, last_partial_words; char first[4096]; } run_result;

/* pushes the signal in 10 ms blocks; collects finals */
static run_result run(im_captions *k, const signal *s, int flush) {
    run_result r = {0};
    int block = s->rate / 100;
    char line[4096];
    for (long i = 0; i < s->n; i += block) {
        int m = (int)(s->n - i < block ? s->n - i : block);
        int f = im_captions_push(k, s->x + i, m);
        if (f > 0 && (f & IM_CAPTIONS_PARTIAL) && im_captions_partial(k)[0]) {
            r.partials++;
            r.last_partial_words = words_in(im_captions_partial(k));
        }
        while (im_captions_take_final(k, line, sizeof line) > 0) {
            if (!r.finals) snprintf(r.first, sizeof r.first, "%s", line);
            r.finals++;
            r.words += words_in(line);
        }
    }
    if (flush) im_captions_flush(k);
    while (im_captions_take_final(k, line, sizeof line) > 0) {
        if (!r.finals) snprintf(r.first, sizeof r.first, "%s", line);
        r.finals++;
        r.words += words_in(line);
    }
    return r;
}

static im_captions *make(int rate, counter *c) {
    im_captions_config cfg;
    im_captions_default_config(&cfg);
    cfg.in_rate = rate;
    memset(c, 0, sizeof *c);
    return im_captions_create(&cfg, count_words, c);
}

static void test_ctc(void) {
    const char *tok[] = {"<blk>", "\xE2\x96\x81" "ال", "سلام", "\xE2\x96\x81" "عليكم", "<unk>", "م"};
    int seq[] = {1, 1, 0, 2, 0, 3, 4, 0, 5, 0, 5, 5};
    int T = (int)(sizeof seq / sizeof seq[0]), V = 6;
    float *lg = calloc((size_t)T * V, sizeof(float));
    for (int t = 0; t < T; t++) lg[t * V + seq[t]] = 5.0f;
    char out[256];
    int n = im_ctc_decode(lg, T, V, 0, tok, out, sizeof out);
    CHECK(strcmp(out, "السلام عليكممم") == 0 && n == (int)strlen(out), "CTC: repeats merged, blanks and <unk> out, ▁ is a space: \"%s\"", out);
    /* a blank between two equal tokens keeps both; a space is never first or doubled */
    const char *tok2[] = {"_", "\xE2\x96\x81", "\xE2\x96\x81" "قال"};
    int seq2[] = {1, 0, 1, 2, 0, 1};
    float lg2[6 * 3] = {0};
    for (int t = 0; t < 6; t++) lg2[t * 3 + seq2[t]] = 1.0f;
    im_ctc_decode(lg2, 6, 3, 0, tok2, out, sizeof out);
    CHECK(strcmp(out, "قال") == 0, "CTC: lone word breaks give no stray spaces: \"%s\"", out);
    /* cut on a character boundary: "السلام" is 12 bytes, 2 bytes per letter */
    n = im_ctc_decode(lg, T, V, 0, tok, out, 6);
    CHECK(n == 4 && strcmp(out, "ال") == 0, "CTC: a short buffer cuts between letters (%d bytes)", n);
    CHECK(im_utf8_fit("سلام", 3) == 2 && im_utf8_fit("abc", 9) == 3, "UTF-8 fit");
    free(lg);
}

int main(void) {
    test_ctc();
    counter c;

    /* one sentence between pauses */
    signal s = {0};
    s.rate = 16000;
    quiet(&s, 1.0);
    sentence(&s, 6);
    quiet(&s, 1.5);
    im_captions *k = make(16000, &c);
    run_result r = run(k, &s, 0);
    CHECK(r.finals == 1 && r.words == 6, "one sentence, one line: %d line(s), %d of 6 words", r.finals, r.words);
    CHECK(r.partials >= 2 && r.last_partial_words >= 3, "the line shows while it is spoken: %d partials, last with %d words",
          r.partials, r.last_partial_words);
    CHECK(!im_captions_speaking(k) && im_captions_partial(k)[0] == 0, "after the pause: no open line, partial cleared");
    CHECK(im_captions_last_ms(k) >= 0 && im_captions_last_audio_s(k) > 2.0, "timing of the last recognition (%.1f s of audio)",
          im_captions_last_audio_s(k));
    im_captions_destroy(k);

    /* two sentences: two lines, in order */
    signal s2 = {0};
    s2.rate = 16000;
    quiet(&s2, 0.5);
    sentence(&s2, 3);
    quiet(&s2, 1.2);
    sentence(&s2, 5);
    quiet(&s2, 1.0);
    k = make(16000, &c);
    r = run(k, &s2, 0);
    CHECK(r.finals == 2 && r.words == 8 && words_in(r.first) == 3, "two sentences: %d lines, first with %d words, %d of 8 words",
          r.finals, words_in(r.first), r.words);
    im_captions_destroy(k);

    /* a 30 s run without a long pause: cut into lines of at most 12 s, every word once */
    signal s3 = {0};
    s3.rate = 16000;
    quiet(&s3, 0.5);
    sentence(&s3, 66);
    quiet(&s3, 1.0);
    k = make(16000, &c);
    r = run(k, &s3, 0);
    CHECK(r.finals >= 3 && r.words == 66, "a long run: %d lines, %d of 66 words (none lost or doubled)", r.finals, r.words);
    CHECK(c.max_n <= 12 * 16000 + 320, "no line longer than 12 s (longest %.2f s)", c.max_n / 16000.0);
    im_captions_destroy(k);

    /* a click is not speech */
    signal s4 = {0};
    s4.rate = 16000;
    quiet(&s4, 1.0);
    word(&s4, 0.08);
    quiet(&s4, 1.5);
    k = make(16000, &c);
    r = run(k, &s4, 0);
    CHECK(r.finals == 0, "a click gives no line (%d)", r.finals);
    im_captions_destroy(k);

    /* the end of the stream: flush makes the open line final */
    signal s5 = {0};
    s5.rate = 16000;
    quiet(&s5, 0.5);
    sentence(&s5, 4);
    k = make(16000, &c);
    r = run(k, &s5, 1);
    CHECK(r.finals == 1 && r.words == 4, "flush: the open line ends (%d line, %d words)", r.finals, r.words);
    im_captions_destroy(k);

    /* 48 kHz in: the same lines, and the voice band passes the decimation at full level */
    signal s6 = {0};
    s6.rate = 48000;
    quiet(&s6, 1.0);
    sentence(&s6, 6);
    quiet(&s6, 1.2);
    sentence(&s6, 2);
    quiet(&s6, 1.0);
    k = make(48000, &c);
    r = run(k, &s6, 0);
    CHECK(r.finals == 2 && r.words == 8, "48 kHz in: %d lines, %d of 8 words", r.finals, r.words);
    im_captions_destroy(k);

    /* decimation: a 1 kHz tone keeps its level, a 12 kHz tone (above 8 kHz) is gone */
    for (int pass = 0; pass < 2; pass++) {
        double f = pass ? 12000.0 : 1000.0;
        k = make(48000, &c);
        signal t = {0};
        t.rate = 48000;
        long m = 48000 * 2;
        grow(&t, m);
        /* 50 ms fades: a sudden start would spread energy below 8 kHz by itself */
        long fade = 2400;
        for (long i = 0; i < m; i++) {
            double g = i < fade ? 0.5 - 0.5 * cos(M_PI * i / fade) : i >= m - fade ? 0.5 - 0.5 * cos(M_PI * (m - i) / fade) : 1.0;
            t.x[t.n++] = (float)(g * 0.3 * sin(2 * M_PI * f * i / 48000.0));
        }
        im_captions_config cfg;
        im_captions_default_config(&cfg);
        /* gate low so a line opens for the 12 kHz case too; we only look at what reaches the recogniser */
        cfg.gate_db = -200.0f;
        cfg.gate_above_floor_db = -200.0f;
        cfg.min_speech_s = 0;
        im_captions_destroy(k);
        memset(&c, 0, sizeof c);
        k = im_captions_create(&cfg, count_words, &c);
        run(k, &t, 1);
        double want = 0.3 / sqrt(2.0) * sqrt((2.0 - 0.1 * 0.625) / 2.0);   /* a fade keeps 3/8 of its energy */
        if (!pass) CHECK(fabs(c.rms - want) < 0.03 * want, "decimation: 1 kHz passes (rms %.4f, %.4f expected)", c.rms, want);
        else CHECK(c.rms < want * 1e-3, "decimation: 12 kHz is removed (rms %.2e, %.1f dB)", c.rms, 20 * log10(c.rms / want));
        free(t.x);
        im_captions_destroy(k);
    }

    /* a failure drops that line only */
    signal s7 = {0};
    s7.rate = 16000;
    quiet(&s7, 0.5);
    word(&s7, 0.6);
    quiet(&s7, 1.0);
    sentence(&s7, 3);
    quiet(&s7, 1.0);
    {
        im_captions_config cfg;
        im_captions_default_config(&cfg);
        cfg.in_rate = 16000;
        cfg.partial_every_s = 100.0f;   /* no partials: the first recognition is the first line's final */
        memset(&c, 0, sizeof c);
        k = im_captions_create(&cfg, count_words, &c);
    }
    c.fail_next = 1;
    int saw_fail = 0, finals = 0, words = 0;
    char line[1024];
    for (long i = 0; i < s7.n; i += 160) {
        int m = (int)(s7.n - i < 160 ? s7.n - i : 160);
        if (im_captions_push(k, s7.x + i, m) < 0) saw_fail = 1;
        while (im_captions_take_final(k, line, sizeof line) > 0) finals++, words += words_in(line);
    }
    CHECK(saw_fail && finals == 1 && words == 3, "a failed recognition drops only its line (%d line, %d words)", finals, words);
    im_captions_destroy(k);

    /* reset drops the open line and what waits */
    k = make(16000, &c);
    signal s8 = {0};
    s8.rate = 16000;
    sentence(&s8, 3);
    quiet(&s8, 1.0);
    sentence(&s8, 4);
    for (long i = 0; i < s8.n; i += 160) im_captions_push(k, s8.x + i, (int)(s8.n - i < 160 ? s8.n - i : 160));
    int open = im_captions_speaking(k);
    im_captions_reset(k);
    CHECK(open && !im_captions_speaking(k) && im_captions_partial(k)[0] == 0 && im_captions_take_final(k, line, sizeof line) == 0,
          "reset clears the open line and the waiting ones");
    im_captions_destroy(k);

    /* bad configurations */
    im_captions_config bad;
    im_captions_default_config(&bad);
    bad.in_rate = 44100;
    CHECK(!im_captions_create(&bad, count_words, &c), "44.1 kHz is refused (16 kHz or a multiple)");

    free(s.x), free(s2.x), free(s3.x), free(s4.x), free(s5.x), free(s6.x), free(s7.x), free(s8.x);
    printf(fails ? "%d FAILED\n" : "all passed\n", fails);
    return fails ? 1 : 0;
}
