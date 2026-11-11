/* im-blur on X11: capture (MIT-SHM grabs of the root window, one per monitor, only after XDamage reports a change)
 * and the overlay (one override-redirect window per monitor; bounding shape = the covers, so it works with or
 * without a compositor; empty input shape, so every click reaches the window underneath).
 *
 * The overlay is part of the root window's picture, so the capture sees our covers: the main loop's self-test
 * finds that out and the tracker keeps covers until the scene changes. An X client cannot read what lies under
 * another window without a compositor's help (no backing store), so there is no reliable way to leave them out.
 *
 * Under GNOME Wayland the overlay alone is used through XWayland (override-redirect windows sit in mutter's top
 * layer); the capture then comes from the ScreenCast portal (portal.c). */
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <time.h>

#include "blur_host.h"
#include "x11_dl.h"

static int g_xerr; /* last X error code (requests are synchronised where it matters) */
static int on_xerror(ibx_Display *d, ibx_XErrorEvent *e) {
    (void)d;
    g_xerr = e->error_code;
    return 0;
}

static double now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1e3 + ts.tv_nsec / 1e6;
}

/* A shared-memory XImage (or a plain one when MIT-SHM is not available, e.g. a remote display). */
typedef struct {
    ibx_XImage *img;
    ibx_XShmSegmentInfo shm;
    int use_shm;
} ximg;

static void ximg_free(ibx_api *x, ibx_Display *d, ximg *im) {
    if (!im->img) return;
    if (im->use_shm) {
        x->XShmDetach(d, &im->shm);
        x->XSync(d, 0);
        shmdt(im->shm.shmaddr);
        im->img->data = NULL;
    }
    im->img->f.destroy_image(im->img);
    memset(im, 0, sizeof *im);
}

static int ximg_new(ibx_api *x, ibx_Display *d, ibx_Visual *vis, int depth, int w, int h, int try_shm, ximg *im) {
    memset(im, 0, sizeof *im);
    if (try_shm) {
        im->img = x->XShmCreateImage(d, vis, (unsigned)depth, IBX_ZPixmap, NULL, &im->shm, (unsigned)w, (unsigned)h);
        if (im->img && im->img->bits_per_pixel == 32) {
            im->shm.shmid = shmget(IPC_PRIVATE, (size_t)im->img->bytes_per_line * h, IPC_CREAT | 0600);
            if (im->shm.shmid >= 0) {
                im->shm.shmaddr = im->img->data = shmat(im->shm.shmid, NULL, 0);
                im->shm.readOnly = 0;
                g_xerr = 0;
                int ok = im->shm.shmaddr != (void *)-1 && x->XShmAttach(d, &im->shm);
                x->XSync(d, 0);
                shmctl(im->shm.shmid, IPC_RMID, NULL); /* freed once both sides detach */
                if (ok && !g_xerr) { im->use_shm = 1; return 1; }
                if (im->shm.shmaddr != (void *)-1) shmdt(im->shm.shmaddr);
            }
            im->img->data = NULL;
        }
        if (im->img) im->img->f.destroy_image(im->img);
        im->img = NULL;
    }
    /* no MIT-SHM: a client-side image for XPutImage (the capture uses XGetImage instead) */
    char *data = malloc((size_t)w * h * 4);
    if (!data) return 0;
    im->img = x->XCreateImage(d, vis, (unsigned)depth, IBX_ZPixmap, 0, data, (unsigned)w, (unsigned)h, 32, 0);
    if (!im->img || im->img->bits_per_pixel != 32) {
        if (im->img) im->img->f.destroy_image(im->img); else free(data);
        im->img = NULL;
        return 0;
    }
    return 1;
}

/* Monitors (RandR 1.5), else the whole root window. px_per_dp from the monitor's size in mm (96 dpi when
 * unknown). */
static int monitors(ibx_api *x, ibx_Display *d, int scr, ibx_Window root, ib_geom *g, int max) {
    int n = 0;
    if (x->have_randr) {
        int ev, er, nm = 0;
        if (x->XRRQueryExtension(d, &ev, &er)) {
            ibx_XRRMonitorInfo *m = x->XRRGetMonitors(d, root, 1, &nm);
            for (int i = 0; m && i < nm && n < max; i++) {
                if (m[i].width < 16 || m[i].height < 16) continue;
                float dpi = m[i].mwidth > 0 ? m[i].width * 25.4f / m[i].mwidth : 96.0f;
                if (dpi < 50 || dpi > 600) dpi = 96.0f;
                g[n++] = (ib_geom){m[i].x, m[i].y, m[i].width, m[i].height, dpi / 160.0f};
            }
            if (m) x->XRRFreeMonitors(m);
        }
    }
    if (n == 0) {
        int w = x->XDisplayWidth(d, scr), h = x->XDisplayHeight(d, scr), mm = x->XDisplayWidthMM(d, scr);
        float dpi = mm > 0 ? w * 25.4f / mm : 96.0f;
        if (dpi < 50 || dpi > 600) dpi = 96.0f;
        g[n++] = (ib_geom){0, 0, w, h, dpi / 160.0f};
    }
    return n;
}

static int geom_same(const ib_geom *a, int na, const ib_geom *b, int nb) {
    if (na != nb) return 0;
    for (int i = 0; i < na; i++)
        if (a[i].x != b[i].x || a[i].y != b[i].y || a[i].w != b[i].w || a[i].h != b[i].h) return 0;
    return 1;
}

/* ------------------------------------------------------------------------------------------------ capture */

typedef struct {
    ib_geom g;
    ximg im;
    uint8_t *rgba;
    int fw, fh;
    int dirty;
    double last;
} xscreen;

typedef struct {
    ib_capture base;
    ibx_api x;
    ibx_Display *d;
    int scr, depth, shm, damage_ev;
    ibx_Window root;
    ibx_Visual *vis;
    ibx_XID damage;
    ib_layout lay;
    int n;
    xscreen s[IB_MAX_SCREENS];
    double layout_at;
} x11cap;

static void cap_free_screens(x11cap *c) {
    for (int i = 0; i < c->n; i++) {
        ximg_free(&c->x, c->d, &c->s[i].im);
        free(c->s[i].rgba);
    }
    memset(c->s, 0, sizeof c->s);
    c->n = 0;
}

static int cap_setup_screens(x11cap *c) {
    ib_geom g[IB_MAX_SCREENS];
    int n = monitors(&c->x, c->d, c->scr, c->root, g, IB_MAX_SCREENS);
    cap_free_screens(c);
    for (int i = 0; i < n; i++) {
        xscreen *s = &c->s[i];
        s->g = g[i];
        if (!ximg_new(&c->x, c->d, c->vis, c->depth, g[i].w, g[i].h, c->shm, &s->im)) {
            snprintf(c->base.err, sizeof c->base.err, "cannot create a %dx%d capture image", g[i].w, g[i].h);
            c->n = i;
            return 0;
        }
        if (!ib_layout_from_masks(s->im.img->red_mask, s->im.img->green_mask, s->im.img->blue_mask, &c->lay)) {
            snprintf(c->base.err, sizeof c->base.err, "unsupported X visual (masks %lx %lx %lx)",
                     s->im.img->red_mask, s->im.img->green_mask, s->im.img->blue_mask);
            c->n = i + 1;
            return 0;
        }
        ib_scale_size(g[i].w, g[i].h, IB_LONG_SIDE, &s->fw, &s->fh);
        s->rgba = malloc((size_t)s->fw * s->fh * 4);
        s->dirty = 1;
        c->n = i + 1;
        if (!s->rgba) return 0;
    }
    c->layout_at = now_ms();
    return 1;
}

static int cap_count(ib_capture *b) { return ((x11cap *)b)->n; }
static void cap_geometry(ib_capture *b, int i, ib_geom *g) { *g = ((x11cap *)b)->s[i].g; }
static int cap_fd(ib_capture *b) { return ((x11cap *)b)->x.XConnectionNumber(((x11cap *)b)->d); }
static int cap_ready(ib_capture *b) { (void)b; return 0; }

static int cap_dispatch(ib_capture *b) {
    x11cap *c = (x11cap *)b;
    while (c->x.XPending(c->d)) {
        ibx_XEvent ev;
        c->x.XNextEvent(c->d, &ev);
        if (c->damage && ev.type == c->damage_ev + IBX_XDamageNotify) {
            c->x.XDamageSubtract(c->d, c->damage, 0, 0);
            for (int i = 0; i < c->n; i++) c->s[i].dirty = 1;
        }
    }
    /* monitors plugged / resolution changed: checked every 2 s (one round trip) */
    if (now_ms() - c->layout_at > 2000) {
        ib_geom g[IB_MAX_SCREENS], cur[IB_MAX_SCREENS];
        int n = monitors(&c->x, c->d, c->scr, c->root, g, IB_MAX_SCREENS);
        for (int i = 0; i < c->n; i++) cur[i] = c->s[i].g;
        c->layout_at = now_ms();
        if (!geom_same(g, n, cur, c->n)) {
            cap_setup_screens(c);
            return 1;
        }
    }
    return 0;
}

static int cap_grab(ib_capture *b, int i, const uint8_t **rgba, int *fw, int *fh) {
    x11cap *c = (x11cap *)b;
    if (i < 0 || i >= c->n || !c->s[i].rgba) return -1;
    xscreen *s = &c->s[i];
    double t = now_ms();
    /* without XDamage, or as a safety net (some GL compositors do not report changes on the root window), grab at
     * least every 250 ms; an unchanged frame costs the grab, the shrink and a compare, not the models */
    if (c->damage && !s->dirty && t - s->last < 250) return 0;
    s->dirty = 0;
    s->last = t;
    g_xerr = 0;
    const uint8_t *src;
    int stride;
    ibx_XImage *tmp = NULL;
    if (s->im.use_shm) {
        if (!c->x.XShmGetImage(c->d, c->root, s->im.img, s->g.x, s->g.y, IBX_AllPlanes) || g_xerr) {
            snprintf(c->base.err, sizeof c->base.err, "XShmGetImage failed (X error %d)", g_xerr);
            return -1;
        }
        src = (const uint8_t *)s->im.img->data;
        stride = s->im.img->bytes_per_line;
    } else {
        tmp = c->x.XGetImage(c->d, c->root, s->g.x, s->g.y, (unsigned)s->g.w, (unsigned)s->g.h, IBX_AllPlanes,
                             IBX_ZPixmap);
        if (!tmp || tmp->bits_per_pixel != 32) {
            if (tmp) tmp->f.destroy_image(tmp);
            snprintf(c->base.err, sizeof c->base.err, "XGetImage failed (X error %d)", g_xerr);
            return -1;
        }
        src = (const uint8_t *)tmp->data;
        stride = tmp->bytes_per_line;
    }
    ib_downscale(src, s->g.w, s->g.h, stride, c->lay, s->rgba, s->fw, s->fh, s->fw * 4);
    if (tmp) tmp->f.destroy_image(tmp);
    *rgba = s->rgba;
    *fw = s->fw;
    *fh = s->fh;
    return 1;
}

static void cap_destroy(ib_capture *b) {
    x11cap *c = (x11cap *)b;
    cap_free_screens(c);
    if (c->d) c->x.XCloseDisplay(c->d);
    free(c);
}

static ibx_Display *open_display(ibx_api *x, const char *display, char *err, size_t errlen) {
    if (!ibx_load(x, err, errlen)) return NULL;
    x->XSetErrorHandler(on_xerror);
    ibx_Display *d = x->XOpenDisplay(display);
    if (!d) snprintf(err, errlen, "cannot open X display %s", display ? display : "(DISPLAY)");
    return d;
}

ib_capture *ib_x11_capture_new(const char *display, char *err, size_t errlen) {
    x11cap *c = calloc(1, sizeof *c);
    if (!c) return NULL;
    c->d = open_display(&c->x, display, err, errlen);
    if (!c->d) { free(c); return NULL; }
    c->base.name = "x11";
    c->scr = c->x.XDefaultScreen(c->d);
    c->root = c->x.XRootWindow(c->d, c->scr);
    c->vis = c->x.XDefaultVisual(c->d, c->scr);
    c->depth = c->x.XDefaultDepth(c->d, c->scr);
    c->shm = c->x.XShmQueryExtension(c->d);
    int eb, er;
    if (c->x.have_damage && c->x.XDamageQueryExtension(c->d, &eb, &er)) {
        c->damage_ev = eb;
        c->damage = c->x.XDamageCreate(c->d, c->root, IBX_XDamageReportNonEmpty);
    }
    if (!cap_setup_screens(c)) {
        snprintf(err, errlen, "%s", c->base.err);
        cap_destroy(&c->base);
        return NULL;
    }
    c->base.count = cap_count;
    c->base.geometry = cap_geometry;
    c->base.grab = cap_grab;
    c->base.fd = cap_fd;
    c->base.dispatch = cap_dispatch;
    c->base.ready = cap_ready;
    c->base.destroy = cap_destroy;
    return &c->base;
}

/* ------------------------------------------------------------------------------------------------ overlay */

typedef struct {
    ib_geom g;
    ibx_Window w;
    ibx_GC gc;
    ximg im;
    ibx_XRectangle *shape;
    int nshape;
    ib_paint *last;
    ib_cellset *cells;
    int nlast, has_content;
} xsurf;

typedef struct {
    ib_overlay base;
    ibx_api x;
    ibx_Display *d;
    int scr, depth, shm;
    ibx_Window root;
    ibx_Visual *vis;
    ib_layout lay;
    int n;
    xsurf s[IB_MAX_SCREENS];
} x11ov;

#define OV_MAX (IB_MAX_RECTS + 8)

static void ov_free_surfaces(x11ov *o) {
    for (int i = 0; i < o->n; i++) {
        xsurf *s = &o->s[i];
        ximg_free(&o->x, o->d, &s->im);
        if (s->gc) o->x.XFreeGC(o->d, s->gc);
        if (s->w) o->x.XDestroyWindow(o->d, s->w);
        free(s->shape);
        free(s->last);
        free(s->cells);
    }
    memset(o->s, 0, sizeof o->s);
    o->n = 0;
    o->x.XSync(o->d, 0);
}

static int ov_sync(ib_overlay *b, const ib_geom *g, int n) {
    x11ov *o = (x11ov *)b;
    ib_geom cur[IB_MAX_SCREENS];
    for (int i = 0; i < o->n; i++) cur[i] = o->s[i].g;
    if (geom_same(g, n, cur, o->n)) return 1;
    ov_free_surfaces(o);
    for (int i = 0; i < n && i < IB_MAX_SCREENS; i++) {
        xsurf *s = &o->s[i];
        o->n = i + 1;
        s->g = g[i];
        ibx_XSetWindowAttributes a;
        memset(&a, 0, sizeof a);
        a.override_redirect = 1;
        a.background_pixmap = 0; /* None: no clearing (no flicker) */
        a.border_pixel = 0;
        a.event_mask = IBX_ExposureMask;
        g_xerr = 0;
        s->w = o->x.XCreateWindow(o->d, o->root, g[i].x, g[i].y, (unsigned)g[i].w, (unsigned)g[i].h, 0, o->depth,
                                  IBX_InputOutput, o->vis,
                                  IBX_CWOverrideRedirect | IBX_CWBackPixmap | IBX_CWBorderPixel | IBX_CWEventMask, &a);
        o->x.XStoreName(o->d, s->w, "waaiya-blur");
        /* compositors: no shadow (picom/compton), keep it composited */
        unsigned long zero = 0, two = 2;
        o->x.XChangeProperty(o->d, s->w, o->x.XInternAtom(o->d, "_COMPTON_SHADOW", 0), IBX_XA_CARDINAL, 32,
                             IBX_PropModeReplace, (const unsigned char *)&zero, 1);
        o->x.XChangeProperty(o->d, s->w, o->x.XInternAtom(o->d, "_NET_WM_BYPASS_COMPOSITOR", 0), IBX_XA_CARDINAL, 32,
                             IBX_PropModeReplace, (const unsigned char *)&two, 1);
        ibx_Atom type = o->x.XInternAtom(o->d, "_NET_WM_WINDOW_TYPE_NOTIFICATION", 0);
        o->x.XChangeProperty(o->d, s->w, o->x.XInternAtom(o->d, "_NET_WM_WINDOW_TYPE", 0), IBX_XA_ATOM, 32,
                             IBX_PropModeReplace, (const unsigned char *)&type, 1);
        /* clicks pass through everywhere; nothing shown until there is something to cover */
        o->x.XShapeCombineRectangles(o->d, s->w, IBX_ShapeInput, 0, 0, NULL, 0, IBX_ShapeSet, IBX_Unsorted);
        o->x.XShapeCombineRectangles(o->d, s->w, IBX_ShapeBounding, 0, 0, NULL, 0, IBX_ShapeSet, IBX_Unsorted);
        s->gc = o->x.XCreateGC(o->d, s->w, 0, NULL);
        s->shape = calloc(OV_MAX, sizeof *s->shape);
        s->last = calloc(OV_MAX, sizeof *s->last);
        s->cells = calloc(OV_MAX, sizeof *s->cells);
        o->x.XMapRaised(o->d, s->w);
        o->x.XSync(o->d, 0);
        if (g_xerr || !s->shape || !s->last || !s->cells ||
            !ximg_new(&o->x, o->d, o->vis, o->depth, g[i].w, g[i].h, o->shm, &s->im) ||
            !ib_layout_from_masks(s->im.img->red_mask, s->im.img->green_mask, s->im.img->blue_mask, &o->lay)) {
            snprintf(b->err, sizeof b->err, "cannot create the overlay window (X error %d)", g_xerr);
            return 0;
        }
    }
    return 1;
}

static void ov_paint(x11ov *o, xsurf *s) {
    uint32_t *buf = (uint32_t *)(void *)s->im.img->data;
    int stride = s->im.img->bytes_per_line / 4;
    ib_render(buf, stride, s->last, s->nlast, s->cells, o->lay, 0);
    for (int k = 0; k < s->nlast; k++) {
        ib_rect r = s->last[k].r;
        if (s->im.use_shm)
            o->x.XShmPutImage(o->d, s->w, s->gc, s->im.img, r.x, r.y, r.x, r.y, (unsigned)r.w, (unsigned)r.h, 0);
        else
            o->x.XPutImage(o->d, s->w, s->gc, s->im.img, r.x, r.y, r.x, r.y, (unsigned)r.w, (unsigned)r.h);
    }
}

static void ov_draw(ib_overlay *b, int i, const ib_paint *p, int n, const ib_cellset *cells) {
    x11ov *o = (x11ov *)b;
    if (i < 0 || i >= o->n || !o->s[i].im.img) return;
    xsurf *s = &o->s[i];
    if (n > OV_MAX) n = OV_MAX;
    /* window shape = the paints; changed only when they move */
    ibx_XRectangle xr[OV_MAX];
    int m = 0;
    for (int k = 0; k < n; k++)
        xr[m++] = (ibx_XRectangle){(short)p[k].r.x, (short)p[k].r.y, (unsigned short)p[k].r.w,
                                   (unsigned short)p[k].r.h};
    if (m != s->nshape || memcmp(xr, s->shape, sizeof *xr * (size_t)m)) {
        o->x.XShapeCombineRectangles(o->d, s->w, IBX_ShapeBounding, 0, 0, xr, m, IBX_ShapeSet, IBX_Unsorted);
        memcpy(s->shape, xr, sizeof *xr * (size_t)m);
        s->nshape = m;
    }
    memcpy(s->last, p, sizeof *p * (size_t)n);
    s->nlast = n;
    for (int k = 0; k < n; k++)
        if (p[k].kind == IB_PK_COVER) {
            if (cells && p[k].index >= 0) s->cells[k] = cells[p[k].index];
            s->last[k].index = cells && p[k].index >= 0 ? k : -1; /* no cells: drawn opaque */
        }
    s->has_content = n > 0;
    ov_paint(o, s);
    if (n) o->x.XRaiseWindow(o->d, s->w);
    o->x.XSync(o->d, 0); /* the server has read the shared image before it is drawn into again */
}

static void ov_keep_on_top(ib_overlay *b) {
    x11ov *o = (x11ov *)b;
    for (int i = 0; i < o->n; i++)
        if (o->s[i].has_content) o->x.XRaiseWindow(o->d, o->s[i].w);
    o->x.XFlush(o->d);
}

static int ov_fd(ib_overlay *b) { return ((x11ov *)b)->x.XConnectionNumber(((x11ov *)b)->d); }

static void ov_dispatch(ib_overlay *b) {
    x11ov *o = (x11ov *)b;
    int expose[IB_MAX_SCREENS] = {0};
    while (o->x.XPending(o->d)) {
        ibx_XEvent ev;
        o->x.XNextEvent(o->d, &ev);
        if (ev.type == IBX_Expose)
            for (int i = 0; i < o->n; i++)
                if (o->s[i].w == ev.xexpose.window) expose[i] = 1;
    }
    for (int i = 0; i < o->n; i++)
        if (expose[i] && o->s[i].nlast) {
            ov_paint(o, &o->s[i]);
            o->x.XSync(o->d, 0);
        }
}

static void ov_destroy(ib_overlay *b) {
    x11ov *o = (x11ov *)b;
    if (o->d) {
        ov_free_surfaces(o);
        o->x.XCloseDisplay(o->d);
    }
    free(o);
}

ib_overlay *ib_x11_overlay_new(const char *display, char *err, size_t errlen) {
    x11ov *o = calloc(1, sizeof *o);
    if (!o) return NULL;
    o->d = open_display(&o->x, display, err, errlen);
    if (!o->d) { free(o); return NULL; }
    int eb, er;
    if (!o->x.XShapeQueryExtension(o->d, &eb, &er)) {
        snprintf(err, errlen, "the X server has no SHAPE extension (needed so clicks pass through the blur)");
        ov_destroy(&o->base);
        return NULL;
    }
    o->base.name = "x11";
    o->scr = o->x.XDefaultScreen(o->d);
    o->root = o->x.XRootWindow(o->d, o->scr);
    o->vis = o->x.XDefaultVisual(o->d, o->scr);
    o->depth = o->x.XDefaultDepth(o->d, o->scr);
    o->shm = o->x.XShmQueryExtension(o->d);
    o->base.root_w = o->x.XDisplayWidth(o->d, o->scr);
    o->base.root_h = o->x.XDisplayHeight(o->d, o->scr);
    o->base.sync = ov_sync;
    o->base.draw = ov_draw;
    o->base.keep_on_top = ov_keep_on_top;
    o->base.fd = ov_fd;
    o->base.dispatch = ov_dispatch;
    o->base.destroy = ov_destroy;
    return &o->base;
}
