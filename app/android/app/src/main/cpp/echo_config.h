#pragma once

#include "api/audio/echo_canceller3_config.h"

namespace kiosk {

// One configuration for every mode, so a call or a realtime conversation
// starting does not rebuild the canceller and throw away what it learned.
// Measured on recordings from a Galaxy Tab S8 and an Echo Show 8, the
// call-only variant (no comfort noise, no reverb model, faster release)
// removed slightly less echo and kept about the same nearby speech.
inline webrtc::EchoCanceller3Config EchoConfig() {
    webrtc::EchoCanceller3Config config;
    config.filter.refined_initial = config.filter.refined;
    config.filter.coarse_initial = config.filter.coarse;
    return config;
}

}  // namespace kiosk
