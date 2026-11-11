/* Compile-only check (make check-blur-abi): the hand-written declarations im-blur uses with dlopen match the real
 * headers. Needs libx11-dev, libxext-dev, libxrandr-dev, libxdamage-dev (and, for the Wayland part,
 * libpipewire-0.3-dev, libspa-0.2-dev, libwayland-dev): CI installs them, the build itself never needs them. */
#include <stddef.h>

#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/extensions/XShm.h>
#include <X11/extensions/Xdamage.h>
#include <X11/extensions/Xrandr.h>
#include <X11/extensions/shape.h>

#define IBX_NO_LOADER
#include "x11_dl.h"

#define SAME_SIZE(a, b) _Static_assert(sizeof(a) == sizeof(b), "size of " #a)
#define SAME_FIELD(a, b, f) _Static_assert(offsetof(a, f) == offsetof(b, f), #a "." #f)

SAME_SIZE(ibx_XImage, XImage);
SAME_FIELD(ibx_XImage, XImage, data);
SAME_FIELD(ibx_XImage, XImage, bytes_per_line);
SAME_FIELD(ibx_XImage, XImage, bits_per_pixel);
SAME_FIELD(ibx_XImage, XImage, red_mask);
SAME_FIELD(ibx_XImage, XImage, blue_mask);
SAME_FIELD(ibx_XImage, XImage, f);
SAME_FIELD(ibx_XImage, XImage, f.destroy_image);

SAME_SIZE(ibx_XShmSegmentInfo, XShmSegmentInfo);
SAME_FIELD(ibx_XShmSegmentInfo, XShmSegmentInfo, shmid);
SAME_FIELD(ibx_XShmSegmentInfo, XShmSegmentInfo, shmaddr);
SAME_FIELD(ibx_XShmSegmentInfo, XShmSegmentInfo, readOnly);

SAME_SIZE(ibx_XSetWindowAttributes, XSetWindowAttributes);
SAME_FIELD(ibx_XSetWindowAttributes, XSetWindowAttributes, border_pixel);
SAME_FIELD(ibx_XSetWindowAttributes, XSetWindowAttributes, save_under);
SAME_FIELD(ibx_XSetWindowAttributes, XSetWindowAttributes, event_mask);
SAME_FIELD(ibx_XSetWindowAttributes, XSetWindowAttributes, override_redirect);
SAME_FIELD(ibx_XSetWindowAttributes, XSetWindowAttributes, cursor);

SAME_SIZE(ibx_XRectangle, XRectangle);
SAME_SIZE(ibx_XEvent, XEvent);
SAME_FIELD(ibx_XExposeEvent, XExposeEvent, window);
SAME_FIELD(ibx_XExposeEvent, XExposeEvent, count);
SAME_SIZE(ibx_XErrorEvent, XErrorEvent);
SAME_FIELD(ibx_XErrorEvent, XErrorEvent, error_code);

SAME_SIZE(ibx_XRRMonitorInfo, XRRMonitorInfo);
SAME_FIELD(ibx_XRRMonitorInfo, XRRMonitorInfo, x);
SAME_FIELD(ibx_XRRMonitorInfo, XRRMonitorInfo, mwidth);
SAME_FIELD(ibx_XRRMonitorInfo, XRRMonitorInfo, outputs);

_Static_assert(IBX_ZPixmap == ZPixmap && IBX_InputOutput == InputOutput && IBX_Expose == Expose, "X constants");
_Static_assert(IBX_ShapeBounding == ShapeBounding && IBX_ShapeInput == ShapeInput && IBX_ShapeSet == ShapeSet &&
                   IBX_Unsorted == Unsorted,
               "shape constants");
_Static_assert(IBX_CWBackPixmap == CWBackPixmap && IBX_CWBorderPixel == CWBorderPixel &&
                   IBX_CWOverrideRedirect == CWOverrideRedirect && IBX_CWEventMask == CWEventMask &&
                   IBX_ExposureMask == ExposureMask,
               "window attribute masks");
_Static_assert(IBX_PropModeReplace == PropModeReplace && IBX_XA_ATOM == 4 && IBX_XA_CARDINAL == 6, "properties");
_Static_assert(IBX_XDamageReportNonEmpty == XDamageReportNonEmpty && IBX_XDamageNotify == XDamageNotify, "damage");
