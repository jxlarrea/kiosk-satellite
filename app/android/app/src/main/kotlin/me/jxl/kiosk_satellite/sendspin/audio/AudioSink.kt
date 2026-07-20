package me.jxl.kiosk_satellite.sendspin.audio

/**
 * Abstraction over the audio output device. Production code wraps
 * android.media.AudioTrack via AudioTrackSink; tests use FakeAudioSink.
 *
 * This interface mirrors the methods SyncAudioPlayer calls on AudioTrack --
 * it is not a consolidation or redesign. Method semantics must match
 * AudioTrack's exactly.
 */
interface AudioSink {
    /** Begin playback. Mirrors AudioTrack.play(). */
    fun play()

    /** Pause playback. Mirrors AudioTrack.pause(). */
    fun pause()

    /** Stop playback. Mirrors AudioTrack.stop(). */
    fun stop()

    /** Discard queued audio. Mirrors AudioTrack.flush(). */
    fun flush()

    /** Release native resources. Mirrors AudioTrack.release(). */
    fun release()

    /**
     * Write PCM data. Mirrors AudioTrack.write(buffer, offset, size) in
     * blocking mode. Returns the number of bytes written, or a negative
     * error code.
     */
    fun write(buffer: ByteArray, offset: Int, size: Int): Int

    /**
     * Query the DAC timestamp. Returns null if the hardware hasn't produced
     * a valid timestamp yet (mirrors AudioTrack.getTimestamp() returning
     * false).
     */
    fun getTimestamp(): SinkTimestamp?

    /** Current playback head position in frames. Mirrors AudioTrack.getPlaybackHeadPosition(). */
    val playbackHeadPosition: Int

    /** Current state (matches AudioTrack.STATE_* constants). */
    val state: Int

    /**
     * Runtime playback state. Mirrors AudioTrack.getPlayState() -- values are
     * AudioTrack.PLAYSTATE_STOPPED (1), PLAYSTATE_PAUSED (2), or
     * PLAYSTATE_PLAYING (3).
     *
     * This is distinct from [state], which is STATE_INITIALIZED etc.
     */
    val playState: Int

    /** Buffer size in bytes. Mirrors AudioTrack.getBufferSizeInFrames() * bytesPerFrame. */
    val bufferSizeInBytes: Int
}

/**
 * DAC timestamp snapshot. Mirrors android.media.AudioTimestamp but is a
 * plain data class so it can be constructed in JVM tests without the
 * Android runtime.
 */
data class SinkTimestamp(val framePosition: Long, val nanoTime: Long)
