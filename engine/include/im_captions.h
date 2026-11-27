/* Live captions (docs/CAPTIONS.md): Arabic speech to text, on the device, for deaf and hard-of-hearing listeners.
 *
 * Two parts:
 *  - im_asr: one speech-to-text model that follows the ASR contract (asr.contract = 1, below), run on a whole piece
 *    of audio at once and decoded greedily (CTC).
 *  - im_captions: turns a live stream into caption lines. It finds where speech starts and stops (the stream is
 *    expected to be the voice that the engine kept, so a level gate is enough), shows the line being spoken as a
 *    "partial" that is recognised again as it grows, and makes it "final" after a pause, or at the quietest moment
 *    when a line runs too long.
 *
 * ASR contract (asr.contract = 1), models/asr/README.md:
 *   input  "audio"  float32 [1, samples]        mono waveform in [-1, 1] at asr.sample_rate
 *   output "logits" float32 [1, frames, tokens] scores per output frame (log-probabilities or logits: only the
 *                                               largest per frame is used)
 *   metadata asr.contract = 1, asr.sample_rate (16000), asr.blank (the CTC blank's index), asr.frame_ms,
 *            asr.model_name, asr.tokens: the tokens' text in index order, one per line. A token's U+2581 ("▁")
 *            starts a new word; tokens written <...> are not text and are left out.
 * All feature extraction (mel filterbank, normalisation) lives inside the graph, as for the voice models.
 */
#ifndef IM_CAPTIONS_H
#define IM_CAPTIONS_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ---- im_asr: one model ---- */

typedef struct im_asr im_asr;

/* threads: ONNX Runtime intra-op threads (0 = its default). Returns NULL on failure (message in err). */
im_asr *im_asr_create(const char *model_path, int threads, char *err, size_t errlen);
void im_asr_destroy(im_asr *a);
int im_asr_sample_rate(const im_asr *a);
const char *im_asr_model_name(const im_asr *a);

/* Recognises n samples (at im_asr_sample_rate). Writes the text as UTF-8, NUL-terminated, cut at a character
 * boundary when longer than cap - 1 bytes. Returns its length in bytes, or -1 if the model failed. */
int im_asr_transcribe(im_asr *a, const float *x, int n, char *out, size_t cap);

/* ---- im_captions: a live stream ---- */

/* A recogniser: n samples at 16 kHz in, UTF-8 text out (as im_asr_transcribe). */
typedef int (*im_recognize_fn)(void *user, const float *x, int n, char *out, size_t cap);

typedef struct {
    int in_rate;              /* rate of the pushed samples: 16000 or a multiple of it (48000) */
    float partial_every_s;    /* recognise the growing line again after this much new audio (at least) */
    float end_silence_s;      /* a pause this long ends the line */
    float max_line_s;         /* a line longer than this is cut at its quietest moment */
    float min_speech_s;       /* less speech than this in a line (a cough, a click) gives no text */
    float gate_db;            /* speech is louder than this (dBFS) ... */
    float gate_above_floor_db;/* ... and this much louder than the background level */
} im_captions_config;

/* The defaults: 48 kHz in, partial every 0.8 s, 0.7 s pause, 12 s line, 0.3 s speech, -50 dBFS, 9 dB. */
void im_captions_default_config(im_captions_config *c);

typedef struct im_captions im_captions;

/* With a recogniser of your own (tests, another model). Returns NULL for a bad configuration. */
im_captions *im_captions_create(const im_captions_config *c, im_recognize_fn fn, void *user);
/* With an im_asr model, owned by the captions (destroyed with them). NULL on failure (message in err). */
im_captions *im_captions_create_asr(const im_captions_config *c, const char *model_path, int threads, char *err,
                                    size_t errlen);
void im_captions_destroy(im_captions *k);

#define IM_CAPTIONS_PARTIAL 1 /* the partial line changed */
#define IM_CAPTIONS_FINAL 2   /* a final line is waiting (im_captions_take_final) */

/* Feeds n mono samples at in_rate. Recognition runs inside this call when it is due, so a call can take as long as
 * the model does (call it from the audio-reading thread, not the screen's). Returns IM_CAPTIONS_* flags, or -1 when
 * the recogniser failed (the captions keep going: that line is dropped, never shown wrong; lines finished before
 * the failure may still be waiting, so take them as usual). */
int im_captions_push(im_captions *k, const float *x, int n);

/* The end of the stream: the line being spoken becomes final. Returns as im_captions_push. */
int im_captions_flush(im_captions *k);

/* Drops the line being spoken and every waiting final line (the user cleared the screen or paused). */
void im_captions_reset(im_captions *k);

/* The line being spoken, as recognised so far; "" when none. Valid until the next call on k. */
const char *im_captions_partial(const im_captions *k);

/* Takes the oldest waiting final line into out (NUL-terminated, cut as im_asr_transcribe). Returns its length in
 * bytes, 0 when none is waiting. */
int im_captions_take_final(im_captions *k, char *out, size_t cap);

/* 1 while a line is open (speech heard and not yet ended by a pause). */
int im_captions_speaking(const im_captions *k);
/* Level of the last 20 ms in dBFS (for a level meter). */
float im_captions_level_db(const im_captions *k);
/* How long the last recognition took, in milliseconds, and its audio length in seconds (the screen can say the
 * phone is too slow when the first approaches the second). */
double im_captions_last_ms(const im_captions *k);
double im_captions_last_audio_s(const im_captions *k);

#ifdef __cplusplus
}
#endif

#endif
