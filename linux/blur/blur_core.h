/* im-blur, pure parts (no X11, Wayland or models): capture scaling, pixel conversion, the "clean" thumbnail the
 * covers take their colours from, blur cells, cover drawing, rect and shape maths, the command / state protocol.
 * Unit-tested by linux/blur/test_blur_core.c (make test-blur). */
#ifndef IM_BLUR_CORE_H
#define IM_BLUR_CORE_H

#include <stddef.h>
#include <stdint.h>

#include "im_vision.h"

#define IB_LONG_SIDE 640  /* analysed frame: long side in pixels (as Android) */
#define IB_MAX_RECTS 512  /* covers per monitor (body-shaped covers give many thin rects) */
#define IB_MAX_CELLS 8    /* blur cells per cover side (as Android) */
#define IB_CELL_DP 90.0f  /* blur cell size (as Android's window hosts), dp = 1/160 inch */
#define IB_TEST_DP 24.0f  /* self-test square side */
#define IB_THUMB_W 160    /* clean thumbnail width (cells averaged from it) */

typedef struct { int x, y, w, h; } ib_rect; /* pixels */

/* Pixel layout of a 32-bit pixel read as a native uint32: the bit shift of each 8-bit channel. */
typedef struct { int r, g, b; } ib_layout;

/* From X11 visual / XImage masks (0xff0000 -> 16). Returns 0 unless all three are 8-bit masks. */
int ib_layout_from_masks(unsigned long rm, unsigned long gm, unsigned long bm, ib_layout *out);

/* Analysed frame size for a w x h source: long side IB_LONG_SIDE (never larger than the source), even sizes,
 * same shape. */
void ib_scale_size(int sw, int sh, int long_side, int *dw, int *dh);

/* Area-average downscale of a 32-bit source (layout lay, row stride sstride bytes) into RGBA8888 (alpha 255).
 * At most 4x4 samples per destination pixel. */
void ib_downscale(const uint8_t *src, int sw, int sh, int sstride, ib_layout lay, uint8_t *dst, int dw, int dh,
                  int dstride);

/* Is a self-test square (magenta) at normalised (cx, cy) in this RGBA frame? */
int ib_has_magenta(const uint8_t *rgba, int w, int h, int stride, float cx, float cy);

/* Covers with their colours taken from what they hide. In "covers visible" mode the capture shows our own covers,
 * so averaging under a cover again would average the cover itself (and darken it a little more every frame): the
 * thumbnail cells under a drawn cover keep the colour they had before it was drawn. */
typedef struct {
    int w, h;
    uint8_t *rgb;      /* w * h * 3 */
    unsigned char *seen; /* the cell has been filled once */
} ib_thumb;

int ib_thumb_init(ib_thumb *t, int frame_w, int frame_h); /* 0 = out of memory */
void ib_thumb_free(ib_thumb *t);
/* Updates the cells not under any of the covered rects (normalised; the covers on screen when the frame was
 * captured) from the RGBA frame. */
void ib_thumb_update(ib_thumb *t, const uint8_t *rgba, int fw, int fh, int stride, const im_vrect *covered, int n);

/* Number of blur cells for a cover of pw x ph pixels at cell size cell_px: 1..IB_MAX_CELLS each way. */
void ib_cell_count(float pw, float ph, float cell_px, int *nx, int *ny);
/* Averages the thumbnail under the normalised rect r into nx * ny cells (0xRRGGBB, row-major). Cells the thumbnail
 * has never seen are a neutral grey. */
void ib_cells(const ib_thumb *t, const im_vrect *r, int nx, int ny, uint32_t *cells);

/* 0xRRGGBB -> native pixel (layout lay, extra bits | e.g. 0xff000000 for opaque ARGB). */
static inline uint32_t ib_pixel(uint32_t rgb, ib_layout lay, uint32_t extra) {
    return ((rgb >> 16 & 255u) << lay.r) | ((rgb >> 8 & 255u) << lay.g) | ((rgb & 255u) << lay.b) | extra;
}

/* Draws one cover into a native-pixel buffer (stride in pixels): the cells smoothly stretched over the rect (each
 * cell centre at its full colour, bilinear in between, as Android's filtered bitmap), then the dark tint. */
void ib_draw_cells(uint32_t *buf, int stride, ib_rect r, const uint32_t *cells, int nx, int ny, ib_layout lay,
                   uint32_t extra);
void ib_fill(uint32_t *buf, int stride, ib_rect r, uint32_t px);

/* Covers (normalised) -> pixel rects in a W x H output, floor/ceil, clamped; empty ones dropped. Returns count. */
int ib_to_pixels(const im_vrect *r, int n, int W, int H, ib_rect *out, int max);
/* Same rect list? (to update the window shape only when the covers change) */
int ib_rects_equal(const ib_rect *a, int na, const ib_rect *b, int nb);
/* Bounding box of a rect list ({0,0,0,0} when empty). */
ib_rect ib_union(const ib_rect *r, int n);

/* Fail display: 0 none, 1 cover everything, 2 warning bar. */
enum { IB_FAIL_NONE = 0, IB_FAIL_COVER = 1, IB_FAIL_WARN = 2 };

/* What the overlay shows on one W x H output: the pixel rects (and their kinds) to paint. Adds the fail cover / bar
 * and the self-test square (sq_px side, at the left edge half-way down, as Android). Returns the count. */
typedef struct { ib_rect r; int kind; int index; /* index into the covers, -1 for extras */ } ib_paint;
enum { IB_PK_COVER = 0, IB_PK_FULL = 1, IB_PK_FAILCOVER = 2, IB_PK_BAR = 3, IB_PK_TEST = 4 };
int ib_layout_paint(const im_vrect *covers, int n, int W, int H, int fail, int test_square, int sq_px, int bar_px,
                    ib_paint *out, int max);

/* Per cover cells (the blurred picture). */
typedef struct { int nx, ny; uint32_t c[IB_MAX_CELLS * IB_MAX_CELLS]; } ib_cellset;

/* Colours (0xRRGGBB) of the opaque covers, the warning bar and the self-test square. */
#define IB_COL_SURFACE 0x2b2d31u
#define IB_COL_BAR 0xd32f2fu
#define IB_COL_TEST 0xff00ffu

/* Paints into a native-pixel buffer (stride in pixels): covers as cells (cells[p.index]), FULL and the fail cover
 * opaque, the warning bar red, the self-test square magenta. */
void ib_render(uint32_t *buf, int stride, const ib_paint *p, int n, const ib_cellset *cells, ib_layout lay,
               uint32_t extra);

/* ---- protocol ---- */

/* Live settings, from the command line or stdin. */
typedef struct {
    unsigned policy;    /* IM_VISION_WOMEN | IM_VISION_NSFW; 0 = idle (nothing captured or drawn) */
    int strictness;     /* blur_strictness 0/1/2 */
    int fail_cover;     /* blur_fail_cover: 1 cover the screen, 0 warning bar */
} ib_settings;

/* p(man) a person needs to be left uncovered, for blur_strictness 0/1/2 (Settings.blurMaleClear). */
float ib_male_clear(int strictness);

/* One stdin line: "policy N", "strictness N", "fail_cover 0|1", "quit". Returns 1 applied, 2 quit, 0 unknown or
 * bad value (ignored, the settings are unchanged). */
int ib_command(const char *line, ib_settings *s);

/* State codes reported on stdout. */
typedef enum {
    IB_ST_STARTING, IB_ST_ON, IB_ST_ON_COVERS_VISIBLE, IB_ST_FAILING, IB_ST_MODELS_MISSING, IB_ST_NO_CAPTURE,
    IB_ST_NO_OVERLAY, IB_ST_IDLE
} ib_state;
const char *ib_state_name(ib_state s);

/* One JSON line (with '\n'), e.g. {"state":"on","error":"","backend":"x11","overlay":"x11","covers":2,
 * "ms":31.5,"cpu":12.0,"fps":4.0}. ms / cpu / fps < 0 are left out. Returns the length (truncated to cap-1). */
int ib_state_json(char *buf, size_t cap, ib_state st, const char *error, const char *backend, const char *overlay,
                  int covers, double ms, double cpu, double fps);

#endif
