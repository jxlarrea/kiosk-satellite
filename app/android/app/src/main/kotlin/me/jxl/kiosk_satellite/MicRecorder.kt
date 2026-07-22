package me.jxl.kiosk_satellite

import android.content.Context
import android.media.AudioDeviceInfo
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.MediaRecorder
import android.media.audiofx.AcousticEchoCanceler
import android.media.audiofx.AutomaticGainControl
import android.media.audiofx.NoiseSuppressor
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
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
 *
 * Capture DSP: echo cancellation on, everything else off. We are the audio
 * source for wake-word inference, the stop word and STT, and only the first of
 * those is helped by the platform's other processing:
 *
 *  - Echo cancellation earns its keep because the stop word listens *while*
 *    TTS plays out of this same device. Without it the mic hears our own
 *    speech and scores it.
 *  - Noise suppression and AGC are off: they reshape the signal the wake
 *    models were trained on (AGC in particular pumps the level between
 *    utterances), and STT engines do better with the unprocessed stream.
 *
 * VOICE_COMMUNICATION rather than MIC is deliberate: it is the capture path
 * that carries the playback reference AEC needs. On a MIC session the effect
 * usually attaches and then silently does nothing. The tradeoff is that this
 * source also applies the platform's own NS/AGC by default, which is exactly
 * what [applyDsp] turns back off.
 */
class MicRecorder(context: Context, messenger: BinaryMessenger) : EventChannel.StreamHandler {
    companion object {
        const val CHANNEL = "kiosk_satellite/mic"
        private const val TAG = "MicRecorder"
        private const val SAMPLE_RATE = 16000
        private const val CHUNK_BYTES = 1280 * 2 // 80 ms of 16-bit mono
    }

    private val appContext = context.applicationContext
    private val eventChannel = EventChannel(messenger, CHANNEL)
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile private var recording = false
    private var record: AudioRecord? = null
    private var worker: Thread? = null
    private var aec: AcousticEchoCanceler? = null
    private var ns: NoiseSuppressor? = null
    private var agc: AutomaticGainControl? = null

    // Bluetooth capture routing we brought up and therefore owe a teardown:
    // the communication device on Android 12+, the SCO link below it.
    private var commDeviceSet = false
    private var scoStarted = false

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
                MediaRecorder.AudioSource.VOICE_COMMUNICATION,
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
        val selector = (arguments as? Map<*, *>)?.get("device") as? String
        Log.i(TAG, "capture opening (device=${selector ?: "automatic"})")
        applyPreferredDevice(rec, selector)
        applyDsp(rec.audioSessionId)
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

    /**
     * Pin capture to the user's chosen input, when one is configured and
     * currently present. A Bluetooth microphone additionally needs its call
     * audio link brought up - a plain setPreferredDevice quietly keeps
     * recording from the built-in mic without it. Absent or unmatched
     * selections fall through to Android's own routing.
     */
    private fun applyPreferredDevice(rec: AudioRecord, selector: String?) {
        if (selector.isNullOrBlank()) return
        val device = AudioRouting.resolve(selector, source = true)
        if (device == null) {
            // Absent device (BT speaker off) or a stale selector: Android
            // routes. Said out loud because silently-wrong capture routing is
            // exactly the complaint this feature answers.
            Log.w(TAG, "selected mic not matched ($selector); automatic routing")
            return
        }
        rec.preferredDevice = device
        Log.i(TAG, "capture pinned to ${device.productName} (type ${device.type}, ${device.address})")
        val bluetooth = device.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
            (Build.VERSION.SDK_INT >= 31 && device.type == 26 /* TYPE_BLE_HEADSET */)
        if (!bluetooth) return
        val am = appContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (Build.VERSION.SDK_INT >= 31) {
            commDeviceSet = try {
                am.setCommunicationDevice(device)
            } catch (e: IllegalArgumentException) {
                Log.w(TAG, "setCommunicationDevice rejected: ${e.message}")
                false
            }
        } else {
            @Suppress("DEPRECATION")
            am.startBluetoothSco()
            @Suppress("DEPRECATION")
            am.isBluetoothScoOn = true
            scoStarted = true
        }
        if (commDeviceSet || scoStarted) {
            Log.i(TAG, "bluetooth capture link up (${device.productName})")
        }
    }

    /**
     * Echo cancellation on, noise suppression and AGC off, on this capture
     * session. Each effect is device-optional, so every step is best-effort:
     * a tablet without an AEC implementation still captures fine, it just does
     * not cancel. The resulting state is logged rather than assumed, since
     * "created the effect" and "the effect is actually running" are different
     * things on Android and vary by OEM.
     */
    private fun applyDsp(sessionId: Int) {
        if (AcousticEchoCanceler.isAvailable()) {
            aec = try {
                AcousticEchoCanceler.create(sessionId)?.also { it.setEnabled(true) }
            } catch (e: RuntimeException) {
                Log.w(TAG, "AEC unavailable on this session: ${e.message}")
                null
            }
        }
        // Creating these and disabling them is how you turn off the processing
        // VOICE_COMMUNICATION applies by default; there is no "raw" flavour of
        // this source.
        if (NoiseSuppressor.isAvailable()) {
            ns = try {
                NoiseSuppressor.create(sessionId)?.also { it.setEnabled(false) }
            } catch (e: RuntimeException) {
                Log.w(TAG, "NS control unavailable: ${e.message}")
                null
            }
        }
        if (AutomaticGainControl.isAvailable()) {
            agc = try {
                AutomaticGainControl.create(sessionId)?.also { it.setEnabled(false) }
            } catch (e: RuntimeException) {
                Log.w(TAG, "AGC control unavailable: ${e.message}")
                null
            }
        }
        Log.i(
            TAG,
            "capture DSP: aec=${describe(aec?.enabled, AcousticEchoCanceler.isAvailable())} " +
                "ns=${describe(ns?.enabled, NoiseSuppressor.isAvailable())} " +
                "agc=${describe(agc?.enabled, AutomaticGainControl.isAvailable())}",
        )
    }

    private fun describe(enabled: Boolean?, available: Boolean): String = when {
        enabled == true -> "on"
        enabled == false -> "off"
        available -> "unsupported-on-session"
        else -> "unsupported-on-device"
    }

    override fun onCancel(arguments: Any?) {
        stop()
    }

    private fun stop() {
        recording = false
        worker?.let { try { it.join(500) } catch (_: InterruptedException) {} }
        worker = null
        // Effects first: they are attached to the session this AudioRecord owns.
        aec?.release()
        ns?.release()
        agc?.release()
        aec = null
        ns = null
        agc = null
        record?.let {
            try { it.stop() } catch (_: IllegalStateException) {}
            it.release()
        }
        record = null
        // Only tear down Bluetooth routing this recorder brought up; a stop
        // with automatic routing must not disturb whatever else holds it.
        if (commDeviceSet || scoStarted) {
            val am = appContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            if (commDeviceSet && Build.VERSION.SDK_INT >= 31) am.clearCommunicationDevice()
            if (scoStarted) {
                @Suppress("DEPRECATION")
                am.isBluetoothScoOn = false
                @Suppress("DEPRECATION")
                am.stopBluetoothSco()
            }
            commDeviceSet = false
            scoStarted = false
        }
    }
}
