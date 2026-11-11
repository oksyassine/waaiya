/* Screen blur ("modesty blur"): finds what to cover in a captured screen frame.
 *
 * Two parts, both plain C on the ONNX Runtime C API (same code on Android, Linux, desktop ports):
 *   im_vision  runs the models on one RGBA frame: person detector -> per-person woman/man classifier, and a
 *              frame-level nudity classifier; optionally a person segmenter gives each covered person an outline
 *              (im_vshape). Models follow the `im.vision = 1` contract (models/vision/export_vision.py).
 *   im_cover   turns detections over time into the rectangles to draw: margins, motion lead, hold times, and,
 *              when our own covers show up in the capture, keeps them until the scene changes. A person with an
 *              outline is drawn as a stack of horizontal strips that follow the body, so text beside them stays
 *              readable; without one (no segmenter, a model error, an implausible mask) as the whole rectangle.
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
/* flag OR-ed into the kind of an im_cover output rect that is one piece of a larger shape (a strip of an outline, or a
 * bridge): draw it with square corners, so the pieces read as one shape */
#define IM_VK_PART 16

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
    const char *seg_model;    /* optional person segmenter: outlines instead of rectangles (NULL = rectangles) */
} im_vision_config;

typedef struct {
    float person_score;  /* detector threshold (default 0.10: low, recall first; eval_blur.py) */
    float nms_iou;       /* default 0.5 */
    float male_clear;    /* a person is left clear only when p(man or boy) >= this (default 0.999, for gender_v2.onnx: eval/results/blur_gender_v2.md) */
    float nsfw_score;    /* frame covered when p(nsfw) >= this (default 0.6) */
    int max_people;      /* people classified per frame, largest first; the rest are covered (default 12) */
    int tiles;           /* elongated frames (a phone held upright): the person detector also runs on up to this many
                            overlapping square tiles along the long side, where small people appear about twice as
                            large as in the whole frame (0 = whole frame only; default 3: eval/results/blur_tiles.md) */
    int tiles_per_frame; /* tiles run per call, taking turns (0 = all every call). Fewer is faster; the cover tracker
                            holds a person between the frames that see them (hold_ms) */
    float nest;          /* a box with at least this fraction inside a kept, higher-scoring box of at least half its
                            area is the same person seen twice (whole frame and a tile, or a body part) and dropped;
                            smaller boxes inside a big one (a child in front of an adult) are kept. 0 = off (default:
                            it barely triggers, eval/results/blur_tiles.md) */
    float tile_score;    /* detector threshold inside tiles when above person_score (default 0 = person_score: higher
                            values leave more men clear but lose more small women, eval/results/blur_tiles.md) */
    int seg;             /* 1 = outline the covered people with the segmenter (when loaded), 0 = rectangles (default 1) */
    float seg_threshold; /* a pixel is part of the person when p(person) >= this: low, so covering wins (default 0.15:
                            eval/results/blur_silhouette.md) */
    float seg_min_fill;  /* an outline covering less than this share of the person's box is not trusted: the whole
                            rectangle is covered instead (default 0.25: eval/results/blur_silhouette.md) */
    int seg_max_people;  /* covered people outlined per frame, largest first; smaller ones get their rectangle (default
                            6: about 7-11 ms per person on one x86 core, eval/results/blur_silhouette.md) */
    int seg_min_px;      /* people shorter than this (frame pixels) keep their rectangle: too few pixels to outline
                            (default 48: 96 gives the same coverage on photos but outlines half as many people in
                            a portrait frame, where people are small; eval/results/blur_silhouette.md) */
} im_vision_params;

/* Outline of one person, relative to their box (0,0 = box top-left, 1,1 = box bottom-right; values outside 0..1
 * are outside the box, in the context the segmenter saw). rows = 0: no outline, cover the whole rectangle. */
#define IM_SHAPE_ROWS 16
#define IM_SHAPE_OPEN_TOP 1u    /* the body continues above the top row (cut by the segmenter's crop) */
#define IM_SHAPE_OPEN_BOTTOM 2u /* ... below the bottom row */
typedef struct {
    int rows;
    unsigned flags;
    float y0, y1;                /* the rows split y0..y1 evenly */
    float l[IM_SHAPE_ROWS];      /* per row: leftmost and rightmost covered x; l > r = nothing in that row */
    float r[IM_SHAPE_ROWS];
} im_vshape;

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
/* Same, and shapes[i] = the outline of out[i] (rows = 0 when it has none: men left clear, people past max_people, no
 * segmenter, a model error, a mask that fills too little of the box). shapes = NULL: no segmentation is run. */
IM_VAPI int im_vision_detect_shapes(im_vision *v, const uint8_t *rgba, int w, int h, int stride, int run_nsfw,
                                    im_vrect *out, im_vshape *shapes, int max);
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
    float merge_gap;     /* covers closer than this fraction of the smaller one's height are drawn as one, so the
                          * gaps in a group (where a missed person often is) are covered too (default 0.30: eval/results/blur.md; 0 = off).
                          * Only rectangle covers are joined this way; outlined people are joined by bridges (bridge_gap) */
    float strip_margin;  /* outlined people: border added around each strip, fraction of the person's size (default 0.05);
                          * strips never reach past the rectangle the person would get without an outline */
    float bridge_gap;    /* an outlined person and another cover closer than this fraction of the smaller one's height
                          * get a bridge: a rect over the space between them, at the height they share (default 0.30; 0 = off) */
    float open_reach;    /* outlined people whose body goes on past the top or bottom of the segmenter's crop (a box cut
                          * short by the detector): that end strip reaches this fraction of their height past the box,
                          * further than the rectangle would (default 0.80: eval/results/blur_silhouette.md) */
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
/* Same, with an outline per detection (im_vision_detect_shapes; shapes may be NULL). An outlined person is written as
 * up to IM_SHAPE_ROWS strip rects of their kind; when out has no room for all of a person's strips, their whole
 * rectangle is written instead. Outlines are ignored when covers_visible (the capture shows our covers there). */
IM_VAPI int im_cover_update_shapes(im_cover *c, double t_ms, const uint8_t *rgba, int w, int h, int stride,
                                   const im_vrect *dets, const im_vshape *shapes, int n, im_vrect *out, int max);

#ifdef __cplusplus
}
#endif
#endif
