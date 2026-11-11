/* im-blur, pure parts. See blur_core.h. */
#include "blur_core.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int mask_shift(unsigned long m) {
    for (int s = 0; s <= 24; s += 8)
        if (m == (0xfful << s)) return s;
    return -1;
}

int ib_layout_from_masks(unsigned long rm, unsigned long gm, unsigned long bm, ib_layout *out) {
    int r = mask_shift(rm), g = mask_shift(gm), b = mask_shift(bm);
    if (r < 0 || g < 0 || b < 0 || r == g || g == b || r == b) return 0;
    out->r = r; out->g = g; out->b = b;
    return 1;
}

void ib_scale_size(int sw, int sh, int long_side, int *dw, int *dh) {
    if (sw < 2) sw = 2;
    if (sh < 2) sh = 2;
    int l = sw > sh ? sw : sh;
    double s = l > long_side ? (double)long_side / l : 1.0;
    int w = (int)(sw * s) / 2 * 2, h = (int)(sh * s) / 2 * 2;
    *dw = w < 2 ? 2 : w;
    *dh = h < 2 ? 2 : h;
}

void ib_downscale(const uint8_t *src, int sw, int sh, int sstride, ib_layout lay, uint8_t *dst, int dw, int dh,
                  int dstride) {
    /* up to 4 evenly spaced samples per axis inside each destination pixel's source area */
    int fx = sw / dw, fy = sh / dh;
    int nx = fx < 1 ? 1 : (fx > 4 ? 4 : fx), ny = fy < 1 ? 1 : (fy > 4 ? 4 : fy);
    int cnt = nx * ny;
    for (int y = 0; y < dh; y++) {
        uint8_t *o = dst + (size_t)y * dstride;
        double y0 = (double)y * sh / dh, ys = (double)sh / dh;
        for (int x = 0; x < dw; x++) {
            double x0 = (double)x * sw / dw, xs = (double)sw / dw;
            unsigned r = 0, g = 0, b = 0;
            for (int j = 0; j < ny; j++) {
                int sy = (int)(y0 + (j + 0.5) * ys / ny);
                if (sy >= sh) sy = sh - 1;
                const uint32_t *row = (const uint32_t *)(const void *)(src + (size_t)sy * sstride);
                for (int i = 0; i < nx; i++) {
                    int sx = (int)(x0 + (i + 0.5) * xs / nx);
                    if (sx >= sw) sx = sw - 1;
                    uint32_t p = row[sx];
                    r += p >> lay.r & 255u; g += p >> lay.g & 255u; b += p >> lay.b & 255u;
                }
            }
            o[x * 4] = (uint8_t)(r / cnt); o[x * 4 + 1] = (uint8_t)(g / cnt); o[x * 4 + 2] = (uint8_t)(b / cnt);
            o[x * 4 + 3] = 255;
        }
    }
}

int ib_has_magenta(const uint8_t *rgba, int w, int h, int stride, float cx, float cy) {
    int x = (int)(cx * w), y = (int)(cy * h);
    if (x < 0 || y < 0 || x >= w || y >= h) return 0;
    const uint8_t *p = rgba + (size_t)y * stride + (size_t)x * 4;
    return p[0] > 200 && p[1] < 60 && p[2] > 200;
}

int ib_thumb_init(ib_thumb *t, int frame_w, int frame_h) {
    memset(t, 0, sizeof *t);
    t->w = IB_THUMB_W;
    t->h = frame_h * IB_THUMB_W / (frame_w > 0 ? frame_w : 1);
    if (t->h < 1) t->h = 1;
    t->rgb = calloc((size_t)t->w * t->h, 3);
    t->seen = calloc((size_t)t->w * t->h, 1);
    if (!t->rgb || !t->seen) { ib_thumb_free(t); return 0; }
    return 1;
}

void ib_thumb_free(ib_thumb *t) {
    free(t->rgb);
    free(t->seen);
    t->rgb = NULL; t->seen = NULL;
}

void ib_thumb_update(ib_thumb *t, const uint8_t *rgba, int fw, int fh, int stride, const im_vrect *covered, int n) {
    if (!t->rgb) return;
    for (int ty = 0; ty < t->h; ty++) {
        int y0 = ty * fh / t->h, y1 = (ty + 1) * fh / t->h;
        if (y1 <= y0) y1 = y0 + 1;
        float cy0 = (float)ty / t->h, cy1 = (float)(ty + 1) / t->h;
        for (int tx = 0; tx < t->w; tx++) {
            float cx0 = (float)tx / t->w, cx1 = (float)(tx + 1) / t->w;
            int hidden = 0;
            for (int i = 0; i < n && !hidden; i++)
                hidden = cx1 > covered[i].x0 && cx0 < covered[i].x1 && cy1 > covered[i].y0 && cy0 < covered[i].y1;
            if (hidden) continue;
            int x0 = tx * fw / t->w, x1 = (tx + 1) * fw / t->w;
            if (x1 <= x0) x1 = x0 + 1;
            unsigned r = 0, g = 0, b = 0, c = 0;
            for (int y = y0; y < y1 && y < fh; y++)
                for (int x = x0; x < x1 && x < fw; x++) {
                    const uint8_t *p = rgba + (size_t)y * stride + (size_t)x * 4;
                    r += p[0]; g += p[1]; b += p[2]; c++;
                }
            if (!c) continue;
            uint8_t *o = t->rgb + ((size_t)ty * t->w + tx) * 3;
            o[0] = (uint8_t)(r / c); o[1] = (uint8_t)(g / c); o[2] = (uint8_t)(b / c);
            t->seen[ty * t->w + tx] = 1;
        }
    }
}

void ib_cell_count(float pw, float ph, float cell_px, int *nx, int *ny) {
    if (cell_px < 1) cell_px = 1;
    int x = (int)lroundf(pw / cell_px), y = (int)lroundf(ph / cell_px);
    *nx = x < 1 ? 1 : (x > IB_MAX_CELLS ? IB_MAX_CELLS : x);
    *ny = y < 1 ? 1 : (y > IB_MAX_CELLS ? IB_MAX_CELLS : y);
}

static int clampi(int v, int lo, int hi) { return v < lo ? lo : (v > hi ? hi : v); }

void ib_cells(const ib_thumb *t, const im_vrect *r, int nx, int ny, uint32_t *cells) {
    for (int j = 0; j < ny; j++)
        for (int i = 0; i < nx; i++) {
            uint32_t col = 0x808080;
            if (t && t->rgb) {
                float fx0 = r->x0 + (r->x1 - r->x0) * i / nx, fx1 = r->x0 + (r->x1 - r->x0) * (i + 1) / nx;
                float fy0 = r->y0 + (r->y1 - r->y0) * j / ny, fy1 = r->y0 + (r->y1 - r->y0) * (j + 1) / ny;
                int x0 = clampi((int)(fx0 * t->w), 0, t->w - 1), x1 = clampi((int)ceilf(fx1 * t->w), x0 + 1, t->w);
                int y0 = clampi((int)(fy0 * t->h), 0, t->h - 1), y1 = clampi((int)ceilf(fy1 * t->h), y0 + 1, t->h);
                unsigned sr = 0, sg = 0, sb = 0, c = 0;
                for (int y = y0; y < y1; y++)
                    for (int x = x0; x < x1; x++) {
                        if (!t->seen[y * t->w + x]) continue;
                        const uint8_t *p = t->rgb + ((size_t)y * t->w + x) * 3;
                        sr += p[0]; sg += p[1]; sb += p[2]; c++;
                    }
                if (c) col = (sr / c) << 16 | (sg / c) << 8 | (sb / c);
            }
            cells[j * nx + i] = col;
        }
}

/* Android's tint: argb(120, 30, 30, 30) over the cells. */
#define TINT_A 120u
#define TINT_C 30u

void ib_draw_cells(uint32_t *buf, int stride, ib_rect r, const uint32_t *cells, int nx, int ny, ib_layout lay,
                   uint32_t extra) {
    if (r.w <= 0 || r.h <= 0 || nx < 1 || ny < 1) return;
    enum { MAXW = 16384 };
    static int xi0[MAXW], xi1[MAXW], xf[MAXW]; /* drawing runs on one thread */
    int w = r.w < MAXW ? r.w : MAXW;
    for (int x = 0; x < w; x++) {
        float u = (x + 0.5f) * nx / r.w - 0.5f;
        if (u < 0) u = 0;
        if (u > nx - 1) u = (float)(nx - 1);
        int i0 = (int)u;
        xi0[x] = i0; xi1[x] = i0 + 1 < nx ? i0 + 1 : i0; xf[x] = (int)((u - i0) * 256);
    }
    const unsigned keep = 255 - TINT_A, add = TINT_C * TINT_A;
    for (int y = 0; y < r.h; y++) {
        float v = (y + 0.5f) * ny / r.h - 0.5f;
        if (v < 0) v = 0;
        if (v > ny - 1) v = (float)(ny - 1);
        int j0 = (int)v, j1 = j0 + 1 < ny ? j0 + 1 : j0, yf = (int)((v - j0) * 256);
        uint32_t *row = buf + (size_t)(r.y + y) * stride + r.x;
        for (int x = 0; x < w; x++) {
            uint32_t a = cells[j0 * nx + xi0[x]], b = cells[j0 * nx + xi1[x]];
            uint32_t c = cells[j1 * nx + xi0[x]], d = cells[j1 * nx + xi1[x]];
            int f = xf[x];
            uint32_t out = 0;
            for (int s = 0; s <= 16; s += 8) {
                int top = (int)(a >> s & 255) * (256 - f) + (int)(b >> s & 255) * f;
                int bot = (int)(c >> s & 255) * (256 - f) + (int)(d >> s & 255) * f;
                unsigned v8 = (unsigned)((top * (256 - yf) + bot * yf) >> 16);
                v8 = (v8 * keep + add) / 255;
                out |= v8 << s;
            }
            row[x] = ib_pixel(out, lay, extra);
        }
    }
}

void ib_fill(uint32_t *buf, int stride, ib_rect r, uint32_t px) {
    for (int y = 0; y < r.h; y++) {
        uint32_t *row = buf + (size_t)(r.y + y) * stride + r.x;
        for (int x = 0; x < r.w; x++) row[x] = px;
    }
}

int ib_to_pixels(const im_vrect *r, int n, int W, int H, ib_rect *out, int max) {
    int m = 0;
    for (int i = 0; i < n && m < max; i++) {
        int x0 = clampi((int)floorf(r[i].x0 * W), 0, W), x1 = clampi((int)ceilf(r[i].x1 * W), 0, W);
        int y0 = clampi((int)floorf(r[i].y0 * H), 0, H), y1 = clampi((int)ceilf(r[i].y1 * H), 0, H);
        if (x1 > x0 && y1 > y0) out[m++] = (ib_rect){x0, y0, x1 - x0, y1 - y0};
    }
    return m;
}

int ib_rects_equal(const ib_rect *a, int na, const ib_rect *b, int nb) {
    return na == nb && (na == 0 || memcmp(a, b, sizeof *a * (size_t)na) == 0);
}

ib_rect ib_union(const ib_rect *r, int n) {
    if (n <= 0) return (ib_rect){0, 0, 0, 0};
    int x0 = r[0].x, y0 = r[0].y, x1 = r[0].x + r[0].w, y1 = r[0].y + r[0].h;
    for (int i = 1; i < n; i++) {
        if (r[i].x < x0) x0 = r[i].x;
        if (r[i].y < y0) y0 = r[i].y;
        if (r[i].x + r[i].w > x1) x1 = r[i].x + r[i].w;
        if (r[i].y + r[i].h > y1) y1 = r[i].y + r[i].h;
    }
    return (ib_rect){x0, y0, x1 - x0, y1 - y0};
}

int ib_layout_paint(const im_vrect *covers, int n, int W, int H, int fail, int test_square, int sq_px, int bar_px,
                    ib_paint *out, int max) {
    int m = 0;
    if (max <= 0 || W <= 0 || H <= 0) return 0;
    if (fail == IB_FAIL_COVER) {
        out[m++] = (ib_paint){{0, 0, W, H}, IB_PK_FAILCOVER, -1};
    } else {
        for (int i = 0; i < n && m < max; i++) {
            ib_rect pr;
            if (ib_to_pixels(&covers[i], 1, W, H, &pr, 1) != 1) continue;
            out[m++] = (ib_paint){pr, covers[i].kind == IM_VK_FULL ? IB_PK_FULL : IB_PK_COVER, i};
        }
        if (fail == IB_FAIL_WARN && m < max) out[m++] = (ib_paint){{0, 0, W, bar_px < H ? bar_px : H}, IB_PK_BAR, -1};
    }
    if (test_square && m < max) {
        int s = sq_px < W ? sq_px : W, y = H / 2;
        if (y + s > H) s = H - y;
        if (s > 0) out[m++] = (ib_paint){{0, y, s, s}, IB_PK_TEST, -1};
    }
    return m;
}

void ib_render(uint32_t *buf, int stride, const ib_paint *p, int n, const ib_cellset *cells, ib_layout lay,
               uint32_t extra) {
    for (int i = 0; i < n; i++) {
        switch (p[i].kind) {
        case IB_PK_COVER:
            if (cells && p[i].index >= 0) {
                const ib_cellset *c = &cells[p[i].index];
                ib_draw_cells(buf, stride, p[i].r, c->c, c->nx, c->ny, lay, extra);
            } else {
                ib_fill(buf, stride, p[i].r, ib_pixel(IB_COL_SURFACE, lay, extra)); /* no cells: opaque */
            }
            break;
        case IB_PK_FULL:
        case IB_PK_FAILCOVER: ib_fill(buf, stride, p[i].r, ib_pixel(IB_COL_SURFACE, lay, extra)); break;
        case IB_PK_BAR: ib_fill(buf, stride, p[i].r, ib_pixel(IB_COL_BAR, lay, extra)); break;
        case IB_PK_TEST: ib_fill(buf, stride, p[i].r, ib_pixel(IB_COL_TEST, lay, extra)); break;
        }
    }
}

float ib_male_clear(int strictness) {
    switch (strictness) {
    case 1: return 0.99f;
    case 2: return 0.98f;
    default: return 0.999f;
    }
}

static int parse_int(const char *s, int lo, int hi, int *out) {
    char *end;
    long v = strtol(s, &end, 10);
    while (*end == ' ' || *end == '\t' || *end == '\r' || *end == '\n') end++;
    if (end == s || *end || v < lo || v > hi) return 0;
    *out = (int)v;
    return 1;
}

int ib_command(const char *line, ib_settings *s) {
    while (*line == ' ' || *line == '\t') line++;
    const char *arg = strchr(line, ' ');
    size_t klen = arg ? (size_t)(arg - line) : strcspn(line, "\r\n");
    if (arg) while (*arg == ' ') arg++;
    int v;
    if (klen == 4 && !strncmp(line, "quit", 4)) return 2;
    if (!arg) return 0;
    if (klen == 6 && !strncmp(line, "policy", 6) && parse_int(arg, 0, 3, &v)) { s->policy = (unsigned)v; return 1; }
    if (klen == 10 && !strncmp(line, "strictness", 10) && parse_int(arg, 0, 2, &v)) { s->strictness = v; return 1; }
    if (klen == 10 && !strncmp(line, "fail_cover", 10) && parse_int(arg, 0, 1, &v)) { s->fail_cover = v; return 1; }
    return 0;
}

const char *ib_state_name(ib_state s) {
    static const char *const n[] = {"starting", "on", "on_covers_visible", "failing", "models_missing",
                                    "no_capture", "no_overlay", "idle"};
    return (unsigned)s < sizeof n / sizeof *n ? n[s] : "failing";
}

/* JSON string body: quotes, backslashes and control characters escaped. */
static size_t json_str(char *o, size_t cap, const char *s) {
    size_t k = 0;
    for (; s && *s && k + 7 < cap; s++) {
        unsigned char c = (unsigned char)*s;
        if (c == '"' || c == '\\') { o[k++] = '\\'; o[k++] = (char)c; }
        else if (c == '\n') { o[k++] = '\\'; o[k++] = 'n'; }
        else if (c < 0x20) k += (size_t)snprintf(o + k, cap - k, "\\u%04x", c);
        else o[k++] = (char)c;
    }
    o[k] = 0;
    return k;
}

int ib_state_json(char *buf, size_t cap, ib_state st, const char *error, const char *backend, const char *overlay,
                  int covers, double ms, double cpu, double fps) {
    char e[512], b[64], ov[64];
    json_str(e, sizeof e, error);
    json_str(b, sizeof b, backend);
    json_str(ov, sizeof ov, overlay);
    int k = snprintf(buf, cap, "{\"state\":\"%s\",\"error\":\"%s\",\"backend\":\"%s\",\"overlay\":\"%s\",\"covers\":%d",
                     ib_state_name(st), e, b, ov, covers);
    if (k < 0 || (size_t)k >= cap) k = (int)cap - 1;
    if (ms >= 0 && (size_t)k < cap) k += snprintf(buf + k, cap - k, ",\"ms\":%.1f", ms);
    if ((size_t)k >= cap) k = (int)cap - 1;
    if (cpu >= 0 && (size_t)k < cap) k += snprintf(buf + k, cap - k, ",\"cpu\":%.1f", cpu);
    if ((size_t)k >= cap) k = (int)cap - 1;
    if (fps >= 0 && (size_t)k < cap) k += snprintf(buf + k, cap - k, ",\"fps\":%.1f", fps);
    if ((size_t)k >= cap) k = (int)cap - 1;
    if ((size_t)k + 2 < cap) { buf[k++] = '}'; buf[k++] = '\n'; buf[k] = 0; }
    return k;
}
