package me.jxl.kiosk_satellite.plugins

import android.os.Handler
import android.os.Looper
import java.nio.ByteBuffer
import java.util.concurrent.CopyOnWriteArraySet
import me.jxl.kiosk_satellite.VolumeController
import me.jxl.kiosk_satellite.sendspin.NativeAudioOutput

/**
 * The gains every plugin player's output takes from KS: the media volume and the assistant's duck, the same two the
 * Sendspin player and the AirPlay receiver apply.
 */
internal object PluginAudio {
    private val outputs = CopyOnWriteArraySet<PluginAudioOutput>()
    @Volatile var duck = 1f
        private set
    @Volatile private var listening = false

    fun add(output: PluginAudioOutput) {
        if (!listening) {
            listening = true
            Handler(Looper.getMainLooper()).post { VolumeController.addListener { apply() } }
        }
        outputs.add(output)
        output.setGains(VolumeController.mediaGain, duck)
    }

    fun remove(output: PluginAudioOutput) { outputs.remove(output) }

    fun setDuck(factor: Float) {
        duck = factor.coerceIn(0f, 1f)
        apply()
    }

    private fun apply() {
        val media = VolumeController.mediaGain
        for (output in outputs) output.setGains(media, duck)
    }
}

/**
 * A plugin player's PCM output: Sendspin's [NativeAudioOutput], so the AudioTrack handling, soft start, gain stages,
 * route changes and the echo canceller's tap are the same. The timestamp is the output's presented frames, the clock
 * the echo canceller reads, so a plugin keeping time with other speakers and the canceller agree.
 */
internal class PluginAudioOutput(private val rate: Int, private val channels: Int) : PluginOutput {
    private val output = NativeAudioOutput()
    private val lock = Any()
    private val frameBytes = channels * 2
    @Volatile private var closed = false
    private var presented = 0L
    private var presentedAtNs = 0L

    init { PluginAudio.add(this) }

    fun setGains(media: Float, duck: Float) {
        output.setMediaGain(media)
        output.setDuckGain(duck)
    }

    override fun write(pcm: ByteBuffer, frames: Int, timeoutMs: Int): Int {
        if (closed) return -1
        if (frames <= 0) return 0
        synchronized(lock) {
            if (closed) return -1
            if (!output.isStarted) {
                if (!output.start(rate, channels, 16)) return -1
                presented = 0
                presentedAtNs = 0
            }
        }
        val length = minOf(frames.toLong() * frameBytes, (pcm.remaining() / frameBytes).toLong() * frameBytes).toInt()
        if (length <= 0) return 0
        // The output narrows the buffer's limit as it writes, so it gets a view of its own.
        val view = pcm.duplicate()
        val taken = output.write(view, length, timeoutMs.coerceIn(1, 2000))
        if (closed) return -1
        pcm.position(pcm.position() + taken)
        return taken / frameBytes
    }

    override fun getTimestamp(out: LongArray): Boolean {
        require(out.size >= 2) { "The timestamp needs two longs" }
        synchronized(lock) {
            if (closed || !output.isStarted) return false
            output.takePresentedFramesDelta()?.let {
                presented += it.frames
                presentedAtNs = it.sampledAtUs * 1000
            }
            if (presentedAtNs == 0L) return false
            out[0] = presented
            out[1] = presentedAtNs
            return true
        }
    }

    override fun framesWritten(): Long = if (closed) 0 else output.totalFramesWritten()

    override fun flush() {
        synchronized(lock) {
            if (closed) return
            if (output.isStarted) output.pause()
            presented = 0
            presentedAtNs = 0
        }
    }

    override fun close() {
        synchronized(lock) {
            if (closed) return
            closed = true
            PluginAudio.remove(this)
        }
        output.release()
    }
}
