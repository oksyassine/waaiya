/* Minimal libpipewire-0.3 client ABI, loaded at run time with dlopen("libpipewire-0.3.so.0"), like cli/pulse_dl.h:
 * im-blur builds without libpipewire-0.3-dev and starts on systems without PipeWire (X11). Only what a video
 * capture stream needs. Struct layouts and constants are checked against the real headers by abi_check.c. */
#ifndef IM_PW_DL_H
#define IM_PW_DL_H

#include <stddef.h>
#include <stdint.h>

struct ibp_pw_thread_loop;
struct ibp_pw_loop;
struct ibp_pw_context;
struct ibp_pw_core;
struct ibp_pw_stream;
struct ibp_pw_properties;

struct ibp_spa_pod { uint32_t size, type; };
struct ibp_spa_chunk { uint32_t offset, size; int32_t stride, flags; };
struct ibp_spa_data {
    uint32_t type, flags;
    int64_t fd;
    uint32_t mapoffset, maxsize;
    void *data;
    struct ibp_spa_chunk *chunk;
};
struct ibp_spa_buffer {
    uint32_t n_metas, n_datas;
    void *metas;
    struct ibp_spa_data *datas;
};
/* only the first field is used (struct pw_buffer grew over 0.3.x) */
struct ibp_pw_buffer { struct ibp_spa_buffer *buffer; };

/* struct pw_stream_events, version 0 (the later fields are optional and left out) */
struct ibp_pw_stream_events {
    uint32_t version;
    void (*destroy)(void *data);
    void (*state_changed)(void *data, int old, int state, const char *error);
    void (*control_info)(void *data, uint32_t id, const void *control);
    void (*io_changed)(void *data, uint32_t id, void *area, uint32_t size);
    void (*param_changed)(void *data, uint32_t id, const struct ibp_spa_pod *param);
    void (*add_buffer)(void *data, struct ibp_pw_buffer *buffer);
    void (*remove_buffer)(void *data, struct ibp_pw_buffer *buffer);
    void (*process)(void *data);
    void (*drained)(void *data);
};

#define IBP_HOOK_SIZE 64 /* struct spa_hook is 48 bytes on 64-bit (abi_check.c) */

enum {
    IBP_TYPE_Id = 3, IBP_TYPE_Int = 4, IBP_TYPE_Rectangle = 10, IBP_TYPE_Fraction = 11, IBP_TYPE_Object = 15,
    IBP_TYPE_Choice = 19,
    IBP_TYPE_OBJECT_Format = 0x40003, IBP_TYPE_OBJECT_ParamBuffers = 0x40004,
    IBP_PARAM_EnumFormat = 3, IBP_PARAM_Format = 4, IBP_PARAM_Buffers = 5,
    IBP_FORMAT_mediaType = 1, IBP_FORMAT_mediaSubtype = 2,
    IBP_FORMAT_VIDEO_format = 0x20001, IBP_FORMAT_VIDEO_size = 0x20003, IBP_FORMAT_VIDEO_framerate = 0x20004,
    IBP_MEDIA_TYPE_video = 2, IBP_MEDIA_SUBTYPE_raw = 1,
    IBP_VIDEO_FORMAT_RGBx = 7, IBP_VIDEO_FORMAT_BGRx = 8, IBP_VIDEO_FORMAT_RGBA = 11, IBP_VIDEO_FORMAT_BGRA = 12,
    IBP_CHOICE_Range = 1, IBP_CHOICE_Enum = 3, IBP_CHOICE_Flags = 4,
    IBP_PARAM_BUFFERS_dataType = 6, IBP_DATA_MemPtr = 1, IBP_DATA_MemFd = 2,
    IBP_CHUNK_FLAG_CORRUPTED = 1,
    IBP_DIRECTION_INPUT = 0,
    IBP_STREAM_FLAG_AUTOCONNECT = 1, IBP_STREAM_FLAG_MAP_BUFFERS = 4,
    IBP_STREAM_STATE_ERROR = -1, IBP_STREAM_STATE_UNCONNECTED = 0, IBP_STREAM_STATE_CONNECTING = 1,
    IBP_STREAM_STATE_STREAMING = 3,
};

#define IBP_FUNCS(F)                                                                                               \
    F(void, pw_init, (int *, char ***))                                                                            \
    F(struct ibp_pw_thread_loop *, pw_thread_loop_new, (const char *, const void *))                               \
    F(struct ibp_pw_loop *, pw_thread_loop_get_loop, (struct ibp_pw_thread_loop *))                                \
    F(int, pw_thread_loop_start, (struct ibp_pw_thread_loop *))                                                    \
    F(void, pw_thread_loop_stop, (struct ibp_pw_thread_loop *))                                                    \
    F(void, pw_thread_loop_lock, (struct ibp_pw_thread_loop *))                                                    \
    F(void, pw_thread_loop_unlock, (struct ibp_pw_thread_loop *))                                                  \
    F(void, pw_thread_loop_destroy, (struct ibp_pw_thread_loop *))                                                 \
    F(struct ibp_pw_context *, pw_context_new, (struct ibp_pw_loop *, struct ibp_pw_properties *, size_t))        \
    F(void, pw_context_destroy, (struct ibp_pw_context *))                                                         \
    F(struct ibp_pw_core *, pw_context_connect_fd, (struct ibp_pw_context *, int, struct ibp_pw_properties *,     \
                                                    size_t))                                                       \
    F(int, pw_core_disconnect, (struct ibp_pw_core *))                                                             \
    F(struct ibp_pw_properties *, pw_properties_new, (const char *, ...))                                          \
    F(struct ibp_pw_stream *, pw_stream_new, (struct ibp_pw_core *, const char *, struct ibp_pw_properties *))     \
    F(void, pw_stream_add_listener, (struct ibp_pw_stream *, void *, const struct ibp_pw_stream_events *,         \
                                     void *))                                                                      \
    F(int, pw_stream_connect, (struct ibp_pw_stream *, int, uint32_t, int, const struct ibp_spa_pod **, uint32_t)) \
    F(int, pw_stream_update_params, (struct ibp_pw_stream *, const struct ibp_spa_pod **, uint32_t))              \
    F(struct ibp_pw_buffer *, pw_stream_dequeue_buffer, (struct ibp_pw_stream *))                                  \
    F(int, pw_stream_queue_buffer, (struct ibp_pw_stream *, struct ibp_pw_buffer *))                               \
    F(void, pw_stream_destroy, (struct ibp_pw_stream *))

typedef struct {
#define IBP_PTR(ret, name, args) ret(*name) args;
    IBP_FUNCS(IBP_PTR)
#undef IBP_PTR
    void *lib;
} ibp_api;

#ifndef IBP_NO_LOADER
#include <dlfcn.h>
#include <stdio.h>

static ibp_api P;

static int ibp_load(ibp_api *p, char *err, size_t errlen) {
    if (p->lib) return 1;
    void *h = dlopen("libpipewire-0.3.so.0", RTLD_NOW | RTLD_LOCAL);
    if (!h) { snprintf(err, errlen, "cannot load libpipewire-0.3.so.0 (PipeWire is needed for Wayland capture)"); return 0; }
#define IBP_SYM(ret, name, args)                                                                                   \
    if (!(*(void **)&p->name = dlsym(h, #name))) {                                                                 \
        snprintf(err, errlen, "libpipewire: %s missing", #name);                                                   \
        dlclose(h);                                                                                                \
        return 0;                                                                                                  \
    }
    IBP_FUNCS(IBP_SYM)
#undef IBP_SYM
    p->lib = h;
    return 1;
}
#endif

#endif
