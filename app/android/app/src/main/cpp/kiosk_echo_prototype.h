#pragma once

#include <array>
#include <complex>
#include <cstddef>

namespace kiosk {

// Experimental echo subtraction at 16 kHz. The caller owns one instance per
// capture stream. No gain control, output gate or replacement noise is used.
// This interface accepts arbitrary chunk lengths with a fixed 128-sample delay.
class EchoPrototype {
 public:
    static constexpr int kBlock = 128;
    static constexpr int kFft = 2 * kBlock;
    static constexpr int kBins = kBlock + 1;
    static constexpr int kParts = 32;

    EchoPrototype();
    void Process(const float* reference, const float* microphone, float* output,
                 size_t frames);
    void Reset();
    int recoveries() const { return recoveries_; }

 private:
    using Complex = std::complex<float>;
    using Spectrum = std::array<Complex, kBins>;
    using Block = std::array<float, kBlock>;
    struct HighPass {
        double z1 = 0, z2 = 0;
        float Process(float sample);
    };
    void Transform(std::array<Complex, kFft>& values, bool inverse) const;
    Spectrum Forward(const Block& first, const Block& second) const;
    void Inverse(const Spectrum& spectrum, std::array<float, kFft>& output) const;
    void FilterBlock();
    void ResetFilter();

    std::array<Complex, kBlock> twiddle_;
    std::array<int, kFft> reverse_;
    std::array<Spectrum, kParts> weights_{};
    std::array<Spectrum, kParts> reference_{};
    std::array<std::array<float, kBins>, kParts> uncertainty_{};
    std::array<float, kBins> innovation_{};
    Block previous_{}, render_{}, capture_{}, ready_{};
    HighPass render_highpass_, capture_highpass_;
    int position_ = 0;
    int head_ = 0;
    int unstable_ = 0;
    int recoveries_ = 0;
};

}  // namespace kiosk
