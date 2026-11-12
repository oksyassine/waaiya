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

ENGINE_OBJ = $(OUT)/im_engine.o $(OUT)/im_detector.o
VISION_OBJ = $(OUT)/im_vision.o $(OUT)/im_cover.o

all: $(OUT)/waaiya-filter.exe $(OUT)/waaiya-wtest.exe $(OUT)/im-process.exe $(OUT)/test-mono.exe \
     $(OUT)/test-failclosed.exe $(OUT)/test-detector.exe $(OUT)/onnxruntime.dll

$(OUT):
	mkdir -p $(OUT)

$(OUT)/onnxruntime.dll: | $(OUT)
	cp $(ORT)/lib/onnxruntime.dll $@

$(OUT)/%.o: engine/src/%.c $(wildcard engine/src/*.h) $(wildcard engine/include/*.h) | $(OUT)
	$(CC) $(CFLAGS) -c $< -o $@

FILTER_SRC = windows/filter/wfilter.cpp windows/filter/sessions.cpp windows/common/wasapi.cpp
WIN_LIBS   = -lole32 -loleaut32 -luuid -lmmdevapi -lavrt -lshell32 -lpropsys

$(OUT)/waaiya-filter.exe: $(FILTER_SRC) $(wildcard windows/filter/*.h windows/common/*.h) $(ENGINE_OBJ)
	$(CXX) $(CXXFLAGS) -municode $(FILTER_SRC) $(ENGINE_OBJ) -o $@ $(LDFLAGS) $(ORTLIB) $(WIN_LIBS)

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
