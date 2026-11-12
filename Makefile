# islamic-mute: engine (C11 + ONNX Runtime C API), CLI and LADSPA plugin.
ORT     ?= third_party/onnxruntime
CC      ?= gcc
# Optional local sysroot (third_party/sysroot) when libc6-dev is not installed system-wide.
SYSROOT ?= $(if $(wildcard third_party/sysroot/usr/include/stdio.h),third_party/sysroot)
SYSFLAG  = $(if $(SYSROOT),--sysroot=$(SYSROOT))
CFLAGS  ?= -O2 -g -Wall -Wextra -std=c11 -D_POSIX_C_SOURCE=200809L
CFLAGS  += $(SYSFLAG) -Iengine/include -I$(ORT)/include -fvisibility=hidden -fPIC
LDLIBS   = -L$(ORT)/lib -lonnxruntime -lm
BUILD    = build

all: $(BUILD)/im-process $(BUILD)/im-stream $(BUILD)/islamic_mute_ladspa.so $(BUILD)/im-pulse $(BUILD)/libimvision.so

# im-pulse loads libpulse.so.0 at run time (cli/pulse_dl.h), so it builds without libpulse-dev.
pulse: $(BUILD)/im-pulse

$(BUILD):
	mkdir -p $(BUILD)
	cp -P $(ORT)/lib/libonnxruntime.so* $(BUILD)/

ENGINE_OBJ = $(BUILD)/im_engine.o $(BUILD)/im_detector.o

$(BUILD)/im_engine.o: engine/src/im_engine.c engine/include/im_engine.h engine/src/im_detector.h | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/im_detector.o: engine/src/im_detector.c engine/src/im_detector.h | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

VISION_SRC = engine/src/im_vision.c engine/src/im_cover.c

# Screen blur (models/vision): shared library, used by the Python scorer (models/vision/eval_blur.py) via ctypes.
$(BUILD)/libimvision.so: $(VISION_SRC) engine/include/im_vision.h | $(BUILD)
	$(CC) $(CFLAGS) -shared $(VISION_SRC) -o $@ $(LDLIBS) -Wl,-rpath,'$$ORIGIN' -Wl,--no-undefined

$(BUILD)/test-detector: engine/test/test_detector.c $(ENGINE_OBJ)
	$(CC) $(CFLAGS) -Iengine/src -Icli $^ cli/wav.c -o $@ $(LDLIBS) -Wl,-rpath,'$$ORIGIN'

# make build/test-mono && build/test-mono models/dfn3/dfn3_stream_int8.onnx
$(BUILD)/test-mono: engine/test/test_mono.c $(ENGINE_OBJ)
	$(CC) $(CFLAGS) -D_GNU_SOURCE $^ -o $@ $(LDLIBS) -Wl,-rpath,'$$ORIGIN'

$(BUILD)/im-process: cli/im_process.c cli/wav.c $(ENGINE_OBJ)
	$(CC) $(CFLAGS) -Icli $^ -o $@ $(LDLIBS) -Wl,-rpath,'$$ORIGIN'

$(BUILD)/im-stream: cli/im_stream.c $(ENGINE_OBJ)
	$(CC) $(CFLAGS) $^ -o $@ $(LDLIBS) -Wl,-rpath,'$$ORIGIN'

$(BUILD)/im-pulse: cli/im_pulse.c cli/pulse_dl.h $(ENGINE_OBJ)
	$(CC) $(CFLAGS) -pthread $(filter %.c %.o,$^) -o $@ $(LDLIBS) -ldl -Wl,-rpath,'$$ORIGIN'

$(BUILD)/islamic_mute_ladspa.so: linux/ladspa/im_ladspa.c $(ENGINE_OBJ)
	$(CC) $(CFLAGS) -shared $^ -o $@ $(LDLIBS) -Wl,-rpath,'$$ORIGIN' -Wl,--no-undefined

clean:
	rm -rf $(BUILD)

.PHONY: all clean pulse
