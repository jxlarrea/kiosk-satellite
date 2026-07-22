package me.jxl.kiosk_satellite.sendspin.audio

import android.media.AudioTimestamp
import android.media.AudioTrack

/**
 * AudioSink backed by a real android.media.AudioTrack.
 *
 * All methods delegate directly to the underlying track with identical
 * semantics. Callers own AudioTrack construction (sample rate, channels,
 * bit depth, buffer size, transfer mode) and hand the built track in.
 *
 * @param track the underlying AudioTrack to wrap
 * @param bytesPerFrame used to expose bufferSizeInBytes; AudioTrack itself
 *     reports a frame count, not a byte count
 */
class AudioTrackSink(
    private val track: AudioTrack,
    private val bytesPerFrame: Int,
) : AudioSink {

    private val ts = AudioTimestamp()

    // getTimestamp() is polled at high rate from the playback loop, and the
    // HAL often reports the same (framePosition, nanoTime) pair across polls.
    // Cache the last snapshot and only allocate when the value changes.
    // SinkTimestamp is immutable, so returning a shared instance is safe.
    private var lastTimestamp: SinkTimestamp? = null

    override fun play() = track.play()
    override fun pause() = track.pause()
    override fun stop() = track.stop()
    override fun flush() = track.flush()
    override fun release() = track.release()

    override fun write(buffer: ByteArray, offset: Int, size: Int): Int =
        track.write(buffer, offset, size)

    override fun getTimestamp(): SinkTimestamp? {
        if (!track.getTimestamp(ts)) return null
        val cached = lastTimestamp
        if (cached != null &&
            cached.framePosition == ts.framePosition &&
            cached.nanoTime == ts.nanoTime
        ) {
            return cached
        }
        val fresh = SinkTimestamp(ts.framePosition, ts.nanoTime)
        lastTimestamp = fresh
        return fresh
    }

    override val playbackHeadPosition: Int
        get() = track.playbackHeadPosition

    override val state: Int
        get() = track.state

    override val playState: Int
        get() = track.playState

    override val bufferSizeInBytes: Int
        get() = track.bufferSizeInFrames * bytesPerFrame
}
