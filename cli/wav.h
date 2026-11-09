#ifndef IM_WAV_H
#define IM_WAV_H
/* Minimal WAV I/O: reads PCM 16/24/32-bit and IEEE float32/64; writes float32. */
typedef struct { int channels, rate; long frames; float *data; /* interleaved */ } wav_t;
int wav_read(const char *path, wav_t *w, char *err, int errlen);
int wav_write_f32(const char *path, const wav_t *w);
void wav_free(wav_t *w);
#endif
