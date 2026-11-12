/* im-blur: the capture and overlay backends behind the main loop (im_blur.c).
 *
 * A "screen" is one monitor: the capture gives its analysed frame (RGBA, long side 640) and its place in the
 * overlay's coordinates; the overlay draws one surface per screen. Covers travel normalised (0..1 of the screen). */
#ifndef IM_BLUR_HOST_H
#define IM_BLUR_HOST_H

#include <stdint.h>

#include "blur_core.h"

#define IB_MAX_SCREENS 8

typedef struct {
    int x, y, w, h;   /* in the overlay's coordinates (X11 root pixels, Wayland logical pixels) */
    float px_per_dp;  /* overlay pixels per dp (1/160 inch), for the blur cell size */
} ib_geom;

typedef struct ib_capture ib_capture;
struct ib_capture {
    const char *name;
    char err[256];
    /* Screens now; geometry of screen i. */
    int (*count)(ib_capture *);
    void (*geometry)(ib_capture *, int i, ib_geom *g);
    /* The newest frame of screen i: 1 = new frame in *rgba (fw x fh, stride fw * 4, owned by the capture, valid
     * until the next grab of that screen), 0 = nothing new since the last grab, -1 = capture failed (err). */
    int (*grab)(ib_capture *, int i, const uint8_t **rgba, int *fw, int *fh);
    /* Something to wait on (-1: none) and its handler. dispatch returns 1 when the screens changed. */
    int (*fd)(ib_capture *);
    int (*dispatch)(ib_capture *);
    /* 1 while setting up (Wayland: the share dialog is open), 0 ready, -1 failed for good (err). */
    int (*ready)(ib_capture *);
    /* Wayland: the screen-share dialog is waiting for the user (read without locking: a hint for the state). */
    volatile int waiting_user;
    /* Tests (--capture-ppm): the capture never shows the overlay, skip the self-test. */
    int no_selftest;
    void (*destroy)(ib_capture *);
};

typedef struct ib_overlay ib_overlay;
struct ib_overlay {
    const char *name;
    char err[256];
    /* One surface per screen at these geometries. 0 = failed (err). */
    int (*sync)(ib_overlay *, const ib_geom *g, int n);
    /* Shows the paints on screen i (cells[p.index] for IB_PK_COVER paints). */
    void (*draw)(ib_overlay *, int i, const ib_paint *p, int n, const ib_cellset *cells);
    /* Keeps the surfaces above other windows (called twice a second). */
    void (*keep_on_top)(ib_overlay *);
    int (*fd)(ib_overlay *);
    void (*dispatch)(ib_overlay *);
    void (*destroy)(ib_overlay *);
    /* X11: the root window's size (0 for layer-shell), to map the portal's logical layout onto XWayland;
     * update_root reads it again (a resolution change), NULL for layer-shell */
    int root_w, root_h;
    void (*update_root)(ib_overlay *);
    /* Monitors the overlay knows now (wl_output / RandR), to tell when the capture misses some; NULL: unknown */
    int (*outputs)(ib_overlay *);
};

/* Backends. Each returns NULL with err filled when it cannot work here. */
ib_capture *ib_x11_capture_new(const char *display, char *err, size_t errlen);
ib_overlay *ib_x11_overlay_new(const char *display, char *err, size_t errlen);
ib_capture *ib_portal_capture_new(const char *token_file, char *err, size_t errlen);
ib_overlay *ib_layer_overlay_new(char *err, size_t errlen);

#endif
