# LocalVQE (https://github.com/localai-org/LocalVQE), the neural echo canceller
# SoftwareEcho runs (its GTCRN-AEC model), and the ggml it builds on. Pinned to
# a release commit with its ggml submodule; three patches go on top:
#   - LocalVQE's own fused GRU op for ggml (patches/ggml-gru.patch in its tree,
#     applied here first because the next patch builds on it; LocalVQE's
#     configure then sees the op present and leaves ggml alone),
#   - localvqe-ggml-armv7.patch: ggml's CPU backend made fast on 32-bit ARM
#     (NEON paths that need VFPv4, 32-bit indexing, small mat-mul and conv
#     kernels),
#   - localvqe-armv7.patch: LocalVQE's echo front-end and GTCRN transforms in
#     NEON, localvqe_resume / localvqe_echo_delay in its C API, and its
#     static single-library ggml build on every Android ABI.
# A local checkout can stand in with -DFETCHCONTENT_SOURCE_DIR_LOCALVQE=<dir>.

include(FetchContent)

FetchContent_Declare(
    localvqe
    GIT_REPOSITORY https://github.com/localai-org/LocalVQE.git
    GIT_TAG        7f61cd05095d42e56a135b303f5bb4d761da22b9
    GIT_SUBMODULES ggml/vendor/ggml
)
FetchContent_GetProperties(localvqe)
if(NOT localvqe_POPULATED)
    FetchContent_Populate(localvqe)
endif()

# The patches stack (the ARMv7 ggml patch rewrites code the GRU patch adds),
# so they go on as a set: the fetched tree carries a stamp of the set applied,
# and a missing or different stamp resets both git trees to the pinned commits
# and applies all three in order. A local checkout given through
# FETCHCONTENT_SOURCE_DIR_LOCALVQE is used as it is, never reset or patched.
set(localvqe_patches
    "${localvqe_SOURCE_DIR}/ggml/patches/ggml-gru.patch|ggml/vendor/ggml"
    "${CMAKE_CURRENT_LIST_DIR}/patches/localvqe-ggml-armv7.patch|ggml/vendor/ggml"
    "${CMAKE_CURRENT_LIST_DIR}/patches/localvqe-armv7.patch|.")
if(NOT FETCHCONTENT_SOURCE_DIR_LOCALVQE)
    set(localvqe_patch_id "")
    foreach(entry IN LISTS localvqe_patches)
        string(REPLACE "|" ";" parts "${entry}")
        list(GET parts 0 patch)
        set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${patch}")
        file(SHA256 "${patch}" hash)
        string(APPEND localvqe_patch_id "${hash}")
    endforeach()
    set(stamp "${localvqe_SOURCE_DIR}/.kiosk-patches")
    set(applied "")
    if(EXISTS "${stamp}")
        file(READ "${stamp}" applied)
    endif()
    if(NOT applied STREQUAL localvqe_patch_id)
        foreach(dir "${localvqe_SOURCE_DIR}" "${localvqe_SOURCE_DIR}/ggml/vendor/ggml")
            execute_process(COMMAND git checkout -q -- . WORKING_DIRECTORY "${dir}")
            execute_process(COMMAND git clean -fdq WORKING_DIRECTORY "${dir}")
        endforeach()
        foreach(entry IN LISTS localvqe_patches)
            string(REPLACE "|" ";" parts "${entry}")
            list(GET parts 0 patch)
            list(GET parts 1 sub)
            execute_process(
                COMMAND git apply --whitespace=nowarn "${patch}"
                WORKING_DIRECTORY "${localvqe_SOURCE_DIR}/${sub}"
                RESULT_VARIABLE result ERROR_VARIABLE error)
            if(NOT result EQUAL 0)
                message(FATAL_ERROR "Cannot apply ${patch}: ${error}")
            endif()
        endforeach()
        file(WRITE "${stamp}" "${localvqe_patch_id}")
    endif()
endif()

set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(LOCALVQE_BUILD_SHARED OFF CACHE BOOL "" FORCE)
set(GGML_OPENMP OFF CACHE BOOL "" FORCE)
# ggml's NEON float path needs fused multiply-add, which 32-bit ARM only has
# from VFPv4 on (Cortex-A7/A15/A53 and later). Only LocalVQE and ggml are built
# for it (this directory property reaches targets created after it);
# SoftwareEcho checks the CPU before using them.
if(ANDROID_ABI STREQUAL "armeabi-v7a")
    add_compile_options(-mfpu=neon-vfpv4)
endif()
add_subdirectory("${localvqe_SOURCE_DIR}/ggml" "${CMAKE_BINARY_DIR}/localvqe" EXCLUDE_FROM_ALL)
set(LOCALVQE_API_SOURCE "${localvqe_SOURCE_DIR}/ggml/localvqe_api.cpp")
