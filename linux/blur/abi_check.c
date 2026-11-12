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

/* ---------------------------------------------------------------- PipeWire / SPA (pw_dl.h) */
#include <pipewire/pipewire.h>
#include <spa/param/param.h>
#if __has_include(<spa/param/buffers.h>) /* PipeWire 0.3.50+; before, the buffer keys were in param.h */
#include <spa/param/buffers.h>
#endif
#include <spa/param/video/format-utils.h>

#define IBP_NO_LOADER
#include "pw_dl.h"

SAME_SIZE(struct ibp_spa_pod, struct spa_pod);
SAME_SIZE(struct ibp_spa_chunk, struct spa_chunk);
SAME_FIELD(struct ibp_spa_chunk, struct spa_chunk, stride);
SAME_FIELD(struct ibp_spa_chunk, struct spa_chunk, flags);
SAME_SIZE(struct ibp_spa_data, struct spa_data);
SAME_FIELD(struct ibp_spa_data, struct spa_data, maxsize);
SAME_FIELD(struct ibp_spa_data, struct spa_data, data);
SAME_FIELD(struct ibp_spa_data, struct spa_data, chunk);
SAME_SIZE(struct ibp_spa_buffer, struct spa_buffer);
SAME_FIELD(struct ibp_spa_buffer, struct spa_buffer, n_datas);
SAME_FIELD(struct ibp_spa_buffer, struct spa_buffer, datas);
SAME_FIELD(struct ibp_pw_buffer, struct pw_buffer, buffer);
SAME_FIELD(struct ibp_pw_stream_events, struct pw_stream_events, state_changed);
SAME_FIELD(struct ibp_pw_stream_events, struct pw_stream_events, param_changed);
SAME_FIELD(struct ibp_pw_stream_events, struct pw_stream_events, process);
SAME_FIELD(struct ibp_pw_stream_events, struct pw_stream_events, drained);
_Static_assert(sizeof(struct spa_hook) <= IBP_HOOK_SIZE, "spa_hook fits");
_Static_assert(IBP_TYPE_Id == SPA_TYPE_Id && IBP_TYPE_Int == SPA_TYPE_Int && IBP_TYPE_Rectangle == SPA_TYPE_Rectangle &&
                   IBP_TYPE_Fraction == SPA_TYPE_Fraction && IBP_TYPE_Object == SPA_TYPE_Object &&
                   IBP_TYPE_Choice == SPA_TYPE_Choice,
               "spa pod types");
_Static_assert(IBP_TYPE_OBJECT_Format == SPA_TYPE_OBJECT_Format &&
                   IBP_TYPE_OBJECT_ParamBuffers == SPA_TYPE_OBJECT_ParamBuffers,
               "spa object types");
_Static_assert(IBP_PARAM_EnumFormat == SPA_PARAM_EnumFormat && IBP_PARAM_Format == SPA_PARAM_Format &&
                   IBP_PARAM_Buffers == SPA_PARAM_Buffers && IBP_PARAM_BUFFERS_dataType == SPA_PARAM_BUFFERS_dataType,
               "spa params");
_Static_assert(IBP_FORMAT_mediaType == SPA_FORMAT_mediaType && IBP_FORMAT_mediaSubtype == SPA_FORMAT_mediaSubtype &&
                   IBP_FORMAT_VIDEO_format == SPA_FORMAT_VIDEO_format && IBP_FORMAT_VIDEO_size == SPA_FORMAT_VIDEO_size &&
                   IBP_FORMAT_VIDEO_framerate == SPA_FORMAT_VIDEO_framerate,
               "spa format keys");
_Static_assert(IBP_MEDIA_TYPE_video == SPA_MEDIA_TYPE_video && IBP_MEDIA_SUBTYPE_raw == SPA_MEDIA_SUBTYPE_raw,
               "media types");
_Static_assert(IBP_VIDEO_FORMAT_RGBx == SPA_VIDEO_FORMAT_RGBx && IBP_VIDEO_FORMAT_BGRx == SPA_VIDEO_FORMAT_BGRx &&
                   IBP_VIDEO_FORMAT_RGBA == SPA_VIDEO_FORMAT_RGBA && IBP_VIDEO_FORMAT_BGRA == SPA_VIDEO_FORMAT_BGRA,
               "video formats");
_Static_assert(IBP_CHOICE_Range == SPA_CHOICE_Range && IBP_CHOICE_Enum == SPA_CHOICE_Enum &&
                   IBP_CHOICE_Flags == SPA_CHOICE_Flags,
               "choices");
_Static_assert(IBP_DATA_MemPtr == SPA_DATA_MemPtr && IBP_DATA_MemFd == SPA_DATA_MemFd &&
                   IBP_CHUNK_FLAG_CORRUPTED == SPA_CHUNK_FLAG_CORRUPTED,
               "data types");
_Static_assert(IBP_DIRECTION_INPUT == (int)PW_DIRECTION_INPUT &&
                   IBP_STREAM_FLAG_AUTOCONNECT == PW_STREAM_FLAG_AUTOCONNECT &&
                   IBP_STREAM_FLAG_MAP_BUFFERS == PW_STREAM_FLAG_MAP_BUFFERS,
               "stream flags");
_Static_assert(IBP_STREAM_STATE_ERROR == PW_STREAM_STATE_ERROR &&
                   IBP_STREAM_STATE_UNCONNECTED == PW_STREAM_STATE_UNCONNECTED &&
                   IBP_STREAM_STATE_CONNECTING == PW_STREAM_STATE_CONNECTING &&
                   IBP_STREAM_STATE_STREAMING == PW_STREAM_STATE_STREAMING,
               "stream states");

/* ---------------------------------------------------------------- Wayland (wl_dl.h) */
#include <wayland-client.h>

#include "wl_dl.h"

SAME_SIZE(struct ibw_message, struct wl_message);
SAME_FIELD(struct ibw_message, struct wl_message, types);
SAME_SIZE(struct ibw_interface, struct wl_interface);
SAME_FIELD(struct ibw_interface, struct wl_interface, methods);
SAME_FIELD(struct ibw_interface, struct wl_interface, events);
_Static_assert(IBWL_DISPLAY_GET_REGISTRY == WL_DISPLAY_GET_REGISTRY && IBWL_REGISTRY_BIND == WL_REGISTRY_BIND &&
                   IBWL_COMPOSITOR_CREATE_SURFACE == WL_COMPOSITOR_CREATE_SURFACE &&
                   IBWL_COMPOSITOR_CREATE_REGION == WL_COMPOSITOR_CREATE_REGION,
               "wl core opcodes");
_Static_assert(IBWL_SURFACE_DESTROY == WL_SURFACE_DESTROY && IBWL_SURFACE_ATTACH == WL_SURFACE_ATTACH &&
                   IBWL_SURFACE_DAMAGE == WL_SURFACE_DAMAGE &&
                   IBWL_SURFACE_SET_INPUT_REGION == WL_SURFACE_SET_INPUT_REGION &&
                   IBWL_SURFACE_COMMIT == WL_SURFACE_COMMIT,
               "wl_surface opcodes");
_Static_assert(IBWL_REGION_DESTROY == WL_REGION_DESTROY && IBWL_SHM_CREATE_POOL == WL_SHM_CREATE_POOL &&
                   IBWL_SHM_POOL_CREATE_BUFFER == WL_SHM_POOL_CREATE_BUFFER &&
                   IBWL_SHM_POOL_DESTROY == WL_SHM_POOL_DESTROY && IBWL_BUFFER_DESTROY == WL_BUFFER_DESTROY &&
                   IBWL_SHM_FORMAT_ARGB8888 == WL_SHM_FORMAT_ARGB8888 &&
                   IBWL_MARSHAL_FLAG_DESTROY == WL_MARSHAL_FLAG_DESTROY,
               "wl_shm / wl_buffer");
