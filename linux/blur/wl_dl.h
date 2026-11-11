/* The libwayland-client ABI im-blur uses through dlopen (layer.c): the message / interface tables (stable since
 * wayland 1.0) and the core opcodes from wayland.xml. Checked against wayland-client.h by abi_check.c. */
#ifndef IM_WL_DL_H
#define IM_WL_DL_H

#include <stdint.h>

struct wl_display;
struct wl_proxy;
struct ibw_message {
    const char *name;
    const char *signature;
    const struct ibw_interface **types;
};
struct ibw_interface {
    const char *name;
    int version;
    int method_count;
    const struct ibw_message *methods;
    int event_count;
    const struct ibw_message *events;
};

#define IBWL_MARSHAL_FLAG_DESTROY (1 << 0)

/* opcodes, from wayland.xml (checked in abi_check.c) */
enum {
    IBWL_DISPLAY_GET_REGISTRY = 1,
    IBWL_REGISTRY_BIND = 0,
    IBWL_COMPOSITOR_CREATE_SURFACE = 0, IBWL_COMPOSITOR_CREATE_REGION = 1,
    IBWL_SURFACE_DESTROY = 0, IBWL_SURFACE_ATTACH = 1, IBWL_SURFACE_DAMAGE = 2, IBWL_SURFACE_SET_INPUT_REGION = 5,
    IBWL_SURFACE_COMMIT = 6,
    IBWL_REGION_DESTROY = 0,
    IBWL_SHM_CREATE_POOL = 0, IBWL_SHM_POOL_CREATE_BUFFER = 0, IBWL_SHM_POOL_DESTROY = 1, IBWL_BUFFER_DESTROY = 0,
    IBWL_SHM_FORMAT_ARGB8888 = 0,
    IBWL_OUTPUT_RELEASE = 0,
};

#endif
