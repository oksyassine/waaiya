/* Screen-blur tracker (im_cover), covers visible in the capture (app-overlay host):
 *  1. a cover that hides most of the screen (the scene change cannot be seen) lifts after blind_hold_ms, and the
 *     next frame is judged afresh; seen again right after, the next wait doubles (up to blind_max_hold_ms)
 *  2. a small cover on a still screen stays (what is under it cannot be seen; the uncovered part says nothing changed)
 * Usage: test-cover (no model needed) */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "im_vision.h"

static int fails;
#define CHECK(c, msg) do { if (c) printf("ok: %s\n", msg); else { printf("FAIL: %s\n", msg); fails++; } } while (0)

enum { W = 96, H = 160 };
static uint8_t frame[W * H * 4];

/* frames every 100 ms from t0 to t1 with no detection; returns the time the person covers were gone (-1: never) */
static double run_until_gone(im_cover *c, double t0, double t1) {
    im_vrect out[256];
    for (double t = t0; t <= t1; t += 100) {
        int n = im_cover_update(c, t, frame, W, H, W * 4, NULL, 0, out, 256);
        int people = 0;
        for (int i = 0; i < n; i++) if (out[i].kind != IM_VK_FULL) people++;
        if (!people) return t;
    }
    return -1;
}

static int detect(im_cover *c, double t, float x0, float y0, float x1, float y1) {
    im_vrect d = {x0, y0, x1, y1, IM_VK_WOMAN, 0.9f, 0.05f}, out[256];
    return im_cover_update(c, t, frame, W, H, W * 4, &d, 1, out, 256);
}

int main(void) {
    for (int i = 0; i < W * H; i++) {  /* a fixed picture: what the capture shows, still */
        frame[i * 4] = (uint8_t)(i * 37); frame[i * 4 + 1] = (uint8_t)(i * 11); frame[i * 4 + 2] = (uint8_t)(i * 5);
        frame[i * 4 + 3] = 255;
    }
    im_cover *c = im_cover_create(1);
    im_cover_params p;
    im_cover_get_params(c, &p);
    printf("blind hold %.0f ms, at most %.0f ms\n", p.blind_hold_ms, p.blind_max_hold_ms);

    /* 1. a person filling the screen */
    CHECK(detect(c, 0, 0.05f, 0.05f, 0.95f, 0.95f) >= 1, "a large cover");
    double gone = run_until_gone(c, 100, 60000);
    printf("large cover, nothing new detected: lifted at %.0f ms\n", gone);
    CHECK(gone >= p.blind_hold_ms && gone <= p.blind_hold_ms + 400, "it lifts after the blind hold, not before");
    /* seen again on the next frame: covered at once; the next wait doubles */
    CHECK(detect(c, gone + 100, 0.05f, 0.05f, 0.95f, 0.95f) >= 1, "seen again: covered again at once");
    double gone2 = run_until_gone(c, gone + 200, gone + 60000);
    printf("again: lifted %.0f ms later\n", gone2 - gone);
    CHECK(gone2 - (gone + 100) >= 2 * p.blind_hold_ms, "seen again right after: the wait doubles");
    double t = gone2;
    double last = 0;
    for (int k = 0; k < 6; k++) {   /* keeps being seen: the wait grows to the cap and stays there */
        detect(c, t + 100, 0.05f, 0.05f, 0.95f, 0.95f);
        double g = run_until_gone(c, t + 200, t + 120000);
        last = g - (t + 100);
        t = g;
    }
    printf("after many: wait %.0f ms\n", last);
    CHECK(last >= p.blind_max_hold_ms && last <= p.blind_max_hold_ms + 400, "the wait stops at blind_max_hold_ms");
    /* not seen again for a while: back to the short wait */
    detect(c, t + 3 * p.blind_max_hold_ms, 0.05f, 0.05f, 0.95f, 0.95f);
    double g = run_until_gone(c, t + 3 * p.blind_max_hold_ms + 100, t + 10 * p.blind_max_hold_ms);
    CHECK(g - (t + 3 * p.blind_max_hold_ms) <= p.blind_hold_ms + 400, "a new episode starts with the short wait again");

    /* 2. a small cover on a still screen stays */
    im_cover_reset(c);
    CHECK(detect(c, 0, 0.40f, 0.40f, 0.55f, 0.60f) >= 1, "a small cover");
    CHECK(run_until_gone(c, 100, 60000) < 0, "small cover, still screen: kept for a minute (the scene can be judged)");

    /* off: blind_hold_ms = 0 keeps the old behaviour */
    im_cover_reset(c);
    p.blind_hold_ms = 0;
    im_cover_set_params(c, &p);
    detect(c, 0, 0.05f, 0.05f, 0.95f, 0.95f);
    CHECK(run_until_gone(c, 100, 60000) < 0, "blind_hold_ms 0: the large cover is never lifted (as before)");
    im_cover_destroy(c);
    printf(fails ? "%d FAILED\n" : "all passed\n", fails);
    return fails ? 1 : 0;
}
