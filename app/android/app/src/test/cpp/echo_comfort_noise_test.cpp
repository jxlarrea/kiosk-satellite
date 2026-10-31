// Standalone regression for replacement noise in a continuous speakerphone call.
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <memory>
#include <optional>
#include <vector>

#include "../../main/cpp/echo_config.h"
#include "api/audio/echo_control.h"
#include "modules/audio_processing/aec3/echo_canceller3.h"
#include "modules/audio_processing/include/audio_processing.h"

namespace {
constexpr int kRate = 16000;
constexpr int kFrame = 160;
constexpr int kSeconds = 300;
constexpr double kPi = 3.14159265358979323846;

class Factory : public webrtc::EchoControlFactory {
 public:
  explicit Factory(bool comfort_noise) {
    config_ = kiosk::EchoConfig();
    config_.comfort_noise.enabled = comfort_noise;
  }
  std::unique_ptr<webrtc::EchoControl> Create(int rate, int render, int capture) override {
    return std::make_unique<webrtc::EchoCanceller3>(
        config_, std::nullopt, rate, render, capture);
  }
 private:
  webrtc::EchoCanceller3Config config_;
};

std::vector<int16_t> Run(bool comfort_noise, const std::vector<int16_t>& render,
                         const std::vector<int16_t>& capture) {
  auto apm = webrtc::AudioProcessingBuilder()
                 .SetEchoControlFactory(std::make_unique<Factory>(comfort_noise))
                 .Create();
  webrtc::AudioProcessing::Config config;
  config.echo_canceller.enabled = true;
  config.high_pass_filter.enabled = true;
  config.gain_controller1.enabled = false;
  config.gain_controller2.enabled = false;
  apm->ApplyConfig(config);
  const webrtc::StreamConfig format(kRate, 1);
  std::vector<int16_t> output(capture.size());
  int16_t reverse[kFrame];
  for (size_t at = 0; at < capture.size(); at += kFrame) {
    apm->ProcessReverseStream(render.data() + at, format, format, reverse);
    apm->set_stream_delay_ms(0);
    apm->ProcessStream(capture.data() + at, format, format, output.data() + at);
  }
  return output;
}

double Rms(const std::vector<int16_t>& samples, int first_second, int last_second) {
  double power = 0;
  for (int i = first_second * kRate; i < last_second * kRate; ++i)
    power += static_cast<double>(samples[i]) * samples[i];
  return std::sqrt(power / ((last_second - first_second) * kRate));
}

double NearGain(const std::vector<int16_t>& output, const std::vector<double>& near,
                int start, int end) {
  double projection = 0, power = 0;
  // AEC3's analysis and synthesis add 128 samples at 16 kHz.
  for (int i = start * kRate; i < end * kRate; ++i) {
    projection += output[i + 128] * near[i];
    power += near[i] * near[i];
  }
  return projection / power;
}
}  // namespace

int main() {
  // Every mode shares one configuration, and it keeps comfort noise on.
  if (!kiosk::EchoConfig().comfort_noise.enabled) {
    std::fprintf(stderr, "The shared configuration must keep comfort noise on\n");
    return 1;
  }
  std::vector<int16_t> render(kSeconds * kRate), capture(render.size());
  std::vector<double> near(render.size());
  uint32_t state = 42;
  auto noise = [&state]() {
    state = state * 1664525u + 1013904223u;
    return static_cast<double>(state >> 8) / 16777216.0 * 2.0 - 1.0;
  };
  for (size_t i = 0; i < render.size(); ++i) {
    render[i] = static_cast<int16_t>(noise() * 600);
    const double t = static_cast<double>(i) / kRate;
    if (t >= 275) {
      const double envelope = .2 + .8 * std::fmax(0., std::sin(2 * kPi * 4 * t));
      render[i] = static_cast<int16_t>(envelope *
          (600 * std::sin(2 * kPi * 705 * t) + 300 * std::sin(2 * kPi * 1410 * t)));
    }
    if (t >= 280 && t < 290) {
      const double envelope = .3 + .7 * std::fmax(0., std::sin(2 * kPi * 3 * t));
      near[i] = (t < 285 ? 900 : 300) * envelope * (std::sin(2 * kPi * 193 * t) +
                                 .5 * std::sin(2 * kPi * 386 * t));
    }
    const double echo = i >= 807 ? .8 * render[i - 800] + .3 * render[i - 807] : 0;
    capture[i] = static_cast<int16_t>(echo + near[i] + noise() * 5);
  }
  const auto with_noise = Run(true, render, capture);
  const auto without_noise = Run(false, render, capture);
  const double before = Rms(with_noise, 260, 270);
  const double after = Rms(without_noise, 260, 270);
  const double near_before = NearGain(with_noise, near, 281, 284);
  const double near_after = NearGain(without_noise, near, 281, 284);
  const double quiet_before = NearGain(with_noise, near, 286, 289);
  const double quiet_after = NearGain(without_noise, near, 286, 289);
  std::printf("quiet near speech gain %.3f -> %.3f\n", quiet_before, quiet_after);
  std::printf("late quiet RMS %.2f -> %.2f, near speech gain %.3f -> %.3f\n",
              before, after, near_before, near_after);
  if (after > before * .25 || after > 20 || near_after < .2 || near_after < near_before * .95 ||
      std::abs(near_after - near_before) > .05 ||
      quiet_after < .1 || quiet_after < quiet_before * .95) {
    std::fprintf(stderr, "Comfort noise regression failed\n");
    return 1;
  }
  return 0;
}
