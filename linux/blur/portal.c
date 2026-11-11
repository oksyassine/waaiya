/* im-blur on Wayland: screen capture through xdg-desktop-portal's ScreenCast (GNOME, KDE Plasma, wlroots with
 * xdg-desktop-portal-wlr) and PipeWire. GIO (D-Bus) and libpipewire-0.3 are loaded at run time (dlopen); the few
 * structs and constants used are checked against the real headers by abi_check.c.
 *
 * The share dialog appears once: the session is persistent (ScreenCast v4+, persist_mode 2) and its restore token
 * is kept in --token-file, so later starts are silent. A refused dialog is reported as no_capture (never retried
 * by itself: the app restarts the helper when the user turns a blur option on again).
 *
 * Frames: whole monitors, cursor hidden when the portal allows it, shared-memory buffers only (no DMA-BUF: no GPU
 * import needed), at most 15 frames a second (the blur analyses fewer; a still screen sends none). Each frame is
 * shrunk to the analysed size (long side 640) on PipeWire's thread. */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

#include "blur_host.h"
#include "pw_dl.h"

/* ---------------------------------------------------------------- GLib / GIO (opaque, function calls only) */

typedef struct _GDBusConnection GDBusConnection;
typedef struct _GVariant GVariant;
typedef struct _GVariantBuilder GVariantBuilder;
typedef struct _GVariantType GVariantType;
typedef struct _GUnixFDList GUnixFDList;
typedef struct _GMainContext GMainContext;
typedef struct { uint32_t domain; int code; char *message; } GError;
typedef void (*GDBusSignalCallback)(GDBusConnection *, const char *, const char *, const char *, const char *,
                                    GVariant *, void *);

#define G_FUNCS(F)                                                                                                 \
    F(GDBusConnection *, g_bus_get_sync, (int, void *, GError **))                                                 \
    F(const char *, g_dbus_connection_get_unique_name, (GDBusConnection *))                                        \
    F(GVariant *, g_dbus_connection_call_sync, (GDBusConnection *, const char *, const char *, const char *,      \
                                                const char *, GVariant *, const GVariantType *, int, int, void *,  \
                                                GError **))                                                        \
    F(GVariant *, g_dbus_connection_call_with_unix_fd_list_sync,                                                   \
      (GDBusConnection *, const char *, const char *, const char *, const char *, GVariant *, const GVariantType *, \
       int, int, GUnixFDList *, GUnixFDList **, void *, GError **))                                                \
    F(unsigned, g_dbus_connection_signal_subscribe, (GDBusConnection *, const char *, const char *, const char *,  \
                                                     const char *, const char *, int, GDBusSignalCallback, void *, \
                                                     void (*)(void *)))                                            \
    F(void, g_dbus_connection_signal_unsubscribe, (GDBusConnection *, unsigned))                                   \
    F(int, g_unix_fd_list_get, (GUnixFDList *, int, GError **))                                                    \
    F(GMainContext *, g_main_context_new, (void))                                                                  \
    F(void, g_main_context_unref, (GMainContext *))                                                                \
    F(void, g_main_context_push_thread_default, (GMainContext *))                                                  \
    F(void, g_main_context_pop_thread_default, (GMainContext *))                                                   \
    F(int, g_main_context_iteration, (GMainContext *, int))                                                        \
    F(GVariant *, g_variant_new, (const char *, ...))                                                              \
    F(GVariantBuilder *, g_variant_builder_new, (const GVariantType *))                                            \
    F(void, g_variant_builder_add, (GVariantBuilder *, const char *, ...))                                         \
    F(void, g_variant_builder_unref, (GVariantBuilder *))                                                          \
    F(const GVariantType *, g_variant_type_checked_, (const char *))                                               \
    F(GVariant *, g_variant_new_string, (const char *))                                                            \
    F(GVariant *, g_variant_new_uint32, (uint32_t))                                                                \
    F(GVariant *, g_variant_new_boolean, (int))                                                                    \
    F(GVariant *, g_variant_lookup_value, (GVariant *, const char *, const GVariantType *))                        \
    F(void, g_variant_get, (GVariant *, const char *, ...))                                                        \
    F(GVariant *, g_variant_get_child_value, (GVariant *, size_t))                                                 \
    F(size_t, g_variant_n_children, (GVariant *))                                                                  \
    F(uint32_t, g_variant_get_uint32, (GVariant *))                                                                \
    F(const char *, g_variant_get_string, (GVariant *, size_t *))                                                  \
    F(void, g_variant_unref, (GVariant *))                                                                         \
    F(void, g_error_free, (GError *))                                                                              \
    F(void, g_object_unref, (void *))

static struct {
#define G_PTR(ret, name, args) ret(*name) args;
    G_FUNCS(G_PTR)
#undef G_PTR
    void *lib;
} G;

enum { G_BUS_TYPE_SESSION = 2 };
#define DEST "org.freedesktop.portal.Desktop"
#define OBJ "/org/freedesktop/portal/desktop"
#define SC "org.freedesktop.portal.ScreenCast"
#define T(s) G.g_variant_type_checked_(s)

static int g_load(char *err, size_t errlen) {
    if (G.lib) return 1;
    void *h = dlopen("libgio-2.0.so.0", RTLD_NOW | RTLD_LOCAL);
    if (!h) { snprintf(err, errlen, "cannot load libgio-2.0.so.0"); return 0; }
#define G_SYM(ret, name, args)                                                                                     \
    if (!(*(void **)&G.name = dlsym(h, #name))) {                                                                  \
        snprintf(err, errlen, "GIO: %s missing", #name);                                                           \
        dlclose(h);                                                                                                \
        return 0;                                                                                                  \
    }
    G_FUNCS(G_SYM)
#undef G_SYM
    G.lib = h;
    return 1;
}

/* ---------------------------------------------------------------- SPA pods (the bits PipeWire needs from us) */

typedef struct { uint8_t b[1024]; size_t n; } podb;

static void put32(podb *p, uint32_t v) {
    if (p->n + 4 <= sizeof p->b) { memcpy(p->b + p->n, &v, 4); p->n += 4; }
}
static size_t pod_begin(podb *p, uint32_t type) {
    size_t at = p->n;
    put32(p, 0);
    put32(p, type);
    return at;
}
static void pod_end(podb *p, size_t at) {
    uint32_t size = (uint32_t)(p->n - at - 8);
    memcpy(p->b + at, &size, 4);
    while (p->n % 8 && p->n < sizeof p->b) p->b[p->n++] = 0;
}
static void pod_id(podb *p, uint32_t v) { size_t a = pod_begin(p, IBP_TYPE_Id); put32(p, v); pod_end(p, a); }
static void prop(podb *p, uint32_t key) { put32(p, key); put32(p, 0); }

/* EnumFormat: raw video, 32-bit RGB formats only, any size, at most 15 frames a second. No modifier property, so
 * the compositor sends shared memory, not DMA-BUF. */
static const void *enum_format(podb *p) {
    p->n = 0;
    size_t o = pod_begin(p, IBP_TYPE_Object);
    put32(p, IBP_TYPE_OBJECT_Format);
    put32(p, IBP_PARAM_EnumFormat);
    prop(p, IBP_FORMAT_mediaType); pod_id(p, IBP_MEDIA_TYPE_video);
    prop(p, IBP_FORMAT_mediaSubtype); pod_id(p, IBP_MEDIA_SUBTYPE_raw);
    prop(p, IBP_FORMAT_VIDEO_format);
    size_t c = pod_begin(p, IBP_TYPE_Choice);
    put32(p, IBP_CHOICE_Enum); put32(p, 0); put32(p, 4); put32(p, IBP_TYPE_Id);
    put32(p, IBP_VIDEO_FORMAT_BGRx); /* default */
    put32(p, IBP_VIDEO_FORMAT_BGRx); put32(p, IBP_VIDEO_FORMAT_BGRA);
    put32(p, IBP_VIDEO_FORMAT_RGBx); put32(p, IBP_VIDEO_FORMAT_RGBA);
    pod_end(p, c);
    prop(p, IBP_FORMAT_VIDEO_size);
    c = pod_begin(p, IBP_TYPE_Choice);
    put32(p, IBP_CHOICE_Range); put32(p, 0); put32(p, 8); put32(p, IBP_TYPE_Rectangle);
    put32(p, 1920); put32(p, 1080); put32(p, 1); put32(p, 1); put32(p, 16384); put32(p, 16384);
    pod_end(p, c);
    prop(p, IBP_FORMAT_VIDEO_framerate);
    c = pod_begin(p, IBP_TYPE_Choice);
    put32(p, IBP_CHOICE_Range); put32(p, 0); put32(p, 8); put32(p, IBP_TYPE_Fraction);
    put32(p, 15); put32(p, 1); put32(p, 0); put32(p, 1); put32(p, 15); put32(p, 1);
    pod_end(p, c);
    pod_end(p, o);
    return p->b;
}

/* Buffers: mapped memory (MemPtr or MemFd), never DMA-BUF. */
static const void *buffers_param(podb *p) {
    p->n = 0;
    size_t o = pod_begin(p, IBP_TYPE_Object);
    put32(p, IBP_TYPE_OBJECT_ParamBuffers);
    put32(p, IBP_PARAM_Buffers);
    prop(p, IBP_PARAM_BUFFERS_dataType);
    size_t c = pod_begin(p, IBP_TYPE_Choice);
    put32(p, IBP_CHOICE_Flags); put32(p, 0); put32(p, 4); put32(p, IBP_TYPE_Int);
    put32(p, (1u << IBP_DATA_MemPtr) | (1u << IBP_DATA_MemFd));
    pod_end(p, c);
    pod_end(p, o);
    return p->b;
}

/* A negotiated Format: video format and size (values may be wrapped in a one-value Choice). */
static int parse_format(const struct ibp_spa_pod *pod, uint32_t *fmt, int *w, int *h) {
    if (!pod || pod->type != IBP_TYPE_Object || pod->size < 8) return 0;
    const uint8_t *b = (const uint8_t *)(pod + 1), *end = b + pod->size;
    const uint8_t *q = b + 8; /* object type, id */
    *fmt = 0; *w = *h = 0;
    while (q + 16 <= end) {
        uint32_t key, vsize, vtype;
        memcpy(&key, q, 4);
        memcpy(&vsize, q + 8, 4);
        memcpy(&vtype, q + 12, 4);
        const uint8_t *v = q + 16;
        if (v + vsize > end) break;
        uint32_t vs = vsize, vt = vtype;
        if (vt == IBP_TYPE_Choice && vs >= 16) { /* {choice type, flags, child size, child type, values...} */
            memcpy(&vs, v + 8, 4);
            memcpy(&vt, v + 12, 4);
            v += 16;
        }
        if (key == IBP_FORMAT_VIDEO_format && vt == IBP_TYPE_Id && vs >= 4) memcpy(fmt, v, 4);
        if (key == IBP_FORMAT_VIDEO_size && vt == IBP_TYPE_Rectangle && vs >= 8) {
            uint32_t r[2];
            memcpy(r, v, 8);
            *w = (int)r[0];
            *h = (int)r[1];
        }
        q += 16 + ((vsize + 7) & ~7u);
    }
    return *fmt && *w > 0 && *h > 0;
}

/* ---------------------------------------------------------------- capture */

typedef struct portalcap portalcap;
typedef struct {
    portalcap *c;
    uint32_t node;
    int px, py, pw, ph, have_pos, have_size; /* portal: logical position / size */
    struct ibp_pw_stream *stream;
    _Alignas(16) uint8_t hook[IBP_HOOK_SIZE];
    int w, h;
    ib_layout lay;
    int state; /* pw_stream_state */
    char err[160];
    /* analysed frame (under c->mu) */
    uint8_t *rgba, *front;
    int fw, fh, fresh;
} pstream;

struct portalcap {
    ib_capture base;
    char token_file[1024];
    pthread_t th;
    pthread_mutex_t mu;
    volatile int quit;
    int ready; /* 1 setting up, 0 streaming, -1 failed (base.err) */
    double ready_at;
    /* D-Bus (portal thread) */
    GDBusConnection *conn;
    GMainContext *ctx;
    char sender[128], session[256];
    int nreq;
    /* PipeWire */
    struct ibp_pw_thread_loop *loop;
    struct ibp_pw_context *context;
    struct ibp_pw_core *core;
    int pwfd;
    pstream s[IB_MAX_SCREENS];
    int n;
};

static double mono_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1e3 + ts.tv_nsec / 1e6;
}

static void fail(portalcap *c, const char *fmt, const char *detail) {
    pthread_mutex_lock(&c->mu);
    if (detail != c->base.err) snprintf(c->base.err, sizeof c->base.err, fmt, detail ? detail : "");
    c->ready = -1;
    pthread_mutex_unlock(&c->mu);
}

/* PipeWire thread */
static void on_state(void *data, int old, int state, const char *error) {
    (void)old;
    pstream *s = data;
    pthread_mutex_lock(&s->c->mu);
    s->state = state;
    if (state == IBP_STREAM_STATE_ERROR) snprintf(s->err, sizeof s->err, "%s", error ? error : "stream error");
    pthread_mutex_unlock(&s->c->mu);
}

static void on_param(void *data, uint32_t id, const struct ibp_spa_pod *param) {
    pstream *s = data;
    if (id != IBP_PARAM_Format || !param) return;
    uint32_t fmt;
    int w, h;
    if (!parse_format(param, &fmt, &w, &h)) return;
    ib_layout lay = fmt == IBP_VIDEO_FORMAT_RGBx || fmt == IBP_VIDEO_FORMAT_RGBA ? (ib_layout){0, 8, 16}
                                                                                 : (ib_layout){16, 8, 0};
    pthread_mutex_lock(&s->c->mu);
    s->w = w;
    s->h = h;
    s->lay = lay;
    int fw, fh;
    ib_scale_size(w, h, IB_LONG_SIDE, &fw, &fh);
    if (fw != s->fw || fh != s->fh || !s->rgba) {
        free(s->rgba);
        free(s->front);
        s->rgba = malloc((size_t)fw * fh * 4);
        s->front = malloc((size_t)fw * fh * 4);
        s->fw = fw;
        s->fh = fh;
        s->fresh = 0;
    }
    pthread_mutex_unlock(&s->c->mu);
    podb p;
    const struct ibp_spa_pod *params[1] = {buffers_param(&p)};
    P.pw_stream_update_params(s->stream, params, 1);
}

static void on_process(void *data) {
    pstream *s = data;
    struct ibp_pw_buffer *b, *last = NULL;
    while ((b = P.pw_stream_dequeue_buffer(s->stream))) {
        if (last) P.pw_stream_queue_buffer(s->stream, last);
        last = b;
    }
    if (!last) return;
    struct ibp_spa_buffer *sb = last->buffer;
    if (sb && sb->n_datas >= 1) {
        struct ibp_spa_data *d = &sb->datas[0];
        struct ibp_spa_chunk *ch = d->chunk;
        if (d->data && ch && ch->size > 0 && !(ch->flags & IBP_CHUNK_FLAG_CORRUPTED)) {
            pthread_mutex_lock(&s->c->mu);
            int stride = ch->stride > 0 ? ch->stride : s->w * 4;
            if (s->rgba && s->w > 0 && (uint64_t)ch->offset + (uint64_t)stride * s->h <= d->maxsize) {
                ib_downscale((const uint8_t *)d->data + ch->offset, s->w, s->h, stride, s->lay, s->rgba, s->fw, s->fh,
                             s->fw * 4);
                s->fresh = 1;
            }
            pthread_mutex_unlock(&s->c->mu);
        }
    }
    P.pw_stream_queue_buffer(s->stream, last);
}

static const struct ibp_pw_stream_events stream_events = {
    .version = 0, .state_changed = on_state, .param_changed = on_param, .process = on_process};

static int connect_pipewire(portalcap *c) {
    char err[256];
    if (!ibp_load(&P, err, sizeof err)) { fail(c, "%s", err); return 0; }
    P.pw_init(NULL, NULL);
    c->loop = P.pw_thread_loop_new("im-blur", NULL);
    if (!c->loop) { fail(c, "PipeWire: %s", "cannot create a loop"); return 0; }
    P.pw_thread_loop_lock(c->loop);
    c->context = P.pw_context_new(P.pw_thread_loop_get_loop(c->loop), NULL, 0);
    c->core = c->context ? P.pw_context_connect_fd(c->context, c->pwfd, NULL, 0) : NULL;
    c->pwfd = -1; /* owned by PipeWire now */
    if (!c->core) {
        P.pw_thread_loop_unlock(c->loop);
        fail(c, "PipeWire: %s", "cannot connect to the screen-cast remote");
        return 0;
    }
    for (int i = 0; i < c->n; i++) {
        pstream *s = &c->s[i];
        s->stream = P.pw_stream_new(c->core, "waaiya-blur",
                                    P.pw_properties_new("media.type", "Video", "media.category", "Capture",
                                                        "media.role", "Screen", NULL));
        if (!s->stream) continue;
        P.pw_stream_add_listener(s->stream, (void *)s->hook, &stream_events, s);
        podb p;
        const struct ibp_spa_pod *params[1] = {enum_format(&p)};
        P.pw_stream_connect(s->stream, IBP_DIRECTION_INPUT, s->node,
                            IBP_STREAM_FLAG_AUTOCONNECT | IBP_STREAM_FLAG_MAP_BUFFERS, params, 1);
    }
    P.pw_thread_loop_unlock(c->loop);
    if (P.pw_thread_loop_start(c->loop) != 0) { fail(c, "PipeWire: %s", "cannot start its thread"); return 0; }
    return 1;
}

/* ---------------------------------------------------------------- portal (its own thread) */

typedef struct { int done; uint32_t code; GVariant *results; } resp;

static void on_response(GDBusConnection *conn, const char *sender, const char *path, const char *iface,
                        const char *signal, GVariant *params, void *ud) {
    (void)conn; (void)sender; (void)path; (void)iface; (void)signal;
    resp *r = ud;
    G.g_variant_get(params, "(u@a{sv})", &r->code, &r->results);
    r->done = 1;
}

static GVariantBuilder *options(portalcap *c, char *token, size_t len) {
    snprintf(token, len, "waaiya%d_%d", (int)getpid(), ++c->nreq);
    GVariantBuilder *b = G.g_variant_builder_new(T("a{sv}"));
    G.g_variant_builder_add(b, "{sv}", "handle_token", G.g_variant_new_string(token));
    return b;
}

/* Calls a portal method that answers with a Request/Response; returns the results (or NULL, *code set). */
static GVariant *request(portalcap *c, const char *method, GVariant *params, const char *token, uint32_t *code) {
    char path[512];
    snprintf(path, sizeof path, OBJ "/request/%s/%s", c->sender, token);
    resp r = {0, 2, NULL};
    unsigned sub = G.g_dbus_connection_signal_subscribe(c->conn, DEST, "org.freedesktop.portal.Request", "Response",
                                                        path, NULL, 0, on_response, &r, NULL);
    GError *e = NULL;
    GVariant *ret = G.g_dbus_connection_call_sync(c->conn, DEST, OBJ, SC, method, params, NULL, 0, -1, NULL, &e);
    if (!ret) {
        G.g_dbus_connection_signal_unsubscribe(c->conn, sub);
        snprintf(c->base.err, sizeof c->base.err, "portal %s: %s", method, e ? e->message : "failed");
        if (e) G.g_error_free(e);
        *code = 3;
        return NULL;
    }
    G.g_variant_unref(ret);
    while (!r.done && !c->quit) {
        while (G.g_main_context_iteration(c->ctx, 0)) {}
        if (!r.done) usleep(20000);
    }
    G.g_dbus_connection_signal_unsubscribe(c->conn, sub);
    *code = r.done ? r.code : 1;
    if (r.done && r.code != 0 && r.results) { G.g_variant_unref(r.results); r.results = NULL; }
    return r.results;
}

static uint32_t sc_property(portalcap *c, const char *name) {
    GError *e = NULL;
    GVariant *ret = G.g_dbus_connection_call_sync(c->conn, DEST, OBJ, "org.freedesktop.DBus.Properties", "Get",
                                                  G.g_variant_new("(ss)", SC, name), NULL, 0, 5000, NULL, &e);
    if (!ret) {
        if (e) G.g_error_free(e);
        return 0;
    }
    GVariant *v = NULL;
    G.g_variant_get(ret, "(v)", &v);
    uint32_t u = v ? G.g_variant_get_uint32(v) : 0;
    if (v) G.g_variant_unref(v);
    G.g_variant_unref(ret);
    return u;
}

static void read_token(portalcap *c, char *tok, size_t len) {
    tok[0] = 0;
    if (!c->token_file[0]) return;
    FILE *f = fopen(c->token_file, "r");
    if (!f) return;
    if (fgets(tok, (int)len, f)) tok[strcspn(tok, "\r\n")] = 0;
    fclose(f);
}

static void write_token(portalcap *c, const char *tok) {
    if (!c->token_file[0]) return;
    if (!tok || !*tok) { unlink(c->token_file); return; }
    char tmp[1100];
    snprintf(tmp, sizeof tmp, "%s.tmp", c->token_file);
    int fd = open(tmp, O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0600);
    if (fd < 0) return;
    size_t n = strlen(tok);
    int ok = write(fd, tok, n) == (ssize_t)n && write(fd, "\n", 1) == 1;
    close(fd);
    if (ok) rename(tmp, c->token_file); else unlink(tmp);
}

/* One full CreateSession / SelectSources / Start round. Returns 1 ok, 0 failed (err set), 2 retry without the
 * token. */
static int share(portalcap *c, uint32_t version, uint32_t cursors, const char *restore) {
    char tok[64], stok[64];
    uint32_t code;
    GVariantBuilder *b = options(c, tok, sizeof tok);
    snprintf(stok, sizeof stok, "waaiya%d_s%d", (int)getpid(), c->nreq);
    G.g_variant_builder_add(b, "{sv}", "session_handle_token", G.g_variant_new_string(stok));
    GVariant *res = request(c, "CreateSession", G.g_variant_new("(a{sv})", b), tok, &code);
    G.g_variant_builder_unref(b);
    if (!res) {
        if (code != 3) snprintf(c->base.err, sizeof c->base.err, "the screen-cast portal refused a session");
        return 0;
    }
    GVariant *sh = G.g_variant_lookup_value(res, "session_handle", NULL);
    snprintf(c->session, sizeof c->session, "%s", sh ? G.g_variant_get_string(sh, NULL) : "");
    if (sh) G.g_variant_unref(sh);
    G.g_variant_unref(res);
    if (!c->session[0]) { snprintf(c->base.err, sizeof c->base.err, "the portal gave no session"); return 0; }

    b = options(c, tok, sizeof tok);
    G.g_variant_builder_add(b, "{sv}", "types", G.g_variant_new_uint32(1)); /* monitors */
    G.g_variant_builder_add(b, "{sv}", "multiple", G.g_variant_new_boolean(1));
    if (cursors & 1) G.g_variant_builder_add(b, "{sv}", "cursor_mode", G.g_variant_new_uint32(1)); /* hidden */
    if (version >= 4) {
        G.g_variant_builder_add(b, "{sv}", "persist_mode", G.g_variant_new_uint32(2)); /* until revoked */
        if (restore && *restore) G.g_variant_builder_add(b, "{sv}", "restore_token", G.g_variant_new_string(restore));
    }
    res = request(c, "SelectSources", G.g_variant_new("(oa{sv})", c->session, b), tok, &code);
    G.g_variant_builder_unref(b);
    if (!res) {
        if (code != 3) snprintf(c->base.err, sizeof c->base.err, "the screen-cast portal refused to pick screens");
        return 0;
    }
    G.g_variant_unref(res);

    pthread_mutex_lock(&c->mu);
    c->base.waiting_user = !(restore && *restore); /* the dialog shows now (with a token it normally does not) */
    pthread_mutex_unlock(&c->mu);
    b = options(c, tok, sizeof tok);
    res = request(c, "Start", G.g_variant_new("(osa{sv})", c->session, "", b), tok, &code);
    G.g_variant_builder_unref(b);
    pthread_mutex_lock(&c->mu);
    c->base.waiting_user = 0;
    pthread_mutex_unlock(&c->mu);
    if (!res) {
        if (code == 1) snprintf(c->base.err, sizeof c->base.err, "screen sharing was not allowed (dialog cancelled)");
        else if (code == 2 && restore && *restore) return 2;
        else if (code != 3) snprintf(c->base.err, sizeof c->base.err, "screen sharing failed to start");
        return 0;
    }
    GVariant *tokv = G.g_variant_lookup_value(res, "restore_token", NULL);
    write_token(c, tokv ? G.g_variant_get_string(tokv, NULL) : "");
    if (tokv) G.g_variant_unref(tokv);
    GVariant *streams = G.g_variant_lookup_value(res, "streams", NULL);
    size_t n = streams ? G.g_variant_n_children(streams) : 0;
    c->n = 0;
    for (size_t i = 0; i < n && c->n < IB_MAX_SCREENS; i++) {
        GVariant *st = G.g_variant_get_child_value(streams, i), *props = NULL;
        pstream *s = &c->s[c->n++];
        memset(s, 0, sizeof *s);
        s->c = c;
        s->state = IBP_STREAM_STATE_CONNECTING;
        G.g_variant_get(st, "(u@a{sv})", &s->node, &props);
        if (props) {
            GVariant *v = G.g_variant_lookup_value(props, "position", T("(ii)"));
            if (v) { G.g_variant_get(v, "(ii)", &s->px, &s->py); s->have_pos = 1; G.g_variant_unref(v); }
            v = G.g_variant_lookup_value(props, "size", T("(ii)"));
            if (v) { G.g_variant_get(v, "(ii)", &s->pw, &s->ph); s->have_size = 1; G.g_variant_unref(v); }
            G.g_variant_unref(props);
        }
        G.g_variant_unref(st);
    }
    if (streams) G.g_variant_unref(streams);
    G.g_variant_unref(res);
    if (!c->n) { snprintf(c->base.err, sizeof c->base.err, "no screen was shared"); return 0; }

    GUnixFDList *fds = NULL;
    GError *e = NULL;
    GVariantBuilder *ob = G.g_variant_builder_new(T("a{sv}"));
    GVariant *ret = G.g_dbus_connection_call_with_unix_fd_list_sync(c->conn, DEST, OBJ, SC, "OpenPipeWireRemote",
                                                                    G.g_variant_new("(oa{sv})", c->session, ob), NULL,
                                                                    0, -1, NULL, &fds, NULL, &e);
    G.g_variant_builder_unref(ob);
    if (!ret) {
        snprintf(c->base.err, sizeof c->base.err, "OpenPipeWireRemote: %s", e ? e->message : "failed");
        if (e) G.g_error_free(e);
        return 0;
    }
    int idx = 0;
    G.g_variant_get(ret, "(h)", &idx);
    G.g_variant_unref(ret);
    c->pwfd = fds ? G.g_unix_fd_list_get(fds, idx, NULL) : -1;
    if (fds) G.g_object_unref(fds);
    if (c->pwfd < 0) { snprintf(c->base.err, sizeof c->base.err, "the portal gave no PipeWire connection"); return 0; }
    return 1;
}

static void *portal_thread(void *arg) {
    portalcap *c = arg;
    c->ctx = G.g_main_context_new();
    G.g_main_context_push_thread_default(c->ctx);
    GError *e = NULL;
    c->conn = G.g_bus_get_sync(G_BUS_TYPE_SESSION, NULL, &e);
    if (!c->conn) {
        fail(c, "no D-Bus session bus: %s", e ? e->message : "");
        if (e) G.g_error_free(e);
        goto out;
    }
    const char *u = G.g_dbus_connection_get_unique_name(c->conn);
    size_t k = 0;
    for (const char *q = u && *u == ':' ? u + 1 : (u ? u : ""); *q && k + 1 < sizeof c->sender; q++)
        c->sender[k++] = *q == '.' ? '_' : *q;
    c->sender[k] = 0;
    uint32_t version = sc_property(c, "version");
    if (!version) {
        fail(c, "%s", "no screen-cast portal (install xdg-desktop-portal with its GNOME, KDE or wlr backend)");
        goto out;
    }
    uint32_t cursors = sc_property(c, "AvailableCursorModes");
    char restore[512];
    read_token(c, restore, sizeof restore);
    int r = share(c, version, cursors, restore);
    if (r == 2) { /* the saved permission is no longer valid: ask again */
        write_token(c, "");
        r = share(c, version, cursors, "");
    }
    if (r != 1) {
        if (!c->quit) fail(c, "%s", c->base.err[0] ? c->base.err : "screen sharing failed");
        goto out;
    }
    if (!connect_pipewire(c)) goto out;
    pthread_mutex_lock(&c->mu);
    c->ready_at = mono_ms();
    pthread_mutex_unlock(&c->mu);
    /* keep the D-Bus connection (and so the session) alive */
    while (!c->quit) {
        while (G.g_main_context_iteration(c->ctx, 0)) {}
        usleep(100000);
    }
out:
    G.g_main_context_pop_thread_default(c->ctx);
    return NULL;
}

/* ---------------------------------------------------------------- ib_capture */

static int pc_count(ib_capture *b) { return ((portalcap *)b)->n; }

static void pc_geometry(ib_capture *b, int i, ib_geom *g) {
    portalcap *c = (portalcap *)b;
    pstream *s = &c->s[i];
    pthread_mutex_lock(&c->mu);
    int w = s->have_size ? s->pw : s->w, h = s->have_size ? s->ph : s->h;
    *g = (ib_geom){s->have_pos ? s->px : 0, s->have_pos ? s->py : 0, w > 0 ? w : 1920, h > 0 ? h : 1080, 0.6f};
    pthread_mutex_unlock(&c->mu);
}

static int pc_grab(ib_capture *b, int i, const uint8_t **rgba, int *fw, int *fh) {
    portalcap *c = (portalcap *)b;
    if (i < 0 || i >= c->n) return -1;
    pstream *s = &c->s[i];
    pthread_mutex_lock(&c->mu);
    int r = 0;
    if (s->state == IBP_STREAM_STATE_ERROR || (s->state == IBP_STREAM_STATE_UNCONNECTED && c->ready_at > 0)) {
        snprintf(b->err, sizeof b->err, "screen sharing stopped (%s)", s->err[0] ? s->err : "the stream ended");
        r = -1;
    } else if (s->fresh && s->front) {
        memcpy(s->front, s->rgba, (size_t)s->fw * s->fh * 4);
        s->fresh = 0;
        *rgba = s->front;
        *fw = s->fw;
        *fh = s->fh;
        r = 1;
    }
    pthread_mutex_unlock(&c->mu);
    return r;
}

static int pc_fd(ib_capture *b) { (void)b; return -1; }
static int pc_dispatch(ib_capture *b) { (void)b; return 0; }

static int pc_ready(ib_capture *b) {
    portalcap *c = (portalcap *)b;
    pthread_mutex_lock(&c->mu);
    int r = c->ready;
    if (r == 1 && c->ready_at > 0) {
        /* streaming once every screen has its size (needed to place the overlay), or after 5 s anyway */
        int all = 1;
        for (int i = 0; i < c->n; i++) all &= c->s[i].w > 0;
        if (all || mono_ms() - c->ready_at > 5000) r = c->ready = 0;
    }
    pthread_mutex_unlock(&c->mu);
    return r;
}

static void pc_destroy(ib_capture *b) {
    portalcap *c = (portalcap *)b;
    c->quit = 1;
    pthread_join(c->th, NULL);
    if (c->loop) {
        P.pw_thread_loop_stop(c->loop);
        for (int i = 0; i < c->n; i++)
            if (c->s[i].stream) P.pw_stream_destroy(c->s[i].stream);
        if (c->core) P.pw_core_disconnect(c->core);
        if (c->context) P.pw_context_destroy(c->context);
        P.pw_thread_loop_destroy(c->loop);
    }
    if (c->conn && c->session[0]) {
        GVariant *r = G.g_dbus_connection_call_sync(c->conn, DEST, c->session, "org.freedesktop.portal.Session",
                                                    "Close", NULL, NULL, 0, 2000, NULL, NULL);
        if (r) G.g_variant_unref(r);
    }
    if (c->conn) G.g_object_unref(c->conn);
    if (c->ctx) G.g_main_context_unref(c->ctx);
    if (c->pwfd >= 0) close(c->pwfd);
    for (int i = 0; i < c->n; i++) {
        free(c->s[i].rgba);
        free(c->s[i].front);
    }
    pthread_mutex_destroy(&c->mu);
    free(c);
}

ib_capture *ib_portal_capture_new(const char *token_file, char *err, size_t errlen) {
    if (!g_load(err, errlen)) return NULL;
    if (!ibp_load(&P, err, errlen)) return NULL; /* checked now: no PipeWire, no capture */
    portalcap *c = calloc(1, sizeof *c);
    if (!c) return NULL;
    pthread_mutex_init(&c->mu, NULL);
    c->ready = 1;
    c->pwfd = -1;
    if (token_file) snprintf(c->token_file, sizeof c->token_file, "%s", token_file);
    c->base.name = "portal";
    c->base.count = pc_count;
    c->base.geometry = pc_geometry;
    c->base.grab = pc_grab;
    c->base.fd = pc_fd;
    c->base.dispatch = pc_dispatch;
    c->base.ready = pc_ready;
    c->base.destroy = pc_destroy;
    if (pthread_create(&c->th, NULL, portal_thread, c) != 0) {
        snprintf(err, errlen, "cannot start the portal thread");
        pthread_mutex_destroy(&c->mu);
        free(c);
        return NULL;
    }
    return &c->base;
}
