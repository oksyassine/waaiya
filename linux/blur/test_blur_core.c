/* Unit tests for im-blur's pure parts (blur_core.c): make test-blur */
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "blur_core.h"

static int fails, checks;
#define CHECK(c)                                                                                                   \
    do {                                                                                                           \
        checks++;                                                                                                  \
        if (!(c)) { fails++; fprintf(stderr, "%s:%d: FAILED %s\n", __FILE__, __LINE__, #c); }                    \
    } while (0)
#define CHECK_INT(a, b)                                                                                            \
    do {                                                                                                           \
        long long a_ = (a), b_ = (b);                                                                              \
        checks++;                                                                                                  \
        if (a_ != b_) { fails++; fprintf(stderr, "%s:%d: %s = %lld, want %lld\n", __FILE__, __LINE__, #a, a_, b_); } \
    } while (0)

static void test_scale(void) {
    int w, h;
    ib_scale_size(1920, 1080, 640, &w, &h); CHECK_INT(w, 640); CHECK_INT(h, 360);
    ib_scale_size(1366, 768, 640, &w, &h); CHECK_INT(w, 640); CHECK_INT(h, 358);
    ib_scale_size(1080, 1920, 640, &w, &h); CHECK_INT(w, 360); CHECK_INT(h, 640);
    ib_scale_size(500, 301, 640, &w, &h); CHECK_INT(w, 500); CHECK_INT(h, 300); /* never enlarged, even sizes */
    ib_scale_size(3840, 2160, 640, &w, &h); CHECK_INT(w, 640); CHECK_INT(h, 360);
}

static void test_layout(void) {
    ib_layout l;
    CHECK(ib_layout_from_masks(0xff0000, 0xff00, 0xff, &l));
    CHECK_INT(l.r, 16); CHECK_INT(l.g, 8); CHECK_INT(l.b, 0);
    CHECK(ib_layout_from_masks(0xff, 0xff00, 0xff0000, &l));
    CHECK_INT(l.r, 0); CHECK_INT(l.b, 16);
    CHECK(!ib_layout_from_masks(0xf800, 0x7e0, 0x1f, &l)); /* 16-bit visual: not supported */
    CHECK(!ib_layout_from_masks(0xff, 0xff, 0xff00, &l));
    CHECK_INT(ib_pixel(0x112233, (ib_layout){16, 8, 0}, 0xff000000u), 0xff112233u);
    CHECK_INT(ib_pixel(0x112233, (ib_layout){0, 8, 16}, 0), 0x332211u);
}

static void test_downscale(void) {
    /* 6x4 X11 pixels (0x00RRGGBB, i.e. bytes B,G,R,X in memory): left half red, right half blue, bottom row green */
    uint32_t src[6 * 4];
    for (int y = 0; y < 4; y++)
        for (int x = 0; x < 6; x++) src[y * 6 + x] = y == 3 ? 0x00ff00u : (x < 3 ? 0xff0000u : 0x0000ffu);
    uint8_t *bytes = (uint8_t *)src;
    CHECK_INT(bytes[2], 0xff); /* red byte third: BGRX */
    uint8_t dst[2 * 2 * 4];
    ib_downscale((uint8_t *)src, 6, 4, 6 * 4, (ib_layout){16, 8, 0}, dst, 2, 2, 2 * 4);
    CHECK_INT(dst[0], 255); CHECK_INT(dst[1], 0); CHECK_INT(dst[2], 0); CHECK_INT(dst[3], 255); /* top-left red */
    CHECK_INT(dst[4], 0); CHECK_INT(dst[6], 255);                                             /* top-right blue */
    /* bottom-left: rows 2 (red) and 3 (green), averaged */
    CHECK_INT(dst[8], 127); CHECK_INT(dst[9], 127); CHECK_INT(dst[10], 0);
    /* same picture as RGBX bytes (PipeWire RGBx): layout r=0 */
    uint32_t rgbx[6 * 4];
    for (int i = 0; i < 24; i++) rgbx[i] = ib_pixel(src[i], (ib_layout){0, 8, 16}, 0);
    uint8_t d2[16];
    ib_downscale((uint8_t *)rgbx, 6, 4, 24, (ib_layout){0, 8, 16}, d2, 2, 2, 8);
    CHECK(!memcmp(dst, d2, sizeof d2));
    CHECK(ib_has_magenta((const uint8_t[]){255, 0, 255, 255}, 1, 1, 4, 0.5f, 0.5f));
    CHECK(!ib_has_magenta((const uint8_t[]){255, 0, 0, 255}, 1, 1, 4, 0.5f, 0.5f));
    CHECK(!ib_has_magenta((const uint8_t[]){255, 0, 255, 255}, 1, 1, 4, 1.5f, 0.5f)); /* outside */
}

static uint8_t *solid(int w, int h, uint8_t r, uint8_t g, uint8_t b) {
    uint8_t *f = malloc((size_t)w * h * 4);
    for (int i = 0; i < w * h; i++) { f[i * 4] = r; f[i * 4 + 1] = g; f[i * 4 + 2] = b; f[i * 4 + 3] = 255; }
    return f;
}

static void test_thumb_and_cells(void) {
    ib_thumb t;
    CHECK(ib_thumb_init(&t, 640, 360));
    CHECK_INT(t.w, IB_THUMB_W); CHECK_INT(t.h, 90);
    uint32_t cells[4];
    im_vrect all = {0, 0, 1, 1, IM_VK_WOMAN, 1, -1};
    ib_cells(&t, &all, 2, 2, cells);
    CHECK_INT(cells[0], 0x808080); /* nothing seen yet: neutral grey */
    uint8_t *red = solid(640, 360, 200, 0, 0), *blue = solid(640, 360, 0, 0, 200);
    ib_thumb_update(&t, red, 640, 360, 640 * 4, NULL, 0);
    /* a cover over the left half: the capture now shows the cover (blue here); the cells under it keep red */
    im_vrect left = {0, 0, 0.5f, 1, IM_VK_WOMAN, 1, -1};
    ib_thumb_update(&t, blue, 640, 360, 640 * 4, &left, 1);
    ib_cells(&t, &all, 2, 1, cells);
    CHECK_INT(cells[0], 0xc80000); /* left: still the colour from before the cover */
    CHECK_INT(cells[1], 0x0000c8); /* right: uncovered, follows the screen */
    im_vrect q = {0.5f, 0, 1, 0.5f, IM_VK_WOMAN, 1, -1};
    ib_cells(&t, &q, 1, 1, cells);
    CHECK_INT(cells[0], 0x0000c8);
    ib_thumb_free(&t);
    free(red); free(blue);

    int nx, ny;
    ib_cell_count(300, 900, 54, &nx, &ny); CHECK_INT(nx, 6); CHECK_INT(ny, IB_MAX_CELLS);
    ib_cell_count(10, 10, 54, &nx, &ny); CHECK_INT(nx, 1); CHECK_INT(ny, 1);
}

static void test_draw(void) {
    uint32_t buf[100 * 10];
    memset(buf, 0, sizeof buf);
    uint32_t cells[2] = {0xff0000, 0x0000ff};
    ib_layout l = {16, 8, 0};
    ib_draw_cells(buf, 100, (ib_rect){0, 0, 100, 10}, cells, 2, 1, l, 0);
    /* left end: red with Android's tint argb(120,30,30,30): 255*135/255 + 30*120/255 = 149; 30*120/255 = 14 */
    CHECK_INT(buf[0], (149u << 16) | (14u << 8) | 14u);
    CHECK_INT(buf[99], (14u << 16) | (14u << 8) | 149u);
    /* middle: half way between the two cell centres */
    uint32_t mid = buf[50];
    CHECK((mid >> 16 & 255) > 70 && (mid >> 16 & 255) < 95 && (mid & 255) > 70 && (mid & 255) < 95);
    /* monotonic red fall-off from the left cell centre to the right one */
    int mono = 1;
    for (int x = 26; x < 75; x++) mono &= (buf[x] >> 16 & 255) <= (buf[x - 1] >> 16 & 255);
    CHECK(mono);
    /* drawing stays inside the rect */
    memset(buf, 0, sizeof buf);
    ib_draw_cells(buf, 100, (ib_rect){10, 2, 20, 3}, cells, 2, 1, l, 0xff000000u);
    CHECK_INT(buf[2 * 100 + 9], 0); CHECK(buf[2 * 100 + 10] != 0); CHECK_INT(buf[2 * 100 + 30], 0);
    CHECK_INT(buf[1 * 100 + 15], 0); CHECK_INT(buf[5 * 100 + 15], 0); CHECK(buf[4 * 100 + 15] >> 24 == 0xff);
}

static void test_rects(void) {
    im_vrect r[3] = {{0.1f, 0.2f, 0.5f, 0.6f, IM_VK_WOMAN, 1, -1},
                     {-0.2f, -0.1f, 0.05f, 0.1f, IM_VK_UNSURE, 1, -1},
                     {0.7f, 0.7f, 0.7f, 0.9f, IM_VK_WOMAN, 1, -1}}; /* empty: dropped */
    ib_rect p[4];
    int n = ib_to_pixels(r, 3, 1920, 1080, p, 4);
    CHECK_INT(n, 2);
    CHECK_INT(p[0].x, 192); CHECK_INT(p[0].y, 216); CHECK_INT(p[0].w, 768); CHECK_INT(p[0].h, 432);
    CHECK_INT(p[1].x, 0); CHECK_INT(p[1].y, 0); CHECK_INT(p[1].w, 96); CHECK_INT(p[1].h, 108);
    ib_rect u = ib_union(p, n);
    CHECK_INT(u.x, 0); CHECK_INT(u.y, 0); CHECK_INT(u.w, 960); CHECK_INT(u.h, 648);
    CHECK(ib_rects_equal(p, 2, p, 2));
    ib_rect q[2] = {p[0], p[1]};
    q[1].w++;
    CHECK(!ib_rects_equal(p, 2, q, 2));
    CHECK(!ib_rects_equal(p, 2, p, 1));
    CHECK(ib_rects_equal(NULL, 0, NULL, 0));
    /* a few hundred thin rects (body-shaped covers) pass through unchanged */
    im_vrect many[IB_MAX_RECTS];
    for (int i = 0; i < IB_MAX_RECTS; i++)
        many[i] = (im_vrect){0.1f, i / (float)IB_MAX_RECTS, 0.2f, (i + 1) / (float)IB_MAX_RECTS, IM_VK_WOMAN, 1, -1};
    static ib_rect pm[IB_MAX_RECTS];
    CHECK_INT(ib_to_pixels(many, IB_MAX_RECTS, 1920, 1080, pm, IB_MAX_RECTS), IB_MAX_RECTS);
}

static void test_paint(void) {
    im_vrect c[2] = {{0.1f, 0.1f, 0.3f, 0.5f, IM_VK_WOMAN, 1, -1}, {0, 0, 1, 1, IM_VK_FULL, 1, -1}};
    ib_paint p[8];
    int n = ib_layout_paint(c, 2, 1000, 500, IB_FAIL_NONE, 0, 24, 6, p, 8);
    CHECK_INT(n, 2);
    CHECK_INT(p[0].kind, IB_PK_COVER); CHECK_INT(p[0].index, 0);
    CHECK_INT(p[1].kind, IB_PK_FULL); CHECK_INT(p[1].r.w, 1000); CHECK_INT(p[1].r.h, 500);
    n = ib_layout_paint(c, 1, 1000, 500, IB_FAIL_WARN, 1, 24, 6, p, 8);
    CHECK_INT(n, 3);
    CHECK_INT(p[1].kind, IB_PK_BAR); CHECK_INT(p[1].r.h, 6); CHECK_INT(p[1].r.w, 1000);
    CHECK_INT(p[2].kind, IB_PK_TEST); CHECK_INT(p[2].r.x, 0); CHECK_INT(p[2].r.y, 250); CHECK_INT(p[2].r.w, 24);
    n = ib_layout_paint(c, 2, 1000, 500, IB_FAIL_COVER, 0, 24, 6, p, 8);
    CHECK_INT(n, 1);
    CHECK_INT(p[0].kind, IB_PK_FAILCOVER); CHECK_INT(p[0].r.w, 1000);
    CHECK_INT(ib_layout_paint(c, 2, 0, 500, IB_FAIL_NONE, 0, 24, 6, p, 8), 0);

    /* render: FULL opaque surface colour, test square magenta, cover from its cells */
    static uint32_t buf[40 * 20];
    memset(buf, 0, sizeof buf);
    ib_cellset cs[1] = {{1, 1, {0x00ff00}}};
    ib_paint q[3] = {{{0, 0, 10, 10}, IB_PK_FULL, -1}, {{20, 0, 5, 5}, IB_PK_TEST, -1}, {{30, 0, 4, 4}, IB_PK_COVER, 0}};
    ib_render(buf, 40, q, 3, cs, (ib_layout){16, 8, 0}, 0xff000000u);
    CHECK_INT(buf[0], 0xff000000u | IB_COL_SURFACE);
    CHECK_INT(buf[22], 0xff000000u | IB_COL_TEST);
    CHECK_INT(buf[31], 0xff000000u | (14u << 16) | (149u << 8) | 14u);
    CHECK_INT(buf[15], 0);
}

static void test_protocol(void) {
    ib_settings s = {3, 0, 1};
    CHECK_INT(ib_command("policy 2", &s), 1); CHECK_INT(s.policy, 2);
    CHECK_INT(ib_command("policy 4", &s), 0); CHECK_INT(s.policy, 2);
    CHECK_INT(ib_command("policy x", &s), 0);
    CHECK_INT(ib_command("policy", &s), 0);
    CHECK_INT(ib_command("strictness 1\n", &s), 1); CHECK_INT(s.strictness, 1);
    CHECK_INT(ib_command("strictness 3", &s), 0); CHECK_INT(s.strictness, 1);
    CHECK_INT(ib_command("  fail_cover 0\r\n", &s), 1); CHECK_INT(s.fail_cover, 0);
    CHECK_INT(ib_command("quit", &s), 2);
    CHECK_INT(ib_command("quit\n", &s), 2);
    CHECK_INT(ib_command("bogus 1", &s), 0);
    CHECK_INT(ib_command("", &s), 0);
    CHECK(fabsf(ib_male_clear(0) - 0.999f) < 1e-6f);
    CHECK(fabsf(ib_male_clear(1) - 0.99f) < 1e-6f);
    CHECK(fabsf(ib_male_clear(2) - 0.98f) < 1e-6f);

    char line[256];
    ib_state_json(line, sizeof line, IB_ST_ON_COVERS_VISIBLE, "", "x11", "x11", 2, -1, -1, -1);
    CHECK(!strcmp(line, "{\"state\":\"on_covers_visible\",\"error\":\"\",\"backend\":\"x11\",\"overlay\":\"x11\","
                        "\"covers\":2}\n"));
    ib_state_json(line, sizeof line, IB_ST_NO_OVERLAY, "say \"no\"\\\nnow", "wayland", "", 0, 31.25, 12, 4);
    CHECK(!strcmp(line, "{\"state\":\"no_overlay\",\"error\":\"say \\\"no\\\"\\\\\\nnow\",\"backend\":\"wayland\","
                        "\"overlay\":\"\",\"covers\":0,\"ms\":31.2,\"cpu\":12.0,\"fps\":4.0}\n") ||
          !strcmp(line, "{\"state\":\"no_overlay\",\"error\":\"say \\\"no\\\"\\\\\\nnow\",\"backend\":\"wayland\","
                        "\"overlay\":\"\",\"covers\":0,\"ms\":31.3,\"cpu\":12.0,\"fps\":4.0}\n"));
    ib_state_json(line, sizeof line, IB_ST_FAILING, "\x01", "", "", 0, -1, -1, -1);
    CHECK(strstr(line, "\\u0001") != NULL);
    const char *names[] = {"starting", "on", "on_covers_visible", "failing", "models_missing", "no_capture",
                           "no_overlay", "idle"};
    for (int i = 0; i <= IB_ST_IDLE; i++) CHECK(!strcmp(ib_state_name((ib_state)i), names[i]));
    /* never longer than the buffer, always terminated */
    char small[20];
    int k = ib_state_json(small, sizeof small, IB_ST_ON, "a long error that does not fit", "x11", "x11", 0, 1, 1, 1);
    CHECK(k < (int)sizeof small && small[k] == 0);
}

int main(void) {
    test_scale();
    test_layout();
    test_downscale();
    test_thumb_and_cells();
    test_draw();
    test_rects();
    test_paint();
    test_protocol();
    printf("%d/%d checks passed\n", checks - fails, checks);
    return fails != 0;
}
