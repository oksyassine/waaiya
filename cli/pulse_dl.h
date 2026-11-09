/* Minimal PulseAudio client ABI, loaded at run time with dlopen("libpulse.so.0").
 * Lets im-pulse build without libpulse-dev: every desktop with PulseAudio or pipewire-pulse ships
 * libpulse.so.0, whose ABI has been frozen since 0.9.x. The declarations below were checked against the
 * pulse 13.99 headers (struct sizes and offsets, enum values, prototypes).
 * Define IMPA_LIST_ONLY after including <pulse/pulseaudio.h> to get only the function list (for that check). */
#ifndef IM_PULSE_DL_H
#define IM_PULSE_DL_H

#ifndef IMPA_LIST_ONLY
#include <stddef.h>
#include <stdint.h>
#include <sys/time.h>

typedef struct pa_threaded_mainloop pa_threaded_mainloop;
typedef struct pa_mainloop_api pa_mainloop_api;
typedef struct pa_context pa_context;
typedef struct pa_stream pa_stream;
typedef struct pa_operation pa_operation;
typedef struct pa_channel_map pa_channel_map; /* only passed as NULL */
typedef struct pa_cvolume pa_cvolume;         /* only passed as NULL */
typedef struct pa_spawn_api pa_spawn_api;     /* only passed as NULL */
typedef uint64_t pa_usec_t;

typedef enum pa_sample_format { PA_SAMPLE_FLOAT32LE = 5 } pa_sample_format_t;
typedef struct pa_sample_spec { pa_sample_format_t format; uint32_t rate; uint8_t channels; } pa_sample_spec;
typedef struct pa_buffer_attr { uint32_t maxlength, tlength, prebuf, minreq, fragsize; } pa_buffer_attr;
typedef struct pa_timing_info {
    struct timeval timestamp;
    int synchronized_clocks;
    pa_usec_t sink_usec, source_usec, transport_usec;
    int playing;
    int write_index_corrupt;
    int64_t write_index;
    int read_index_corrupt;
    int64_t read_index;
    pa_usec_t configured_sink_usec, configured_source_usec;
    int64_t since_underrun;
} pa_timing_info;

typedef enum pa_context_state {
    PA_CONTEXT_UNCONNECTED, PA_CONTEXT_CONNECTING, PA_CONTEXT_AUTHORIZING, PA_CONTEXT_SETTING_NAME,
    PA_CONTEXT_READY, PA_CONTEXT_FAILED, PA_CONTEXT_TERMINATED
} pa_context_state_t;
typedef enum pa_stream_state {
    PA_STREAM_UNCONNECTED, PA_STREAM_CREATING, PA_STREAM_READY, PA_STREAM_FAILED, PA_STREAM_TERMINATED
} pa_stream_state_t;
typedef enum pa_context_flags { PA_CONTEXT_NOFLAGS = 0, PA_CONTEXT_NOAUTOSPAWN = 1 } pa_context_flags_t;
typedef enum pa_stream_flags {
    PA_STREAM_NOFLAGS = 0, PA_STREAM_INTERPOLATE_TIMING = 0x2, PA_STREAM_AUTO_TIMING_UPDATE = 0x8,
    PA_STREAM_DONT_MOVE = 0x200, PA_STREAM_ADJUST_LATENCY = 0x2000
} pa_stream_flags_t;
typedef enum pa_seek_mode { PA_SEEK_RELATIVE = 0 } pa_seek_mode_t;
enum { PA_ERR_NODATA = 16 };

typedef void (*pa_context_notify_cb_t)(pa_context *c, void *userdata);
typedef void (*pa_stream_notify_cb_t)(pa_stream *p, void *userdata);
typedef void (*pa_stream_request_cb_t)(pa_stream *p, size_t nbytes, void *userdata);
typedef void (*pa_free_cb_t)(void *p);
typedef void (*pa_stream_success_cb_t)(pa_stream *s, int success, void *userdata);
#endif /* IMPA_LIST_ONLY */

/* X(return type, name, parameter list) */
#define IMPA_FUNCS(X) \
    X(pa_threaded_mainloop *, pa_threaded_mainloop_new, (void)) \
    X(void, pa_threaded_mainloop_free, (pa_threaded_mainloop *)) \
    X(int, pa_threaded_mainloop_start, (pa_threaded_mainloop *)) \
    X(void, pa_threaded_mainloop_stop, (pa_threaded_mainloop *)) \
    X(void, pa_threaded_mainloop_lock, (pa_threaded_mainloop *)) \
    X(void, pa_threaded_mainloop_unlock, (pa_threaded_mainloop *)) \
    X(void, pa_threaded_mainloop_wait, (pa_threaded_mainloop *)) \
    X(void, pa_threaded_mainloop_signal, (pa_threaded_mainloop *, int)) \
    X(pa_mainloop_api *, pa_threaded_mainloop_get_api, (pa_threaded_mainloop *)) \
    X(pa_context *, pa_context_new, (pa_mainloop_api *, const char *)) \
    X(void, pa_context_set_state_callback, (pa_context *, pa_context_notify_cb_t, void *)) \
    X(int, pa_context_connect, (pa_context *, const char *, pa_context_flags_t, const pa_spawn_api *)) \
    X(pa_context_state_t, pa_context_get_state, (const pa_context *)) \
    X(int, pa_context_errno, (const pa_context *)) \
    X(void, pa_context_disconnect, (pa_context *)) \
    X(void, pa_context_unref, (pa_context *)) \
    X(const char *, pa_strerror, (int)) \
    X(pa_stream *, pa_stream_new, (pa_context *, const char *, const pa_sample_spec *, const pa_channel_map *)) \
    X(void, pa_stream_set_state_callback, (pa_stream *, pa_stream_notify_cb_t, void *)) \
    X(void, pa_stream_set_read_callback, (pa_stream *, pa_stream_request_cb_t, void *)) \
    X(void, pa_stream_set_underflow_callback, (pa_stream *, pa_stream_notify_cb_t, void *)) \
    X(void, pa_stream_set_overflow_callback, (pa_stream *, pa_stream_notify_cb_t, void *)) \
    X(int, pa_stream_connect_record, (pa_stream *, const char *, const pa_buffer_attr *, pa_stream_flags_t)) \
    X(int, pa_stream_connect_playback, (pa_stream *, const char *, const pa_buffer_attr *, pa_stream_flags_t, \
                                        const pa_cvolume *, pa_stream *)) \
    X(pa_stream_state_t, pa_stream_get_state, (const pa_stream *)) \
    X(const char *, pa_stream_get_device_name, (const pa_stream *)) \
    X(int, pa_stream_disconnect, (pa_stream *)) \
    X(void, pa_stream_unref, (pa_stream *)) \
    X(int, pa_stream_peek, (pa_stream *, const void **, size_t *)) \
    X(int, pa_stream_drop, (pa_stream *)) \
    X(int, pa_stream_write, (pa_stream *, const void *, size_t, pa_free_cb_t, int64_t, pa_seek_mode_t)) \
    X(int, pa_stream_get_latency, (pa_stream *, pa_usec_t *, int *)) \
    X(const pa_timing_info *, pa_stream_get_timing_info, (pa_stream *)) \
    X(const pa_buffer_attr *, pa_stream_get_buffer_attr, (pa_stream *)) \
    X(pa_operation *, pa_stream_update_timing_info, (pa_stream *, pa_stream_success_cb_t, void *)) \
    X(void, pa_operation_unref, (pa_operation *))

#endif
