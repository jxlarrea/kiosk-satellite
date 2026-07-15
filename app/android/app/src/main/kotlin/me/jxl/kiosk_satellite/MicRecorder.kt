package me.jxl.kiosk_satellite

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import kotlin.concurrent.thread
import kotlin.math.max

/**
 * Streams 16 kHz mono PCM16 microphone audio to Dart over an EventChannel.
 *
 * Implemented natively (AudioRecord) rather than via a pub package because the
 * available streaming-mic packages don't build against AGP 9. onListen starts
 * capture; onCancel (Dart cancelling the subscription) stops it and releases
 * the mic — which is what frees it for the WebView's getUserMedia during STT.
 */
class MicRecorder(messenger: BinaryMessenger) : EventChannel.StreamHandler {
    companion object {
        const val CHANNEL = "kiosk_satellite/mic"
        private const val SAMPLE_RATE = 16000
        private const val CHUNK_BYTES = 1280 * 2 // 80 ms of 16-bit mono
    }

    private val eventChannel = EventChannel(messenger, CHANNEL)
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile private var recording = false
    private var record: AudioRecord? = null
    private var worker: Thread? = null

    init {
        eventChannel.setStreamHandler(this)
    }

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
        if (sink == null || recording) return
        val minBuf = AudioRecord.getMinBufferSize(
            SAMPLE_RATE,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
        )
        val bufSize = max(minBuf, CHUNK_BYTES * 4)
        val rec = try {
            AudioRecord(
                MediaRecorder.AudioSource.MIC,
                SAMPLE_RATE,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                bufSize,
            )
        } catch (e: SecurityException) {
            mainHandler.post { sink.error("permission", "RECORD_AUDIO not granted", null) }
            return
        }
        if (rec.state != AudioRecord.STATE_INITIALIZED) {
            rec.release()
            mainHandler.post { sink.error("init", "AudioRecord init failed", null) }
            return
        }
        record = rec
        recording = true
        rec.startRecording()
        worker = thread(name = "vsww-mic") {
            val buf = ByteArray(CHUNK_BYTES)
            while (recording) {
                val read = rec.read(buf, 0, buf.size)
                if (read > 0) {
                    val chunk = buf.copyOf(read)
                    mainHandler.post {
                        if (recording) sink.success(chunk)
                    }
                }
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        stop()
    }

    private fun stop() {
        recording = false
        worker?.let { try { it.join(500) } catch (_: InterruptedException) {} }
        worker = null
        record?.let {
            try { it.stop() } catch (_: IllegalStateException) {}
            it.release()
        }
        record = null
    }
}
