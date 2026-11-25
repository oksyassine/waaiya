/* im-music-scan: the "Check for music" tags of a WAV file (docs/MUSIC_CHECK.md), for the evaluation on the server.
 *
 *   im-music-scan models/music/tagger_mn04.onnx in.wav out_prefix
 *
 * Writes out_prefix.tags (float32, windows x 527) and out_prefix.lvl (float32 dBFS per window): window k covers
 * [0.5 k, 0.5 k + 1) s, as in the app (engine/src/im_music.c is the same code). Only windows that start inside the
 * file are written.
 */
#include <stdio.h>
#include <stdlib.h>

#include "im_music.h"
#include "wav.h"

int main(int argc, char **argv) {
    if (argc != 4) { fprintf(stderr, "usage: %s tagger.onnx in.wav out_prefix\n", argv[0]); return 2; }
    char err[512] = {0};
    wav_t w;
    if (!wav_read(argv[2], &w, err, sizeof err)) { fprintf(stderr, "read: %s\n", err); return 1; }
    float *mono = malloc(sizeof(float) * (size_t)(w.frames > 0 ? w.frames : 1));
    for (long i = 0; i < w.frames; i++) {
        float s = 0.0f;
        for (int c = 0; c < w.channels; c++) s += w.data[i * w.channels + c];
        mono[i] = s / (float)w.channels;
    }
    im_music *m = im_music_create(argv[1], w.rate, err, sizeof err);
    if (!m) { fprintf(stderr, "%s\n", err); return 1; }
    int classes = im_music_classes(m);
    long windows = (long)((double)w.frames / w.rate / 0.5) + 1;   /* windows starting inside the file */
    if ((double)(windows - 1) * 0.5 * w.rate >= (double)w.frames) windows--;
    char path[1024];
    snprintf(path, sizeof path, "%s.tags", argv[3]);
    FILE *ft = fopen(path, "wb");
    snprintf(path, sizeof path, "%s.lvl", argv[3]);
    FILE *fl = fopen(path, "wb");
    if (!ft || !fl) { perror("open"); return 1; }
    float *p = malloc(sizeof(float) * (size_t)classes * 64), lv[64];
    long written = 0;
    for (long i = 0;; i += 4096) {
        int n = i < w.frames ? (int)(w.frames - i < 4096 ? w.frames - i : 4096) : 0;
        int r = n > 0 ? im_music_push(m, mono + i, n) : im_music_finish(m);
        if (r < 0) { fprintf(stderr, "tagger failed\n"); return 1; }
        int k;
        while ((k = im_music_take(m, p, lv, 64)) > 0)
            for (int j = 0; j < k && written < windows; j++, written++) {
                fwrite(p + (size_t)j * (size_t)classes, sizeof(float), (size_t)classes, ft);
                fwrite(lv + j, sizeof(float), 1, fl);
            }
        if (n <= 0) break;
    }
    fclose(ft); fclose(fl);
    printf("%ld windows\n", written);
    im_music_destroy(m);
    return 0;
}
