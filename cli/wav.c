#include "wav.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static uint32_t rd32(const unsigned char *p) { return p[0] | p[1] << 8 | p[2] << 16 | (uint32_t)p[3] << 24; }
static uint16_t rd16(const unsigned char *p) { return (uint16_t)(p[0] | p[1] << 8); }

int wav_read(const char *path, wav_t *w, char *err, int errlen) {
    memset(w, 0, sizeof *w);
    FILE *f = fopen(path, "rb");
    if (!f) { snprintf(err, errlen, "cannot open %s", path); return 0; }
    unsigned char h[12];
    if (fread(h, 1, 12, f) != 12 || memcmp(h, "RIFF", 4) || memcmp(h + 8, "WAVE", 4)) {
        snprintf(err, errlen, "not a RIFF/WAVE file"); fclose(f); return 0;
    }
    int fmt = 0, bits = 0, ch = 0, rate = 0, have_fmt = 0;
    for (;;) {
        unsigned char c[8];
        if (fread(c, 1, 8, f) != 8) { snprintf(err, errlen, "no data chunk"); fclose(f); return 0; }
        uint32_t sz = rd32(c + 4);
        if (!memcmp(c, "fmt ", 4)) {
            unsigned char b[40] = {0};
            uint32_t n = sz < 40 ? sz : 40;
            if (fread(b, 1, n, f) != n) break;
            if (sz > n) fseek(f, (long)(sz - n), SEEK_CUR);
            fmt = rd16(b); ch = rd16(b + 2); rate = (int)rd32(b + 4); bits = rd16(b + 14);
            if (fmt == 0xFFFE && sz >= 26) fmt = rd16(b + 24); /* WAVE_FORMAT_EXTENSIBLE subformat */
            have_fmt = 1;
        } else if (!memcmp(c, "data", 4)) {
            if (!have_fmt || ch <= 0) { snprintf(err, errlen, "data before fmt"); fclose(f); return 0; }
            int bps = bits / 8;
            if (!((fmt == 1 && (bits == 16 || bits == 24 || bits == 32)) || (fmt == 3 && (bits == 32 || bits == 64)))) {
                snprintf(err, errlen, "unsupported format %d/%d bit", fmt, bits); fclose(f); return 0;
            }
            long frames = (long)(sz / (uint32_t)(bps * ch));
            unsigned char *raw = malloc((size_t)frames * bps * ch);
            w->data = malloc(sizeof(float) * (size_t)frames * ch);
            if (!raw || !w->data) { free(raw); snprintf(err, errlen, "out of memory"); fclose(f); return 0; }
            frames = (long)(fread(raw, (size_t)bps * ch, (size_t)frames, f));
            for (long i = 0; i < frames * ch; i++) {
                const unsigned char *p = raw + (size_t)i * bps;
                float v;
                if (fmt == 3 && bits == 32) { float t; memcpy(&t, p, 4); v = t; }
                else if (fmt == 3) { double t; memcpy(&t, p, 8); v = (float)t; }
                else if (bits == 16) v = (int16_t)rd16(p) / 32768.0f;
                else if (bits == 24) { int32_t t = (int32_t)((uint32_t)p[0] << 8 | (uint32_t)p[1] << 16 | (uint32_t)p[2] << 24); v = t / 2147483648.0f; }
                else v = (int32_t)rd32(p) / 2147483648.0f;
                w->data[i] = v;
            }
            free(raw);
            w->channels = ch; w->rate = rate; w->frames = frames;
            fclose(f);
            return 1;
        } else {
            fseek(f, (long)(sz + (sz & 1)), SEEK_CUR);
        }
    }
    snprintf(err, errlen, "truncated file");
    fclose(f);
    return 0;
}

static void wr32(FILE *f, uint32_t v) { unsigned char b[4] = {v & 255, v >> 8 & 255, v >> 16 & 255, v >> 24 & 255}; fwrite(b, 1, 4, f); }
static void wr16(FILE *f, uint16_t v) { unsigned char b[2] = {v & 255, v >> 8 & 255}; fwrite(b, 1, 2, f); }

int wav_write_f32(const char *path, const wav_t *w) {
    FILE *f = fopen(path, "wb");
    if (!f) return 0;
    uint32_t data = (uint32_t)(w->frames * w->channels * 4);
    fwrite("RIFF", 1, 4, f); wr32(f, 36 + data); fwrite("WAVE", 1, 4, f);
    fwrite("fmt ", 1, 4, f); wr32(f, 16); wr16(f, 3); wr16(f, (uint16_t)w->channels);
    wr32(f, (uint32_t)w->rate); wr32(f, (uint32_t)(w->rate * w->channels * 4)); wr16(f, (uint16_t)(w->channels * 4)); wr16(f, 32);
    fwrite("data", 1, 4, f); wr32(f, data);
    fwrite(w->data, 4, (size_t)w->frames * w->channels, f);
    int ok = !ferror(f);
    fclose(f);
    return ok;
}

void wav_free(wav_t *w) { free(w->data); w->data = NULL; }
