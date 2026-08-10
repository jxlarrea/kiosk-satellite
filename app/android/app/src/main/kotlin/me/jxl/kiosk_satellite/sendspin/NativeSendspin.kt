package me.jxl.kiosk_satellite.sendspin

import java.nio.ByteBuffer

/**
 * Callbacks from the native sendspin-cpp bridge (libsendspin_jni).
 *
 * Threading: [onAudioWrite] fires on the native sync task thread and is the
 * hot path; everything else fires on the native main loop thread. None of
 * these run on the Android main thread.
 */
interface NativeSendspinCallbacks {
    /**
     * Write decoded PCM to the audio output, blocking at most [timeoutMs].
     * Returns the number of bytes written, which must be a whole number of
     * PCM frames: the native side counts played frames from it.
     */
    fun onAudioWrite(buffer: ByteBuffer, length: Int, timeoutMs: Int): Int

    fun onStreamStart(sampleRate: Int, channels: Int, bitDepth: Int)

    fun onStreamEnd()

    fun onVolumeChanged(volume: Int)

    fun onMuteChanged(muted: Boolean)

    fun onStaticDelayChanged(delayMs: Int)

    /** Absent strings arrive null; absent numerics arrive -1. */
    fun onMetadata(
        title: String?,
        artist: String?,
        album: String?,
        albumArtist: String?,
        artworkUrl: String?,
        year: Int,
        track: Int,
        progressMs: Long,
        durationMs: Long,
        timestampUs: Long,
    )

    /** playbackState: -1 unknown, 0 stopped, 1 playing. */
    fun onGroupUpdate(playbackState: Int, groupId: String?, groupName: String?)

    /** [commands] is a comma-separated list of protocol command names. */
    fun onControllerState(
        commands: String,
        volume: Int,
        muted: Boolean,
        repeat: String,
        shuffle: Boolean,
        seekMaxMs: Long,
    )

    fun onTimeSyncUpdated(errorUs: Float)

    /** [serverName] is non-null only on the connected edge. */
    fun onConnectionChanged(connected: Boolean, serverName: String?)

    fun onRequestHighPerformance()

    fun onReleaseHighPerformance()
}

/**
 * JNI surface of the native SendSpin engine. The protocol, time sync,
 * decoding, and playback scheduling live in sendspin-cpp; Kotlin provides
 * the audio output and reports playback progress back via
 * [nativeNotifyAudioPlayed].
 */
object NativeSendspin {
    // Matches sendspin::SendspinGoodbyeReason.
    const val REASON_ANOTHER_SERVER = 0
    const val REASON_SHUTDOWN = 1
    const val REASON_RESTART = 2
    const val REASON_USER_REQUEST = 3

    // Codec ids in the flattened formats array.
    const val CODEC_FLAC = 0
    const val CODEC_OPUS = 1
    const val CODEC_PCM = 2

    init {
        System.loadLibrary("sendspin_jni")
    }

    /**
     * [formats] is a flattened list of supported formats, four ints each:
     * codec id, channels, sample rate, bit depth. Order is the advertised
     * preference order. Returns 0 on failure.
     */
    external fun nativeCreate(
        callbacks: NativeSendspinCallbacks,
        clientId: String,
        name: String,
        productName: String,
        manufacturer: String,
        softwareVersion: String,
        serverPort: Int,
        audioBufferCapacity: Int,
        fixedDelayUs: Int,
        initialStaticDelayMs: Int,
        formats: IntArray,
    ): Long

    external fun nativeStart(handle: Long): Boolean

    external fun nativeConnect(handle: Long, url: String)

    external fun nativeDisconnect(handle: Long, reason: Int)

    external fun nativeDestroy(handle: Long)

    /** Thread-safe; call from the playback feedback loop. */
    external fun nativeNotifyAudioPlayed(handle: Long, frames: Int, timestampUs: Long)

    external fun nativeUpdateVolume(handle: Long, volume: Int)

    external fun nativeUpdateMuted(handle: Long, muted: Boolean)

    external fun nativeUpdateStaticDelay(handle: Long, delayMs: Int)

    /** [command] is a protocol command name, e.g. "play"; [arg] carries volume/seek values. */
    external fun nativeSendCommand(handle: Long, command: String, arg: Long): Boolean

    external fun nativeSetNetworkReady(handle: Long, ready: Boolean)

    external fun nativeIsConnected(handle: Long): Boolean

    external fun nativeIsTimeSynced(handle: Long): Boolean

    external fun nativeGetTrackProgressMs(handle: Long): Int

    external fun nativeGetTrackDurationMs(handle: Long): Int

    /** steady_clock microseconds, the clock domain of [nativeNotifyAudioPlayed]. */
    external fun nativeMonotonicTimeUs(): Long

    /** 0 none .. 5 verbose, matching sendspin::LogLevel. */
    external fun nativeSetLogLevel(level: Int)
}
