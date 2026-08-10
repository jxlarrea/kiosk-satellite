# Native SendSpin engine: sendspin-cpp (the protocol reference implementation)
# plus a JNI bridge. The library is fetched pinned to a release commit; its own
# dependencies (ArduinoJson, micro-flac, micro-opus, IXWebSocket) are fetched
# transitively by its build.
cmake_minimum_required(VERSION 3.22)
project(kiosk_satellite_native LANGUAGES CXX)

include(FetchContent)

# v0.7.0
FetchContent_Declare(
    sendspin_cpp
    GIT_REPOSITORY https://github.com/Sendspin/sendspin-cpp.git
    GIT_TAG        254603c283bc137aa2f748ff5b2c99a39c56faf2
)

# Player, controller, and metadata are the roles the app uses. Artwork arrives
# via the metadata artwork_url, and the spectrum tap runs on decoded PCM in the
# shell, so those roles stay out of the binary.
set(SENDSPIN_ENABLE_ARTWORK OFF CACHE BOOL "" FORCE)
set(SENDSPIN_ENABLE_COLOR OFF CACHE BOOL "" FORCE)
set(SENDSPIN_ENABLE_VISUALIZER OFF CACHE BOOL "" FORCE)

FetchContent_MakeAvailable(sendspin_cpp)

add_library(sendspin_jni SHARED sendspin_jni.cpp)

target_compile_features(sendspin_jni PRIVATE cxx_std_20)
target_compile_options(sendspin_jni PRIVATE -Wall -Wextra)

find_library(log-lib log)
target_link_libraries(sendspin_jni PRIVATE sendspin ${log-lib})
