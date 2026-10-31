# Native SendSpin engine: sendspin-cpp (the protocol reference implementation)
# plus a JNI bridge. The library is fetched pinned to a release commit; its own
# dependencies (ArduinoJson, micro-flac, micro-opus, IXWebSocket) are fetched
# transitively by its build.
cmake_minimum_required(VERSION 3.22)
project(kiosk_satellite_native LANGUAGES C CXX ASM)

include(FetchContent)

# v0.7.0
FetchContent_Declare(
    sendspin_cpp
    GIT_REPOSITORY https://github.com/Sendspin/sendspin-cpp.git
    GIT_TAG        254603c283bc137aa2f748ff5b2c99a39c56faf2
)

# Player, controller, metadata and artwork are the roles the app uses. The
# artwork role carries the cover as bytes for a kiosk that cannot reach the
# metadata's artwork_url. The spectrum tap runs on decoded PCM in the shell, so
# the color and visualizer roles stay out of the binary.
set(SENDSPIN_ENABLE_ARTWORK ON CACHE BOOL "" FORCE)
set(SENDSPIN_ENABLE_COLOR OFF CACHE BOOL "" FORCE)
set(SENDSPIN_ENABLE_VISUALIZER OFF CACHE BOOL "" FORCE)

FetchContent_MakeAvailable(sendspin_cpp)

add_library(sendspin_jni SHARED sendspin_jni.cpp)

target_compile_features(sendspin_jni PRIVATE cxx_std_20)
target_compile_options(sendspin_jni PRIVATE -Wall -Wextra)

find_library(log-lib log)
target_link_libraries(sendspin_jni PRIVATE sendspin ${log-lib})

add_library(kiosk_wake_fft SHARED
    wake_fft.cpp micro_fft.cpp log_mel.cpp micro_frontend.cpp)
target_compile_features(kiosk_wake_fft PRIVATE cxx_std_17)
target_compile_options(kiosk_wake_fft PRIVATE
    -Wall -Wextra -fno-fast-math -ffp-contract=off)

# Software echo cancellation for realtime conversations (SoftwareEcho.kt):
# WebRTC's audio processing module and a JNI bridge.
include(webrtc_apm.cmake)

add_library(kiosk_echo SHARED echo_jni.cpp)
target_compile_features(kiosk_echo PRIVATE cxx_std_17)
target_compile_options(kiosk_echo PRIVATE -Wall -Wextra)
target_link_libraries(kiosk_echo PRIVATE webrtc_apm ${log-lib})

option(KIOSK_ECHO_PROTOTYPE "Use the experimental canceller for duplex audio tests" OFF)
option(KIOSK_ECHO_PROTOTYPE_REALTIME "Include realtime voice in experimental acoustic tests" OFF)
if(KIOSK_ECHO_PROTOTYPE_REALTIME AND NOT KIOSK_ECHO_PROTOTYPE)
    message(FATAL_ERROR "Realtime prototype tests require KIOSK_ECHO_PROTOTYPE")
endif()
if(KIOSK_ECHO_PROTOTYPE)
    target_sources(kiosk_echo PRIVATE kiosk_echo_prototype.cpp)
    target_compile_definitions(kiosk_echo PRIVATE KIOSK_ECHO_PROTOTYPE=1)
    if(KIOSK_ECHO_PROTOTYPE_REALTIME)
        target_compile_definitions(kiosk_echo PRIVATE KIOSK_ECHO_PROTOTYPE_REALTIME=1)
    endif()
endif()

# Standalone DSP regression. Build this target explicitly and run it on Android.
add_executable(kiosk_echo_comfort_test EXCLUDE_FROM_ALL
    ../../test/cpp/echo_comfort_noise_test.cpp)
target_compile_features(kiosk_echo_comfort_test PRIVATE cxx_std_17)
target_link_libraries(kiosk_echo_comfort_test PRIVATE webrtc_apm ${log-lib})

# Experimental canceller, kept outside the app until acoustic validation passes.
add_executable(kiosk_echo_prototype_test EXCLUDE_FROM_ALL
    kiosk_echo_prototype.cpp ../../test/cpp/echo_prototype_test.cpp)
target_compile_features(kiosk_echo_prototype_test PRIVATE cxx_std_17)
target_compile_options(kiosk_echo_prototype_test PRIVATE -Wall -Wextra)

# LocalVQE's GTCRN-AEC as the echo canceller (SoftwareEcho.kt), with AEC3 as
# the fallback. Last in this file: its 32-bit ARM compile flag applies to the
# targets created after it.
include(localvqe.cmake)
target_sources(kiosk_echo PRIVATE ${LOCALVQE_API_SOURCE})
target_compile_definitions(kiosk_echo PRIVATE KIOSK_LOCALVQE=1 LOCALVQE_BUILD)
target_link_libraries(kiosk_echo PRIVATE dvqe_graph)
