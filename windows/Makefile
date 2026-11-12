# Windows builds (x64), cross-compiled with llvm-mingw (https://github.com/mstorsjo/llvm-mingw) on Linux or Windows:
#   make -f windows/Makefile ORT=<onnxruntime-win-x64-1.19.2> [CROSS=x86_64-w64-mingw32-]
# Outputs in build-win/: waaiya-filter.exe (sound filter), waaiya-blur.exe (screen blur), waaiya-wtest.exe (CI
# audio tool), the engine tests, and onnxruntime.dll. Everything links statically except onnxruntime.dll and the
# Universal C Runtime that Windows 10 and 11 include.
CROSS   ?= x86_64-w64-mingw32-
CC       = $(CROSS)gcc
CXX      = $(CROSS)g++
ORT     ?= third_party/onnxruntime-win
OUT      = build-win
WARN     = -Wall -Wextra
CFLAGS   = -O2 -std=c11 $(WARN) -Iengine/include -Iengine/src -Icli -I$(ORT)/include -DWIN32_LEAN_AND_MEAN -D_WIN32_WINNT=0x0A00
CXXFLAGS = -O2 -std=c++17 $(WARN) -Iengine/include -Iengine/src -I$(ORT)/include -DWIN32_LEAN_AND_MEAN -D_WIN32_WINNT=0x0A00 -DUNICODE -D_UNICODE
LDFLAGS  = -static -L$(ORT)/lib
ORTLIB   = -lonnxruntime

# The app's version (desktop/pubspec.yaml, "0.2.10+12"), in every program's version information (windows/common/version.rc)
WAAIYA_VERSION := $(shell sed -n 's/^version: *//p' desktop/pubspec.yaml | tr -d '\r')
WAAIYA_VERSION_NUM := $(shell echo '$(WAAIYA_VERSION)' | tr '.+' ',,' | awk -F, '{printf "%d,%d,%d,%d", $$1, $$2, $$3, $$4}')
RC = $(CROSS)windres
RCFLAGS = -DWAAIYA_VERSION='\"$(WAAIYA_VERSION)\"' -DWAAIYA_VERSION_NUM=$(WAAIYA_VERSION_NUM)

$(OUT)/version-%.o: windows/common/version.rc desktop/pubspec.yaml | $(OUT)
	$(RC) $(RCFLAGS) -DWAAIYA_FILE='\"waaiya-$*.exe\"' -DWAAIYA_DESCRIPTION='\"$(DESC_$*)\"' $< -O coff -o $@
DESC_filter = Waaiya sound filter
DESC_blur = Waaiya screen blur

ENGINE_OBJ = $(OUT)/im_engine.o $(OUT)/im_detector.o
VISION_OBJ = $(OUT)/im_vision.o $(OUT)/im_cover.o

all: $(OUT)/waaiya-filter.exe $(OUT)/waaiya-blur.exe $(OUT)/waaiya-wtest.exe $(OUT)/im-process.exe $(OUT)/test-mono.exe \
     $(OUT)/test-failclosed.exe $(OUT)/test-detector.exe $(OUT)/onnxruntime.dll

$(OUT):
	mkdir -p $(OUT)

$(OUT)/onnxruntime.dll: | $(OUT)
	cp $(ORT)/lib/onnxruntime.dll $@

$(OUT)/%.o: engine/src/%.c $(wildcard engine/src/*.h) $(wildcard engine/include/*.h) | $(OUT)
	$(CC) $(CFLAGS) -c $< -o $@

FILTER_SRC = windows/filter/wfilter.cpp windows/filter/sessions.cpp windows/common/wasapi.cpp
WIN_LIBS   = -lole32 -loleaut32 -luuid -lmmdevapi -lavrt -lshell32 -lpropsys

# GUI subsystem (-mwindows): started by the desktop app with pipes, never with a console window of its own
$(OUT)/waaiya-filter.exe: $(FILTER_SRC) $(wildcard windows/filter/*.h windows/common/*.h) $(ENGINE_OBJ) $(OUT)/version-filter.o
	$(CXX) $(CXXFLAGS) -municode -mwindows $(FILTER_SRC) $(ENGINE_OBJ) $(OUT)/version-filter.o -o $@ $(LDFLAGS) $(ORTLIB) $(WIN_LIBS)

# Screen blur: the main loop and pure parts shared with Linux (linux/blur), the Windows capture, overlay and system
# layer (windows/blur)
BLUR_C    = linux/blur/im_blur.c linux/blur/blur_core.c windows/blur/sys_win.c
BLUR_CXX  = windows/blur/capture.cpp windows/blur/overlay.cpp
BLUR_OBJ  = $(patsubst %,$(OUT)/blur_%.o,$(basename $(notdir $(BLUR_C) $(BLUR_CXX))))
BLUR_HDR  = $(wildcard linux/blur/*.h windows/common/*.h) engine/include/im_vision.h

$(OUT)/blur_%.o: linux/blur/%.c $(BLUR_HDR) | $(OUT)
	$(CC) $(CFLAGS) -Ilinux/blur -c $< -o $@
$(OUT)/blur_%.o: windows/blur/%.c $(BLUR_HDR) | $(OUT)
	$(CC) $(CFLAGS) -Ilinux/blur -c $< -o $@
$(OUT)/blur_%.o: windows/blur/%.cpp $(BLUR_HDR) | $(OUT)
	$(CXX) $(CXXFLAGS) -Ilinux/blur -c $< -o $@

$(OUT)/waaiya-blur.exe: $(BLUR_OBJ) $(VISION_OBJ) $(OUT)/version-blur.o
	$(CXX) -mwindows $^ -o $@ $(LDFLAGS) $(ORTLIB) -ld3d11 -ldxgi -lshcore -lgdi32 -luser32 -lpthread

$(OUT)/waaiya-wtest.exe: windows/test/wtest.cpp windows/common/wasapi.cpp windows/common/wasapi.h | $(OUT)
	$(CXX) $(CXXFLAGS) -municode windows/test/wtest.cpp windows/common/wasapi.cpp -o $@ $(LDFLAGS) $(WIN_LIBS)

$(OUT)/im-process.exe: cli/im_process.c cli/wav.c $(ENGINE_OBJ)
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS) $(ORTLIB) -lpthread

$(OUT)/test-mono.exe: engine/test/test_mono.c $(ENGINE_OBJ)
	$(CC) $(CFLAGS) -D_GNU_SOURCE $^ -o $@ $(LDFLAGS) $(ORTLIB) -lpthread

$(OUT)/test-failclosed.exe: engine/test/test_failclosed.c $(ENGINE_OBJ)
	$(CC) $(CFLAGS) -D_GNU_SOURCE $^ -o $@ $(LDFLAGS) $(ORTLIB) -lpthread

$(OUT)/test-detector.exe: engine/test/test_detector.c cli/wav.c $(ENGINE_OBJ)
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS) $(ORTLIB) -lpthread

clean:
	rm -rf $(OUT)

.PHONY: all clean
