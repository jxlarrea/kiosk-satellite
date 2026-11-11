package me.jxl.kiosk_satellite

import androidx.media3.common.C
import androidx.media3.common.audio.AudioProcessor
import androidx.media3.common.audio.BaseAudioProcessor
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.log10
import kotlin.math.pow
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * The speaker equalizer (Settings > Screen & Audio > Equalizer): five fixed
 * bands and a preamp over everything the kiosk plays from its own PCM.
 *
 * Every player runs it on its samples before it hands them to its
 * [EchoReference] tap, so the echo canceller's reference is the equalized
 * sound. The echo path the canceller learns (speaker, room, microphone)
 * stays what it was, and a band moved while music plays moves the reference
 * with it. Samples that saturate here are in the reference as they are in
 * the speaker, so they cost the canceller nothing either. What the preamp
 * protects is the part after the kiosk: a boost pushes a device's own
 * amplifier or limiter harder, and what that does to the sound is not in
 * the reference.
 *
 * The bands are biquads, with no delay of their own. Nothing here follows
 * the signal's level: a compressor or a loudness curve ahead of the
 * speaker would be a different feature with its own measurements.
 *
 * With every band at 0 dB, or the switch off, there is no [Setup] and a
 * player's samples are not touched.
 */
object Equalizer {
    /** Each band's frequency in Hz. The first is a low shelf, the last a high shelf. */
    val FREQUENCIES = doubleArrayOf(100.0, 300.0, 1000.0, 3000.0, 10000.0)

    /** The peaking bands' width: they sit 1.6 octaves apart. */
    private const val PEAK_Q = 0.9
    private const val SHELF_Q = 0.7071

    /** A band has to stay this far under half the sample rate to run on a stream. */
    private const val NYQUIST_SHARE = 0.45

    /** How long a stream takes to move from one setup to the next. */
    private const val FADE_MS = 20

    /** The bands in dB and the gain ahead of them. Never changed once made. */
    class Setup(val gainsDb: DoubleArray, val preamp: Double)

    /** What plays now. Null while the equalizer is off or flat. */
    @Volatile var setup: Setup? = null
        private set

    val active: Boolean get() = setup != null

    /**
     * The settings: [gainsDb] per band, and with [automaticPreamp] the whole
     * signal lowered by the largest boost the bands add up to.
     */
    fun set(enabled: Boolean, gainsDb: List<Double>, automaticPreamp: Boolean) {
        val gains = DoubleArray(FREQUENCIES.size) { gainsDb.getOrElse(it) { 0.0 }.coerceIn(-24.0, 24.0) }
        setup = if (!enabled || gains.all { abs(it) < 0.05 }) {
            null
        } else {
            val preampDb = if (automaticPreamp) -peakDb(gains) else 0.0
            Setup(gains, 10.0.pow(preampDb / 20.0))
        }
    }

    /**
     * The most the bands raise any frequency, in dB, never under 0. Bands
     * next to each other overlap, so this can be more than the largest band.
     * Read at 48 kHz for every stream, so a 16 kHz voice and 48 kHz music
     * come down by the same amount.
     */
    fun peakDb(gainsDb: DoubleArray): Double {
        val bands = bands(gainsDb, 48000)
        var peak = 0.0
        var f = 20.0
        while (f <= 20000.0) {
            var db = 0.0
            for (band in bands) db += band.responseDb(f, 48000)
            if (db > peak) peak = db
            f *= 1.02
        }
        return peak
    }

    /** One biquad, normalized: y = b0 x + b1 x1 + b2 x2 - a1 y1 - a2 y2. */
    internal class Band(val b0: Double, val b1: Double, val b2: Double, val a1: Double, val a2: Double) {
        fun responseDb(frequency: Double, rate: Int): Double {
            val w = 2 * PI * frequency / rate
            val c1 = cos(w)
            val s1 = sin(w)
            val c2 = cos(2 * w)
            val s2 = sin(2 * w)
            val nr = b0 + b1 * c1 + b2 * c2
            val ni = -(b1 * s1 + b2 * s2)
            val dr = 1 + a1 * c1 + a2 * c2
            val di = -(a1 * s1 + a2 * s2)
            return 10 * log10((nr * nr + ni * ni) / (dr * dr + di * di))
        }
    }

    /** The bands that do something at [rate], as biquads (Audio EQ Cookbook). */
    internal fun bands(gainsDb: DoubleArray, rate: Int): List<Band> {
        val out = ArrayList<Band>(FREQUENCIES.size)
        for (i in FREQUENCIES.indices) {
            val gain = gainsDb[i]
            if (abs(gain) < 0.05) continue
            val frequency = FREQUENCIES[i]
            if (frequency > rate * NYQUIST_SHARE) continue
            val a = 10.0.pow(gain / 40.0)
            val w = 2 * PI * frequency / rate
            val cosW = cos(w)
            val shelf = i == 0 || i == FREQUENCIES.lastIndex
            val alpha = sin(w) / (2 * if (shelf) SHELF_Q else PEAK_Q)
            val b0: Double
            val b1: Double
            val b2: Double
            val a0: Double
            val a1: Double
            val a2: Double
            if (!shelf) {
                b0 = 1 + alpha * a
                b1 = -2 * cosW
                b2 = 1 - alpha * a
                a0 = 1 + alpha / a
                a1 = -2 * cosW
                a2 = 1 - alpha / a
            } else {
                val root = 2 * sqrt(a) * alpha
                // A high shelf is the low shelf with the cosine terms turned around.
                val k = if (i == 0) cosW else -cosW
                val sign = if (i == 0) 1.0 else -1.0
                b0 = a * ((a + 1) - (a - 1) * k + root)
                b1 = sign * 2 * a * ((a - 1) - (a + 1) * k)
                b2 = a * ((a + 1) - (a - 1) * k - root)
                a0 = (a + 1) + (a - 1) * k + root
                a1 = sign * -2 * ((a - 1) + (a + 1) * k)
                a2 = (a + 1) + (a - 1) * k - root
            }
            out.add(Band(b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0))
        }
        return out
    }

    /** A [Setup] at one stream's rate, with the filters' memory per channel. */
    private class Chain(val setup: Setup?, rate: Int, private val channels: Int) {
        private val bands = if (setup == null) emptyList() else bands(setup.gainsDb, rate)
        private val preamp = setup?.preamp ?: 1.0
        private val count = bands.size

        /** Coefficients, five per band. */
        private val k = DoubleArray(count * 5).also {
            for ((i, band) in bands.withIndex()) {
                it[i * 5] = band.b0
                it[i * 5 + 1] = band.b1
                it[i * 5 + 2] = band.b2
                it[i * 5 + 3] = band.a1
                it[i * 5 + 4] = band.a2
            }
        }

        /** Two values of memory per band and channel (transposed direct form II). */
        private var z = DoubleArray(count * 2 * channels)

        val flat: Boolean get() = setup == null

        fun run(x: Double, channel: Int): Double {
            var v = x * preamp
            var at = channel * count * 2
            var c = 0
            for (band in 0 until count) {
                val y = k[c] * v + z[at]
                z[at] = k[c + 1] * v - k[c + 3] * y + z[at + 1]
                z[at + 1] = k[c + 2] * v - k[c + 4] * y
                v = y
                at += 2
                c += 5
            }
            return v
        }

        fun memory(): DoubleArray = z.copyOf()

        fun restore(memory: DoubleArray) {
            z = memory.copyOf()
        }
    }

    /**
     * One player's equalizer: its own filter memory at its own rate. A
     * player makes one per track and runs every sample through it, in
     * order, before the sample reaches the track and the tap. Not thread
     * safe: one writer at a time.
     */
    class Stream(private val rate: Int, private val channels: Int) {
        private var chain = Chain(setup, rate, channels)

        /** The setup this stream is leaving, while it fades to [chain]. */
        private var leaving: Chain? = null
        private val fadeFrames = maxOf(1, rate * FADE_MS / 1000)
        private var fadeLeft = 0

        private var markChain: Chain? = null
        private var markChainMemory: DoubleArray? = null
        private var markLeaving: Chain? = null
        private var markLeavingMemory: DoubleArray? = null
        private var markFadeLeft = 0

        /**
         * Whether [process] would change anything right now. A player
         * that needs a copy to equalize asks first and writes its own
         * buffer when not.
         */
        fun idle(): Boolean {
            follow()
            return chain.flat && leaving == null
        }

        /** Take up a changed setup, fading over from the one that played. */
        private fun follow() {
            val now = setup
            if (now === chain.setup) return
            // A change in the middle of a fade drops the older of the two:
            // the settings move a step at a time, 20 ms apart at the least.
            leaving = chain
            chain = Chain(now, rate, channels)
            fadeLeft = fadeFrames
        }

        /** Remember where the filters are, for [rewind]. */
        fun mark() {
            follow()
            markChain = chain
            markChainMemory = chain.memory()
            markLeaving = leaving
            markLeavingMemory = leaving?.memory()
            markFadeLeft = fadeLeft
        }

        /**
         * Back to the last [mark]: a player whose track took only part of
         * what was equalized goes back and runs just that part again, so
         * the rest starts from the right memory when it is sent again.
         */
        fun rewind() {
            val marked = markChain ?: return
            chain = marked
            chain.restore(markChainMemory!!)
            leaving = markLeaving
            leaving?.restore(markLeavingMemory!!)
            fadeLeft = markFadeLeft
        }

        /** One sample of [channel]. The fade steps once per frame, on its last channel. */
        private fun sample(x: Double, channel: Int): Double {
            val y = chain.run(x, channel)
            val old = leaving ?: return y
            val share = fadeLeft.toDouble() / fadeFrames
            val mixed = y + (old.run(x, channel) - y) * share
            if (channel == channels - 1 && --fadeLeft <= 0) leaving = null
            return mixed
        }

        /** Equalize [length] bytes of 16 bit PCM in place. */
        fun process(pcm: ByteArray, offset: Int, length: Int) {
            if (idle()) return
            var at = offset
            val end = offset + length - (length % (channels * 2))
            while (at < end) {
                for (c in 0 until channels) {
                    val x = ((pcm[at].toInt() and 0xFF) or (pcm[at + 1].toInt() shl 8)).toDouble()
                    val y = Math.rint(sample(x, c)).coerceIn(-32768.0, 32767.0).toInt()
                    pcm[at] = y.toByte()
                    pcm[at + 1] = (y shr 8).toByte()
                    at += 2
                }
            }
        }

        /**
         * Equalize [length] bytes of little endian PCM from [source]'s
         * position [from] into [target] at its position [to]. The two may
         * be the same buffer at the same place. Neither one's own position
         * moves.
         */
        fun process(
            source: ByteBuffer,
            from: Int,
            target: ByteBuffer,
            to: Int,
            length: Int,
            bytesPerSample: Int = 2,
        ) {
            val frames = length / (channels * bytesPerSample)
            if (idle()) {
                if (source !== target || from != to) {
                    for (i in 0 until frames * channels * bytesPerSample) target.put(to + i, source.get(from + i))
                }
                return
            }
            var read = from
            var write = to
            if (bytesPerSample == 4) {
                for (f in 0 until frames) {
                    for (c in 0 until channels) {
                        val y = Math.rint(sample(source.getInt(read).toDouble(), c))
                            .coerceIn(-2147483648.0, 2147483647.0).toLong().toInt()
                        target.putInt(write, y)
                        read += 4
                        write += 4
                    }
                }
            } else {
                for (f in 0 until frames) {
                    for (c in 0 until channels) {
                        val y = Math.rint(sample(source.getShort(read).toDouble(), c))
                            .coerceIn(-32768.0, 32767.0).toInt()
                        target.putShort(write, y.toShort())
                        read += 2
                        write += 2
                    }
                }
            }
        }
    }
}

/**
 * The [Equalizer] in a Media3 player's sink, placed ahead of the tee that
 * feeds the echo canceller's reference ([tappedSink]). It stays in the
 * chain while the equalizer is off, so a setting changed in the middle of
 * a sound takes hold without the sink being rebuilt.
 */
class EqualizerProcessor : BaseAudioProcessor() {
    private var stream: Equalizer.Stream? = null

    override fun onConfigure(inputAudioFormat: AudioProcessor.AudioFormat): AudioProcessor.AudioFormat {
        if (inputAudioFormat.encoding != C.ENCODING_PCM_16BIT) {
            throw AudioProcessor.UnhandledAudioFormatException(inputAudioFormat)
        }
        return inputAudioFormat
    }

    override fun queueInput(inputBuffer: ByteBuffer) {
        val remaining = inputBuffer.remaining()
        if (remaining == 0) return
        val out = replaceOutputBuffer(remaining)
        val eq = stream
        val frameBytes = inputAudioFormat.bytesPerFrame
        if (eq == null || eq.idle() || frameBytes <= 0 || remaining % frameBytes != 0) {
            out.put(inputBuffer).flip()
            return
        }
        val source = inputBuffer.duplicate().order(ByteOrder.LITTLE_ENDIAN)
        eq.process(source, inputBuffer.position(), out.order(ByteOrder.LITTLE_ENDIAN), out.position(), remaining)
        inputBuffer.position(inputBuffer.limit())
        out.limit(out.position() + remaining)
    }

    override fun onFlush() {
        stream = Equalizer.Stream(inputAudioFormat.sampleRate, inputAudioFormat.channelCount)
    }

    override fun onReset() {
        stream = null
    }
}
