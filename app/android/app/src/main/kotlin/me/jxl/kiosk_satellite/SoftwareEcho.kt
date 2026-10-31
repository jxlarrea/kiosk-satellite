package me.jxl.kiosk_satellite

import android.util.Log

/**
 * Echo cancellation in software: WebRTC's AEC3 by default and the opt-in
 * custom filter for duplex voice, with everything the kiosk plays
 * ([EchoReference]) as the
 * reference. MicRecorder turns it on with the capture when the setting
 * asks for it, and hands every chunk to [process] on its thread before any
 * consumer sees it, so the wake word, Assist, realtime conversations, the
 * intercom and the RTSP stream all hear the cleaned microphone.
 *
 * It only works while something plays and for a short tail after: with
 * nothing in the reference there is no echo to take out, and the idle
 * microphone goes through untouched. The canceller itself stays loaded, so
 * what it learned about the room carries over to the next sound.
 */
object SoftwareEcho {
    private const val TAG = "SoftwareEcho"
    private const val RATE = EchoReference.RATE

    /** A frame, 10 ms of 16 kHz PCM16. */
    private const val FRAME = RATE / 100
    private const val FRAME_BYTES = FRAME * 2

    /** How long after the last sound the room can still echo it. */
    private const val TAIL_MS = 1500L

    /** Each source's recent history, longer than any capture chunk. */
    private const val HISTORY = RATE * 400 / 1000

    private val loaded: Boolean = try {
        System.loadLibrary("kiosk_echo")
        true
    } catch (e: Throwable) {
        Log.w(TAG, "native library unavailable: ${e.message}")
        false
    }

    private val customDuplex = loaded && nativePrototypeAvailable(false)
    private val customRealtime = loaded && nativePrototypeAvailable(true)
    private var usesPrototype = false

    private val lock = Object()
    private var handle = 0L
    private var working = false
    private var workingSinceNs = 0L

    /**
     * WebRTC's noise suppressor over every capture chunk, after the
     * canceller: a microphone's hiss is there whether or not anything
     * plays, and it carried straight into intercom calls on an Echo Show
     * 8. Its own module, so it runs while the canceller's rests.
     */
    private var nsHandle = 0L

    /** Whether the suppressor runs. */
    @Volatile var noiseSuppression = false
        private set

    fun setNoiseSuppression(on: Boolean) {
        synchronized(lock) {
            if (on == noiseSuppression) return
            if (on) {
                if (!loaded) return
                val created = nativeNsCreate(RATE)
                if (created == 0L) return
                nsHandle = created
                noiseSuppression = true
            } else {
                noiseSuppression = false
                nativeDestroy(nsHandle)
                nsHandle = 0L
            }
        }
    }

    /**
     * How far a chunk's place by the clock may stray from where the last
     * chunk ended and still follow on from it. A track's position comes in
     * mixer-sized steps a few milliseconds apart: jumping on each of them
     * would cut the reference into pieces the canceller cannot follow.
     */
    private const val SLACK = RATE * 10 / 1000

    /**
     * A source's recent samples, placed in time: [end] is one past the last
     * one the speaker had presented at [endNs]. A capture chunk reads the
     * samples the speaker was playing while it was being captured, by the
     * capture's own clock (MicRecorder's CaptureClock). Placing each chunk
     * by the clock rather than by when this code happens to run keeps the
     * reference the same distance from the microphone every time a sound
     * starts, so the canceller keeps what it learned instead of relearning
     * the delay for a second and a half at the start of every answer.
     */
    private class Stream {
        val samples = ShortArray(HISTORY)
        var length = 0
        var end = 0L
        var endNs = 0L
        var cursor = Long.MIN_VALUE
    }

    private val streams = HashMap<EchoReference.Source, Stream>()

    private val residualGate = ResidualEchoGate()

    /**
     * Each player owns its processing request. Stopping one cannot disable
     * another. AEC3 runs with one configuration in every mode, so a call
     * starting or ending keeps the canceller and what it learned from the
     * ring and every sound before it: rebuilt at each call, it started
     * every call empty and let the first far sentence through while it
     * learned. Only an experimental build that swaps in the custom filter
     * for a mode rebuilds.
     */
    internal fun setMode(owner: Any, mode: ResidualEchoGate.Mode?) {
        synchronized(lock) {
            residualGate.set(owner, mode)
            val prototype = (customDuplex && residualGate.intercomOnly) ||
                (customRealtime && residualGate.realtime)
            if (enabled && prototype != usesPrototype) {
                val next = nativeCreate(RATE, RATE, false, residualGate.intercomOnly, residualGate.realtime)
                if (next != 0L) {
                    stopWorking()
                    nativeDestroy(handle)
                    handle = next
                    usesPrototype = prototype
                }
            }
        }
    }

    private val mix = ShortArray(FRAME)
    private val mixBytes = ByteArray(FRAME_BYTES)

    /** Whether the capture runs through the canceller. */
    @Volatile var enabled = false
        private set

    /** On or off with the capture's settings. */
    fun setEnabled(on: Boolean) {
        synchronized(lock) {
            if (on == enabled) return
            if (on) {
                if (!loaded) return
                val created = nativeCreate(RATE, RATE, false, residualGate.intercomOnly, residualGate.realtime)
                if (created == 0L) return
                handle = created
                usesPrototype = (customDuplex && residualGate.intercomOnly) || (customRealtime && residualGate.realtime)
                enabled = true
                Log.i(TAG, "on")
            } else {
                enabled = false
                stopWorking()
                nativeDestroy(handle)
                handle = 0L
                usesPrototype = false
                streams.clear()
                residualGate.reset()
                Log.i(TAG, "off")
            }
        }
    }

    /** Each frame's level after the canceller and before the gate, for [MicLevels]. */
    private var levels = DoubleArray(0)

    /** One capture chunk of 16 kHz mono PCM16 whose last frame was heard at [heardNs], cleaned in place. */
    fun process(chunk: ByteArray, heardNs: Long) {
        if (!enabled && !noiseSuppression) return
        synchronized(lock) {
            // Arbitration's levels come before the gate and the suppressor,
            // which only make the floor quieter.
            if (cancel(chunk, heardNs)) MicLevels.add(levels, chunk.size / FRAME_BYTES)
            else MicLevels.measure(chunk)
            val ns = nsHandle
            if (ns != 0L) {
                var at = 0
                while (at + FRAME_BYTES <= chunk.size) {
                    nativeNsProcess(ns, chunk, at)
                    at += FRAME_BYTES
                }
            }
        }
    }

    /**
     * The canceller's share of [process], under [lock]. True when it ran,
     * with each frame's level before the gate in [levels].
     */
    private fun cancel(chunk: ByteArray, heardNs: Long): Boolean {
        if (!enabled) return false
        run {
            val h = handle
            if (h == 0L) return false
            val sources = EchoReference.sources()
            var fresh = false
            for (source in sources) {
                val takenNs = System.nanoTime()
                source.take()?.let {
                    val stream = streams.getOrPut(source) { Stream() }
                    append(stream, it)
                    stream.endNs = takenNs
                    fresh = true
                }
            }
            streams.keys.retainAll(sources.toSet())
            if (!EchoReference.playedWithin(TAIL_MS) && !fresh) {
                stopWorking()
                return false
            }
            if (!working) {
                working = true
                workingSinceNs = System.nanoTime()
            }
            val frames = chunk.size / FRAME_BYTES
            val need = frames * FRAME
            if (levels.size < frames) levels = DoubleArray(frames)
            for (stream in streams.values) {
                // The sample the speaker was presenting as the chunk's last
                // frame was heard, and the chunk's worth before it.
                val heard = stream.end - (stream.endNs - heardNs) * RATE / 1_000_000_000L
                val start = heard - need
                if (stream.cursor == Long.MIN_VALUE || kotlin.math.abs(start - stream.cursor) > SLACK) {
                    stream.cursor = start
                }
            }
            var at = 0
            for (f in 0 until frames) {
                mixFrame(f)
                for (i in 0 until FRAME) {
                    val v = mix[i].toInt()
                    mixBytes[i * 2] = v.toByte()
                    mixBytes[i * 2 + 1] = (v shr 8).toByte()
                }
                val heard = meanAbs(chunk, at)
                val played = meanAbs(mixBytes, 0)
                nativeRender(h, mixBytes, 0)
                nativeCapture(h, chunk, at)
                levels[f] = MicLevels.meanSquare(chunk, at)
                if (residualGate.suppress(heard, played, meanAbs(chunk, at), subtractionOnly = usesPrototype)) {
                    java.util.Arrays.fill(chunk, at, at + FRAME_BYTES, 0)
                }
                at += FRAME_BYTES
            }
            for (stream in streams.values) stream.cursor += need
        }
        return true
    }

    /** Mean |sample| of the frame at [at]. */
    private fun meanAbs(pcm: ByteArray, at: Int): Int {
        var sum = 0
        for (i in 0 until FRAME) {
            val v = (pcm[at + i * 2].toInt() and 0xFF) or (pcm[at + i * 2 + 1].toInt() shl 8)
            sum += kotlin.math.abs(v.toShort().toInt())
        }
        return sum / FRAME
    }

    /** Frame [f] of this chunk from every source, read at its cursor and summed into [mix]. */
    private fun mixFrame(f: Int) {
        java.util.Arrays.fill(mix, 0)
        for (stream in streams.values) {
            val first = stream.end - stream.length
            val from = stream.cursor + f * FRAME
            for (i in 0 until FRAME) {
                val at = from + i - first
                if (at < 0 || at >= stream.length) continue
                mix[i] = (mix[i] + stream.samples[at.toInt()]).coerceIn(-32768, 32767).toShort()
            }
        }
    }

    private fun append(stream: Stream, samples: ShortArray) {
        val buffer = stream.samples
        if (samples.size >= buffer.size) {
            System.arraycopy(samples, samples.size - buffer.size, buffer, 0, buffer.size)
            stream.length = buffer.size
        } else {
            val drop = maxOf(0, stream.length + samples.size - buffer.size)
            if (drop > 0) {
                System.arraycopy(buffer, drop, buffer, 0, stream.length - drop)
                stream.length -= drop
            }
            System.arraycopy(samples, 0, buffer, stream.length, samples.size)
            stream.length += samples.size
        }
        stream.end += samples.size
    }

    /**
     * Back to idle, and a line for the log: how long it worked and the echo
     * delay it found (the time from a sound playing to its echo in the
     * microphone, 110 to 130 ms on a Galaxy Tab S8).
     */
    private fun stopWorking() {
        if (!working) return
        working = false
        residualGate.reset()
        val h = handle
        if (h == 0L) return
        val delayMs = nativeStats(h)[1]
        val seconds = (System.nanoTime() - workingSinceNs) / 1_000_000_000.0
        Log.i(TAG, "cancelled for %.1f s, echo delay %s".format(
            seconds, if (delayMs.isNaN()) "not found" else "${delayMs.toInt()} ms",
        ))
    }

    @JvmStatic private external fun nativeCreate(captureRate: Int, renderRate: Int, noiseSuppression: Boolean, intercom: Boolean, realtime: Boolean): Long
    @JvmStatic private external fun nativePrototypeAvailable(realtime: Boolean): Boolean
    @JvmStatic private external fun nativeRender(handle: Long, pcm: ByteArray, offset: Int)
    @JvmStatic private external fun nativeCapture(handle: Long, pcm: ByteArray, offset: Int)
    @JvmStatic private external fun nativeStats(handle: Long): DoubleArray
    @JvmStatic private external fun nativeDestroy(handle: Long)
    @JvmStatic private external fun nativeNsCreate(rate: Int): Long
    @JvmStatic private external fun nativeNsProcess(handle: Long, pcm: ByteArray, offset: Int)
}
