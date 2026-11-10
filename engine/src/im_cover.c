/* Screen blur tracker: detections over time -> rectangles to draw. See im_vision.h.
 *
 * Two situations:
 *  - covers not visible in the capture (the overlay is excluded from screen capture): every frame shows the real
 *    content, so covers follow the detections, are moved ahead by the measured motion (the overlay is drawn
 *    ~100 ms after the frame was captured), and are held a little after a missed detection.
 *  - covers visible in the capture: what is under a cover cannot be seen any more. A cover then stays until the
 *    uncovered part of the screen shows a scene change, or a scroll moves it off screen; a person stepping out of
 *    a cover makes it grow. Over-covering is preferred to uncovering a woman to check whether she is still there.
 */
#include <math.h>
#include <stdlib.h>
#include <string.h>

#include "im_vision.h"

#define TW 32
#define TH 48 /* thumbnail cells, portrait-ish; only used as a grid */
#define MAX_TRACKS 48
#define MAX_OUT 64
#define SHIFT 6

typedef struct {
    im_vrect r;
    double last_seen;
    float vx, vy; /* centre velocity, frame units per ms */
    int matched;  /* took a detection in this update: one detection per track per frame */
    int nv;       /* has a velocity measurement */
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
    double full_until;
    double t_last;
};

im_cover *im_cover_create(int covers_visible) {
    im_cover *c = calloc(1, sizeof *c);
    if (!c) return NULL;
    c->covers_visible = covers_visible;
    c->p = (im_cover_params){0.20f, 0.015f, 120.0f, 500.0f, 1500.0f, 0.12f, 0.30f};
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

int im_cover_update(im_cover *c, double t_ms, const uint8_t *rgba, int w, int h, int stride, const im_vrect *dets,
                    int n, im_vrect *out, int max) {
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
            tr->last_seen = t_ms;
            tr->matched = 1;
        } else if (c->nt < MAX_TRACKS) {
            c->t[c->nt++] = (track){*d, t_ms, 0, 0, 1, 0};
        } else { /* full: replace the oldest */
            int o = 0;
            for (int i = 1; i < c->nt; i++) if (c->t[i].last_seen < c->t[o].last_seen) o = i;
            c->t[o] = (track){*d, t_ms, 0, 0, 1, 0};
        }
    }

    /* 3. expiry (only when the capture shows what is under the covers) */
    if (!c->covers_visible)
        for (int i = c->nt - 1; i >= 0; i--)
            if (t_ms - c->t[i].last_seen > p->hold_ms) drop(c, i);

    /* 4. output */
    int m = 0;
    if (t_ms < c->full_until) out[m++] = (im_vrect){0, 0, 1, 1, IM_VK_FULL, 1, -1};
    for (int i = 0; i < c->nt && m < max; i++) {
        im_vrect r = c->t[i].r;
        float bw = r.x1 - r.x0, bh = r.y1 - r.y0;
        float mx = fmaxf(p->margin * bw, p->margin_min), my = fmaxf(p->margin * bh, p->margin_min);
        r.x0 -= mx; r.x1 += mx; r.y0 -= my; r.y1 += my;
        if (!c->covers_visible) {
            /* cover where the person is now (motion since the frame) and where they were */
            float lx = c->t[i].vx * (float)(p->lead_ms + (t_ms - c->t[i].last_seen));
            float ly = c->t[i].vy * (float)(p->lead_ms + (t_ms - c->t[i].last_seen));
            lx = fmaxf(-0.3f, fminf(0.3f, lx));
            ly = fmaxf(-0.3f, fminf(0.3f, ly));
            if (lx < 0) r.x0 += lx; else r.x1 += lx;
            if (ly < 0) r.y0 += ly; else r.y1 += ly;
        }
        r.x0 = fmaxf(0, r.x0); r.y0 = fmaxf(0, r.y0); r.x1 = fminf(1, r.x1); r.y1 = fminf(1, r.y1);
        if (r.x1 > r.x0 && r.y1 > r.y0) out[m++] = r;
    }
    m = merge_close(out, m, p->merge_gap);
    memcpy(c->out_prev, c->out_last, sizeof c->out_prev);
    c->n_prev = c->n_last;
    c->n_last = m < MAX_OUT ? m : MAX_OUT;
    memcpy(c->out_last, out, sizeof(im_vrect) * c->n_last);
    c->t_last = t_ms;
    return m;
}
