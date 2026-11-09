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

all: $(BUILD)/im-process $(BUILD)/im-stream $(BUILD)/islamic_mute_ladspa.so

$(BUILD):
	mkdir -p $(BUILD)
	cp -P $(ORT)/lib/libonnxruntime.so* $(BUILD)/

ENGINE_OBJ = $(BUILD)/im_engine.o $(BUILD)/im_detector.o

$(BUILD)/im_engine.o: engine/src/im_engine.c engine/include/im_engine.h engine/src/im_detector.h | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/im_detector.o: engine/src/im_detector.c engine/src/im_detector.h | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/test-detector: engine/test/test_detector.c $(ENGINE_OBJ)
	$(CC) $(CFLAGS) -Iengine/src -Icli $^ cli/wav.c -o $@ $(LDLIBS) -Wl,-rpath,'$$ORIGIN'

$(BUILD)/im-process: cli/im_process.c cli/wav.c $(ENGINE_OBJ)
	$(CC) $(CFLAGS) -Icli $^ -o $@ $(LDLIBS) -Wl,-rpath,'$$ORIGIN'

$(BUILD)/im-stream: cli/im_stream.c $(ENGINE_OBJ)
	$(CC) $(CFLAGS) $^ -o $@ $(LDLIBS) -Wl,-rpath,'$$ORIGIN'

$(BUILD)/islamic_mute_ladspa.so: linux/ladspa/im_ladspa.c $(ENGINE_OBJ)
	$(CC) $(CFLAGS) -shared $^ -o $@ $(LDLIBS) -Wl,-rpath,'$$ORIGIN' -Wl,--no-undefined

clean:
	rm -rf $(BUILD)

.PHONY: all clean
