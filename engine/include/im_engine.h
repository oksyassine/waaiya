/* islamic-mute streaming engine: runs a stateful ONNX voice model hop by hop.
 *
 * Model contract (im.contract = 1): inputs audio_in[hop], state_in[state_size];
 * outputs audio_out[hop], state_out[state_size]; metadata im.sample_rate,
 * im.hop, im.state_size, im.latency_samples. State starts from the optional
 * "<model>.state_init.bin" (raw float32) next to the model, else zeros.
 *
 * The engine is fail-closed: if the model cannot be loaded or a run fails,
 * it outputs silence instead of passing the original audio through.
 */
#ifndef IM_ENGINE_H
#define IM_ENGINE_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct im_engine im_engine;

typedef struct {
    const char *model_path; /* .onnx file following the contract */
    int channels;           /* 1..8 */
    int sample_rate;        /* must equal the model's im.sample_rate */
    int threads;            /* ONNX Runtime intra-op threads, 0 = 1 */
    int mono_mix;           /* 1 = mix channels, run once, copy to all (half the CPU for stereo) */
    const char *detector_path; /* optional women's-singing detector (.onnx, im.detector=1), NULL = none */
} im_config;

enum { IM_OK = 0, IM_ERR_ARGS = 1, IM_ERR_MODEL = 2, IM_ERR_CONTRACT = 3, IM_ERR_RATE = 4, IM_ERR_MEM = 5 };

/* Always returns an engine in *out (unless out is NULL). On error the engine
 * is in "failed" state and outputs silence; err receives a message. */
int im_engine_create(const im_config *cfg, im_engine **out, char *err, size_t errlen);
void im_engine_destroy(im_engine *e);

/* Planar processing, any block size, in-place allowed. */
void im_engine_process(im_engine *e, const float *const *in, float *const *out, int nframes);
/* Interleaved processing, any block size, in-place allowed. */
void im_engine_process_interleaved(im_engine *e, const float *in, float *out, int nframes);

/* Hop-aligned interleaved processing: in/out hold nhops * hop frames. Each hop is processed as soon as it
 * arrives and its output is returned in the same call, so the delay is only the model look-ahead
 * (im_engine_aligned_latency) instead of look-ahead + one hop. Use either this or the any-block-size
 * functions for a stream, not both; call im_engine_reset when switching. In-place allowed.
 * Returns 0, or -1 (nothing processed, out untouched) if the engine holds a partial hop from the other path. */
int im_engine_process_hops_interleaved(im_engine *e, const float *in, float *out, int nhops);

/* Total delay from input to output in samples: model look-ahead + hop buffering. */
int im_engine_latency(const im_engine *e);
/* Delay of im_engine_process_hops_interleaved in samples: model look-ahead only. */
int im_engine_aligned_latency(const im_engine *e);
int im_engine_hop(const im_engine *e);
int im_engine_model_rate(const im_engine *e);
int im_engine_failed(const im_engine *e);       /* 1 if the model never loaded */
unsigned long im_engine_run_errors(const im_engine *e);
const char *im_engine_model_name(const im_engine *e);

/* 1 = filter on (default). 0 = pass the input through with the same delay (A/B listening). */
void im_engine_set_enabled(im_engine *e, int enabled);
/* External gain gate in [0,1], smoothed over ~5 ms (used by the singing/gender filter). */
void im_engine_set_gate(im_engine *e, float gain);
/* Clears all model state and buffers (call on seek or stream restart). */
void im_engine_reset(im_engine *e);

/* Voice policy (needs im_config.detector_path). The detector watches the separated voice and the
 * output is muted while the policy matches, for at least the model's im.det_release_s afterwards.
 *   IM_POLICY_MUTE_FEMALE_SINGING  mute while P(female) * P(singing) >= threshold
 *   IM_POLICY_MUTE_FEMALE_VOICE    mute while P(female) >= threshold (any woman's voice)
 *   IM_POLICY_FAIL_CLOSED          if the detector is missing or fails, mute the voice instead of passing it */
enum { IM_POLICY_MUTE_FEMALE_SINGING = 1, IM_POLICY_MUTE_FEMALE_VOICE = 2, IM_POLICY_FAIL_CLOSED = 4 };
void im_engine_set_policy(im_engine *e, unsigned policy);
/* Latest detector probabilities (female, speech, singing, recitation) into probs (may be NULL).
 * Returns 1 if the policy is muting right now (including fail-closed muting without a detector),
 * 0 if not, -1 if no detector is loaded and nothing is muted. */
int im_engine_detector_status(const im_engine *e, float probs[4]);
/* Message from loading the detector ("" if fine or none requested). */
const char *im_engine_detector_error(const im_engine *e);

#ifdef __cplusplus
}
#endif
#endif
