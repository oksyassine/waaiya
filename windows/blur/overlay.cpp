// waaiya-blur.exe, overlay backend (blur_host.h): one window per monitor, above every other window, that every
// click passes through (WS_EX_TRANSPARENT on a layered window), drawn with UpdateLayeredWindow: the covers opaque,
// the rest of the window fully transparent. The window only spans the covers' bounding box.
//
// WDA_EXCLUDEFROMCAPTURE (Windows 10 2004+) keeps the windows out of every screen capture, ours included, so the
// models see what is under the covers. Screenshots and screen sharing then show the screen uncovered too.
#include <windows.h>

#include <cstdio>
#include <cstring>
#include <vector>

extern "C" {
#include "blur_host.h"
}

extern "C" volatile int ib_win_display_changed = 0;

#ifndef WDA_EXCLUDEFROMCAPTURE
#define WDA_EXCLUDEFROMCAPTURE 0x00000011
#endif

namespace {

const wchar_t *CLASS_NAME = L"WaaiyaBlurCover";

struct Surface {
    HWND hwnd = nullptr;
    ib_geom g = {};
    HDC mem = nullptr;
    HBITMAP bmp = nullptr;
    uint32_t *bits = nullptr;
    int bw = 0, bh = 0; // bitmap size
    bool shown = false;

    void free_bitmap() {
        if (bmp) DeleteObject(bmp);
        if (mem) DeleteDC(mem);
        bmp = nullptr;
        mem = nullptr;
        bits = nullptr;
        bw = bh = 0;
    }
};

struct WinOv {
    ib_overlay base;
    HWND watch = nullptr; // hidden: hears display changes even with no cover shown
    std::vector<Surface> s;
};

WinOv *self(ib_overlay *b) { return reinterpret_cast<WinOv *>(b); }

LRESULT CALLBACK wnd_proc(HWND h, UINT msg, WPARAM wp, LPARAM lp) {
    switch (msg) {
    case WM_DISPLAYCHANGE:
    case WM_DPICHANGED:
        ib_win_display_changed = 1;
        return 0;
    case WM_NCHITTEST:
        return HTTRANSPARENT;
    case WM_MOUSEACTIVATE:
        return MA_NOACTIVATE;
    default:
        return DefWindowProcW(h, msg, wp, lp);
    }
}

HWND make_window(bool cover) {
    DWORD ex = cover ? (WS_EX_LAYERED | WS_EX_TRANSPARENT | WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE)
                     : WS_EX_TOOLWINDOW;
    return CreateWindowExW(ex, CLASS_NAME, L"Waaiya blur", WS_POPUP, 0, 0, 1, 1, nullptr, nullptr,
                           GetModuleHandleW(nullptr), nullptr);
}

void destroy_surface(Surface &s) {
    if (s.hwnd) DestroyWindow(s.hwnd);
    s.hwnd = nullptr;
    s.free_bitmap();
}

int ov_sync(ib_overlay *b, const ib_geom *g, int n) {
    WinOv *o = self(b);
    while ((int)o->s.size() > n) {
        destroy_surface(o->s.back());
        o->s.pop_back();
    }
    while ((int)o->s.size() < n) {
        Surface s;
        s.hwnd = make_window(true);
        if (!s.hwnd) {
            snprintf(b->err, sizeof b->err, "cannot create the cover window (error %lu)", GetLastError());
            return 0;
        }
        // kept out of screen captures; without it (Windows before 10 2004) the covers show in the capture and
        // im_blur.c works in its "covers visible" mode
        if (!SetWindowDisplayAffinity(s.hwnd, WDA_EXCLUDEFROMCAPTURE)) b->excluded = 0;
        o->s.push_back(s);
    }
    for (int i = 0; i < n; i++) o->s[(size_t)i].g = g[i];
    return 1;
}

void ov_draw(ib_overlay *b, int i, const ib_paint *p, int n, const ib_cellset *cells) {
    WinOv *o = self(b);
    if (i < 0 || (size_t)i >= o->s.size()) return;
    Surface &s = o->s[(size_t)i];
    std::vector<ib_rect> rects((size_t)n);
    for (int k = 0; k < n; k++) rects[(size_t)k] = p[k].r;
    ib_rect u = ib_union(rects.data(), n);
    if (n == 0 || u.w <= 0 || u.h <= 0) {
        if (s.shown) ShowWindow(s.hwnd, SW_HIDE);
        s.shown = false;
        return;
    }
    if (u.w != s.bw || u.h != s.bh) {
        s.free_bitmap();
        BITMAPINFO bi = {};
        bi.bmiHeader.biSize = sizeof bi.bmiHeader;
        bi.bmiHeader.biWidth = u.w;
        bi.bmiHeader.biHeight = -u.h; // top-down
        bi.bmiHeader.biPlanes = 1;
        bi.bmiHeader.biBitCount = 32;
        bi.bmiHeader.biCompression = BI_RGB;
        HDC screen = GetDC(nullptr);
        s.mem = CreateCompatibleDC(screen);
        void *bits = nullptr;
        s.bmp = CreateDIBSection(screen, &bi, DIB_RGB_COLORS, &bits, nullptr, 0);
        ReleaseDC(nullptr, screen);
        if (!s.mem || !s.bmp) {
            s.free_bitmap();
            return;
        }
        SelectObject(s.mem, s.bmp);
        s.bits = static_cast<uint32_t *>(bits);
        s.bw = u.w;
        s.bh = u.h;
    }
    // the paints, moved to the bitmap's origin; everything else fully transparent (premultiplied alpha 0)
    memset(s.bits, 0, (size_t)s.bw * s.bh * 4);
    std::vector<ib_paint> local(p, p + n);
    for (auto &q : local) {
        q.r.x -= u.x;
        q.r.y -= u.y;
    }
    ib_render(s.bits, s.bw, local.data(), n, cells, ib_layout{16, 8, 0}, 0xff000000u);
    GdiFlush();
    POINT pos = {s.g.x + u.x, s.g.y + u.y}, zero = {0, 0};
    SIZE size = {u.w, u.h};
    BLENDFUNCTION bf = {AC_SRC_OVER, 0, 255, AC_SRC_ALPHA};
    HDC screen = GetDC(nullptr);
    UpdateLayeredWindow(s.hwnd, screen, &pos, &size, s.mem, &zero, 0, &bf, ULW_ALPHA);
    ReleaseDC(nullptr, screen);
    if (!s.shown) {
        SetWindowPos(s.hwnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_SHOWWINDOW);
        s.shown = true;
    }
}

void ov_keep_on_top(ib_overlay *b) {
    for (auto &s : self(b)->s)
        if (s.shown)
            SetWindowPos(s.hwnd, HWND_TOPMOST, 0, 0, 0, 0,
                         SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_NOOWNERZORDER | SWP_NOSENDCHANGING);
}

int ov_fd(ib_overlay *) { return -1; }

// The windows belong to the main thread: their messages are handled here, once per loop.
void ov_dispatch(ib_overlay *) {
    MSG m;
    while (PeekMessageW(&m, nullptr, 0, 0, PM_REMOVE)) {
        TranslateMessage(&m);
        DispatchMessageW(&m);
    }
}

void ov_destroy(ib_overlay *b) {
    WinOv *o = self(b);
    for (auto &s : o->s) destroy_surface(s);
    if (o->watch) DestroyWindow(o->watch);
    delete o;
}

} // namespace

extern "C" ib_overlay *ib_win_overlay_new(char *err, size_t errlen) {
    WNDCLASSEXW wc = {};
    wc.cbSize = sizeof wc;
    wc.lpfnWndProc = wnd_proc;
    wc.hInstance = GetModuleHandleW(nullptr);
    wc.lpszClassName = CLASS_NAME;
    if (!RegisterClassExW(&wc) && GetLastError() != ERROR_CLASS_ALREADY_EXISTS) {
        snprintf(err, errlen, "cannot register the window class (error %lu)", GetLastError());
        return nullptr;
    }
    WinOv *o = new WinOv();
    o->base.name = "layered";
    o->base.sync = ov_sync;
    o->base.draw = ov_draw;
    o->base.keep_on_top = ov_keep_on_top;
    o->base.fd = ov_fd;
    o->base.dispatch = ov_dispatch;
    o->base.destroy = ov_destroy;
    o->base.excluded = 1; // until a window refuses WDA_EXCLUDEFROMCAPTURE
    o->watch = make_window(false);
    return &o->base;
}
