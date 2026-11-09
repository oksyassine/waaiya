/* Women's-singing detector (internal to the engine).
 *
 * Streams the separated voice (mono, at the detector's sample rate) through a log-mel front end
 * computed in C: pre-emphasis, symmetric Hann window centred in an n_fft frame, power spectrum.
 * Every `eval_every` frames it runs the ONNX classifier on the last `frames` power frames
 * (input "power" [1, n_fft/2+1, frames]; output "probs" [1, 4] = female, speech, singing, recitation).
 * All front-end parameters come from the model's im.det_* metadata.
 */
#ifndef IM_DETECTOR_H
#define IM_DETECTOR_H

#include <stddef.h>

#include "onnxruntime_c_api.h"

typedef struct im_detector im_detector;

enum { IM_DET_FEMALE = 0, IM_DET_SPEECH = 1, IM_DET_SINGING = 2, IM_DET_RECITATION = 3, IM_DET_NOUT = 4 };

/* Returns NULL on failure (message in err). rate must equal the model's im.det_sample_rate. */
im_detector *im_detector_create(const OrtApi *api, OrtEnv *env, const char *path, int rate, char *err, size_t errlen);
void im_detector_destroy(im_detector *d);
void im_detector_reset(im_detector *d);

/* Feed n mono samples. Returns 1 if a new classification was made (probs updated), 0 if not,
 * -1 if the classifier failed to run. */
int im_detector_push(im_detector *d, const float *x, int n);

const float *im_detector_probs(const im_detector *d); /* [IM_DET_NOUT] latest probabilities */
float im_detector_threshold(const im_detector *d);    /* im.det_threshold */
float im_detector_release_s(const im_detector *d);    /* im.det_release_s */
int im_detector_hop(const im_detector *d);            /* samples per front-end frame */
int im_detector_eval_every(const im_detector *d);     /* frames between classifications */

/* Test hook: copies the current front-end power window [bins * frames] (bins-major) into dst. */
int im_detector_power_window(const im_detector *d, float *dst, size_t n);

#endif
