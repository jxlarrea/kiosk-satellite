package me.jxl.kiosk_satellite

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.util.Log
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.abs
import kotlin.math.min

/**
 * Short local sounds, decoded once and kept as PCM.
 *
 * The chimes are the reason. Played through a MediaPlayer, a 300 ms chime
 * costs a NuPlayer, a MediaCodec instance and a fresh AudioTrack every single
 * time, then a teardown - measured on an Echo Show 5 as a ~150 ms stall in
 * the dashboard's rendering at the start of the sound and another as it ends,
 * which is exactly where the voice UI's animation was visibly freezing. A
 * clip decoded once and written straight into an AudioTrack skips all of it.
 *
 * Deliberately only for short local files: streamed TTS cannot be decoded up
 * front (that is the whole point of streaming it), and a long file would cost
 * more memory than the stall is worth.
 */
object SoundClips {
    private const val TAG = "SoundClips"

    /** Longest clip worth holding as PCM. Chimes are well under a second. */
    private const val MAX_SECONDS = 8

    /** Total decoded audio kept, across every clip. */
    private const val MAX_CACHE_BYTES = 4 * 1024 * 1024

    /** Level envelope resolution, matching the page's update cadence. */
    const val LEVEL_WINDOW_MS = 50

    class Clip(
        val pcm: ByteArray,
        val sampleRate: Int,
        val channels: Int,
        /** Mean |amplitude| per [LEVEL_WINDOW_MS], 0..1, for the reactive bar. */
        val levels: FloatArray,
    ) {
        val frames: Int get() = pcm.size / (2 * channels)
        val durationMs: Int get() = (frames * 1000L / sampleRate).toInt()
    }

    /** path + last-modified -> clip. A rewritten file decodes again. */
    private val cache = LinkedHashMap<String, Clip>(8, 0.75f, true)
    private var cachedBytes = 0

    /** Paths that are not worth trying again (too long, or undecodable). */
    private val rejected = mutableSetOf<String>()

    /**
     * The decoded clip for [path], decoding it if this is the first time.
     * Null when the file is not a short local sound this can handle, which
     * is the caller's cue to fall back to a MediaPlayer.
     *
     * Blocking, and expected to be called off the main thread.
     */
    @Synchronized
    fun get(path: String): Clip? {
        val file = File(path)
        if (!file.isFile) return null
        val key = "$path@${file.lastModified()}"
        cache[key]?.let { return it }
        if (key in rejected) return null
        val clip = try {
            decode(path)
        } catch (e: Exception) {
            Log.w(TAG, "decode failed for $path: ${e.message}")
            null
        }
        if (clip == null) {
            rejected += key
            return null
        }
        cache[key] = clip
        cachedBytes += clip.pcm.size
        // Oldest-used out first; the chimes in rotation stay resident.
        val it = cache.entries.iterator()
        while (cachedBytes > MAX_CACHE_BYTES && it.hasNext()) {
            val entry = it.next()
            if (entry.key == key) continue
            cachedBytes -= entry.value.pcm.size
            it.remove()
        }
        return clip
    }

    private fun decode(path: String): Clip? {
        val extractor = MediaExtractor()
        extractor.setDataSource(path)
        var track = -1
        var format: MediaFormat? = null
        for (i in 0 until extractor.trackCount) {
            val f = extractor.getTrackFormat(i)
            if (f.getString(MediaFormat.KEY_MIME)?.startsWith("audio/") == true) {
                track = i
                format = f
                break
            }
        }
        if (track < 0 || format == null) {
            extractor.release()
            return null
        }
        val durationUs = if (format.containsKey(MediaFormat.KEY_DURATION)) {
            format.getLong(MediaFormat.KEY_DURATION)
        } else {
            0L
        }
        if (durationUs > MAX_SECONDS * 1_000_000L) {
            extractor.release()
            return null
        }
        extractor.selectTrack(track)

        val codec = MediaCodec.createDecoderByType(
            format.getString(MediaFormat.KEY_MIME)!!,
        )
        codec.configure(format, null, null, 0)
        codec.start()

        val out = java.io.ByteArrayOutputStream(64 * 1024)
        var sampleRate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
        var channels = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
        val info = MediaCodec.BufferInfo()
        var sawInputEnd = false
        var sawOutputEnd = false
        try {
            while (!sawOutputEnd) {
                if (!sawInputEnd) {
                    val inIndex = codec.dequeueInputBuffer(10_000)
                    if (inIndex >= 0) {
                        val buf = codec.getInputBuffer(inIndex)!!
                        val size = extractor.readSampleData(buf, 0)
                        if (size < 0) {
                            codec.queueInputBuffer(
                                inIndex, 0, 0, 0,
                                MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                            )
                            sawInputEnd = true
                        } else {
                            codec.queueInputBuffer(
                                inIndex, 0, size, extractor.sampleTime, 0,
                            )
                            extractor.advance()
                        }
                    }
                }
                val outIndex = codec.dequeueOutputBuffer(info, 10_000)
                when {
                    outIndex >= 0 -> {
                        if (info.size > 0) {
                            val buf = codec.getOutputBuffer(outIndex)!!
                            val chunk = ByteArray(info.size)
                            buf.position(info.offset)
                            buf.get(chunk, 0, info.size)
                            out.write(chunk)
                            if (out.size() > MAX_CACHE_BYTES) {
                                // Longer than it claimed; not ours to hold.
                                return null
                            }
                        }
                        codec.releaseOutputBuffer(outIndex, false)
                        if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                            sawOutputEnd = true
                        }
                    }
                    outIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                        val f = codec.outputFormat
                        sampleRate = f.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                        channels = f.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                    }
                }
            }
        } finally {
            try {
                codec.stop()
            } catch (_: Exception) {
            }
            codec.release()
            extractor.release()
        }

        val pcm = out.toByteArray()
        if (pcm.isEmpty()) return null
        return Clip(pcm, sampleRate, channels, envelope(pcm, sampleRate, channels))
    }

    /**
     * Mean |amplitude| per window, normalized the way the page's own analyser
     * normalizes element playback, so the bar moves the same for a clip as it
     * does for anything else.
     */
    private fun envelope(pcm: ByteArray, sampleRate: Int, channels: Int): FloatArray {
        val samples = ByteBuffer.wrap(pcm).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer()
        val framesPerWindow = sampleRate * LEVEL_WINDOW_MS / 1000
        val totalFrames = samples.remaining() / channels
        val windows = (totalFrames + framesPerWindow - 1) / framesPerWindow
        val levels = FloatArray(maxOf(windows, 1))
        for (w in 0 until windows) {
            val start = w * framesPerWindow
            val end = min(start + framesPerWindow, totalFrames)
            var sum = 0L
            var n = 0
            var f = start
            while (f < end) {
                sum += abs(samples.get(f * channels).toInt())
                n++
                f++
            }
            levels[w] = if (n == 0) 0f else (sum.toFloat() / n / 32768f).coerceIn(0f, 1f)
        }
        return levels
    }
}
