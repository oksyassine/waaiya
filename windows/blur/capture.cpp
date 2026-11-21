// waaiya-blur.exe, capture backend (blur_host.h): every monitor of the desktop, as the analysed RGBA frame.
//
// DXGI desktop duplication (Windows 8+): one duplication per monitor, on the GPU the monitor is attached to; it says
// when nothing changed, and a frame costs one copy to a CPU texture plus the downscale. Where duplication is not
// available (some remote and virtual sessions), GDI copies each monitor instead.
//
// The covers' windows have WDA_EXCLUDEFROMCAPTURE (overlay.cpp): neither route sees them, so the models see what
// is under the covers. The self-test in im_blur.c confirms that on this machine.
#include "../common/com.h"

#include <d3d11.h>
#include <dxgi1_2.h>
#include <shellscalingapi.h>
#include <windows.h>

#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

extern "C" {
#include "blur_host.h"
}

extern "C" volatile int ib_win_display_changed; // overlay.cpp: WM_DISPLAYCHANGE seen

namespace {

struct Screen {
    ib_geom g = {};
    HMONITOR mon = nullptr;
    // DXGI
    Com<IDXGIOutput1> out;
    Com<ID3D11Device> dev;
    Com<ID3D11DeviceContext> ctx;
    Com<IDXGIOutputDuplication> dup;
    Com<ID3D11Texture2D> staging;
    UINT tw = 0, th = 0; // duplicated texture size (unrotated)
    DXGI_MODE_ROTATION rot = DXGI_MODE_ROTATION_IDENTITY;
    DWORD retry_at = 0;
    bool had_frame = false;
    // GDI
    HDC mem = nullptr;
    HBITMAP bmp = nullptr;
    void *bits = nullptr;
    // analysed frame
    std::vector<uint8_t> rgba, tmp;
    int fw = 0, fh = 0;

    void free_gdi() {
        if (bmp) DeleteObject(bmp);
        if (mem) DeleteDC(mem);
        bmp = nullptr;
        mem = nullptr;
        bits = nullptr;
    }
};

struct WinCap {
    ib_capture base;
    std::vector<Screen> s;
    bool gdi = false; // duplication unavailable here
};

WinCap *self(ib_capture *b) { return reinterpret_cast<WinCap *>(b); }

float px_per_dp(HMONITOR m) {
    UINT dx = 96, dy = 96;
    if (FAILED(GetDpiForMonitor(m, MDT_EFFECTIVE_DPI, &dx, &dy))) dx = 96;
    return (float)dx / 160.0f;
}

void set_err(WinCap *c, const char *what, HRESULT hr) {
    snprintf(c->base.err, sizeof c->base.err, "%s (HRESULT 0x%08lx)", what, (unsigned long)hr);
}

// Creates the duplication of one output. S_OK, or why not (E_ACCESSDENIED: the secure desktop, UAC or the lock
// screen, is showing; it comes back after).
HRESULT open_dup(Screen &s) {
    s.dup.reset();
    s.staging.reset();
    HRESULT hr = s.out->DuplicateOutput(s.dev.p, s.dup.put());
    if (FAILED(hr)) return hr;
    DXGI_OUTDUPL_DESC d;
    s.dup->GetDesc(&d);
    s.tw = d.ModeDesc.Width;
    s.th = d.ModeDesc.Height;
    s.rot = d.Rotation;
    D3D11_TEXTURE2D_DESC td = {};
    td.Width = s.tw;
    td.Height = s.th;
    td.MipLevels = 1;
    td.ArraySize = 1;
    td.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
    td.SampleDesc.Count = 1;
    td.Usage = D3D11_USAGE_STAGING;
    td.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
    hr = s.dev->CreateTexture2D(&td, nullptr, s.staging.put());
    if (FAILED(hr)) s.dup.reset();
    s.had_frame = false;
    return hr;
}

// Every monitor on the desktop, DXGI first.
bool enumerate(WinCap *c) {
    for (auto &x : c->s) x.free_gdi();
    c->s.clear();
    if (!c->gdi) {
        Com<IDXGIFactory1> f;
        HRESULT hr = CreateDXGIFactory1(__uuidof(IDXGIFactory1), reinterpret_cast<void **>(f.put()));
        bool any_dup = false, any = false;
        for (UINT a = 0; SUCCEEDED(hr); a++) {
            Com<IDXGIAdapter1> ad;
            if (f->EnumAdapters1(a, ad.put()) == DXGI_ERROR_NOT_FOUND) break;
            Com<ID3D11Device> dev;
            Com<ID3D11DeviceContext> ctx;
            D3D_FEATURE_LEVEL got;
            if (FAILED(D3D11CreateDevice(ad.p, D3D_DRIVER_TYPE_UNKNOWN, nullptr, 0, nullptr, 0, D3D11_SDK_VERSION,
                                         dev.put(), &got, ctx.put())))
                continue;
            for (UINT o = 0; c->s.size() < IB_MAX_SCREENS; o++) {
                Com<IDXGIOutput> out;
                if (ad->EnumOutputs(o, out.put()) == DXGI_ERROR_NOT_FOUND) break;
                DXGI_OUTPUT_DESC od;
                if (FAILED(out->GetDesc(&od)) || !od.AttachedToDesktop) continue;
                Screen s;
                if (FAILED(out->QueryInterface(__uuidof(IDXGIOutput1), reinterpret_cast<void **>(s.out.put())))) continue;
                s.dev.p = dev.p;
                dev.p->AddRef();
                s.ctx.p = ctx.p;
                ctx.p->AddRef();
                s.mon = od.Monitor;
                RECT r = od.DesktopCoordinates;
                s.g = {r.left, r.top, r.right - r.left, r.bottom - r.top, px_per_dp(od.Monitor)};
                any = true;
                HRESULT dh = open_dup(s);
                if (SUCCEEDED(dh) || dh == E_ACCESSDENIED) any_dup = true;
                else set_err(c, "desktop duplication", dh);
                c->s.push_back(std::move(s));
            }
        }
        if (any && any_dup) return true;
        c->s.clear();
        c->gdi = true; // no duplication here (a remote or virtual session): GDI from now on
    }
    // GDI: the monitors Windows lists
    struct Ctx {
        WinCap *c;
    } ctx{c};
    EnumDisplayMonitors(
        nullptr, nullptr,
        [](HMONITOR m, HDC, LPRECT r, LPARAM lp) -> BOOL {
            WinCap *c = reinterpret_cast<Ctx *>(lp)->c;
            if (c->s.size() >= IB_MAX_SCREENS) return FALSE;
            Screen s;
            s.mon = m;
            s.g = {r->left, r->top, r->right - r->left, r->bottom - r->top, px_per_dp(m)};
            c->s.push_back(std::move(s));
            return TRUE;
        },
        reinterpret_cast<LPARAM>(&ctx));
    return !c->s.empty();
}

int cap_count(ib_capture *b) { return (int)self(b)->s.size(); }

void cap_geometry(ib_capture *b, int i, ib_geom *g) { *g = self(b)->s[(size_t)i].g; }

// Texture (unrotated, tw x th) to desktop orientation, on the small analysed frame.
void rotate(Screen &s, int sw, int sh) {
    const uint32_t *src = reinterpret_cast<const uint32_t *>(s.tmp.data());
    int dw = (s.rot == DXGI_MODE_ROTATION_ROTATE90 || s.rot == DXGI_MODE_ROTATION_ROTATE270) ? sh : sw;
    int dh = dw == sh ? sw : sh;
    s.rgba.resize((size_t)dw * dh * 4);
    uint32_t *dst = reinterpret_cast<uint32_t *>(s.rgba.data());
    for (int y = 0; y < dh; y++)
        for (int x = 0; x < dw; x++) {
            int sx, sy;
            switch (s.rot) {
            case DXGI_MODE_ROTATION_ROTATE90: sx = y; sy = sh - 1 - x; break;       // turned clockwise
            case DXGI_MODE_ROTATION_ROTATE180: sx = sw - 1 - x; sy = sh - 1 - y; break;
            case DXGI_MODE_ROTATION_ROTATE270: sx = sw - 1 - y; sy = x; break;      // turned anticlockwise
            default: sx = x; sy = y; break;
            }
            dst[(size_t)y * dw + x] = src[(size_t)sy * sw + sx];
        }
    s.fw = dw;
    s.fh = dh;
}

int grab_dxgi(WinCap *c, Screen &s, const uint8_t **rgba, int *fw, int *fh) {
    if (!s.dup) {
        DWORD now = GetTickCount();
        if ((int)(now - s.retry_at) < 0) return 0;
        HRESULT hr = open_dup(s);
        if (hr == E_ACCESSDENIED) { // the secure desktop: nothing of ours can show there either
            s.retry_at = now + 500;
            return 0;
        }
        if (FAILED(hr)) {
            set_err(c, "desktop duplication", hr);
            s.retry_at = now + 1000;
            return -1;
        }
    }
    DXGI_OUTDUPL_FRAME_INFO info;
    Com<IDXGIResource> res;
    HRESULT hr = s.dup->AcquireNextFrame(0, &info, res.put());
    if (hr == DXGI_ERROR_WAIT_TIMEOUT) return 0;
    if (hr == DXGI_ERROR_ACCESS_LOST) { // mode change, a full-screen app, the secure desktop: open again
        s.dup.reset();
        s.retry_at = 0;
        return 0;
    }
    if (FAILED(hr)) {
        set_err(c, "desktop duplication frame", hr);
        s.dup.reset();
        return -1;
    }
    int r = 0;
    if (info.LastPresentTime.QuadPart != 0 || !s.had_frame) { // else only the mouse moved
        Com<ID3D11Texture2D> tex;
        if (SUCCEEDED(res->QueryInterface(__uuidof(ID3D11Texture2D), reinterpret_cast<void **>(tex.put())))) {
            s.ctx->CopyResource(s.staging.p, tex.p);
            D3D11_MAPPED_SUBRESOURCE m;
            if (SUCCEEDED(s.ctx->Map(s.staging.p, 0, D3D11_MAP_READ, 0, &m))) {
                int sw, sh;
                ib_scale_size((int)s.tw, (int)s.th, IB_LONG_SIDE, &sw, &sh);
                bool turned = s.rot == DXGI_MODE_ROTATION_ROTATE90 || s.rot == DXGI_MODE_ROTATION_ROTATE180 ||
                              s.rot == DXGI_MODE_ROTATION_ROTATE270;
                std::vector<uint8_t> &dst = turned ? s.tmp : s.rgba;
                dst.resize((size_t)sw * sh * 4);
                ib_downscale(static_cast<const uint8_t *>(m.pData), (int)s.tw, (int)s.th, (int)m.RowPitch,
                             ib_layout{16, 8, 0}, dst.data(), sw, sh, sw * 4);
                s.ctx->Unmap(s.staging.p, 0);
                if (turned) {
                    rotate(s, sw, sh);
                } else {
                    s.fw = sw;
                    s.fh = sh;
                }
                s.had_frame = true;
                r = 1;
            }
        }
    }
    s.dup->ReleaseFrame();
    if (r == 1) {
        *rgba = s.rgba.data();
        *fw = s.fw;
        *fh = s.fh;
    }
    return r;
}

int grab_gdi(WinCap *c, Screen &s, const uint8_t **rgba, int *fw, int *fh) {
    int w = s.g.w, h = s.g.h;
    HDC screen = GetDC(nullptr);
    if (!screen) {
        snprintf(c->base.err, sizeof c->base.err, "GetDC failed (error %lu)", GetLastError());
        return -1;
    }
    if (!s.mem) {
        BITMAPINFO bi = {};
        bi.bmiHeader.biSize = sizeof bi.bmiHeader;
        bi.bmiHeader.biWidth = w;
        bi.bmiHeader.biHeight = -h; // top-down
        bi.bmiHeader.biPlanes = 1;
        bi.bmiHeader.biBitCount = 32;
        bi.bmiHeader.biCompression = BI_RGB;
        s.mem = CreateCompatibleDC(screen);
        s.bmp = CreateDIBSection(s.mem, &bi, DIB_RGB_COLORS, &s.bits, nullptr, 0);
        if (!s.mem || !s.bmp) {
            ReleaseDC(nullptr, screen);
            s.free_gdi();
            snprintf(c->base.err, sizeof c->base.err, "screen copy: out of memory");
            return -1;
        }
        SelectObject(s.mem, s.bmp);
    }
    BOOL ok = BitBlt(s.mem, 0, 0, w, h, screen, s.g.x, s.g.y, SRCCOPY);
    ReleaseDC(nullptr, screen);
    if (!ok) { // the secure desktop is showing: try again later
        return 0;
    }
    GdiFlush();
    ib_scale_size(w, h, IB_LONG_SIDE, &s.fw, &s.fh);
    s.rgba.resize((size_t)s.fw * s.fh * 4);
    ib_downscale(static_cast<const uint8_t *>(s.bits), w, h, w * 4, ib_layout{16, 8, 0}, s.rgba.data(), s.fw, s.fh,
                 s.fw * 4);
    *rgba = s.rgba.data();
    *fw = s.fw;
    *fh = s.fh;
    return 1;
}

int cap_grab(ib_capture *b, int i, const uint8_t **rgba, int *fw, int *fh) {
    WinCap *c = self(b);
    if (i < 0 || (size_t)i >= c->s.size()) return -1;
    Screen &s = c->s[(size_t)i];
    return s.dup || s.out ? grab_dxgi(c, s, rgba, fw, fh) : grab_gdi(c, s, rgba, fw, fh);
}

int cap_fd(ib_capture *) { return -1; }

// Monitors added, removed, moved or resized: found again (the main loop then redoes its screens).
int cap_dispatch(ib_capture *b) {
    if (!ib_win_display_changed) return 0;
    ib_win_display_changed = 0;
    WinCap *c = self(b);
    std::vector<ib_geom> before;
    for (auto &s : c->s) before.push_back(s.g);
    enumerate(c);
    if (before.size() != c->s.size()) return 1;
    for (size_t k = 0; k < before.size(); k++)
        if (memcmp(&before[k], &c->s[k].g, sizeof(ib_geom)) != 0) return 1;
    return 0;
}

int cap_ready(ib_capture *b) { return self(b)->s.empty() ? -1 : 0; }

void cap_destroy(ib_capture *b) {
    WinCap *c = self(b);
    for (auto &s : c->s) s.free_gdi();
    delete c;
}

} // namespace

extern "C" ib_capture *ib_win_capture_new(char *err, size_t errlen) {
    WinCap *c = new WinCap();
    c->base.name = "dxgi";
    c->base.count = cap_count;
    c->base.geometry = cap_geometry;
    c->base.grab = cap_grab;
    c->base.fd = cap_fd;
    c->base.dispatch = cap_dispatch;
    c->base.ready = cap_ready;
    c->base.destroy = cap_destroy;
    if (getenv("WAAIYA_BLUR_GDI")) c->gdi = true; // tests: the fallback on a machine that has duplication
    if (!enumerate(c)) {
        snprintf(err, errlen, "no monitor to capture%s%s", c->base.err[0] ? ": " : "", c->base.err);
        delete c;
        return nullptr;
    }
    if (c->gdi) c->base.name = "gdi";
    return &c->base;
}
