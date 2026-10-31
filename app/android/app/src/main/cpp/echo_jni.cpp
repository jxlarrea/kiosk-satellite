// Software echo cancellation for realtime conversations: WebRTC's audio
// processing module (AEC3) over the microphone, with the assistant's voice
// as it plays as the reference. Driven by SoftwareEcho.kt, which feeds both
// directions from the capture thread, 10 ms at a time.

#include <jni.h>

#include <android/log.h>

#include <cstdint>
#include <cstring>
#include <mutex>
#include <algorithm>
#include <cmath>

#include <memory>
#include <optional>

#include "echo_config.h"
#include "api/audio/echo_control.h"
#include "modules/audio_processing/aec3/echo_canceller3.h"
#include "modules/audio_processing/include/audio_processing.h"

#ifdef KIOSK_ECHO_PROTOTYPE
#include "kiosk_echo_prototype.h"
#endif

namespace {

constexpr const char* kTag = "SoftwareEcho";

// Realtime acoustic tests have not passed. Keep their opt-in separate from calls.
#ifdef KIOSK_ECHO_PROTOTYPE_REALTIME
constexpr bool kPrototypeRealtime = true;
#else
constexpr bool kPrototypeRealtime = false;
#endif

struct Echo {
    rtc::scoped_refptr<webrtc::AudioProcessing> apm;
    webrtc::StreamConfig capture;
    webrtc::StreamConfig render;
    std::mutex lock;
#ifdef KIOSK_ECHO_PROTOTYPE
    std::unique_ptr<kiosk::EchoPrototype> prototype;
    float reference[160]{};
#endif
};

Echo* from(jlong handle) { return reinterpret_cast<Echo*>(handle); }

// AEC3 as the module builds it, but with its initial phase adapting like
// the rest. The canceller starts that phase over at every echo path change
// (each new sound can be one), runs faster filters through it, and swaps to
// its usual ones two and a half seconds in. The swap loosened its hold on
// the echo right there, and realtime answers leaked two to three seconds in.
class Aec3Factory : public webrtc::EchoControlFactory {
public:
    Aec3Factory() : config_(kiosk::EchoConfig()) {}

    std::unique_ptr<webrtc::EchoControl> Create(
        int sample_rate_hz, int num_render_channels, int num_capture_channels) override {
        return std::make_unique<webrtc::EchoCanceller3>(
            config_, std::nullopt, sample_rate_hz, num_render_channels, num_capture_channels);
    }

private:
    webrtc::EchoCanceller3Config config_;
};


}  // namespace

extern "C" JNIEXPORT jlong JNICALL
Java_me_jxl_kiosk_1satellite_SoftwareEcho_nativeCreate(
    JNIEnv*, jclass, jint captureRate, jint renderRate, jboolean noiseSuppression,
    jboolean intercom, jboolean realtime) {
    auto apm = webrtc::AudioProcessingBuilder()
                   .SetEchoControlFactory(std::make_unique<Aec3Factory>())
                   .Create();
    if (!apm) return 0;
    webrtc::AudioProcessing::Config config;
    config.echo_canceller.enabled = true;
    config.echo_canceller.mobile_mode = false;
    config.high_pass_filter.enabled = true;
    config.noise_suppression.enabled = noiseSuppression;
    config.noise_suppression.level =
        webrtc::AudioProcessing::Config::NoiseSuppression::kModerate;
    // The wake word and the provider both want the level as it is.
    config.gain_controller1.enabled = false;
    config.gain_controller2.enabled = false;
    apm->ApplyConfig(config);
    auto* echo = new Echo{apm, webrtc::StreamConfig(captureRate, 1),
                          webrtc::StreamConfig(renderRate, 1), {}};
#ifdef KIOSK_ECHO_PROTOTYPE
    if ((intercom || (realtime && kPrototypeRealtime)) && captureRate == 16000 && renderRate == 16000) {
        echo->prototype = std::make_unique<kiosk::EchoPrototype>();
        __android_log_print(ANDROID_LOG_INFO, kTag,
                            "experimental kiosk echo subtraction enabled, latency 8 ms");
    }
#endif
    __android_log_print(ANDROID_LOG_INFO, kTag,
                        "started (capture %d Hz, reference %d Hz, ns %s, mode %s)",
                        captureRate, renderRate, noiseSuppression ? "on" : "off",
                        intercom ? "intercom" : (realtime ? "realtime" : "default"));
    return reinterpret_cast<jlong>(echo);
}

// The prototype build bypasses the extra realtime output gate.
extern "C" JNIEXPORT jboolean JNICALL
Java_me_jxl_kiosk_1satellite_SoftwareEcho_nativePrototypeAvailable(JNIEnv*, jclass, jboolean realtime) {
#ifdef KIOSK_ECHO_PROTOTYPE
    return (!realtime || kPrototypeRealtime) ? JNI_TRUE : JNI_FALSE;
#else
    return JNI_FALSE;
#endif
}

// One 10 ms frame of what the speaker played, PCM16 at the reference rate.
extern "C" JNIEXPORT void JNICALL
Java_me_jxl_kiosk_1satellite_SoftwareEcho_nativeRender(
    JNIEnv* env, jclass, jlong handle, jbyteArray pcm, jint offset) {
    auto* echo = from(handle);
    const size_t frames = echo->render.num_frames();
    int16_t block[480];
    if (frames > sizeof(block) / sizeof(block[0])) return;
    env->GetByteArrayRegion(pcm, offset, static_cast<jsize>(frames * 2),
                            reinterpret_cast<jbyte*>(block));
    std::lock_guard<std::mutex> guard(echo->lock);
#ifdef KIOSK_ECHO_PROTOTYPE
    if (echo->prototype) {
        for (size_t i = 0; i < frames; ++i) echo->reference[i] = block[i] / 32768.f;
        return;
    }
#endif
    echo->apm->ProcessReverseStream(block, echo->render, echo->render, block);
}

// One 10 ms frame of the microphone, PCM16 at the capture rate, cleaned in
// place.
extern "C" JNIEXPORT void JNICALL
Java_me_jxl_kiosk_1satellite_SoftwareEcho_nativeCapture(
    JNIEnv* env, jclass, jlong handle, jbyteArray pcm, jint offset) {
    auto* echo = from(handle);
    const size_t frames = echo->capture.num_frames();
    int16_t block[480];
    if (frames > sizeof(block) / sizeof(block[0])) return;
    env->GetByteArrayRegion(pcm, offset, static_cast<jsize>(frames * 2),
                            reinterpret_cast<jbyte*>(block));
    {
        std::lock_guard<std::mutex> guard(echo->lock);
#ifdef KIOSK_ECHO_PROTOTYPE
        if (echo->prototype) {
            float microphone[160], output[160];
            for (size_t i = 0; i < frames; ++i) microphone[i] = block[i] / 32768.f;
            echo->prototype->Process(echo->reference, microphone, output, frames);
            for (size_t i = 0; i < frames; ++i)
                block[i] = static_cast<int16_t>(std::clamp(std::round(output[i] * 32768.f), -32768.f, 32767.f));
        } else
#endif
        {
        echo->apm->set_stream_delay_ms(0);
        echo->apm->ProcessStream(block, echo->capture, echo->capture, block);
        }
    }
    env->SetByteArrayRegion(pcm, offset, static_cast<jsize>(frames * 2),
                            reinterpret_cast<const jbyte*>(block));
}

// [echo return loss enhancement dB, delay ms, residual echo likelihood],
// NaN where the module has no figure yet.
extern "C" JNIEXPORT jdoubleArray JNICALL
Java_me_jxl_kiosk_1satellite_SoftwareEcho_nativeStats(JNIEnv* env, jclass, jlong handle) {
    auto* echo = from(handle);
    webrtc::AudioProcessingStats stats;
    {
        std::lock_guard<std::mutex> guard(echo->lock);
        stats = echo->apm->GetStatistics();
    }
    const double nan = __builtin_nan("");
    jdouble values[3] = {
        stats.echo_return_loss_enhancement.value_or(nan),
        stats.delay_ms ? static_cast<double>(*stats.delay_ms) : nan,
        stats.residual_echo_likelihood.value_or(nan),
    };
    jdoubleArray out = env->NewDoubleArray(3);
    env->SetDoubleArrayRegion(out, 0, 3, values);
    return out;
}

extern "C" JNIEXPORT void JNICALL
Java_me_jxl_kiosk_1satellite_SoftwareEcho_nativeDestroy(JNIEnv*, jclass, jlong handle) {
    delete from(handle);
}

// A second module with only the noise suppressor on, over every capture
// frame whether or not anything plays: a microphone's hiss is there all
// the time, and the canceller's module only runs while there is an echo.
extern "C" JNIEXPORT jlong JNICALL
Java_me_jxl_kiosk_1satellite_SoftwareEcho_nativeNsCreate(JNIEnv*, jclass, jint rate) {
    auto apm = webrtc::AudioProcessingBuilder().Create();
    if (!apm) return 0;
    webrtc::AudioProcessing::Config config;
    config.noise_suppression.enabled = true;
    // Moderate takes an Echo Show 8's hiss out of an intercom call and
    // leaves the room (an air conditioner's hum) as it is. High did the
    // same for the hiss, and Low was never needed.
    config.noise_suppression.level =
        webrtc::AudioProcessing::Config::NoiseSuppression::kModerate;
    config.gain_controller1.enabled = false;
    config.gain_controller2.enabled = false;
    apm->ApplyConfig(config);
    auto* echo = new Echo{apm, webrtc::StreamConfig(rate, 1), webrtc::StreamConfig(rate, 1), {}};
    __android_log_print(ANDROID_LOG_INFO, kTag, "noise suppression started (%d Hz)", rate);
    return reinterpret_cast<jlong>(echo);
}

// One 10 ms frame of the microphone, PCM16, suppressed in place.
extern "C" JNIEXPORT void JNICALL
Java_me_jxl_kiosk_1satellite_SoftwareEcho_nativeNsProcess(
    JNIEnv* env, jclass, jlong handle, jbyteArray pcm, jint offset) {
    auto* echo = from(handle);
    const size_t frames = echo->capture.num_frames();
    int16_t block[480];
    if (frames > sizeof(block) / sizeof(block[0])) return;
    env->GetByteArrayRegion(pcm, offset, static_cast<jsize>(frames * 2),
                            reinterpret_cast<jbyte*>(block));
    {
        std::lock_guard<std::mutex> guard(echo->lock);
        echo->apm->ProcessStream(block, echo->capture, echo->capture, block);
    }
    env->SetByteArrayRegion(pcm, offset, static_cast<jsize>(frames * 2),
                            reinterpret_cast<const jbyte*>(block));
}
