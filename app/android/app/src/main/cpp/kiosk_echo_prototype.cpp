#include "kiosk_echo_prototype.h"

#include <algorithm>
#include <cmath>

namespace kiosk {

EchoPrototype::EchoPrototype() {
    constexpr double pi = 3.14159265358979323846;
    for (int i = 0; i < kBlock; ++i) {
        double angle = -2 * pi * i / kFft;
        twiddle_[i] = Complex(std::cos(angle), std::sin(angle));
    }
    for (int i = 0; i < kFft; ++i) {
        int value = i, reversed = 0;
        for (int bit = 0; bit < 8; ++bit) {
            reversed = (reversed << 1) | (value & 1);
            value >>= 1;
        }
        reverse_[i] = reversed;
    }
    Reset();
}

void EchoPrototype::ResetFilter() {
    for (auto& partition : weights_) partition.fill(Complex{});
    for (auto& partition : uncertainty_) partition.fill(.1f);
    innovation_.fill(1e-5f);
    unstable_ = 0;
}

void EchoPrototype::Reset() {
    ResetFilter();
    for (auto& partition : reference_) partition.fill(Complex{});
    previous_.fill(0);
    render_.fill(0);
    capture_.fill(0);
    ready_.fill(0);
    render_highpass_ = {};
    capture_highpass_ = {};
    position_ = head_ = recoveries_ = 0;
}

float EchoPrototype::HighPass::Process(float sample) {
    // Second-order Butterworth high-pass at 80 Hz, sampled at 16 kHz.
    constexpr double b0 = .97803047920656;
    constexpr double b1 = -1.95606095841312;
    constexpr double a1 = -1.95557824031504;
    constexpr double a2 = .956543676511203;
    double output = b0 * sample + z1;
    z1 = b1 * sample - a1 * output + z2;
    z2 = b0 * sample - a2 * output;
    return static_cast<float>(output);
}

void EchoPrototype::Transform(std::array<Complex, kFft>& values, bool inverse) const {
    for (int i = 0; i < kFft; ++i)
        if (reverse_[i] > i) std::swap(values[i], values[reverse_[i]]);
    for (int width = 2; width <= kFft; width *= 2) {
        int half = width / 2;
        for (int from = 0; from < kFft; from += width) {
            for (int i = 0; i < half; ++i) {
                Complex twiddle = twiddle_[i * kFft / width];
                if (inverse) twiddle = std::conj(twiddle);
                Complex upper = values[from + i];
                Complex lower = values[from + i + half] * twiddle;
                values[from + i] = upper + lower;
                values[from + i + half] = upper - lower;
            }
        }
    }
    if (inverse)
        for (auto& value : values) value /= static_cast<float>(kFft);
}

EchoPrototype::Spectrum EchoPrototype::Forward(const Block& first, const Block& second) const {
    std::array<Complex, kFft> values;
    for (int i = 0; i < kBlock; ++i) {
        values[i] = first[i];
        values[i + kBlock] = second[i];
    }
    Transform(values, false);
    Spectrum result;
    std::copy_n(values.begin(), kBins, result.begin());
    return result;
}

void EchoPrototype::Inverse(const Spectrum& spectrum, std::array<float, kFft>& output) const {
    std::array<Complex, kFft> values;
    std::copy(spectrum.begin(), spectrum.end(), values.begin());
    for (int i = kBins; i < kFft; ++i) values[i] = std::conj(spectrum[kFft - i]);
    Transform(values, true);
    for (int i = 0; i < kFft; ++i) output[i] = values[i].real();
}

void EchoPrototype::FilterBlock() {
    head_ = (head_ + kParts - 1) % kParts;
    reference_[head_] = Forward(previous_, render_);
    previous_ = render_;
    Spectrum prediction{};
    for (int p = 0; p < kParts; ++p) {
        const auto& reference = reference_[(head_ + p) % kParts];
        for (int bin = 0; bin < kBins; ++bin)
            prediction[bin] += weights_[p][bin] * reference[bin];
    }
    std::array<float, kFft> time;
    Inverse(prediction, time);
    float input_power = 0, output_power = 0;
    for (int i = 0; i < kBlock; ++i) {
        ready_[i] = capture_[i] - time[kBlock + i];
        input_power += capture_[i] * capture_[i];
        output_power += ready_[i] * ready_[i];
    }
    // Recover from a broken echo path without muting the nearby speaker.
    if (!std::isfinite(output_power) || output_power > 4 * input_power + 1e-7f)
        ++unstable_;
    else
        unstable_ = 0;
    if (unstable_ >= 12 || !std::isfinite(output_power)) {
        ResetFilter();
        ready_ = capture_;
        ++recoveries_;
        return;
    }
    const Block zero{};
    Spectrum error = Forward(zero, ready_);
    std::array<float, kBins> denominator;
    for (int bin = 0; bin < kBins; ++bin) {
        innovation_[bin] = .9f * innovation_[bin] + .1f * std::norm(error[bin]);
        denominator[bin] = 2 * innovation_[bin] + 1e-7f;
        for (int p = 0; p < kParts; ++p)
            denominator[bin] += uncertainty_[p][bin] *
                std::norm(reference_[(head_ + p) % kParts][bin]);
    }
    for (int p = 0; p < kParts; ++p) {
        const auto& reference = reference_[(head_ + p) % kParts];
        Spectrum delta;
        std::array<float, kBins> gain;
        for (int bin = 0; bin < kBins; ++bin) {
            gain[bin] = uncertainty_[p][bin] / denominator[bin];
            delta[bin] = gain[bin] * std::conj(reference[bin]) * error[bin];
        }
        Inverse(delta, time);
        Block taps;
        std::copy_n(time.begin(), kBlock, taps.begin());
        delta = Forward(taps, zero);
        for (int bin = 0; bin < kBins; ++bin) {
            weights_[p][bin] += delta[bin];
            uncertainty_[p][bin] = std::min(100.f,
                (1 - .5f * gain[bin] * std::norm(reference[bin])) * uncertainty_[p][bin]
                + .001f * std::norm(weights_[p][bin]) + 1e-10f);
        }
    }
}

void EchoPrototype::Process(const float* reference, const float* microphone,
                           float* output, size_t frames) {
    for (size_t i = 0; i < frames; ++i) {
        render_[position_] = render_highpass_.Process(reference[i]);
        capture_[position_] = capture_highpass_.Process(microphone[i]);
        output[i] = ready_[position_];
        if (++position_ == kBlock) {
            FilterBlock();
            position_ = 0;
        }
    }
}

}  // namespace kiosk
