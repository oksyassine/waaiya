/* "Check for music" (docs/MUSIC_CHECK.md): AudioSet tags of a whole recording, for 1 s windows every 0.5 s.
 *
 * Feed the recording's samples (mono, any sample rate); they are resampled to the tagger's rate (32 kHz) with a
 * windowed-sinc filter and pass through the same C front end as the singing detector (im_detector). Window k (from 0)
 * covers [0.5 k, 0.5 k + 1) s of the recording; for each one the tagger gives the 527 AudioSet probabilities
 * (class_labels_indices.csv) and the window's level in dBFS. The decision (music, percussion only, none) is made by
 * the caller (MusicCheck.kt) from these numbers.
 */
#ifndef IM_MUSIC_H
#define IM_MUSIC_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct im_music im_music;

/* tagger_path: an ONNX model with im.music=1 metadata (models/music/export_tagger.py). in_rate: the samples' rate.
 * Returns NULL on failure (message in err). */
im_music *im_music_create(const char *tagger_path, int in_rate, char *err, size_t errlen);
void im_music_destroy(im_music *m);

int im_music_classes(const im_music *m); /* 527 */

/* Feeds n mono samples. Returns the number of windows waiting to be taken, or -1 if the tagger failed. */
int im_music_push(im_music *m, const float *x, int n);

/* The end of the recording: pads with silence so its last second is tagged too. Returns as im_music_push. */
int im_music_finish(im_music *m);

/* Takes up to max waiting windows, oldest first: probs gets classes floats per window, level_db one float per window
 * (may be NULL). Returns how many were taken. */
int im_music_take(im_music *m, float *probs, float *level_db, int max);

#ifdef __cplusplus
}
#endif

#endif
