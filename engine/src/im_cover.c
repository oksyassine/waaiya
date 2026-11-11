/* Screen blur tracker: detections over time -> rectangles to draw. See im_vision.h.
 *
 * Two situations:
 *  - covers not visible in the capture (the overlay is excluded from screen capture): every frame shows the real
 *    content, so covers follow the detections, are moved ahead by the measured motion (the overlay is drawn
 *    ~100 ms after the frame was captured), and are held a little after a missed detection.
 *  - covers visible in the capture: what is under a cover cannot be seen any more. A cover then stays until the
 *    uncovered part of the screen shows a scene change, or a scroll moves it off screen; a person stepping out of
 *    a cover makes it grow. Over-covering is preferred to uncovering a woman to check whether she is still there.
 *
 * A person with an outline (im_vshape, from the segmenter) is drawn as strips that follow the body, each kept inside
 * the rectangle they would get otherwise; in the second situation outlines are not used (the capture would show our
 * own covers to the segmenter). Rectangles closer than merge_gap are drawn as their bounding box (a group); an
 * outlined person instead gets a bridge to each close neighbour, so text beside a group stays readable but the space
 * between two people (where a missed one may stand) is still covered.
 */
#include <math.h>
#include <stdlib.h>
#include <string.h>

#include "im_vision.h"

#define TW 32
#define TH 48 /* thumbnail cells, portrait-ish; only used as a grid */
#define MAX_TRACKS 48
#define MAX_OUT 256 /* rects remembered for the scene-change mask; callers' buffers are sized the same */
#define SHIFT 6

typedef struct {
    im_vrect r;
    double last_seen;
    float vx, vy;  /* centre velocity, frame units per ms */
    int matched;   /* took a detection in this update: one detection per track per frame */
    int nv;        /* has a velocity measurement */
    im_vshape sh;  /* outline from the last detection (rows = 0: the whole rectangle) */
} track;

struct im_cover {
    int covers_visible;
    im_cover_params p;
    track t[MAX_TRACKS];
    int nt;
    float thumb[TW * TH], prev[TW * TH];
    unsigned char mask[TW * TH];
    int have_prev;
    im_vrect out_prev[MAX_OUT], out_last[MAX_OUT];
    int n_prev, n_last;
    /* output scratch: outlined people's strips and rectangles, and every cover's extent for the bridges */
    im_vrect strip[MAX_TRACKS][IM_SHAPE_ROWS], unit_rect[MAX_TRACKS];
    int unit_n[MAX_TRACKS];
    im_vrect ext[MAX_OUT + MAX_TRACKS], ext_rect[MAX_OUT + MAX_TRACKS]; /* drawn extent; rectangle (closeness) */
    unsigned char ext_outlined[MAX_OUT + MAX_TRACKS];
    double full_until;
    double t_last;
};

im_cover *im_cover_create(int covers_visible) {
    im_cover *c = calloc(1, sizeof *c);
    if (!c) return NULL;
    c->covers_visible = covers_visible;
    c->p = (im_cover_params){0.20f, 0.015f, 120.0f, 500.0f, 1500.0f, 0.12f, 0.30f, 0.05f, 0.30f};
    return c;
}

void im_cover_destroy(im_cover *c) { free(c); }
void im_cover_get_params(const im_cover *c, im_cover_params *p) { if (c && p) *p = c->p; }
void im_cover_set_params(im_cover *c, const im_cover_params *p) { if (c && p) c->p = *p; }

void im_cover_reset(im_cover *c) {
    if (!c) return;
    im_cover_params p = c->p;
    int cv = c->covers_visible;
    memset(c, 0, sizeof *c);
    c->p = p;
    c->covers_visible = cv;
}

static void make_thumb(const uint8_t *rgba, int w, int h, int stride, float *th) {
    for (int ty = 0; ty < TH; ty++)
        for (int tx = 0; tx < TW; tx++) {
            float acc = 0;
            for (int sy = 0; sy < 3; sy++)
                for (int sx = 0; sx < 3; sx++) {
                    int x = (int)(((tx + (sx + 0.5f) / 3) / TW) * w), y = (int)(((ty + (sy + 0.5f) / 3) / TH) * h);
                    if (x >= w) x = w - 1;
                    if (y >= h) y = h - 1;
                    const uint8_t *q = rgba + (size_t)y * stride + (size_t)x * 4;
                    acc += 0.299f * q[0] + 0.587f * q[1] + 0.114f * q[2];
                }
            th[ty * TW + tx] = acc / (9 * 255.0f);
        }
}

static void mark(unsigned char *mask, const im_vrect *r, int n) {
    for (int i = 0; i < n; i++) {
        int x0 = (int)floorf(r[i].x0 * TW), x1 = (int)ceilf(r[i].x1 * TW);
        int y0 = (int)floorf(r[i].y0 * TH), y1 = (int)ceilf(r[i].y1 * TH);
        for (int y = y0 < 0 ? 0 : y0; y < y1 && y < TH; y++)
            for (int x = x0 < 0 ? 0 : x0; x < x1 && x < TW; x++) mask[y * TW + x] = 1;
    }
}

/* Mean absolute change between the current and previous thumbnail, the content moved by (dx, dy) cells,
 * over cells not under a cover. Returns -1 when too few cells can be compared. */
static float change(const im_cover *c, int dx, int dy) {
    float acc = 0;
    int n = 0;
    for (int y = 0; y < TH; y++) {
        int py = y - dy;
        if (py < 0 || py >= TH) continue;
        for (int x = 0; x < TW; x++) {
            int px = x - dx;
            if (px < 0 || px >= TW || c->mask[y * TW + x] || c->mask[py * TW + px]) continue;
            acc += fabsf(c->thumb[y * TW + x] - c->prev[py * TW + px]);
            n++;
        }
    }
    return n * 10 >= TW * TH * 3 ? acc / n : -1;
}

static int center_in(const im_vrect *a, const im_vrect *b) {
    float cx = (a->x0 + a->x1) / 2, cy = (a->y0 + a->y1) / 2;
    return cx >= b->x0 && cx <= b->x1 && cy >= b->y0 && cy <= b->y1;
}

static float overlap(const im_vrect *a, const im_vrect *b) {
    float ix = fminf(a->x1, b->x1) - fmaxf(a->x0, b->x0), iy = fminf(a->y1, b->y1) - fmaxf(a->y0, b->y0);
    if (ix <= 0 || iy <= 0) return 0;
    float i = ix * iy, u = (a->x1 - a->x0) * (a->y1 - a->y0) + (b->x1 - b->x0) * (b->y1 - b->y0) - i;
    return u > 0 ? i / u : 0;
}

static int stricter(int a, int b) {
    /* WOMAN and UNSURE are both covered; keep WOMAN once seen as such */
    if (a == IM_VK_WOMAN || b == IM_VK_WOMAN) return IM_VK_WOMAN;
    if (a == IM_VK_NSFW || b == IM_VK_NSFW) return IM_VK_NSFW;
    return IM_VK_UNSURE;
}

static void drop(im_cover *c, int i) { c->t[i] = c->t[--c->nt]; }

/* Group covers: two covers whose gap is at most gap * (the smaller one's height) become their bounding box, until
 * no pair is left. Only the drawn rects are merged; tracks stay one per person. A FULL rect is left alone. */
static int merge_close(im_vrect *r, int n, float gap) {
    if (gap <= 0) return n;
    for (int again = 1; again;) {
        again = 0;
        for (int i = 0; i < n && !again; i++) {
            if (r[i].kind == IM_VK_FULL) continue;
            for (int j = i + 1; j < n; j++) {
                if (r[j].kind == IM_VK_FULL) continue;
                float g = gap * fminf(r[i].y1 - r[i].y0, r[j].y1 - r[j].y0);
                float gx = fmaxf(r[i].x0, r[j].x0) - fminf(r[i].x1, r[j].x1); /* < 0: they overlap on this axis */
                float gy = fmaxf(r[i].y0, r[j].y0) - fminf(r[i].y1, r[j].y1);
                if (gx > g || gy > g) continue;
                r[i].x0 = fminf(r[i].x0, r[j].x0); r[i].y0 = fminf(r[i].y0, r[j].y0);
                r[i].x1 = fmaxf(r[i].x1, r[j].x1); r[i].y1 = fmaxf(r[i].y1, r[j].y1);
                r[i].kind = stricter(r[i].kind, r[j].kind);
                r[i].score = fmaxf(r[i].score, r[j].score);
                r[i].p_male = -1;
                r[j] = r[--n];
                again = 1; /* the grown cover may now reach others: start over */
                break;
            }
        }
    }
    return n;
}

/* The strips of an outlined track (see im_vshape), in frame units: each row widened by the strip margin, the top and
 * bottom rows extended by it (or to the rectangle's edge when the body goes on past the segmenter's crop), stretched
 * by the motion lead (lx, ly) like the rectangle, and clipped to rect = the cover the person would get without an
 * outline. Rows with the same span are joined. Returns the strip count (0 = draw rect). */
static int strips_of(const im_cover_params *p, const im_vrect *b, const im_vshape *sh, float lx, float ly,
                     const im_vrect *rect, im_vrect *s) {
    if (sh->rows < 1 || sh->rows > IM_SHAPE_ROWS || !(sh->y1 > sh->y0)) return 0;
    float bw = b->x1 - b->x0, bh = b->y1 - b->y0;
    float mx = fmaxf(p->strip_margin * bw, 0.5f * p->margin_min), my = fmaxf(p->strip_margin * bh, 0.5f * p->margin_min);
    float rh = (sh->y1 - sh->y0) / sh->rows * bh, seam = fminf(0.25f * rh, 0.003f); /* overlap: no hairline gaps */
    int first = -1, last = -1, n = 0;
    for (int k = 0; k < sh->rows; k++)
        if (sh->l[k] <= sh->r[k]) { if (first < 0) first = k; last = k; }
    if (first < 0) return 0;
    for (int k = first; k <= last; k++) {
        if (sh->l[k] > sh->r[k]) continue;
        float ya = b->y0 + sh->y0 * bh + k * rh;
        im_vrect r = *b;
        r.kind |= IM_VK_PART;
        r.x0 = b->x0 + sh->l[k] * bw - mx;
        r.x1 = b->x0 + sh->r[k] * bw + mx;
        r.y0 = ya - seam;
        r.y1 = ya + rh + seam;
        if (k == first) r.y0 = k == 0 && (sh->flags & IM_SHAPE_OPEN_TOP) ? rect->y0 : ya - my;
        if (k == last) r.y1 = k == sh->rows - 1 && (sh->flags & IM_SHAPE_OPEN_BOTTOM) ? rect->y1 : ya + rh + my;
        if (lx < 0) r.x0 += lx; else r.x1 += lx;
        if (ly < 0) r.y0 += ly; else r.y1 += ly;
        r.x0 = fmaxf(r.x0, rect->x0); r.x1 = fminf(r.x1, rect->x1);
        r.y0 = fmaxf(r.y0, rect->y0); r.y1 = fminf(r.y1, rect->y1);
        if (r.x1 <= r.x0 || r.y1 <= r.y0) continue;
        if (n && fabsf(r.x0 - s[n - 1].x0) < 0.004f && fabsf(r.x1 - s[n - 1].x1) < 0.004f && r.y0 <= s[n - 1].y1) {
            s[n - 1].x0 = fminf(s[n - 1].x0, r.x0); s[n - 1].x1 = fmaxf(s[n - 1].x1, r.x1);
            s[n - 1].y1 = fmaxf(s[n - 1].y1, r.y1);
        } else s[n++] = r;
    }
    return n;
}

/* A rect over the space between two covers (extents a, b): between their centres along the axis they are apart on,
 * over the span they share on the other one (between the centres too when they share none). */
static im_vrect bridge(const im_vrect *a, const im_vrect *b) {
    float ax = (a->x0 + a->x1) / 2, ay = (a->y0 + a->y1) / 2, bx = (b->x0 + b->x1) / 2, by = (b->y0 + b->y1) / 2;
    float sw = (a->x1 - a->x0 + b->x1 - b->x0) / 2, sh = (a->y1 - a->y0 + b->y1 - b->y0) / 2;
    im_vrect r = *a;
    r.kind = stricter(a->kind & ~IM_VK_PART, b->kind & ~IM_VK_PART) | IM_VK_PART;
    r.score = fmaxf(a->score, b->score);
    r.p_male = -1;
    float ox0 = fmaxf(a->x0, b->x0), ox1 = fminf(a->x1, b->x1), oy0 = fmaxf(a->y0, b->y0), oy1 = fminf(a->y1, b->y1);
    if (fabsf(ax - bx) / sw >= fabsf(ay - by) / sh) { /* side by side */
        r.x0 = fminf(ax, bx); r.x1 = fmaxf(ax, bx);
        if (oy1 > oy0) { r.y0 = oy0; r.y1 = oy1; } else { r.y0 = fminf(ay, by); r.y1 = fmaxf(ay, by); }
    } else {                                          /* one above the other */
        r.y0 = fminf(ay, by); r.y1 = fmaxf(ay, by);
        if (ox1 > ox0) { r.x0 = ox0; r.x1 = ox1; } else { r.x0 = fminf(ax, bx); r.x1 = fmaxf(ax, bx); }
    }
    return r;
}

static int close_to(const im_vrect *a, const im_vrect *b, float gap) {
    float g = gap * fminf(a->y1 - a->y0, b->y1 - b->y0);
    return fmaxf(a->x0, b->x0) - fminf(a->x1, b->x1) <= g && fmaxf(a->y0, b->y0) - fminf(a->y1, b->y1) <= g;
}

int im_cover_update(im_cover *c, double t_ms, const uint8_t *rgba, int w, int h, int stride, const im_vrect *dets,
                    int n, im_vrect *out, int max) {
    return im_cover_update_shapes(c, t_ms, rgba, w, h, stride, dets, NULL, n, out, max);
}

int im_cover_update_shapes(im_cover *c, double t_ms, const uint8_t *rgba, int w, int h, int stride,
                           const im_vrect *dets, const im_vshape *shapes, int n, im_vrect *out, int max) {
    if (!c || !out || max < 1) return 0;
    const im_cover_params *p = &c->p;

    /* 1. scene change / scroll, measured where no cover hides the content */
    if (rgba && w >= 8 && h >= 8) {
        make_thumb(rgba, w, h, stride, c->thumb);
        if (c->covers_visible && c->have_prev) {
            memset(c->mask, 0, sizeof c->mask);
            mark(c->mask, c->out_last, c->n_last); /* the overlay may lag a frame behind: both outputs */
            mark(c->mask, c->out_prev, c->n_prev);
            float still = change(c, 0, 0);
            if (still >= 0) {
                float best = still;
                int bx = 0, by = 0;
                if (still > 0.01f)
                    for (int dy = -SHIFT; dy <= SHIFT; dy++)
                        for (int dx = -SHIFT / 2; dx <= SHIFT / 2; dx++) {
                            float ch = change(c, dx, dy);
                            if (ch >= 0 && ch < best - 1e-4f) { best = ch; bx = dx; by = dy; }
                        }
                if (best > p->cut_level) {
                    c->nt = 0; /* new scene: nothing known about it, start over */
                    c->full_until = 0;
                } else if ((bx || by) && best < 0.7f * still) {
                    float ox = (float)bx / TW, oy = (float)by / TH;
                    for (int i = c->nt - 1; i >= 0; i--) {
                        im_vrect *r = &c->t[i].r;
                        r->x0 += ox; r->x1 += ox; r->y0 += oy; r->y1 += oy;
                        if (r->x1 <= 0 || r->x0 >= 1 || r->y1 <= 0 || r->y0 >= 1) drop(c, i);
                    }
                }
            }
        }
        memcpy(c->prev, c->thumb, sizeof c->prev);
        c->have_prev = 1;
    }

    /* 2. detections -> tracks (one-to-one per frame: overlapping people must keep separate covers) */
    for (int i = 0; i < c->nt; i++) c->t[i].matched = 0;
    for (int k = 0; k < n; k++) {
        const im_vrect *d = &dets[k];
        if (d->kind == IM_VK_FULL) {
            double hold = c->covers_visible ? 2 * p->full_hold_ms : p->full_hold_ms;
            if (t_ms + hold > c->full_until) c->full_until = t_ms + hold;
            continue;
        }
        if (d->kind == IM_VK_CLEAR) continue; /* a man: never refreshes a cover, so flickering labels stay covered */
        int best = -1;
        float bo = 0.2f;
        for (int i = 0; i < c->nt; i++) {
            if (c->t[i].matched && !c->covers_visible) continue;
            float o = overlap(d, &c->t[i].r);
            if (o > bo || (best < 0 && center_in(d, &c->t[i].r))) { bo = o > bo ? o : bo; best = i; }
        }
        if (best < 0 && !c->covers_visible) {
            /* fast mover: no overlap with its last box, but a track of similar size within one body width */
            float dw = d->x1 - d->x0, dh = d->y1 - d->y0, bd = 1e9f;
            for (int i = 0; i < c->nt; i++) {
                const im_vrect *r = &c->t[i].r;
                if (c->t[i].matched) continue;
                float rw = r->x1 - r->x0, rh = r->y1 - r->y0;
                if (rw < 0.6f * dw || rw > 1.6f * dw || rh < 0.6f * dh || rh > 1.6f * dh) continue;
                float dx = (d->x0 + d->x1 - r->x0 - r->x1) / 2, dy = (d->y0 + d->y1 - r->y0 - r->y1) / 2;
                float dist = sqrtf(dx * dx + dy * dy);
                if (dist < fmaxf(dw, rw) * 1.2f && dist < bd) { bd = dist; best = i; }
            }
        }
        if (best >= 0) {
            track *tr = &c->t[best];
            if (c->covers_visible) {
                tr->r.x0 = fminf(tr->r.x0, d->x0); tr->r.y0 = fminf(tr->r.y0, d->y0);
                tr->r.x1 = fmaxf(tr->r.x1, d->x1); tr->r.y1 = fmaxf(tr->r.y1, d->y1);
            } else {
                double dt = t_ms - tr->last_seen;
                if (dt > 1 && dt < 1000) {
                    float vx = (float)(((d->x0 + d->x1) - (tr->r.x0 + tr->r.x1)) / 2 / dt);
                    float vy = (float)(((d->y0 + d->y1) - (tr->r.y0 + tr->r.y1)) / 2 / dt);
                    float k = tr->nv ? 0.5f : 1.0f; /* the first measurement is taken as is */
                    tr->vx = (1 - k) * tr->vx + k * vx;
                    tr->vy = (1 - k) * tr->vy + k * vy;
                    tr->nv = 1;
                }
                int kind = tr->r.kind;
                tr->r = *d;
                tr->r.kind = stricter(kind, d->kind);
            }
            /* the outline of this detection, or none (the whole rectangle) */
            tr->sh.rows = 0;
            if (shapes && !c->covers_visible) tr->sh = shapes[k];
            tr->last_seen = t_ms;
            tr->matched = 1;
        } else {
            int o = c->nt;
            if (c->nt < MAX_TRACKS) c->nt++;
            else /* full: replace the oldest */
                for (int i = o = 0; i < c->nt; i++) if (c->t[i].last_seen < c->t[o].last_seen) o = i;
            c->t[o] = (track){*d, t_ms, 0, 0, 1, 0, {0}};
            if (shapes && !c->covers_visible) c->t[o].sh = shapes[k];
        }
    }

    /* 3. expiry (only when the capture shows what is under the covers) */
    if (!c->covers_visible)
        for (int i = c->nt - 1; i >= 0; i--)
            if (t_ms - c->t[i].last_seen > p->hold_ms) drop(c, i);

    /* 4. output: the whole-frame cover, then rectangle covers (close ones joined), then outlined people as strips
     * (or their rectangle when out has no room for all of them), then bridges between outlined people and their
     * close neighbours */
    int m = 0, nu = 0;
    if (t_ms < c->full_until) out[m++] = (im_vrect){0, 0, 1, 1, IM_VK_FULL, 1, -1};
    for (int i = 0; i < c->nt && m < max; i++) {
        im_vrect r = c->t[i].r, b = r;
        float bw = r.x1 - r.x0, bh = r.y1 - r.y0, lx = 0, ly = 0;
        float mx = fmaxf(p->margin * bw, p->margin_min), my = fmaxf(p->margin * bh, p->margin_min);
        r.x0 -= mx; r.x1 += mx; r.y0 -= my; r.y1 += my;
        if (!c->covers_visible) {
            /* cover where the person is now (motion since the frame) and where they were */
            lx = c->t[i].vx * (float)(p->lead_ms + (t_ms - c->t[i].last_seen));
            ly = c->t[i].vy * (float)(p->lead_ms + (t_ms - c->t[i].last_seen));
            lx = fmaxf(-0.3f, fminf(0.3f, lx));
            ly = fmaxf(-0.3f, fminf(0.3f, ly));
            if (lx < 0) r.x0 += lx; else r.x1 += lx;
            if (ly < 0) r.y0 += ly; else r.y1 += ly;
        }
        r.x0 = fmaxf(0, r.x0); r.y0 = fmaxf(0, r.y0); r.x1 = fminf(1, r.x1); r.y1 = fminf(1, r.y1);
        if (r.x1 <= r.x0 || r.y1 <= r.y0) continue;
        int ns = c->covers_visible ? 0 : strips_of(p, &b, &c->t[i].sh, lx, ly, &r, c->strip[nu]);
        if (ns > 0) {
            c->unit_rect[nu] = r;
            c->unit_n[nu++] = ns;
        } else out[m++] = r;
    }
    m = merge_close(out, m, p->merge_gap);
    int n_ext = 0;
    for (int i = 0; i < m; i++)
        if (out[i].kind != IM_VK_FULL) {
            c->ext[n_ext] = c->ext_rect[n_ext] = out[i];
            c->ext_outlined[n_ext++] = 0;
        }
    for (int u = 0; u < nu && m < max; u++) {
        const im_vrect *s = c->strip[u];
        int ns = c->unit_n[u];
        if (m + ns > max) { /* no room for the whole outline: never a partial one */
            out[m++] = c->unit_rect[u];
            c->ext[n_ext] = c->ext_rect[n_ext] = c->unit_rect[u];
            c->ext_outlined[n_ext++] = 0;
            continue;
        }
        im_vrect e = s[0];
        for (int k = 0; k < ns; k++) {
            out[m++] = s[k];
            e.x0 = fminf(e.x0, s[k].x0); e.y0 = fminf(e.y0, s[k].y0);
            e.x1 = fmaxf(e.x1, s[k].x1); e.y1 = fmaxf(e.y1, s[k].y1);
        }
        c->ext[n_ext] = e;
        c->ext_rect[n_ext] = c->unit_rect[u];
        c->ext_outlined[n_ext++] = 1;
    }
    if (p->bridge_gap > 0)
        for (int i = 0; i < n_ext && m < max; i++)
            for (int j = i + 1; j < n_ext && m < max; j++) {
                if (!c->ext_outlined[i] && !c->ext_outlined[j]) continue;
                /* close as rectangles (as merge_gap judges them); the bridge spans what is drawn */
                if (!close_to(&c->ext_rect[i], &c->ext_rect[j], p->bridge_gap)) continue;
                im_vrect r = bridge(&c->ext[i], &c->ext[j]);
                if (r.x1 > r.x0 && r.y1 > r.y0) out[m++] = r;
            }
    memcpy(c->out_prev, c->out_last, sizeof c->out_prev);
    c->n_prev = c->n_last;
    c->n_last = m < MAX_OUT ? m : MAX_OUT;
    memcpy(c->out_last, out, sizeof(im_vrect) * c->n_last);
    c->t_last = t_ms;
    return m;
}
