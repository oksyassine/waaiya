cmake_minimum_required(VERSION 3.22.1)
project(imengine C)
set(ENGINE ${CMAKE_CURRENT_SOURCE_DIR}/../../../../../engine)
add_library(onnxruntime SHARED IMPORTED)
set_target_properties(onnxruntime PROPERTIES IMPORTED_LOCATION ${ORT_DIR}/jni/${ANDROID_ABI}/libonnxruntime.so)
add_library(imengine SHARED ${ENGINE}/src/im_engine.c ${ENGINE}/src/im_detector.c im_jni.c
            ${ENGINE}/src/im_music.c music_jni.c
            ${ENGINE}/src/im_vision.c ${ENGINE}/src/im_cover.c vision_jni.c
            ${ENGINE}/src/im_asr.c ${ENGINE}/src/im_ctc.c ${ENGINE}/src/im_captions.c captions_jni.c)
target_include_directories(imengine PRIVATE ${ENGINE}/include ${ORT_DIR}/headers)
target_compile_options(imengine PRIVATE -O2 -Wall -std=c11)
target_link_libraries(imengine onnxruntime log m)

# Updates: rebuilds a new APK from the installed one and a zstd patch (AppUpdatePatch.kt). Decoder-only zstd.
add_library(waaiyapatch SHARED zpatch/zpatch.c zpatch/zpatch_jni.c zstd/zstddeclib.c)
target_compile_options(waaiyapatch PRIVATE -O2 -Wall -std=c11 -D_FILE_OFFSET_BITS=64)
