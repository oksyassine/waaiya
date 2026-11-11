/* Minimal Xlib / MIT-SHM / XShape / RandR client ABI, loaded at run time with dlopen (libX11.so.6, libXext.so.6,
 * libXrandr.so.2), like cli/pulse_dl.h for libpulse: im-blur builds without libx11-dev and starts on systems
 * without X11 (Wayland-only). These ABIs have been frozen for decades; the struct layouts and constants below are
 * checked against the real headers by linux/blur/abi_check.c (make check-blur-abi, CI). */
#ifndef IM_X11_DL_H
#define IM_X11_DL_H

#include <stddef.h>

typedef struct _XDisplay ibx_Display;
typedef unsigned long ibx_XID;
typedef ibx_XID ibx_Window, ibx_Pixmap, ibx_Colormap, ibx_Cursor, ibx_Drawable;
typedef unsigned long ibx_Atom;
typedef unsigned long ibx_ShmSeg;
typedef struct _XGC *ibx_GC;
typedef struct ibx_Visual ibx_Visual; /* only passed around */

typedef struct ibx_XImage {
    int width, height, xoffset, format;
    char *data;
    int byte_order, bitmap_unit, bitmap_bit_order, bitmap_pad, depth, bytes_per_line, bits_per_pixel;
    unsigned long red_mask, green_mask, blue_mask;
    char *obdata;
    struct {
        struct ibx_XImage *(*create_image)(void);
        int (*destroy_image)(struct ibx_XImage *);
        unsigned long (*get_pixel)(struct ibx_XImage *, int, int);
        int (*put_pixel)(struct ibx_XImage *, int, int, unsigned long);
        struct ibx_XImage *(*sub_image)(struct ibx_XImage *, int, int, unsigned int, unsigned int);
        int (*add_pixel)(struct ibx_XImage *, long);
    } f;
} ibx_XImage;

typedef struct {
    ibx_ShmSeg shmseg;
    int shmid;
    char *shmaddr;
    int readOnly;
} ibx_XShmSegmentInfo;

typedef struct {
    ibx_Pixmap background_pixmap;
    unsigned long background_pixel;
    ibx_Pixmap border_pixmap;
    unsigned long border_pixel;
    int bit_gravity, win_gravity, backing_store;
    unsigned long backing_planes, backing_pixel;
    int save_under;
    long event_mask, do_not_propagate_mask;
    int override_redirect;
    ibx_Colormap colormap;
    ibx_Cursor cursor;
} ibx_XSetWindowAttributes;

typedef struct { short x, y; unsigned short width, height; } ibx_XRectangle;

typedef struct {
    int type;
    unsigned long serial;
    int send_event;
    ibx_Display *display;
    ibx_Window window;
    int x, y, width, height, count;
} ibx_XExposeEvent;

typedef union {
    int type;
    ibx_XExposeEvent xexpose;
    long pad[24];
} ibx_XEvent;

typedef struct {
    int type;
    ibx_Display *display;
    ibx_XID resourceid;
    unsigned long serial;
    unsigned char error_code, request_code, minor_code;
} ibx_XErrorEvent;

typedef unsigned long ibx_RROutput;
typedef struct {
    ibx_Atom name;
    int primary, automatic, noutput;
    int x, y, width, height, mwidth, mheight;
    ibx_RROutput *outputs;
} ibx_XRRMonitorInfo;

enum {
    IBX_ZPixmap = 2, IBX_InputOutput = 1, IBX_Expose = 12,
    IBX_ShapeBounding = 0, IBX_ShapeInput = 2, IBX_ShapeSet = 0, IBX_Unsorted = 0,
    IBX_PropModeReplace = 0, IBX_XA_ATOM = 4, IBX_XA_CARDINAL = 6, IBX_XDamageReportNonEmpty = 3,
    IBX_XDamageNotify = 0,
};
#define IBX_CWBackPixmap (1L << 0)
#define IBX_CWBorderPixel (1L << 3)
#define IBX_CWOverrideRedirect (1L << 9)
#define IBX_CWEventMask (1L << 11)
#define IBX_ExposureMask (1L << 15)
#define IBX_AllPlanes (~0UL)

typedef int (*ibx_ErrorHandler)(ibx_Display *, ibx_XErrorEvent *);

/* F(library index, return type, name, parameters); library 0 = libX11, 1 = libXext, 2 = libXrandr (optional),
 * 3 = libXdamage (optional) */
#define IBX_FUNCS(F)                                                                                               \
    F(0, ibx_Display *, XOpenDisplay, (const char *))                                                              \
    F(0, int, XCloseDisplay, (ibx_Display *))                                                                      \
    F(0, int, XDefaultScreen, (ibx_Display *))                                                                     \
    F(0, ibx_Window, XRootWindow, (ibx_Display *, int))                                                            \
    F(0, ibx_Visual *, XDefaultVisual, (ibx_Display *, int))                                                       \
    F(0, int, XDefaultDepth, (ibx_Display *, int))                                                                 \
    F(0, int, XDisplayWidth, (ibx_Display *, int))                                                                 \
    F(0, int, XDisplayHeight, (ibx_Display *, int))                                                                \
    F(0, int, XDisplayWidthMM, (ibx_Display *, int))                                                               \
    F(0, int, XConnectionNumber, (ibx_Display *))                                                                  \
    F(0, ibx_Window, XCreateWindow, (ibx_Display *, ibx_Window, int, int, unsigned, unsigned, unsigned, int,      \
                                     unsigned, ibx_Visual *, unsigned long, ibx_XSetWindowAttributes *))           \
    F(0, int, XDestroyWindow, (ibx_Display *, ibx_Window))                                                         \
    F(0, int, XMapRaised, (ibx_Display *, ibx_Window))                                                             \
    F(0, int, XRaiseWindow, (ibx_Display *, ibx_Window))                                                           \
    F(0, int, XMoveResizeWindow, (ibx_Display *, ibx_Window, int, int, unsigned, unsigned))                        \
    F(0, ibx_GC, XCreateGC, (ibx_Display *, ibx_Drawable, unsigned long, void *))                                  \
    F(0, int, XFreeGC, (ibx_Display *, ibx_GC))                                                                    \
    F(0, int, XFlush, (ibx_Display *))                                                                             \
    F(0, int, XSync, (ibx_Display *, int))                                                                         \
    F(0, int, XPending, (ibx_Display *))                                                                           \
    F(0, int, XNextEvent, (ibx_Display *, ibx_XEvent *))                                                           \
    F(0, ibx_Atom, XInternAtom, (ibx_Display *, const char *, int))                                                \
    F(0, int, XChangeProperty, (ibx_Display *, ibx_Window, ibx_Atom, ibx_Atom, int, int, const unsigned char *,   \
                                int))                                                                              \
    F(0, int, XStoreName, (ibx_Display *, ibx_Window, const char *))                                               \
    F(0, ibx_XImage *, XGetImage, (ibx_Display *, ibx_Drawable, int, int, unsigned, unsigned, unsigned long, int)) \
    F(0, ibx_XImage *, XCreateImage, (ibx_Display *, ibx_Visual *, unsigned, int, int, char *, unsigned,         \
                                      unsigned, int, int))                                                         \
    F(0, int, XPutImage, (ibx_Display *, ibx_Drawable, ibx_GC, ibx_XImage *, int, int, int, int, unsigned,        \
                          unsigned))                                                                               \
    F(0, ibx_ErrorHandler, XSetErrorHandler, (ibx_ErrorHandler))                                                   \
    F(0, int, XFree, (void *))                                                                                     \
    F(1, int, XShmQueryExtension, (ibx_Display *))                                                                 \
    F(1, ibx_XImage *, XShmCreateImage, (ibx_Display *, ibx_Visual *, unsigned, int, char *,                      \
                                         ibx_XShmSegmentInfo *, unsigned, unsigned))                               \
    F(1, int, XShmAttach, (ibx_Display *, ibx_XShmSegmentInfo *))                                                  \
    F(1, int, XShmDetach, (ibx_Display *, ibx_XShmSegmentInfo *))                                                  \
    F(1, int, XShmGetImage, (ibx_Display *, ibx_Drawable, ibx_XImage *, int, int, unsigned long))                  \
    F(1, int, XShmPutImage, (ibx_Display *, ibx_Drawable, ibx_GC, ibx_XImage *, int, int, int, int, unsigned,     \
                             unsigned, int))                                                                       \
    F(1, int, XShapeQueryExtension, (ibx_Display *, int *, int *))                                                 \
    F(1, void, XShapeCombineRectangles, (ibx_Display *, ibx_Window, int, int, int, ibx_XRectangle *, int, int,    \
                                         int))                                                                     \
    F(2, int, XRRQueryExtension, (ibx_Display *, int *, int *))                                                    \
    F(2, ibx_XRRMonitorInfo *, XRRGetMonitors, (ibx_Display *, ibx_Window, int, int *))                            \
    F(2, void, XRRFreeMonitors, (ibx_XRRMonitorInfo *))                                                            \
    F(3, int, XDamageQueryExtension, (ibx_Display *, int *, int *))                                                \
    F(3, ibx_XID, XDamageCreate, (ibx_Display *, ibx_Drawable, int))                                               \
    F(3, void, XDamageSubtract, (ibx_Display *, ibx_XID, ibx_XID, ibx_XID))

typedef struct {
#define IBX_PTR(L, ret, name, args) ret(*name) args;
    IBX_FUNCS(IBX_PTR)
#undef IBX_PTR
    void *lib[4];
    int have_randr;  /* libXrandr loaded (optional: without it, one screen = the root window) */
    int have_damage; /* libXdamage loaded (optional: without it, the screen is polled) */
} ibx_api;

#ifndef IBX_NO_LOADER
#include <dlfcn.h>
#include <stdio.h>
#include <string.h>

/* Loads libX11 and libXext (required), libXrandr and libXdamage (optional). Returns 0 and fills err on failure. */
static int ibx_load(ibx_api *x, char *err, size_t errlen) {
    static const char *const names[4] = {"libX11.so.6", "libXext.so.6", "libXrandr.so.2", "libXdamage.so.1"};
    memset(x, 0, sizeof *x);
    for (int i = 0; i < 4; i++) {
        x->lib[i] = dlopen(names[i], RTLD_NOW | RTLD_LOCAL);
        if (!x->lib[i] && i < 2) {
            snprintf(err, errlen, "cannot load %s (X11 libraries not installed)", names[i]);
            return 0;
        }
    }
    x->have_randr = x->lib[2] != NULL;
    x->have_damage = x->lib[3] != NULL;
#define IBX_SYM(L, ret, name, args)                                                                              \
    if (x->lib[L]) {                                                                                               \
        *(void **)&x->name = dlsym(x->lib[L], #name);                                                              \
        if (!x->name) {                                                                                            \
            if (L == 2) x->have_randr = 0;                                                                         \
            else if (L == 3) x->have_damage = 0;                                                                   \
            else { snprintf(err, errlen, "%s missing in %s", #name, names[L]); return 0; }                         \
        }                                                                                                          \
    }
    IBX_FUNCS(IBX_SYM)
#undef IBX_SYM
    return 1;
}
#endif

#endif
