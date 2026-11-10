/* Screen blur ("modesty blur"): finds what to cover in a captured screen frame.
 *
 * Two parts, both plain C on the ONNX Runtime C API (same code on Android, Linux, desktop ports):
 *   im_vision  runs the models on one RGBA frame: person detector -> per-person woman/man classifier, and a
 *              frame-level nudity classifier. Models follow the `im.vision = 1` contract
 *              (models/vision/export_vision.py).
 *   im_cover   turns detections over time into the rectangles to draw: margins, motion lead, hold times, and,
 *              when our own covers show up in the capture, keeps them until the scene changes.
 *
 * Fail-closed rules (the user's choice, see docs): a person the classifier cannot confidently call a man is
 * covered; without a gender model every person is covered; a model that fails to load is reported so the caller
 * can apply the user's "cover the screen" / "warn" setting.
 * Coordinates are normalised to the frame: 0..1, origin top-left. */
#ifndef IM_VISION_H
#define IM_VISION_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32)
#define IM_VAPI __declspec(dllexport)
#else
#define IM_VAPI __attribute__((visibility("default")))
#endif

/* policy bits */
#define IM_VISION_WOMEN 1u /* cover women (and people not confidently men) */
#define IM_VISION_NSFW  2u /* cover nudity / immodest frames, anyone */

/* rect kinds */
enum { IM_VK_CLEAR = 0, IM_VK_WOMAN = 1, IM_VK_UNSURE = 2, IM_VK_NSFW = 3, IM_VK_FULL = 4 };

typedef struct {
    float x0, y0, x1, y1;
    int kind;
    float score; /* detector score (people) or nudity probability (FULL) */
    float p_male; /* classifier: probability of man or boy, -1 when not classified */
} im_vrect;

typedef struct {
    const char *person_model; /* required when policy has IM_VISION_WOMEN */
    const char *gender_model; /* optional: without it every person is covered */
    const char *nsfw_model;   /* required when policy has IM_VISION_NSFW */
    int threads;              /* ONNX Runtime intra-op threads per model (default 2) */
    unsigned policy;
} im_vision_config;

typedef struct {
    float person_score;  /* detector threshold (default 0.10: low, recall first; eval_blur.py) */
    float nms_iou;       /* default 0.5 */
    float male_clear;    /* a person is left clear only when p(man or boy) >= this (default 0.85) */
    float nsfw_score;    /* frame covered when p(nsfw) >= this (default 0.6) */
    int max_people;      /* people classified per frame, largest first; the rest are covered (default 12) */
} im_vision_params;

typedef struct im_vision im_vision;

/* Never returns NULL unless out of memory; check im_vision_status() for missing models. */
IM_VAPI im_vision *im_vision_create(const im_vision_config *cfg, char *err, size_t errlen);
IM_VAPI void im_vision_destroy(im_vision *v);
IM_VAPI void im_vision_set_policy(im_vision *v, unsigned policy);
IM_VAPI void im_vision_get_params(const im_vision *v, im_vision_params *p);
IM_VAPI void im_vision_set_params(im_vision *v, const im_vision_params *p);
/* Bits of the policy that cannot be served (model missing or failed). 0 = all good. */
IM_VAPI unsigned im_vision_status(const im_vision *v);
IM_VAPI const char *im_vision_error(const im_vision *v);

/* Runs the models on one frame (RGBA8888, row stride in bytes). run_nsfw = 0 skips the (slower) nudity model on
 * this frame. Writes up to max rects (people with their kind, IM_VK_CLEAR included so callers can score them,
 * plus one IM_VK_FULL when the frame is judged immodest). Returns the count, or -1 on failure. */
IM_VAPI int im_vision_detect(im_vision *v, const uint8_t *rgba, int w, int h, int stride, int run_nsfw,
                             im_vrect *out, int max);
/* Last nudity probability (-1 = never run). */
IM_VAPI float im_vision_last_nsfw(const im_vision *v);

/* ---- tracker ---- */
typedef struct im_cover im_cover;

typedef struct {
    float margin;        /* extra border around a person, fraction of the person's size (default 0.20) */
    float margin_min;    /* and at least this fraction of the frame (default 0.015) */
    float lead_ms;       /* covers are moved ahead by the measured motion over this time (default 120) */
    float hold_ms;       /* keep a cover this long after the person was last seen (default 500) */
    float full_hold_ms;  /* same for a whole-frame (nudity) cover (default 1500) */
    float cut_level;     /* mean thumbnail change (0..1) that counts as a scene change (default 0.12) */
} im_cover_params;

/* covers_visible = 1 when our own covers appear in the captured frames (the overlay could not be excluded from
 * the capture): covers are then kept until the scene changes or scrolls them away, since what is under them
 * cannot be seen. 0 = the capture shows the real content under the covers. */
IM_VAPI im_cover *im_cover_create(int covers_visible);
IM_VAPI void im_cover_destroy(im_cover *c);
IM_VAPI void im_cover_get_params(const im_cover *c, im_cover_params *p);
IM_VAPI void im_cover_set_params(im_cover *c, const im_cover_params *p);
IM_VAPI void im_cover_reset(im_cover *c);
/* One frame: t_ms its capture time, dets/n the im_vision_detect output for it (or n = -1 when the models were not
 * run on this frame: tracks are only moved/held). The frame is used for scene-change and scroll detection.
 * Writes the rects to draw now (kind WOMAN / UNSURE / NSFW / FULL). Returns their count. */
IM_VAPI int im_cover_update(im_cover *c, double t_ms, const uint8_t *rgba, int w, int h, int stride,
                            const im_vrect *dets, int n, im_vrect *out, int max);

#ifdef __cplusplus
}
#endif
#endif
