/* Front-end + classifier parity hook: push a mono 48 kHz WAV through im_detector, then write the final
 * power window (bins x frames, float32) and print the last probabilities.
 * Usage: test-detector detector.onnx in.wav power_out.bin */
#include <stdio.h>
#include <stdlib.h>

#include "im_detector.h"
#include "wav.h"

int main(int argc, char **argv) {
    if (argc != 4) { fprintf(stderr, "usage: test-detector detector.onnx in.wav power_out.bin\n"); return 2; }
    char err[512];
    wav_t w;
    if (!wav_read(argv[2], &w, err, sizeof err)) { fprintf(stderr, "%s\n", err); return 1; }
    const OrtApi *api = OrtGetApiBase()->GetApi(ORT_API_VERSION);
    OrtEnv *env = NULL;
    if (api->CreateEnv(ORT_LOGGING_LEVEL_WARNING, "t", &env)) return 1;
    im_detector *d = im_detector_create(api, env, argv[1], w.rate, err, sizeof err);
    if (!d) { fprintf(stderr, "%s\n", err); return 1; }
    int runs = 0, fails = 0;
    for (long i = 0; i < w.frames; i += 333) { /* odd block size on purpose */
        int n = (int)(w.frames - i < 333 ? w.frames - i : 333);
        float buf[333];
        for (int k = 0; k < n; k++) buf[k] = w.data[(size_t)(i + k) * w.channels];
        int r = im_detector_push(d, buf, n);
        runs += r > 0;
        fails += r < 0;
    }
    size_t n = (size_t)769 * 100;
    float *pw = malloc(n * sizeof(float));
    if (!pw || !im_detector_power_window(d, pw, n)) return 1;
    FILE *f = fopen(argv[3], "wb");
    fwrite(pw, sizeof(float), n, f);
    fclose(f);
    const float *p = im_detector_probs(d);
    printf("runs=%d fails=%d probs=%.6f %.6f %.6f %.6f threshold=%.4f\n", runs, fails, p[0], p[1], p[2], p[3],
           im_detector_threshold(d));
    im_detector_destroy(d);
    api->ReleaseEnv(env);
    free(pw);
    wav_free(&w);
    return 0;
}
