// JNI bridge between the Kotlin NativeSendspinEngine shell and sendspin-cpp.
//
// Threading model: connect_to()/disconnect() must run on the thread that calls
// SendspinClient::loop(), so every mutation is enqueued and drained by the loop
// thread. State the shell polls (connected, progress) is mirrored into atomics
// by the loop thread. The only native call made directly from another thread is
// notify_audio_played(), which the library documents as thread-safe.

#include <jni.h>
#include <android/log.h>

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cstdio>
#include <cstring>
#include <functional>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <unistd.h>
#include <vector>

#include "sendspin/client.h"
#include "sendspin/controller_role.h"
#include "sendspin/metadata_role.h"
#include "sendspin/player_role.h"

namespace {

constexpr const char* TAG = "sendspin-cpp";

JavaVM* g_vm = nullptr;

// ---------------------------------------------------------------------------
// Per-thread JNIEnv attachment with automatic detach at thread exit.
// ---------------------------------------------------------------------------

pthread_key_t g_env_key;

void detach_thread(void* /*unused*/) {
    if (g_vm != nullptr) {
        g_vm->DetachCurrentThread();
    }
}

JNIEnv* get_env() {
    JNIEnv* env = nullptr;
    if (g_vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) == JNI_OK) {
        return env;
    }
    JavaVMAttachArgs args{JNI_VERSION_1_6, "sendspin-native", nullptr};
    if (g_vm->AttachCurrentThread(&env, &args) != JNI_OK) {
        return nullptr;
    }
    pthread_setspecific(g_env_key, env);
    return env;
}

bool clear_exception(JNIEnv* env) {
    if (env->ExceptionCheck()) {
        env->ExceptionDescribe();
        env->ExceptionClear();
        return true;
    }
    return false;
}

// ---------------------------------------------------------------------------
// stderr -> logcat pump. sendspin-cpp's host logging writes to stderr, which
// Android discards; a pipe spliced over fd 2 recovers it. Process-wide, started
// once on first engine creation.
// ---------------------------------------------------------------------------

std::once_flag g_stderr_pump_once;

void start_stderr_pump() {
    std::call_once(g_stderr_pump_once, [] {
        int fds[2];
        if (pipe(fds) != 0) return;
        // Line-buffer stderr so each SS_LOG line arrives whole.
        setvbuf(stderr, nullptr, _IOLBF, 0);
        dup2(fds[1], STDERR_FILENO);
        close(fds[1]);
        int read_fd = fds[0];
        std::thread([read_fd] {
            char buf[1024];
            std::string pending;
            ssize_t n;
            while ((n = read(read_fd, buf, sizeof(buf))) > 0) {
                pending.append(buf, static_cast<size_t>(n));
                size_t pos;
                while ((pos = pending.find('\n')) != std::string::npos) {
                    std::string line = pending.substr(0, pos);
                    pending.erase(0, pos + 1);
                    if (line.empty()) continue;
                    // Host log lines start with "<severity> <tag>: ".
                    int prio = ANDROID_LOG_INFO;
                    if (line[0] == 'E') prio = ANDROID_LOG_ERROR;
                    else if (line[0] == 'W') prio = ANDROID_LOG_WARN;
                    else if (line[0] == 'D') prio = ANDROID_LOG_DEBUG;
                    else if (line[0] == 'V') prio = ANDROID_LOG_VERBOSE;
                    __android_log_write(prio, TAG, line.c_str());
                }
            }
        }).detach();
    });
}

int64_t monotonic_us() {
    auto now = std::chrono::steady_clock::now();
    return std::chrono::duration_cast<std::chrono::microseconds>(now.time_since_epoch()).count();
}

// ---------------------------------------------------------------------------
// Command <-> string mapping (stable across library enum reordering).
// ---------------------------------------------------------------------------

const std::pair<const char*, sendspin::SendspinControllerCommand> kCommands[] = {
    {"play", sendspin::SendspinControllerCommand::PLAY},
    {"pause", sendspin::SendspinControllerCommand::PAUSE},
    {"stop", sendspin::SendspinControllerCommand::STOP},
    {"next", sendspin::SendspinControllerCommand::NEXT},
    {"previous", sendspin::SendspinControllerCommand::PREVIOUS},
    {"volume", sendspin::SendspinControllerCommand::VOLUME},
    {"mute", sendspin::SendspinControllerCommand::MUTE},
    {"repeat_off", sendspin::SendspinControllerCommand::REPEAT_OFF},
    {"repeat_one", sendspin::SendspinControllerCommand::REPEAT_ONE},
    {"repeat_all", sendspin::SendspinControllerCommand::REPEAT_ALL},
    {"shuffle", sendspin::SendspinControllerCommand::SHUFFLE},
    {"unshuffle", sendspin::SendspinControllerCommand::UNSHUFFLE},
    {"switch", sendspin::SendspinControllerCommand::SWITCH},
    {"seek", sendspin::SendspinControllerCommand::SEEK},
    {"seek_relative", sendspin::SendspinControllerCommand::SEEK_RELATIVE},
};

const char* command_name(sendspin::SendspinControllerCommand cmd) {
    for (const auto& [name, value] : kCommands) {
        if (value == cmd) return name;
    }
    return nullptr;
}

std::optional<sendspin::SendspinControllerCommand> command_value(const char* name) {
    for (const auto& [n, value] : kCommands) {
        if (std::strcmp(n, name) == 0) return value;
    }
    return std::nullopt;
}

// ---------------------------------------------------------------------------
// Bridge
// ---------------------------------------------------------------------------

class Bridge final : public sendspin::PlayerRoleListener,
                     public sendspin::MetadataRoleListener,
                     public sendspin::ControllerRoleListener,
                     public sendspin::SendspinClientListener,
                     public sendspin::SendspinNetworkProvider {
public:
    std::unique_ptr<sendspin::SendspinClient> client;
    sendspin::PlayerRole* player = nullptr;
    sendspin::ControllerRole* controller = nullptr;
    sendspin::MetadataRole* metadata = nullptr;

    jobject callbacks = nullptr;  // global ref

    jmethodID mid_audio_write = nullptr;
    jmethodID mid_stream_start = nullptr;
    jmethodID mid_stream_end = nullptr;
    jmethodID mid_volume_changed = nullptr;
    jmethodID mid_mute_changed = nullptr;
    jmethodID mid_static_delay_changed = nullptr;
    jmethodID mid_metadata = nullptr;
    jmethodID mid_group_update = nullptr;
    jmethodID mid_controller_state = nullptr;
    jmethodID mid_time_sync = nullptr;
    jmethodID mid_connection_changed = nullptr;
    jmethodID mid_request_high_perf = nullptr;
    jmethodID mid_release_high_perf = nullptr;

    std::thread loop_thread;
    std::atomic<bool> running{false};
    std::mutex queue_mutex;
    std::vector<std::function<void()>> queue;

    std::atomic<bool> network_ready{true};
    std::atomic<bool> connected{false};
    std::atomic<bool> time_synced{false};
    std::atomic<int> progress_ms{0};
    std::atomic<int> duration_ms{0};

    void post(std::function<void()> fn) {
        std::lock_guard<std::mutex> lock(this->queue_mutex);
        this->queue.push_back(std::move(fn));
    }

    void run_loop() {
        bool last_connected = false;
        while (this->running.load()) {
            std::vector<std::function<void()>> pending;
            {
                std::lock_guard<std::mutex> lock(this->queue_mutex);
                pending.swap(this->queue);
            }
            for (auto& fn : pending) fn();

            this->client->loop();

            bool now_connected = this->client->is_connected();
            this->connected.store(now_connected);
            this->time_synced.store(this->client->is_time_synced());
            if (this->metadata != nullptr) {
                this->progress_ms.store(static_cast<int>(this->metadata->get_track_progress_ms()));
                this->duration_ms.store(static_cast<int>(this->metadata->get_track_duration_ms()));
            }
            if (now_connected != last_connected) {
                last_connected = now_connected;
                JNIEnv* env = get_env();
                if (env != nullptr) {
                    jstring server_name = nullptr;
                    if (now_connected) {
                        auto info = this->client->get_server_information();
                        if (info) server_name = env->NewStringUTF(info->name.c_str());
                    }
                    env->CallVoidMethod(this->callbacks, this->mid_connection_changed,
                                        static_cast<jboolean>(now_connected), server_name);
                    clear_exception(env);
                    if (server_name != nullptr) env->DeleteLocalRef(server_name);
                }
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
        }
    }

    // --- PlayerRoleListener -------------------------------------------------

    size_t on_audio_write(uint8_t* data, size_t length, uint32_t timeout_ms) override {
        JNIEnv* env = get_env();
        if (env == nullptr) return 0;
        jobject buffer = env->NewDirectByteBuffer(data, static_cast<jlong>(length));
        if (buffer == nullptr) {
            clear_exception(env);
            return 0;
        }
        jint written = env->CallIntMethod(this->callbacks, this->mid_audio_write, buffer,
                                          static_cast<jint>(length),
                                          static_cast<jint>(timeout_ms));
        env->DeleteLocalRef(buffer);
        if (clear_exception(env) || written < 0) return 0;
        return std::min(static_cast<size_t>(written), length);
    }

    void on_stream_start() override {
        const auto& params = this->player->get_current_stream_params();
        JNIEnv* env = get_env();
        if (env == nullptr) return;
        env->CallVoidMethod(this->callbacks, this->mid_stream_start,
                            static_cast<jint>(params.sample_rate.value_or(48000)),
                            static_cast<jint>(params.channels.value_or(2)),
                            static_cast<jint>(params.bit_depth.value_or(16)));
        clear_exception(env);
    }

    void on_stream_end() override {
        JNIEnv* env = get_env();
        if (env == nullptr) return;
        env->CallVoidMethod(this->callbacks, this->mid_stream_end);
        clear_exception(env);
    }

    void on_volume_changed(uint8_t volume) override {
        JNIEnv* env = get_env();
        if (env == nullptr) return;
        env->CallVoidMethod(this->callbacks, this->mid_volume_changed,
                            static_cast<jint>(volume));
        clear_exception(env);
    }

    void on_mute_changed(bool muted) override {
        JNIEnv* env = get_env();
        if (env == nullptr) return;
        env->CallVoidMethod(this->callbacks, this->mid_mute_changed,
                            static_cast<jboolean>(muted));
        clear_exception(env);
    }

    void on_static_delay_changed(uint16_t delay_ms) override {
        JNIEnv* env = get_env();
        if (env == nullptr) return;
        env->CallVoidMethod(this->callbacks, this->mid_static_delay_changed,
                            static_cast<jint>(delay_ms));
        clear_exception(env);
    }

    // --- MetadataRoleListener ----------------------------------------------

    void on_metadata(const sendspin::ServerMetadataStateObject& md) override {
        JNIEnv* env = get_env();
        if (env == nullptr) return;
        jstring title = to_jstring(env, md.title);
        jstring artist = to_jstring(env, md.artist);
        jstring album = to_jstring(env, md.album);
        jstring album_artist = to_jstring(env, md.album_artist);
        jstring artwork_url = to_jstring(env, md.artwork_url);
        jint year = md.year ? static_cast<jint>(*md.year) : -1;
        jint track = md.track ? static_cast<jint>(*md.track) : -1;
        jlong progress = md.progress ? static_cast<jlong>(md.progress->track_progress) : -1;
        jlong duration = md.progress ? static_cast<jlong>(md.progress->track_duration) : -1;
        env->CallVoidMethod(this->callbacks, this->mid_metadata, title, artist, album,
                            album_artist, artwork_url, year, track, progress, duration,
                            static_cast<jlong>(md.timestamp));
        clear_exception(env);
        for (jstring s : {title, artist, album, album_artist, artwork_url}) {
            if (s != nullptr) env->DeleteLocalRef(s);
        }
    }

    // --- ControllerRoleListener --------------------------------------------

    void on_controller_state(const sendspin::ServerStateControllerObject& state) override {
        JNIEnv* env = get_env();
        if (env == nullptr) return;
        std::string commands;
        for (const auto& cmd : state.supported_commands) {
            const char* name = command_name(cmd);
            if (name == nullptr) continue;
            if (!commands.empty()) commands.push_back(',');
            commands.append(name);
        }
        jstring commands_str = env->NewStringUTF(commands.c_str());
        const char* repeat = state.repeat == sendspin::SendspinRepeatMode::ONE   ? "one"
                             : state.repeat == sendspin::SendspinRepeatMode::ALL ? "all"
                                                                                : "off";
        jstring repeat_str = env->NewStringUTF(repeat);
        jlong seek_max = state.seek_max_ms ? static_cast<jlong>(*state.seek_max_ms) : -1;
        env->CallVoidMethod(this->callbacks, this->mid_controller_state, commands_str,
                            static_cast<jint>(state.volume),
                            static_cast<jboolean>(state.muted), repeat_str,
                            static_cast<jboolean>(state.shuffle), seek_max);
        clear_exception(env);
        env->DeleteLocalRef(commands_str);
        env->DeleteLocalRef(repeat_str);
    }

    // --- SendspinClientListener --------------------------------------------

    void on_group_update(const sendspin::GroupUpdateObject& group) override {
        JNIEnv* env = get_env();
        if (env == nullptr) return;
        jint playback = -1;
        if (group.playback_state) {
            playback = *group.playback_state == sendspin::SendspinPlaybackState::PLAYING ? 1 : 0;
        }
        jstring group_id = to_jstring(env, group.group_id);
        jstring group_name = to_jstring(env, group.group_name);
        env->CallVoidMethod(this->callbacks, this->mid_group_update, playback, group_id,
                            group_name);
        clear_exception(env);
        if (group_id != nullptr) env->DeleteLocalRef(group_id);
        if (group_name != nullptr) env->DeleteLocalRef(group_name);
    }

    void on_time_sync_updated(float error) override {
        JNIEnv* env = get_env();
        if (env == nullptr) return;
        env->CallVoidMethod(this->callbacks, this->mid_time_sync, static_cast<jfloat>(error));
        clear_exception(env);
    }

    void on_request_high_performance() override {
        JNIEnv* env = get_env();
        if (env == nullptr) return;
        env->CallVoidMethod(this->callbacks, this->mid_request_high_perf);
        clear_exception(env);
    }

    void on_release_high_performance() override {
        JNIEnv* env = get_env();
        if (env == nullptr) return;
        env->CallVoidMethod(this->callbacks, this->mid_release_high_perf);
        clear_exception(env);
    }

    // --- SendspinNetworkProvider -------------------------------------------

    bool is_network_ready() override {
        return this->network_ready.load();
    }

private:
    static jstring to_jstring(JNIEnv* env, const std::optional<std::string>& s) {
        return s ? env->NewStringUTF(s->c_str()) : nullptr;
    }
};

Bridge* bridge_from(jlong handle) {
    return reinterpret_cast<Bridge*>(handle);
}

jmethodID require_method(JNIEnv* env, jclass cls, const char* name, const char* sig) {
    jmethodID mid = env->GetMethodID(cls, name, sig);
    if (mid == nullptr) {
        // Clear the pending NoSuchMethodError: returning to Java with it
        // pending aborts the runtime. nativeCreate fails soft instead.
        clear_exception(env);
        __android_log_print(ANDROID_LOG_ERROR, TAG, "Missing callback method %s%s", name, sig);
    }
    return mid;
}

std::string jstring_to_string(JNIEnv* env, jstring s) {
    if (s == nullptr) return {};
    const char* chars = env->GetStringUTFChars(s, nullptr);
    std::string out = chars != nullptr ? chars : "";
    if (chars != nullptr) env->ReleaseStringUTFChars(s, chars);
    return out;
}

}  // namespace

extern "C" JNIEXPORT jint JNI_OnLoad(JavaVM* vm, void* /*reserved*/) {
    g_vm = vm;
    pthread_key_create(&g_env_key, detach_thread);
    return JNI_VERSION_1_6;
}

extern "C" JNIEXPORT jlong JNICALL
Java_me_jxl_kiosk_1satellite_sendspin_NativeSendspin_nativeCreate(
    JNIEnv* env, jobject /*thiz*/, jobject callbacks, jstring client_id, jstring name,
    jstring product_name, jstring manufacturer, jstring software_version, jint server_port,
    jint audio_buffer_capacity, jint fixed_delay_us, jint initial_static_delay_ms,
    jintArray formats) {
    start_stderr_pump();

    auto bridge = std::make_unique<Bridge>();

    jclass cls = env->GetObjectClass(callbacks);
    bridge->mid_audio_write = require_method(env, cls, "onAudioWrite", "(Ljava/nio/ByteBuffer;II)I");
    bridge->mid_stream_start = require_method(env, cls, "onStreamStart", "(III)V");
    bridge->mid_stream_end = require_method(env, cls, "onStreamEnd", "()V");
    bridge->mid_volume_changed = require_method(env, cls, "onVolumeChanged", "(I)V");
    bridge->mid_mute_changed = require_method(env, cls, "onMuteChanged", "(Z)V");
    bridge->mid_static_delay_changed = require_method(env, cls, "onStaticDelayChanged", "(I)V");
    bridge->mid_metadata = require_method(
        env, cls, "onMetadata",
        "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;"
        "Ljava/lang/String;IIJJJ)V");
    bridge->mid_group_update =
        require_method(env, cls, "onGroupUpdate", "(ILjava/lang/String;Ljava/lang/String;)V");
    bridge->mid_controller_state = require_method(
        env, cls, "onControllerState", "(Ljava/lang/String;IZLjava/lang/String;ZJ)V");
    bridge->mid_time_sync = require_method(env, cls, "onTimeSyncUpdated", "(F)V");
    bridge->mid_connection_changed =
        require_method(env, cls, "onConnectionChanged", "(ZLjava/lang/String;)V");
    bridge->mid_request_high_perf = require_method(env, cls, "onRequestHighPerformance", "()V");
    bridge->mid_release_high_perf = require_method(env, cls, "onReleaseHighPerformance", "()V");
    env->DeleteLocalRef(cls);

    if (bridge->mid_audio_write == nullptr || bridge->mid_stream_start == nullptr) {
        return 0;
    }
    bridge->callbacks = env->NewGlobalRef(callbacks);

    sendspin::SendspinClientConfig config;
    config.client_id = jstring_to_string(env, client_id);
    config.name = jstring_to_string(env, name);
    config.product_name = jstring_to_string(env, product_name);
    config.manufacturer = jstring_to_string(env, manufacturer);
    config.software_version = jstring_to_string(env, software_version);
    config.server_port = static_cast<uint16_t>(server_port);
    bridge->client = std::make_unique<sendspin::SendspinClient>(std::move(config));

    sendspin::PlayerRoleConfig player_config;
    jsize formats_len = env->GetArrayLength(formats);
    jint* formats_data = env->GetIntArrayElements(formats, nullptr);
    for (jsize i = 0; i + 3 < formats_len; i += 4) {
        sendspin::AudioSupportedFormatObject fmt;
        switch (formats_data[i]) {
            case 0: fmt.codec = sendspin::SendspinCodecFormat::FLAC; break;
            case 1: fmt.codec = sendspin::SendspinCodecFormat::OPUS; break;
            default: fmt.codec = sendspin::SendspinCodecFormat::PCM; break;
        }
        fmt.channels = static_cast<uint8_t>(formats_data[i + 1]);
        fmt.sample_rate = static_cast<uint32_t>(formats_data[i + 2]);
        fmt.bit_depth = static_cast<uint8_t>(formats_data[i + 3]);
        player_config.audio_formats.push_back(fmt);
    }
    env->ReleaseIntArrayElements(formats, formats_data, JNI_ABORT);
    player_config.audio_buffer_capacity = static_cast<size_t>(audio_buffer_capacity);
    player_config.fixed_delay_us = fixed_delay_us;
    player_config.initial_static_delay_ms = static_cast<uint16_t>(initial_static_delay_ms);

    bridge->player = &bridge->client->add_player(std::move(player_config));
    bridge->controller = &bridge->client->add_controller();
    bridge->metadata = &bridge->client->add_metadata();

    bridge->player->set_listener(bridge.get());
    bridge->player->set_static_delay_adjustable(true);
    bridge->controller->set_listener(bridge.get());
    bridge->metadata->set_listener(bridge.get());
    bridge->client->set_listener(bridge.get());
    bridge->client->set_network_provider(bridge.get());

    return reinterpret_cast<jlong>(bridge.release());
}

extern "C" JNIEXPORT jboolean JNICALL
Java_me_jxl_kiosk_1satellite_sendspin_NativeSendspin_nativeStart(JNIEnv* /*env*/,
                                                                 jobject /*thiz*/,
                                                                 jlong handle) {
    Bridge* bridge = bridge_from(handle);
    if (bridge == nullptr || bridge->running.load()) return JNI_FALSE;
    if (!bridge->client->start_server()) {
        __android_log_write(ANDROID_LOG_ERROR, TAG, "start_server failed");
        return JNI_FALSE;
    }
    bridge->running.store(true);
    bridge->loop_thread = std::thread([bridge] { bridge->run_loop(); });
    return JNI_TRUE;
}

extern "C" JNIEXPORT void JNICALL
Java_me_jxl_kiosk_1satellite_sendspin_NativeSendspin_nativeConnect(JNIEnv* env,
                                                                   jobject /*thiz*/,
                                                                   jlong handle, jstring url) {
    Bridge* bridge = bridge_from(handle);
    if (bridge == nullptr) return;
    std::string url_str = jstring_to_string(env, url);
    bridge->post([bridge, url_str] { bridge->client->connect_to(url_str); });
}

extern "C" JNIEXPORT void JNICALL
Java_me_jxl_kiosk_1satellite_sendspin_NativeSendspin_nativeDisconnect(JNIEnv* /*env*/,
                                                                      jobject /*thiz*/,
                                                                      jlong handle,
                                                                      jint reason) {
    Bridge* bridge = bridge_from(handle);
    if (bridge == nullptr) return;
    auto goodbye = static_cast<sendspin::SendspinGoodbyeReason>(reason);
    bridge->post([bridge, goodbye] { bridge->client->disconnect(goodbye); });
}

extern "C" JNIEXPORT void JNICALL
Java_me_jxl_kiosk_1satellite_sendspin_NativeSendspin_nativeDestroy(JNIEnv* env,
                                                                   jobject /*thiz*/,
                                                                   jlong handle) {
    Bridge* bridge = bridge_from(handle);
    if (bridge == nullptr) return;
    if (bridge->running.exchange(false) && bridge->loop_thread.joinable()) {
        bridge->loop_thread.join();
    }
    bridge->client->disconnect(sendspin::SendspinGoodbyeReason::SHUTDOWN);
    if (bridge->callbacks != nullptr) {
        env->DeleteGlobalRef(bridge->callbacks);
    }
    delete bridge;
}

extern "C" JNIEXPORT void JNICALL
Java_me_jxl_kiosk_1satellite_sendspin_NativeSendspin_nativeNotifyAudioPlayed(
    JNIEnv* /*env*/, jobject /*thiz*/, jlong handle, jint frames, jlong timestamp_us) {
    Bridge* bridge = bridge_from(handle);
    if (bridge == nullptr || bridge->player == nullptr) return;
    bridge->player->notify_audio_played(static_cast<uint32_t>(frames), timestamp_us);
}

extern "C" JNIEXPORT void JNICALL
Java_me_jxl_kiosk_1satellite_sendspin_NativeSendspin_nativeUpdateVolume(JNIEnv* /*env*/,
                                                                        jobject /*thiz*/,
                                                                        jlong handle,
                                                                        jint volume) {
    Bridge* bridge = bridge_from(handle);
    if (bridge == nullptr) return;
    auto value = static_cast<uint8_t>(std::clamp(static_cast<int>(volume), 0, 100));
    bridge->post([bridge, value] { bridge->player->update_volume(value); });
}

extern "C" JNIEXPORT void JNICALL
Java_me_jxl_kiosk_1satellite_sendspin_NativeSendspin_nativeUpdateMuted(JNIEnv* /*env*/,
                                                                       jobject /*thiz*/,
                                                                       jlong handle,
                                                                       jboolean muted) {
    Bridge* bridge = bridge_from(handle);
    if (bridge == nullptr) return;
    bool value = muted == JNI_TRUE;
    bridge->post([bridge, value] { bridge->player->update_muted(value); });
}

extern "C" JNIEXPORT void JNICALL
Java_me_jxl_kiosk_1satellite_sendspin_NativeSendspin_nativeUpdateStaticDelay(JNIEnv* /*env*/,
                                                                             jobject /*thiz*/,
                                                                             jlong handle,
                                                                             jint delay_ms) {
    Bridge* bridge = bridge_from(handle);
    if (bridge == nullptr) return;
    auto value = static_cast<uint16_t>(std::clamp(static_cast<int>(delay_ms), 0, 5000));
    bridge->post([bridge, value] { bridge->player->update_static_delay(value); });
}

extern "C" JNIEXPORT jboolean JNICALL
Java_me_jxl_kiosk_1satellite_sendspin_NativeSendspin_nativeSendCommand(JNIEnv* env,
                                                                       jobject /*thiz*/,
                                                                       jlong handle,
                                                                       jstring command,
                                                                       jlong arg) {
    Bridge* bridge = bridge_from(handle);
    if (bridge == nullptr || bridge->controller == nullptr) return JNI_FALSE;
    std::string name = jstring_to_string(env, command);
    auto cmd = command_value(name.c_str());
    if (!cmd) return JNI_FALSE;
    bridge->post([bridge, cmd = *cmd, arg] {
        sendspin::ClientCommandControllerObject obj;
        obj.command = cmd;
        switch (cmd) {
            case sendspin::SendspinControllerCommand::VOLUME:
                obj.volume = static_cast<uint8_t>(std::clamp<jlong>(arg, 0, 100));
                break;
            case sendspin::SendspinControllerCommand::MUTE:
                obj.muted = arg != 0;
                break;
            case sendspin::SendspinControllerCommand::SEEK:
                obj.position_ms = static_cast<uint32_t>(std::max<jlong>(arg, 0));
                break;
            case sendspin::SendspinControllerCommand::SEEK_RELATIVE:
                obj.offset_ms = static_cast<int32_t>(arg);
                break;
            default:
                break;
        }
        bridge->controller->send_command(obj);
    });
    return JNI_TRUE;
}

extern "C" JNIEXPORT void JNICALL
Java_me_jxl_kiosk_1satellite_sendspin_NativeSendspin_nativeSetNetworkReady(JNIEnv* /*env*/,
                                                                           jobject /*thiz*/,
                                                                           jlong handle,
                                                                           jboolean ready) {
    Bridge* bridge = bridge_from(handle);
    if (bridge == nullptr) return;
    bridge->network_ready.store(ready == JNI_TRUE);
}

extern "C" JNIEXPORT jboolean JNICALL
Java_me_jxl_kiosk_1satellite_sendspin_NativeSendspin_nativeIsConnected(JNIEnv* /*env*/,
                                                                       jobject /*thiz*/,
                                                                       jlong handle) {
    Bridge* bridge = bridge_from(handle);
    return bridge != nullptr && bridge->connected.load() ? JNI_TRUE : JNI_FALSE;
}

extern "C" JNIEXPORT jboolean JNICALL
Java_me_jxl_kiosk_1satellite_sendspin_NativeSendspin_nativeIsTimeSynced(JNIEnv* /*env*/,
                                                                        jobject /*thiz*/,
                                                                        jlong handle) {
    Bridge* bridge = bridge_from(handle);
    return bridge != nullptr && bridge->time_synced.load() ? JNI_TRUE : JNI_FALSE;
}

extern "C" JNIEXPORT jint JNICALL
Java_me_jxl_kiosk_1satellite_sendspin_NativeSendspin_nativeGetTrackProgressMs(JNIEnv* /*env*/,
                                                                              jobject /*thiz*/,
                                                                              jlong handle) {
    Bridge* bridge = bridge_from(handle);
    return bridge != nullptr ? bridge->progress_ms.load() : 0;
}

extern "C" JNIEXPORT jint JNICALL
Java_me_jxl_kiosk_1satellite_sendspin_NativeSendspin_nativeGetTrackDurationMs(JNIEnv* /*env*/,
                                                                              jobject /*thiz*/,
                                                                              jlong handle) {
    Bridge* bridge = bridge_from(handle);
    return bridge != nullptr ? bridge->duration_ms.load() : 0;
}

extern "C" JNIEXPORT jlong JNICALL
Java_me_jxl_kiosk_1satellite_sendspin_NativeSendspin_nativeMonotonicTimeUs(JNIEnv* /*env*/,
                                                                           jobject /*thiz*/) {
    return monotonic_us();
}

extern "C" JNIEXPORT void JNICALL
Java_me_jxl_kiosk_1satellite_sendspin_NativeSendspin_nativeSetLogLevel(JNIEnv* /*env*/,
                                                                       jobject /*thiz*/,
                                                                       jint level) {
    sendspin::SendspinClient::set_log_level(static_cast<sendspin::LogLevel>(level));
}
