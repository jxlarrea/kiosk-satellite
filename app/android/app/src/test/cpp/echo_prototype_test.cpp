#include "../../main/cpp/kiosk_echo_prototype.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <memory>
#include <random>
#include <vector>

namespace {
constexpr int rate = 16000;
constexpr int delay = kiosk::EchoPrototype::kBlock;

std::vector<float> Run(const std::vector<float>& reference,
                       const std::vector<float>& microphone, int chunk = 160) {
    auto filter = std::make_unique<kiosk::EchoPrototype>();
    std::vector<float> output(microphone.size());
    for (size_t at = 0; at < output.size(); at += chunk) {
        size_t count = std::min(static_cast<size_t>(chunk), output.size() - at);
        filter->Process(reference.data() + at, microphone.data() + at, output.data() + at, count);
    }
    return output;
}

int Replay(const char* source, const char* destination) {
    FILE* input = std::fopen(source, "rb");
    if (!input) return 2;
    FILE* output = std::fopen(destination, "wb");
    if (!output) { std::fclose(input); return 2; }
    auto filter = std::make_unique<kiosk::EchoPrototype>();
    int16_t block[3][160], encoded[160];
    float reference[160], microphone[160], clean[160];
    std::vector<double> elapsed;
    while (std::fread(block, sizeof(block), 1, input) == 1) {
        for (int i = 0; i < 160; ++i) {
            reference[i] = block[0][i] / 32768.f;
            microphone[i] = block[1][i] / 32768.f;
        }
        auto start = std::chrono::steady_clock::now();
        filter->Process(reference, microphone, clean, 160);
        elapsed.push_back(std::chrono::duration<double, std::milli>(
            std::chrono::steady_clock::now() - start).count());
        for (int i = 0; i < 160; ++i) {
            if (!std::isfinite(clean[i])) return 3;
            encoded[i] = static_cast<int16_t>(std::clamp(std::round(clean[i] * 32768.f), -32768.f, 32767.f));
        }
        if (std::fwrite(encoded, sizeof(encoded), 1, output) != 1) return 4;
    }
    bool failed = std::ferror(input) || std::ferror(output);
    std::fclose(input);
    failed |= std::fclose(output) != 0;
    if (elapsed.empty()) return 5;
    double total = 0;
    for (double value : elapsed) total += value;
    std::sort(elapsed.begin(), elapsed.end());
    std::printf("frames=%zu mean_ms=%.3f p95_ms=%.3f max_ms=%.3f recoveries=%d\n",
        elapsed.size(), total / elapsed.size(), elapsed[elapsed.size() * 95 / 100],
        elapsed.back(), filter->recoveries());
    return failed ? 6 : 0;
}

int Test() {
    std::mt19937 rng(713);
    std::normal_distribution<float> normal(0, 1);
    const int count = rate * 32;
    std::vector<float> reference(count), microphone(count), near(count), zero(count);
    for (int i = 0; i < count; ++i) {
        reference[i] = .05f * normal(rng);
        if (i >= rate * 12 && i < rate * 18) near[i] = .008f * normal(rng);
        microphone[i] = near[i];
        // Change the path after overlap ends to test relearning.
        float path_gain = i < rate * 20 ? .6f : -.4f;
        if (i >= 2100) microphone[i] += path_gain * reference[i - 2100];
        if (i >= 2197) microphone[i] -= .2f * reference[i - 2197];
        if (i >= 2600) microphone[i] += .08f * reference[i - 2600];
    }
    auto output = Run(reference, microphone);
    auto fragmented = Run(reference, microphone, 77);
    if (output != fragmented) return 10;
    auto silence = Run(zero, zero);
    for (float sample : silence) if (sample != 0) return 11;
    double input_power = 0, error_power = 0, projection = 0, near_power = 0;
    double changed_input = 0, changed_error = 0;
    for (int i = rate * 9; i < rate * 11; ++i) {
        input_power += microphone[i] * microphone[i];
        error_power += output[i + delay] * output[i + delay];
    }
    auto clean_near = Run(zero, near);
    for (int i = rate * 14; i < rate * 17; ++i) {
        projection += output[i + delay] * clean_near[i + delay];
        near_power += clean_near[i + delay] * clean_near[i + delay];
    }
    for (int i = rate * 29; i < rate * 31; ++i) {
        changed_input += microphone[i] * microphone[i];
        changed_error += output[i + delay] * output[i + delay];
    }
    double reduction = 10 * std::log10(input_power / error_power);
    double transfer = projection / near_power;
    double recovery = 10 * std::log10(changed_input / changed_error);
    std::printf("echo_reduction_db=%.2f near_transfer=%.4f changed_path_db=%.2f\n",
                reduction, transfer, recovery);
    if (reduction < 25 || transfer < .95 || transfer > 1.05 || recovery < 25) return 12;
    auto filter = std::make_unique<kiosk::EchoPrototype>();
    float ref[160]{}, mic[160]{}, out[160]{};
    ref[0] = .5f;
    mic[0] = .1f;
    filter->Process(ref, mic, out, 160);
    filter->Reset();
    std::fill_n(ref, 160, 0);
    std::fill_n(mic, 160, 0);
    filter->Process(ref, mic, out, 160);
    for (float sample : out) if (sample != 0) return 13;
    std::puts("silence, overlap, path change, reset and chunk-boundary tests passed");
    return 0;
}
}  // namespace

int main(int argc, char** argv) {
    if (argc == 3) return Replay(argv[1], argv[2]);
    return Test();
}
