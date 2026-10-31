# WebRTC's audio processing module (AEC3 echo cancellation, noise suppression,
# gain control) from freedesktop's webrtc-audio-processing, which packages it
# with meson. This mirrors that build for Android: the source lists come from
# its compile commands for arm64, armeabi-v7a and x86_64 (NEON on), and
# abseil comes in through its own CMake build. When moving to another
# release, run its meson setup with an NDK cross file per ABI and
# -Dneon=enabled, then copy the .cc and .c files each compile_commands.json
# lists for the webrtc-audio-processing library.

include(FetchContent)

# v2.1
FetchContent_Declare(
    webrtc_apm
    GIT_REPOSITORY https://gitlab.freedesktop.org/pulseaudio/webrtc-audio-processing.git
    GIT_TAG        846fe90a289f58b7c9303a635142aa2c7caa93e5
)
FetchContent_GetProperties(webrtc_apm)
if(NOT webrtc_apm_POPULATED)
    FetchContent_Populate(webrtc_apm)
endif()

# Add per-instance control of generated comfort noise. Realtime keeps the
# upstream default. Intercom can avoid feeding synthetic noise around a call.
# The reverse check makes this safe across repeated CMake configuration runs.
set(apm_comfort_patch "${CMAKE_CURRENT_LIST_DIR}/patches/webrtc-apm-comfort-noise.patch")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${apm_comfort_patch}")
execute_process(
    COMMAND git apply --reverse --check "${apm_comfort_patch}"
    WORKING_DIRECTORY "${webrtc_apm_SOURCE_DIR}"
    RESULT_VARIABLE apm_comfort_applied OUTPUT_QUIET ERROR_QUIET)
if(NOT apm_comfort_applied EQUAL 0)
    execute_process(
        COMMAND git apply "${apm_comfort_patch}"
        WORKING_DIRECTORY "${webrtc_apm_SOURCE_DIR}"
        RESULT_VARIABLE apm_comfort_result ERROR_VARIABLE apm_comfort_error)
    if(NOT apm_comfort_result EQUAL 0)
        message(FATAL_ERROR "Cannot apply WebRTC comfort noise patch: ${apm_comfort_error}")
    endif()
endif()

# The abseil release webrtc-audio-processing v2.1 builds against.
FetchContent_Declare(
    absl
    URL      https://github.com/abseil/abseil-cpp/releases/download/20240722.0/abseil-cpp-20240722.0.tar.gz
    URL_HASH SHA256=f50e5ac311a81382da7fa75b97310e4b9006474f9560ac46f54a9967f07d4ae3
)
set(ABSL_PROPAGATE_CXX_STD ON CACHE BOOL "" FORCE)
set(ABSL_ENABLE_INSTALL OFF CACHE BOOL "" FORCE)
set(ABSL_BUILD_TESTING OFF CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(absl)

set(WEBRTC_APM_SOURCES
    webrtc/api/audio/audio_frame.cc
    webrtc/api/audio/audio_processing.cc
    webrtc/api/audio/audio_processing_statistics.cc
    webrtc/api/audio/channel_layout.cc
    webrtc/api/audio/echo_canceller3_config.cc
    webrtc/api/rtp_headers.cc
    webrtc/api/rtp_packet_info.cc
    webrtc/api/task_queue/task_queue_base.cc
    webrtc/api/units/frequency.cc
    webrtc/api/units/time_delta.cc
    webrtc/api/units/timestamp.cc
    webrtc/api/video/color_space.cc
    webrtc/api/video/hdr_metadata.cc
    webrtc/api/video/video_content_type.cc
    webrtc/api/video/video_timing.cc
    webrtc/common_audio/audio_converter.cc
    webrtc/common_audio/audio_util.cc
    webrtc/common_audio/channel_buffer.cc
    webrtc/common_audio/fir_filter_c.cc
    webrtc/common_audio/fir_filter_factory.cc
    webrtc/common_audio/resampler/push_resampler.cc
    webrtc/common_audio/resampler/push_sinc_resampler.cc
    webrtc/common_audio/resampler/resampler.cc
    webrtc/common_audio/resampler/sinc_resampler.cc
    webrtc/common_audio/resampler/sinusoidal_linear_chirp_source.cc
    webrtc/common_audio/ring_buffer.c
    webrtc/common_audio/signal_processing/auto_corr_to_refl_coef.c
    webrtc/common_audio/signal_processing/auto_correlation.c
    webrtc/common_audio/signal_processing/complex_bit_reverse.c
    webrtc/common_audio/signal_processing/complex_fft.c
    webrtc/common_audio/signal_processing/copy_set_operations.c
    webrtc/common_audio/signal_processing/cross_correlation.c
    webrtc/common_audio/signal_processing/division_operations.c
    webrtc/common_audio/signal_processing/dot_product_with_scale.cc
    webrtc/common_audio/signal_processing/downsample_fast.c
    webrtc/common_audio/signal_processing/energy.c
    webrtc/common_audio/signal_processing/filter_ar.c
    webrtc/common_audio/signal_processing/filter_ar_fast_q12.c
    webrtc/common_audio/signal_processing/filter_ma_fast_q12.c
    webrtc/common_audio/signal_processing/get_hanning_window.c
    webrtc/common_audio/signal_processing/get_scaling_square.c
    webrtc/common_audio/signal_processing/ilbc_specific_functions.c
    webrtc/common_audio/signal_processing/levinson_durbin.c
    webrtc/common_audio/signal_processing/lpc_to_refl_coef.c
    webrtc/common_audio/signal_processing/min_max_operations.c
    webrtc/common_audio/signal_processing/randomization_functions.c
    webrtc/common_audio/signal_processing/real_fft.c
    webrtc/common_audio/signal_processing/refl_coef_to_lpc.c
    webrtc/common_audio/signal_processing/resample.c
    webrtc/common_audio/signal_processing/resample_48khz.c
    webrtc/common_audio/signal_processing/resample_by_2.c
    webrtc/common_audio/signal_processing/resample_by_2_internal.c
    webrtc/common_audio/signal_processing/resample_fractional.c
    webrtc/common_audio/signal_processing/spl_init.c
    webrtc/common_audio/signal_processing/spl_inl.c
    webrtc/common_audio/signal_processing/spl_sqrt.c
    webrtc/common_audio/signal_processing/splitting_filter.c
    webrtc/common_audio/signal_processing/sqrt_of_one_minus_x_squared.c
    webrtc/common_audio/signal_processing/vector_scaling_operations.c
    webrtc/common_audio/smoothing_filter.cc
    webrtc/common_audio/third_party/ooura/fft_size_128/ooura_fft.cc
    webrtc/common_audio/third_party/ooura/fft_size_256/fft4g.cc
    webrtc/common_audio/third_party/spl_sqrt_floor/spl_sqrt_floor.c
    webrtc/common_audio/vad/vad.cc
    webrtc/common_audio/vad/vad_core.c
    webrtc/common_audio/vad/vad_filterbank.c
    webrtc/common_audio/vad/vad_gmm.c
    webrtc/common_audio/vad/vad_sp.c
    webrtc/common_audio/vad/webrtc_vad.c
    webrtc/modules/audio_coding/codecs/isac/main/source/filter_functions.c
    webrtc/modules/audio_coding/codecs/isac/main/source/isac_vad.c
    webrtc/modules/audio_coding/codecs/isac/main/source/pitch_estimator.c
    webrtc/modules/audio_coding/codecs/isac/main/source/pitch_filter.c
    webrtc/modules/audio_processing/aec3/adaptive_fir_filter.cc
    webrtc/modules/audio_processing/aec3/adaptive_fir_filter_erl.cc
    webrtc/modules/audio_processing/aec3/aec3_common.cc
    webrtc/modules/audio_processing/aec3/aec3_fft.cc
    webrtc/modules/audio_processing/aec3/aec_state.cc
    webrtc/modules/audio_processing/aec3/alignment_mixer.cc
    webrtc/modules/audio_processing/aec3/api_call_jitter_metrics.cc
    webrtc/modules/audio_processing/aec3/block_buffer.cc
    webrtc/modules/audio_processing/aec3/block_delay_buffer.cc
    webrtc/modules/audio_processing/aec3/block_framer.cc
    webrtc/modules/audio_processing/aec3/block_processor.cc
    webrtc/modules/audio_processing/aec3/block_processor_metrics.cc
    webrtc/modules/audio_processing/aec3/clockdrift_detector.cc
    webrtc/modules/audio_processing/aec3/coarse_filter_update_gain.cc
    webrtc/modules/audio_processing/aec3/comfort_noise_generator.cc
    webrtc/modules/audio_processing/aec3/config_selector.cc
    webrtc/modules/audio_processing/aec3/decimator.cc
    webrtc/modules/audio_processing/aec3/dominant_nearend_detector.cc
    webrtc/modules/audio_processing/aec3/downsampled_render_buffer.cc
    webrtc/modules/audio_processing/aec3/echo_audibility.cc
    webrtc/modules/audio_processing/aec3/echo_canceller3.cc
    webrtc/modules/audio_processing/aec3/echo_path_delay_estimator.cc
    webrtc/modules/audio_processing/aec3/echo_path_variability.cc
    webrtc/modules/audio_processing/aec3/echo_remover.cc
    webrtc/modules/audio_processing/aec3/echo_remover_metrics.cc
    webrtc/modules/audio_processing/aec3/erl_estimator.cc
    webrtc/modules/audio_processing/aec3/erle_estimator.cc
    webrtc/modules/audio_processing/aec3/fft_buffer.cc
    webrtc/modules/audio_processing/aec3/filter_analyzer.cc
    webrtc/modules/audio_processing/aec3/frame_blocker.cc
    webrtc/modules/audio_processing/aec3/fullband_erle_estimator.cc
    webrtc/modules/audio_processing/aec3/matched_filter.cc
    webrtc/modules/audio_processing/aec3/matched_filter_lag_aggregator.cc
    webrtc/modules/audio_processing/aec3/moving_average.cc
    webrtc/modules/audio_processing/aec3/multi_channel_content_detector.cc
    webrtc/modules/audio_processing/aec3/refined_filter_update_gain.cc
    webrtc/modules/audio_processing/aec3/render_buffer.cc
    webrtc/modules/audio_processing/aec3/render_delay_buffer.cc
    webrtc/modules/audio_processing/aec3/render_delay_controller.cc
    webrtc/modules/audio_processing/aec3/render_delay_controller_metrics.cc
    webrtc/modules/audio_processing/aec3/render_signal_analyzer.cc
    webrtc/modules/audio_processing/aec3/residual_echo_estimator.cc
    webrtc/modules/audio_processing/aec3/reverb_decay_estimator.cc
    webrtc/modules/audio_processing/aec3/reverb_frequency_response.cc
    webrtc/modules/audio_processing/aec3/reverb_model.cc
    webrtc/modules/audio_processing/aec3/reverb_model_estimator.cc
    webrtc/modules/audio_processing/aec3/signal_dependent_erle_estimator.cc
    webrtc/modules/audio_processing/aec3/spectrum_buffer.cc
    webrtc/modules/audio_processing/aec3/stationarity_estimator.cc
    webrtc/modules/audio_processing/aec3/subband_erle_estimator.cc
    webrtc/modules/audio_processing/aec3/subband_nearend_detector.cc
    webrtc/modules/audio_processing/aec3/subtractor.cc
    webrtc/modules/audio_processing/aec3/subtractor_output.cc
    webrtc/modules/audio_processing/aec3/subtractor_output_analyzer.cc
    webrtc/modules/audio_processing/aec3/suppression_filter.cc
    webrtc/modules/audio_processing/aec3/suppression_gain.cc
    webrtc/modules/audio_processing/aec3/transparent_mode.cc
    webrtc/modules/audio_processing/aec_dump/null_aec_dump_factory.cc
    webrtc/modules/audio_processing/aecm/aecm_core.cc
    webrtc/modules/audio_processing/aecm/aecm_core_c.cc
    webrtc/modules/audio_processing/aecm/echo_control_mobile.cc
    webrtc/modules/audio_processing/agc/agc.cc
    webrtc/modules/audio_processing/agc/agc_manager_direct.cc
    webrtc/modules/audio_processing/agc/legacy/analog_agc.cc
    webrtc/modules/audio_processing/agc/legacy/digital_agc.cc
    webrtc/modules/audio_processing/agc/loudness_histogram.cc
    webrtc/modules/audio_processing/agc/utility.cc
    webrtc/modules/audio_processing/agc2/adaptive_digital_gain_controller.cc
    webrtc/modules/audio_processing/agc2/agc2_testing_common.cc
    webrtc/modules/audio_processing/agc2/biquad_filter.cc
    webrtc/modules/audio_processing/agc2/clipping_predictor.cc
    webrtc/modules/audio_processing/agc2/clipping_predictor_level_buffer.cc
    webrtc/modules/audio_processing/agc2/compute_interpolated_gain_curve.cc
    webrtc/modules/audio_processing/agc2/cpu_features.cc
    webrtc/modules/audio_processing/agc2/fixed_digital_level_estimator.cc
    webrtc/modules/audio_processing/agc2/gain_applier.cc
    webrtc/modules/audio_processing/agc2/input_volume_controller.cc
    webrtc/modules/audio_processing/agc2/input_volume_stats_reporter.cc
    webrtc/modules/audio_processing/agc2/interpolated_gain_curve.cc
    webrtc/modules/audio_processing/agc2/limiter.cc
    webrtc/modules/audio_processing/agc2/limiter_db_gain_curve.cc
    webrtc/modules/audio_processing/agc2/noise_level_estimator.cc
    webrtc/modules/audio_processing/agc2/rnn_vad/auto_correlation.cc
    webrtc/modules/audio_processing/agc2/rnn_vad/features_extraction.cc
    webrtc/modules/audio_processing/agc2/rnn_vad/lp_residual.cc
    webrtc/modules/audio_processing/agc2/rnn_vad/pitch_search.cc
    webrtc/modules/audio_processing/agc2/rnn_vad/pitch_search_internal.cc
    webrtc/modules/audio_processing/agc2/rnn_vad/rnn.cc
    webrtc/modules/audio_processing/agc2/rnn_vad/rnn_fc.cc
    webrtc/modules/audio_processing/agc2/rnn_vad/rnn_gru.cc
    webrtc/modules/audio_processing/agc2/rnn_vad/spectral_features.cc
    webrtc/modules/audio_processing/agc2/rnn_vad/spectral_features_internal.cc
    webrtc/modules/audio_processing/agc2/saturation_protector.cc
    webrtc/modules/audio_processing/agc2/saturation_protector_buffer.cc
    webrtc/modules/audio_processing/agc2/speech_level_estimator.cc
    webrtc/modules/audio_processing/agc2/speech_probability_buffer.cc
    webrtc/modules/audio_processing/agc2/vad_wrapper.cc
    webrtc/modules/audio_processing/agc2/vector_float_frame.cc
    webrtc/modules/audio_processing/audio_buffer.cc
    webrtc/modules/audio_processing/audio_processing_builder_impl.cc
    webrtc/modules/audio_processing/audio_processing_impl.cc
    webrtc/modules/audio_processing/capture_levels_adjuster/audio_samples_scaler.cc
    webrtc/modules/audio_processing/capture_levels_adjuster/capture_levels_adjuster.cc
    webrtc/modules/audio_processing/echo_control_mobile_impl.cc
    webrtc/modules/audio_processing/echo_detector/circular_buffer.cc
    webrtc/modules/audio_processing/echo_detector/mean_variance_estimator.cc
    webrtc/modules/audio_processing/echo_detector/moving_max.cc
    webrtc/modules/audio_processing/echo_detector/normalized_covariance_estimator.cc
    webrtc/modules/audio_processing/gain_control_impl.cc
    webrtc/modules/audio_processing/gain_controller2.cc
    webrtc/modules/audio_processing/high_pass_filter.cc
    webrtc/modules/audio_processing/include/aec_dump.cc
    webrtc/modules/audio_processing/include/audio_frame_proxies.cc
    webrtc/modules/audio_processing/logging/apm_data_dumper.cc
    webrtc/modules/audio_processing/ns/fast_math.cc
    webrtc/modules/audio_processing/ns/histograms.cc
    webrtc/modules/audio_processing/ns/noise_estimator.cc
    webrtc/modules/audio_processing/ns/noise_suppressor.cc
    webrtc/modules/audio_processing/ns/ns_fft.cc
    webrtc/modules/audio_processing/ns/prior_signal_model.cc
    webrtc/modules/audio_processing/ns/prior_signal_model_estimator.cc
    webrtc/modules/audio_processing/ns/quantile_noise_estimator.cc
    webrtc/modules/audio_processing/ns/signal_model.cc
    webrtc/modules/audio_processing/ns/signal_model_estimator.cc
    webrtc/modules/audio_processing/ns/speech_probability_estimator.cc
    webrtc/modules/audio_processing/ns/suppression_params.cc
    webrtc/modules/audio_processing/ns/wiener_filter.cc
    webrtc/modules/audio_processing/residual_echo_detector.cc
    webrtc/modules/audio_processing/rms_level.cc
    webrtc/modules/audio_processing/splitting_filter.cc
    webrtc/modules/audio_processing/three_band_filter_bank.cc
    webrtc/modules/audio_processing/utility/cascaded_biquad_filter.cc
    webrtc/modules/audio_processing/utility/delay_estimator.cc
    webrtc/modules/audio_processing/utility/delay_estimator_wrapper.cc
    webrtc/modules/audio_processing/utility/pffft_wrapper.cc
    webrtc/modules/audio_processing/vad/gmm.cc
    webrtc/modules/audio_processing/vad/pitch_based_vad.cc
    webrtc/modules/audio_processing/vad/pitch_internal.cc
    webrtc/modules/audio_processing/vad/pole_zero_filter.cc
    webrtc/modules/audio_processing/vad/standalone_vad.cc
    webrtc/modules/audio_processing/vad/vad_audio_proc.cc
    webrtc/modules/audio_processing/vad/vad_circular_buffer.cc
    webrtc/modules/audio_processing/vad/voice_activity_detector.cc
    webrtc/modules/third_party/fft/fft.c
    webrtc/rtc_base/checks.cc
    webrtc/rtc_base/containers/flat_tree.cc
    webrtc/rtc_base/event.cc
    webrtc/rtc_base/event_tracer.cc
    webrtc/rtc_base/experiments/field_trial_parser.cc
    webrtc/rtc_base/logging.cc
    webrtc/rtc_base/memory/aligned_malloc.cc
    webrtc/rtc_base/platform_thread.cc
    webrtc/rtc_base/platform_thread_types.cc
    webrtc/rtc_base/race_checker.cc
    webrtc/rtc_base/random.cc
    webrtc/rtc_base/string_encode.cc
    webrtc/rtc_base/string_to_number.cc
    webrtc/rtc_base/string_utils.cc
    webrtc/rtc_base/strings/string_builder.cc
    webrtc/rtc_base/synchronization/sequence_checker_internal.cc
    webrtc/rtc_base/synchronization/yield_policy.cc
    webrtc/rtc_base/system/file_wrapper.cc
    webrtc/rtc_base/system/warn_current_thread_is_deadlocked.cc
    webrtc/rtc_base/system_time.cc
    webrtc/rtc_base/time_utils.cc
    webrtc/rtc_base/zero_memory.cc
    webrtc/system_wrappers/source/cpu_features.cc
    webrtc/system_wrappers/source/denormal_disabler.cc
    webrtc/system_wrappers/source/field_trial.cc
    webrtc/system_wrappers/source/metrics.cc
    webrtc/system_wrappers/source/sleep.cc
    webrtc/third_party/pffft/src/pffft.c
    webrtc/third_party/rnnoise/src/rnn_vad_weights.cc
)

set(WEBRTC_APM_NEON_SOURCES
    webrtc/common_audio/fir_filter_neon.cc
    webrtc/common_audio/resampler/sinc_resampler_neon.cc
    webrtc/common_audio/signal_processing/cross_correlation_neon.c
    webrtc/common_audio/signal_processing/downsample_fast_neon.c
    webrtc/common_audio/signal_processing/min_max_operations_neon.c
    webrtc/common_audio/third_party/ooura/fft_size_128/ooura_fft_neon.cc
    webrtc/modules/audio_processing/aecm/aecm_core_neon.cc
)

set(WEBRTC_APM_ARMV7_ASM_SOURCES
    webrtc/common_audio/signal_processing/complex_bit_reverse_arm.S
    webrtc/common_audio/signal_processing/filter_ar_fast_q12_armv7.S
    webrtc/common_audio/third_party/spl_sqrt_floor/spl_sqrt_floor_arm.S
)

set(WEBRTC_APM_SSE2_SOURCES
    webrtc/common_audio/fir_filter_sse.cc
    webrtc/common_audio/resampler/sinc_resampler_sse.cc
    webrtc/common_audio/third_party/ooura/fft_size_128/ooura_fft_sse2.cc
)

set(WEBRTC_APM_AVX2_SOURCES
    webrtc/common_audio/fir_filter_avx2.cc
    webrtc/common_audio/resampler/sinc_resampler_avx2.cc
    webrtc/modules/audio_processing/aec3/adaptive_fir_filter_avx2.cc
    webrtc/modules/audio_processing/aec3/adaptive_fir_filter_erl_avx2.cc
    webrtc/modules/audio_processing/aec3/fft_data_avx2.cc
    webrtc/modules/audio_processing/aec3/matched_filter_avx2.cc
    webrtc/modules/audio_processing/aec3/vector_math_avx2.cc
    webrtc/modules/audio_processing/agc2/rnn_vad/vector_math_avx2.cc
)

set(apm_arch_defines)
set(apm_sources ${WEBRTC_APM_SOURCES})
if(ANDROID_ABI STREQUAL "arm64-v8a")
    list(APPEND apm_arch_defines WEBRTC_ARCH_ARM64 WEBRTC_HAS_NEON)
    list(APPEND apm_sources ${WEBRTC_APM_NEON_SOURCES})
elseif(ANDROID_ABI STREQUAL "armeabi-v7a")
    list(APPEND apm_arch_defines WEBRTC_ARCH_ARM WEBRTC_ARCH_ARM_V7 WEBRTC_HAS_NEON)
    list(APPEND apm_sources ${WEBRTC_APM_NEON_SOURCES} ${WEBRTC_APM_ARMV7_ASM_SOURCES})
elseif(ANDROID_ABI STREQUAL "x86_64")
    list(APPEND apm_arch_defines WEBRTC_ENABLE_AVX2)
    list(APPEND apm_sources ${WEBRTC_APM_SSE2_SOURCES} ${WEBRTC_APM_AVX2_SOURCES})
    list(TRANSFORM WEBRTC_APM_SSE2_SOURCES PREPEND ${webrtc_apm_SOURCE_DIR}/)
    list(TRANSFORM WEBRTC_APM_AVX2_SOURCES PREPEND ${webrtc_apm_SOURCE_DIR}/)
    set_source_files_properties(${WEBRTC_APM_SSE2_SOURCES} PROPERTIES COMPILE_OPTIONS "-msse2")
    set_source_files_properties(${WEBRTC_APM_AVX2_SOURCES} PROPERTIES COMPILE_OPTIONS "-mavx2;-mfma")
endif()
list(TRANSFORM apm_sources PREPEND ${webrtc_apm_SOURCE_DIR}/)

add_library(webrtc_apm STATIC ${apm_sources})
target_compile_features(webrtc_apm PUBLIC cxx_std_17)
target_compile_definitions(webrtc_apm PUBLIC
    WEBRTC_ANDROID WEBRTC_LINUX WEBRTC_POSIX WEBRTC_APM_DEBUG_DUMP=0
    ${apm_arch_defines}
    PRIVATE NDEBUG WEBRTC_LIBRARY_IMPL _GNU_SOURCE)
if(ANDROID_ABI STREQUAL "armeabi-v7a")
    target_compile_options(webrtc_apm PRIVATE -mfpu=neon)
endif()
target_compile_options(webrtc_apm PRIVATE -w)
target_include_directories(webrtc_apm PUBLIC
    ${webrtc_apm_SOURCE_DIR}
    ${webrtc_apm_SOURCE_DIR}/webrtc
    ${webrtc_apm_SOURCE_DIR}/webrtc/third_party/pffft
    ${webrtc_apm_SOURCE_DIR}/webrtc/third_party/rnnoise
    ${webrtc_apm_SOURCE_DIR}/webrtc/modules/third_party/fft)
target_link_libraries(webrtc_apm PUBLIC
    absl::base absl::flags absl::strings absl::numeric
    absl::synchronization absl::bad_optional_access absl::optional)
