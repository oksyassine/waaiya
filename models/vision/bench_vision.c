/* Times im_vision_detect_shapes on real frames, on the machine it runs on (a phone through adb, or this one).
 *
 *   bench_vision PERSON GENDER|- SEG|- NSFW|- FRAMES THREADS [TILES_PER_FRAME]
 *
 * FRAMES: raw file, int32 width, int32 height, then RGBA8888 frames of that size (bench_frames.py writes it).
 * Each frame is run twice (warm-up pass over all frames first); prints the median and p90 ms per frame and how many
 * people were found per frame. "-" leaves a model out (no gender model = every person covered, no classifying).
 * For a phone (arm64), with the libonnxruntime.so and headers unpacked from the app's onnxruntime-android AAR in ORT:
 *   $NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android29-clang -O2 -Iengine/include -Iengine/src \
 *     -I$ORT/headers models/vision/bench_vision.c engine/src/im_vision.c engine/src/im_cover.c \
 *     -L$ORT/jni/arm64-v8a -lonnxruntime -lm -o bench_vision
 *   adb push bench_vision $ORT/jni/arm64-v8a/libonnxruntime.so FRAMES MODELS... /data/local/tmp/wb/
 *   adb shell "cd /data/local/tmp/wb && LD_LIBRARY_PATH=. ./bench_vision ..."
 * Results: eval/results/blur_speed.md. */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "im_vision.h"

static double now_ms(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec * 1e3 + t.tv_nsec / 1e6;
}

static int cmp(const void *a, const void *b) {
    double x = *(const double *)a, y = *(const double *)b;
    return (x > y) - (x < y);
}

static const char *opt(const char *s) { return strcmp(s, "-") ? s : NULL; }

int main(int argc, char **argv) {
    if (argc < 7) {
        fprintf(stderr, "usage: %s PERSON GENDER|- SEG|- NSFW|- FRAMES THREADS [TILES_PER_FRAME]\n", argv[0]);
        return 2;
    }
    FILE *f = fopen(argv[5], "rb");
    int32_t wh[2];
    if (!f || fread(wh, 4, 2, f) != 2) { fprintf(stderr, "cannot read %s\n", argv[5]); return 1; }
    size_t fsz = (size_t)wh[0] * wh[1] * 4;
    uint8_t *frames = NULL;
    int n = 0;
    for (;;) {
        frames = realloc(frames, fsz * (n + 1));
        if (!frames || fread(frames + fsz * n, 1, fsz, f) != fsz) break;
        n++;
    }
    fclose(f);
    if (!n) { fprintf(stderr, "no frames\n"); return 1; }

    unsigned policy = IM_VISION_WOMEN | (opt(argv[4]) ? IM_VISION_NSFW : 0);
    im_vision_config cfg = {argv[1], opt(argv[2]), opt(argv[4]), atoi(argv[6]), policy, opt(argv[3])};
    char err[256] = "";
    im_vision *v = im_vision_create(&cfg, err, sizeof err);
    if (!v || im_vision_status(v)) { fprintf(stderr, "vision: %s %s\n", err, v ? im_vision_error(v) : ""); return 1; }
    if (argc > 7) {
        im_vision_params p;
        im_vision_get_params(v, &p);
        p.tiles_per_frame = atoi(argv[7]);
        im_vision_set_params(v, &p);
    }

    static im_vrect out[128];
    static im_vshape shapes[128];
    double *ms = malloc(sizeof(double) * n * 2);
    long people = 0;
    for (int i = 0; i < n; i++) /* warm-up */
        im_vision_detect_shapes(v, frames + fsz * i, wh[0], wh[1], wh[0] * 4, 0, out, shapes, 128);
    for (int k = 0; k < 2 * n; k++) {
        double t = now_ms();
        int m = im_vision_detect_shapes(v, frames + fsz * (k % n), wh[0], wh[1], wh[0] * 4, cfg.nsfw_model != NULL,
                                        out, shapes, 128);
        ms[k] = now_ms() - t;
        if (m < 0) { fprintf(stderr, "detect failed: %s\n", im_vision_error(v)); return 1; }
        people += m;
    }
    qsort(ms, 2 * n, sizeof *ms, cmp);
    printf("%d frames %dx%d, threads %s: median %.1f ms, p90 %.1f ms, %.1f people/frame\n", n, wh[0], wh[1], argv[6],
           ms[n], ms[(int)(2 * n * 0.9)], people / (2.0 * n));
    im_vision_destroy(v);
    free(ms);
    free(frames);
    return 0;
}
