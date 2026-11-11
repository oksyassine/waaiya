/* im-blur on Wayland: the overlay as wlr-layer-shell surfaces (KDE Plasma, sway, Hyprland, other wlroots desktops),
 * one per output, on the "overlay" layer above every window, with an empty input region so every click reaches
 * the window underneath. libwayland-client is loaded at run time (dlopen); the two protocols it does not carry
 * (zwlr_layer_shell_v1, zxdg_output_v1) are written out below from their XML, checked against wayland-scanner's
 * output (linux/blur/abi_check.c checks the core opcodes against wayland-client-protocol.h).
 *
 * GNOME (mutter) has no layer-shell: the main loop then falls back to an X11 override-redirect window through
 * XWayland (x11.c). */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <poll.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

#include "blur_host.h"

/* ---------------------------------------------------------------- libwayland-client ABI (stable since 1.0) */

#include "wl_dl.h"

#define WL_FUNCS(F)                                                                                                \
    F(struct wl_display *, wl_display_connect, (const char *))                                                     \
    F(void, wl_display_disconnect, (struct wl_display *))                                                          \
    F(int, wl_display_get_fd, (struct wl_display *))                                                               \
    F(int, wl_display_roundtrip, (struct wl_display *))                                                            \
    F(int, wl_display_dispatch_pending, (struct wl_display *))                                                     \
    F(int, wl_display_flush, (struct wl_display *))                                                                \
    F(int, wl_display_prepare_read, (struct wl_display *))                                                         \
    F(int, wl_display_read_events, (struct wl_display *))                                                          \
    F(void, wl_display_cancel_read, (struct wl_display *))                                                         \
    F(int, wl_display_get_error, (struct wl_display *))                                                            \
    F(struct wl_proxy *, wl_proxy_marshal_flags, (struct wl_proxy *, uint32_t, const struct ibw_interface *,       \
                                                  uint32_t, uint32_t, ...))                                        \
    F(int, wl_proxy_add_listener, (struct wl_proxy *, void (**)(void), void *))                                    \
    F(void, wl_proxy_destroy, (struct wl_proxy *))                                                                 \
    F(uint32_t, wl_proxy_get_version, (struct wl_proxy *))

#define WL_IFACES(F)                                                                                               \
    F(wl_registry_interface) F(wl_compositor_interface) F(wl_surface_interface) F(wl_region_interface)            \
    F(wl_shm_interface) F(wl_shm_pool_interface) F(wl_buffer_interface) F(wl_output_interface)

static struct {
#define WL_PTR(ret, name, args) ret(*name) args;
    WL_FUNCS(WL_PTR)
#undef WL_PTR
#define WL_IPTR(name) const struct ibw_interface *name;
    WL_IFACES(WL_IPTR)
#undef WL_IPTR
    void *lib;
} wl;

/* ---------------------------------------------------------------- the two extra protocols */

static const struct ibw_interface *ls_types[10];
static const struct ibw_message zwlr_layer_shell_v1_requests[] = {
    {"get_layer_surface", "no?ous", ls_types + 4},
    {"destroy", "3", ls_types + 0},
};
static const struct ibw_message zwlr_layer_surface_v1_requests[] = {
    {"set_size", "uu", ls_types + 0},
    {"set_anchor", "u", ls_types + 0},
    {"set_exclusive_zone", "i", ls_types + 0},
    {"set_margin", "iiii", ls_types + 0},
    {"set_keyboard_interactivity", "u", ls_types + 0},
    {"get_popup", "o", ls_types + 9},
    {"ack_configure", "u", ls_types + 0},
    {"destroy", "", ls_types + 0},
    {"set_layer", "2u", ls_types + 0},
};
static const struct ibw_message zwlr_layer_surface_v1_events[] = {
    {"configure", "uuu", ls_types + 0},
    {"closed", "", ls_types + 0},
};
static const struct ibw_interface zwlr_layer_surface_v1_interface = {
    "zwlr_layer_surface_v1", 4, 9, zwlr_layer_surface_v1_requests, 2, zwlr_layer_surface_v1_events};
static const struct ibw_interface zwlr_layer_shell_v1_interface = {
    "zwlr_layer_shell_v1", 4, 2, zwlr_layer_shell_v1_requests, 0, NULL};

static const struct ibw_interface *xo_types[4];
static const struct ibw_message zxdg_output_manager_v1_requests[] = {
    {"destroy", "", xo_types + 0},
    {"get_xdg_output", "no", xo_types + 2},
};
static const struct ibw_message zxdg_output_v1_requests[] = {{"destroy", "", xo_types + 0}};
static const struct ibw_message zxdg_output_v1_events[] = {
    {"logical_position", "ii", xo_types + 0},
    {"logical_size", "ii", xo_types + 0},
    {"done", "", xo_types + 0},
    {"name", "2s", xo_types + 0},
    {"description", "2s", xo_types + 0},
};
static const struct ibw_interface zxdg_output_v1_interface = {
    "zxdg_output_v1", 3, 1, zxdg_output_v1_requests, 5, zxdg_output_v1_events};
static const struct ibw_interface zxdg_output_manager_v1_interface = {
    "zxdg_output_manager_v1", 3, 2, zxdg_output_manager_v1_requests, 0, NULL};

enum {
    LS_GET_LAYER_SURFACE = 0, LS_LAYER_OVERLAY = 3,
    LSS_SET_ANCHOR = 1, LSS_SET_EXCLUSIVE_ZONE = 2, LSS_SET_KEYBOARD_INTERACTIVITY = 4, LSS_ACK_CONFIGURE = 6,
    LSS_DESTROY = 7, LSS_ANCHOR_ALL = 1 | 2 | 4 | 8,
    XOM_GET_XDG_OUTPUT = 1, XO_DESTROY = 0,
};

static int wl_load(char *err, size_t errlen) {
    if (wl.lib) return 1;
    void *h = dlopen("libwayland-client.so.0", RTLD_NOW | RTLD_LOCAL);
    if (!h) { snprintf(err, errlen, "cannot load libwayland-client.so.0"); return 0; }
#define WL_SYM(ret, name, args)                                                                                    \
    if (!(*(void **)&wl.name = dlsym(h, #name))) {                                                                 \
        snprintf(err, errlen, "libwayland-client: %s missing (too old?)", #name);                                  \
        dlclose(h);                                                                                                \
        return 0;                                                                                                  \
    }
    WL_FUNCS(WL_SYM)
#undef WL_SYM
#define WL_ISYM(name)                                                                                              \
    if (!(wl.name = dlsym(h, #name))) {                                                                            \
        snprintf(err, errlen, "libwayland-client: %s missing", #name);                                             \
        dlclose(h);                                                                                                \
        return 0;                                                                                                  \
    }
    WL_IFACES(WL_ISYM)
#undef WL_ISYM
    ls_types[4] = &zwlr_layer_surface_v1_interface;
    ls_types[5] = wl.wl_surface_interface;
    ls_types[6] = wl.wl_output_interface;
    xo_types[2] = &zxdg_output_v1_interface;
    xo_types[3] = wl.wl_output_interface;
    wl.lib = h;
    return 1;
}

#define P(x) ((struct wl_proxy *)(x))
#define REQ(proxy, op, ...)                                                                                        \
    wl.wl_proxy_marshal_flags(P(proxy), op, NULL, wl.wl_proxy_get_version(P(proxy)), 0, ##__VA_ARGS__)
#define NEW(proxy, op, iface, ...)                                                                                 \
    wl.wl_proxy_marshal_flags(P(proxy), op, iface, wl.wl_proxy_get_version(P(proxy)), 0, NULL, ##__VA_ARGS__)
#define DESTROY(proxy, op) wl.wl_proxy_marshal_flags(P(proxy), op, NULL, wl.wl_proxy_get_version(P(proxy)), IBWL_MARSHAL_FLAG_DESTROY)

/* ---------------------------------------------------------------- overlay */

#define MAX_OUT 8

typedef struct {
    struct wl_proxy *proxy, *xdg;
    uint32_t name;
    int lx, ly, lw, lh, have_logical; /* logical position / size (xdg-output) */
    int mm_w, mode_w, scale;
} output;

typedef struct {
    struct wl_proxy *buf;
    uint32_t *px;
    int busy;
} sbuf;

typedef struct layerov layerov;
typedef struct {
    layerov *o;
    int idx;
    ib_geom g;
    output *out;
    struct wl_proxy *surface, *layer;
    int w, h, configured, closed;
    int fd;
    size_t size;
    uint8_t *map;
    struct wl_proxy *pool;
    sbuf b[2];
    ib_paint *last;
    ib_cellset *cells;
    int nlast, pending;
} lsurf;

struct layerov {
    ib_overlay base;
    struct wl_display *d;
    struct wl_proxy *registry, *compositor, *shm, *shell, *xdg_manager;
    output out[MAX_OUT];
    int nout;
    lsurf s[IB_MAX_SCREENS];
    int n;
};

#define PAINT_MAX (IB_MAX_RECTS + 8)

static void out_geometry(void *data, struct wl_proxy *o, int32_t x, int32_t y, int32_t pw, int32_t ph, int32_t sub,
                         const char *make, const char *model, int32_t transform) {
    (void)o; (void)x; (void)y; (void)ph; (void)sub; (void)make; (void)model; (void)transform;
    ((output *)data)->mm_w = pw;
}
static void out_mode(void *data, struct wl_proxy *o, uint32_t flags, int32_t w, int32_t h, int32_t r) {
    (void)o; (void)h; (void)r;
    if (flags & 1) ((output *)data)->mode_w = w; /* current mode */
}
static void out_done(void *data, struct wl_proxy *o) { (void)data; (void)o; }
static void out_scale(void *data, struct wl_proxy *o, int32_t s) { (void)o; ((output *)data)->scale = s; }
static void out_str(void *data, struct wl_proxy *o, const char *s) { (void)data; (void)o; (void)s; }
static void (*const output_listener[])(void) = {
    (void (*)(void))out_geometry, (void (*)(void))out_mode, (void (*)(void))out_done,
    (void (*)(void))out_scale, (void (*)(void))out_str, (void (*)(void))out_str};

static void xo_pos(void *data, struct wl_proxy *x, int32_t px, int32_t py) {
    (void)x;
    output *o = data;
    o->lx = px; o->ly = py; o->have_logical = 1;
}
static void xo_size(void *data, struct wl_proxy *x, int32_t w, int32_t h) {
    (void)x;
    output *o = data;
    o->lw = w; o->lh = h;
}
static void xo_done(void *data, struct wl_proxy *x) { (void)data; (void)x; }
static void xo_str(void *data, struct wl_proxy *x, const char *s) { (void)data; (void)x; (void)s; }
static void (*const xdg_output_listener[])(void) = {
    (void (*)(void))xo_pos, (void (*)(void))xo_size, (void (*)(void))xo_done, (void (*)(void))xo_str,
    (void (*)(void))xo_str};

static void add_xdg(layerov *o, output *out) {
    if (!o->xdg_manager || out->xdg) return;
    out->xdg = NEW(o->xdg_manager, XOM_GET_XDG_OUTPUT, &zxdg_output_v1_interface, out->proxy);
    wl.wl_proxy_add_listener(out->xdg, (void (**)(void))xdg_output_listener, out);
}

static void reg_global(void *data, struct wl_proxy *reg, uint32_t name, const char *iface, uint32_t version) {
    layerov *o = data;
#define BIND(ifc, v) wl.wl_proxy_marshal_flags(reg, IBWL_REGISTRY_BIND, ifc, v, 0, name, (ifc)->name, v, NULL)
#define MIN(a, b) ((a) < (b) ? (a) : (b))
    if (!strcmp(iface, "wl_compositor")) o->compositor = BIND(wl.wl_compositor_interface, MIN(version, 4u));
    else if (!strcmp(iface, "wl_shm")) o->shm = BIND(wl.wl_shm_interface, 1u);
    else if (!strcmp(iface, "zwlr_layer_shell_v1")) o->shell = BIND(&zwlr_layer_shell_v1_interface, MIN(version, 4u));
    else if (!strcmp(iface, "zxdg_output_manager_v1")) {
        o->xdg_manager = BIND(&zxdg_output_manager_v1_interface, MIN(version, 3u));
        for (int i = 0; i < o->nout; i++) add_xdg(o, &o->out[i]);
    } else if (!strcmp(iface, "wl_output") && o->nout < MAX_OUT) {
        output *out = &o->out[o->nout++];
        memset(out, 0, sizeof *out);
        out->name = name;
        out->scale = 1;
        out->proxy = BIND(wl.wl_output_interface, MIN(version, 4u));
        wl.wl_proxy_add_listener(out->proxy, (void (**)(void))output_listener, out);
        add_xdg(o, out);
    }
#undef BIND
#undef MIN
}
static void reg_remove(void *data, struct wl_proxy *reg, uint32_t name) {
    (void)reg;
    layerov *o = data;
    for (int i = 0; i < o->nout; i++)
        if (o->out[i].name == name) o->out[i].proxy = NULL; /* its surfaces get "closed" */
}
static void (*const registry_listener[])(void) = {(void (*)(void))reg_global, (void (*)(void))reg_remove};

static void ls_configure(void *data, struct wl_proxy *ls, uint32_t serial, uint32_t w, uint32_t h) {
    lsurf *s = data;
    REQ(ls, LSS_ACK_CONFIGURE, serial);
    if ((int)w != s->w || (int)h != s->h) {
        s->w = (int)w;
        s->h = (int)h;
        s->configured = 0; /* buffers made again at this size */
    }
    s->pending = 1;
}
static void ls_closed(void *data, struct wl_proxy *ls) {
    (void)ls;
    ((lsurf *)data)->closed = 1;
}
static void (*const layer_listener[])(void) = {(void (*)(void))ls_configure, (void (*)(void))ls_closed};

static void buf_release(void *data, struct wl_proxy *b) {
    (void)b;
    ((sbuf *)data)->busy = 0;
}
static void (*const buffer_listener[])(void) = {(void (*)(void))buf_release};

static void free_buffers(lsurf *s) {
    for (int k = 0; k < 2; k++)
        if (s->b[k].buf) DESTROY(s->b[k].buf, IBWL_BUFFER_DESTROY);
    if (s->pool) DESTROY(s->pool, IBWL_SHM_POOL_DESTROY);
    if (s->map) munmap(s->map, s->size);
    if (s->fd >= 0) close(s->fd);
    memset(s->b, 0, sizeof s->b);
    s->pool = NULL; s->map = NULL; s->fd = -1; s->size = 0;
}

static int make_buffers(layerov *o, lsurf *s) {
    free_buffers(s);
    if (s->w <= 0 || s->h <= 0) return 0;
    size_t one = (size_t)s->w * s->h * 4;
    s->size = one * 2;
    s->fd = memfd_create("waaiya-blur", MFD_CLOEXEC);
    if (s->fd < 0 || ftruncate(s->fd, (off_t)s->size) != 0) return 0;
    s->map = mmap(NULL, s->size, PROT_READ | PROT_WRITE, MAP_SHARED, s->fd, 0);
    if (s->map == MAP_FAILED) { s->map = NULL; return 0; }
    s->pool = NEW(o->shm, IBWL_SHM_CREATE_POOL, wl.wl_shm_pool_interface, s->fd, (int32_t)s->size);
    for (int k = 0; k < 2; k++) {
        s->b[k].px = (uint32_t *)(void *)(s->map + one * k);
        s->b[k].buf = NEW(s->pool, IBWL_SHM_POOL_CREATE_BUFFER, wl.wl_buffer_interface, (int32_t)(one * k), s->w, s->h,
                          s->w * 4, (uint32_t)IBWL_SHM_FORMAT_ARGB8888);
        wl.wl_proxy_add_listener(s->b[k].buf, (void (**)(void))buffer_listener, &s->b[k]);
    }
    s->configured = 1;
    return 1;
}

static void destroy_surface(lsurf *s) {
    free_buffers(s);
    if (s->layer) DESTROY(s->layer, LSS_DESTROY);
    if (s->surface) DESTROY(s->surface, IBWL_SURFACE_DESTROY);
    s->layer = s->surface = NULL;
}

static int create_surface(layerov *o, lsurf *s) {
    s->surface = NEW(o->compositor, IBWL_COMPOSITOR_CREATE_SURFACE, wl.wl_surface_interface);
    /* clicks pass through everywhere: an empty input region */
    struct wl_proxy *region = NEW(o->compositor, IBWL_COMPOSITOR_CREATE_REGION, wl.wl_region_interface);
    REQ(s->surface, IBWL_SURFACE_SET_INPUT_REGION, region);
    DESTROY(region, IBWL_REGION_DESTROY);
    s->layer = NEW(o->shell, LS_GET_LAYER_SURFACE, &zwlr_layer_surface_v1_interface, s->surface,
                   s->out ? s->out->proxy : NULL, (uint32_t)LS_LAYER_OVERLAY, "waaiya-blur");
    wl.wl_proxy_add_listener(s->layer, (void (**)(void))layer_listener, s);
    REQ(s->layer, LSS_SET_ANCHOR, (uint32_t)LSS_ANCHOR_ALL);
    REQ(s->layer, LSS_SET_EXCLUSIVE_ZONE, (int32_t)-1);
    REQ(s->layer, LSS_SET_KEYBOARD_INTERACTIVITY, (uint32_t)0);
    REQ(s->surface, IBWL_SURFACE_COMMIT);
    s->closed = 0;
    s->configured = 0;
    s->w = s->h = 0;
    return 1;
}

/* The output showing this screen: same logical position (xdg-output), else by order. */
static output *match_output(layerov *o, const ib_geom *g, int i, int n) {
    for (int k = 0; k < o->nout; k++)
        if (o->out[k].proxy && o->out[k].have_logical && abs(o->out[k].lx - g->x) <= 2 && abs(o->out[k].ly - g->y) <= 2)
            return &o->out[k];
    if (n == o->nout && i < o->nout && o->out[i].proxy) return &o->out[i];
    return NULL; /* the compositor picks (one output) */
}

static void paint(layerov *o, lsurf *s) {
    (void)o;
    if (s->closed || !s->layer || s->w <= 0) return;
    if (!s->configured && !make_buffers(o, s)) return;
    sbuf *b = !s->b[0].busy ? &s->b[0] : (!s->b[1].busy ? &s->b[1] : NULL);
    if (!b) { s->pending = 1; return; } /* both with the compositor: drawn on release */
    memset(b->px, 0, (size_t)s->w * s->h * 4); /* transparent where nothing is covered */
    /* screens are in the portal's logical size; the surface may differ a little (rounding, scale) */
    ib_paint p[PAINT_MAX];
    int n = s->nlast;
    for (int k = 0; k < n; k++) {
        p[k] = s->last[k];
        if (s->g.w > 0 && s->g.h > 0 && (s->g.w != s->w || s->g.h != s->h)) {
            ib_rect r = p[k].r;
            int x0 = r.x * s->w / s->g.w, y0 = r.y * s->h / s->g.h;
            int x1 = (r.x + r.w) * s->w / s->g.w, y1 = (r.y + r.h) * s->h / s->g.h;
            p[k].r = (ib_rect){x0, y0, x1 - x0, y1 - y0};
        }
        if (p[k].r.x + p[k].r.w > s->w) p[k].r.w = s->w - p[k].r.x;
        if (p[k].r.y + p[k].r.h > s->h) p[k].r.h = s->h - p[k].r.y;
        if (p[k].r.w < 0) p[k].r.w = 0;
        if (p[k].r.h < 0) p[k].r.h = 0;
    }
    /* ARGB8888, opaque inside the covers */
    ib_render(b->px, s->w, p, n, s->cells, (ib_layout){16, 8, 0}, 0xff000000u);
    REQ(s->surface, IBWL_SURFACE_ATTACH, b->buf, (int32_t)0, (int32_t)0);
    REQ(s->surface, IBWL_SURFACE_DAMAGE, (int32_t)0, (int32_t)0, (int32_t)s->w, (int32_t)s->h);
    REQ(s->surface, IBWL_SURFACE_COMMIT);
    b->busy = 1;
    s->pending = 0;
    wl.wl_display_flush(o->d);
}

static int lo_sync(ib_overlay *b, const ib_geom *g, int n) {
    layerov *o = (layerov *)b;
    for (int i = 0; i < o->n; i++) {
        destroy_surface(&o->s[i]);
        free(o->s[i].last);
        free(o->s[i].cells);
    }
    memset(o->s, 0, sizeof o->s);
    o->n = 0;
    wl.wl_display_roundtrip(o->d); /* outputs and their logical positions are known */
    for (int i = 0; i < n && i < IB_MAX_SCREENS; i++) {
        lsurf *s = &o->s[i];
        s->o = o;
        s->idx = i;
        s->g = g[i];
        s->fd = -1;
        s->out = match_output(o, &g[i], i, n);
        s->last = calloc(PAINT_MAX, sizeof *s->last);
        s->cells = calloc(PAINT_MAX, sizeof *s->cells);
        if (!s->last || !s->cells) return 0;
        create_surface(o, s);
        o->n = i + 1;
    }
    if (wl.wl_display_roundtrip(o->d) < 0) {
        snprintf(b->err, sizeof b->err, "Wayland connection lost (error %d)", wl.wl_display_get_error(o->d));
        return 0;
    }
    for (int i = 0; i < o->n; i++)
        if (o->s[i].closed) {
            snprintf(b->err, sizeof b->err, "the compositor closed the overlay layer");
            return 0;
        }
    return 1;
}

static void lo_draw(ib_overlay *b, int i, const ib_paint *p, int n, const ib_cellset *cells) {
    layerov *o = (layerov *)b;
    if (i < 0 || i >= o->n) return;
    lsurf *s = &o->s[i];
    if (n > PAINT_MAX) n = PAINT_MAX;
    memcpy(s->last, p, sizeof *p * (size_t)n);
    for (int k = 0; k < n; k++)
        if (p[k].kind == IB_PK_COVER) {
            if (cells && p[k].index >= 0) s->cells[k] = cells[p[k].index];
            s->last[k].index = cells && p[k].index >= 0 ? k : -1;
        }
    s->nlast = n;
    paint(o, s);
}

static void lo_keep_on_top(ib_overlay *b) { (void)b; /* the overlay layer is above every window already */ }
static int lo_fd(ib_overlay *b) { return wl.wl_display_get_fd(((layerov *)b)->d); }

static void lo_dispatch(ib_overlay *b) {
    layerov *o = (layerov *)b;
    while (wl.wl_display_prepare_read(o->d) != 0) wl.wl_display_dispatch_pending(o->d);
    wl.wl_display_flush(o->d);
    struct pollfd pf = {wl.wl_display_get_fd(o->d), POLLIN, 0};
    if (poll(&pf, 1, 0) > 0) wl.wl_display_read_events(o->d);
    else wl.wl_display_cancel_read(o->d);
    wl.wl_display_dispatch_pending(o->d);
    for (int i = 0; i < o->n; i++) {
        lsurf *s = &o->s[i];
        if (s->closed) { /* output gone or the compositor dropped it: make it again */
            destroy_surface(s);
            create_surface(o, s);
            wl.wl_display_flush(o->d);
        } else if (s->pending && s->w > 0) {
            paint(o, s);
        }
    }
}

static void lo_destroy(ib_overlay *b) {
    layerov *o = (layerov *)b;
    for (int i = 0; i < o->n; i++) {
        destroy_surface(&o->s[i]);
        free(o->s[i].last);
        free(o->s[i].cells);
    }
    if (o->d) {
        wl.wl_display_flush(o->d);
        wl.wl_display_disconnect(o->d);
    }
    free(o);
}

ib_overlay *ib_layer_overlay_new(char *err, size_t errlen) {
    if (!wl_load(err, errlen)) return NULL;
    layerov *o = calloc(1, sizeof *o);
    if (!o) return NULL;
    o->d = wl.wl_display_connect(NULL);
    if (!o->d) {
        snprintf(err, errlen, "cannot connect to the Wayland display (%s)", strerror(errno));
        free(o);
        return NULL;
    }
    o->registry = wl.wl_proxy_marshal_flags(P(o->d), IBWL_DISPLAY_GET_REGISTRY, wl.wl_registry_interface, 1, 0, NULL);
    wl.wl_proxy_add_listener(o->registry, (void (**)(void))registry_listener, o);
    wl.wl_display_roundtrip(o->d);
    wl.wl_display_roundtrip(o->d);
    if (!o->shell || !o->compositor || !o->shm) {
        snprintf(err, errlen, "%s",
                 !o->shell ? "this compositor has no wlr-layer-shell (GNOME has none)" : "no wl_compositor / wl_shm");
        lo_destroy(&o->base);
        return NULL;
    }
    o->base.name = "layer-shell";
    o->base.sync = lo_sync;
    o->base.draw = lo_draw;
    o->base.keep_on_top = lo_keep_on_top;
    o->base.fd = lo_fd;
    o->base.dispatch = lo_dispatch;
    o->base.destroy = lo_destroy;
    return &o->base;
}
