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
 *
 * All three of those choices are overridable from settings, because on custom
 * ROMs they are exactly what goes wrong: VOICE_COMMUNICATION is the phone-call
 * capture path, and a ROM that never had its call audio calibrated can deliver
 * it 20 dB down while a recorder app on plain MIC sounds fine. The defaults are
 * the behaviour described above; the overrides arrive as stream arguments,
 * which is why a change of any of them reopens capture.
 *
 * Channel selection: multichannel USB arrays put differently-processed
 * signals on each channel (the reSpeaker XVF3800 sends its comms output on
 * channel 1 and its raw ASR output on channel 2), and Android's stereo-to-
 * mono contraction averages them, polluting the clean channel with the
 * processed one. A `channel` argument of 1..N opens capture with a channel
 * index mask wide enough to include it and forwards only that channel; 0 (the
 * default) is the platform's mono downmix, the app's historical behavior.
 */
class MicRecorder(context: Context, messenger: BinaryMessenger) : EventChannel.StreamHandler {
    companion object {
        const val CHANNEL = "kiosk_satellite/mic"
        private const val TAG = "MicRecorder"
        private const val SAMPLE_RATE = 16000
        private const val CHUNK_BYTES = 1280 * 2 // 80 ms of 16-bit mono

        /**
         * Deafness guard: a capture stuck on all-zero frames (a wedged
         * AudioRecord after an audioserver death, or a ROM whose direct
         * 16 kHz record path is broken) cannot be fixed in place, so it is
         * reopened once at this rate - the mismatch against the usual
         * 16 kHz device forces AudioFlinger's record converter path and a
         * fresh server-side track - and decimated back to 16 kHz here.
         */
        private const val FALLBACK_RATE = 48000

        /**
         * How much all-zero audio after open before concluding the capture
         * is broken (2 s at 16 kHz). Real capture never does this - even a
         * silent room floors at nonzero ADC noise.
         */
        private const val SILENT_FALLBACK_BYTES = 2L * SAMPLE_RATE * 2
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
        val args = arguments as? Map<*, *>
        val source = audioSource(args?.get("source") as? String)
        val wantAgc = args?.get("agc") == true
        // A gain of 0 dB is the overwhelmingly common case, and a factor of
        // exactly 1 lets the read loop skip the sample walk entirely.
        val gain = gainFactor((args?.get("gainDb") as? Number)?.toDouble() ?: 0.0)
        val selector = args?.get("device") as? String
        val wantChannel = (args?.get("channel") as? Number)?.toInt() ?: 0
        // The mask must reach the chosen channel even when the device cannot
        // be resolved right now (it may still appear by open time), and must
        // cover the whole device when it can, so a 4-channel array does not
        // get opened 2-wide and remapped underneath the selection.
        val chans = if (wantChannel >= 1) {
            val reported = AudioRouting.resolve(selector, source = true)
                ?.channelCounts?.maxOrNull() ?: 0
            maxOf(2, wantChannel, reported)
        } else {
            1
        }
        var rec = try {
            openRecord(source, SAMPLE_RATE, chans)
        } catch (e: SecurityException) {
            mainHandler.post { sink.error("permission", "RECORD_AUDIO not granted", null) }
            return
        }
        // A channel selection the device cannot satisfy (mic swapped for a
        // mono one, a ROM that refuses index masks): capture beats silence,
        // so fall back to the plain mono open rather than erroring out.
        var openChans = chans
        if (rec == null && chans > 1) {
            Log.w(TAG, "$chans-channel capture failed to open; falling back to mono downmix")
            openChans = 1
            rec = try {
                openRecord(source, SAMPLE_RATE, 1)
            } catch (e: SecurityException) {
                mainHandler.post { sink.error("permission", "RECORD_AUDIO not granted", null) }
                return
            }
        }
        val opened = rec ?: run {
            mainHandler.post { sink.error("init", "AudioRecord init failed", null) }
            return
        }
        record = opened
        Log.i(
            TAG,
            "capture opening (device=${selector ?: "automatic"} " +
                "source=${sourceName(source)} gain=${"%.1f".format(gainDbOf(gain))}dB " +
                "agc=$wantAgc" +
                (if (openChans > 1) " channel=$wantChannel/$openChans" else "") + ")",
        )
        applyPreferredDevice(opened, selector)
        applyDsp(opened.audioSessionId, wantAgc)
        recording = true
        opened.startRecording()
        val channelIdx = wantChannel - 1
        worker = thread(name = "vsww-mic") {
            var cur = opened
            var chansNow = openChans
            var decimate = false
            var fellBack = false
            var announcedFallbackAudio = false
            // Rolling, not since-open: a capture can emit a startup
            // transient before going silent, so any single nonzero frame
            // must not disarm the watchdog for good.
            var zeroRun = 0L
            var buf = ByteArray(CHUNK_BYTES * chansNow)
            while (recording) {
                val read = cur.read(buf, 0, buf.size)
                if (read <= 0) continue
                // Everything downstream - the watchdog included - listens to
                // the selected channel: the array's other channels carrying
                // audio is no consolation when the chosen one is dead.
                val mono = if (chansNow > 1) extractChannel(buf, read, chansNow, channelIdx) else null
                val monoLen = mono?.size ?: read
                if (allZero(mono ?: buf, monoLen)) {
                    zeroRun += monoLen
                    if (!fellBack && zeroRun >= SILENT_FALLBACK_BYTES) {
                        fellBack = true
                        val next = try {
                            openRecord(source, FALLBACK_RATE, chansNow)
                        } catch (_: SecurityException) {
                            null
                        }
                        if (next != null) {
                            Log.w(
                                TAG,
                                "capture read only zeros for 2s - reopening at " +
                                    "$FALLBACK_RATE Hz for a fresh track through " +
                                    "the record converter path",
                            )
                            aec?.release()
                            ns?.release()
                            agc?.release()
                            aec = null
                            ns = null
                            agc = null
                            try { cur.stop() } catch (_: IllegalStateException) {}
                            cur.release()
                            applyPreferredDevice(next, selector)
                            applyDsp(next.audioSessionId, wantAgc)
                            next.startRecording()
                            cur = next
                            record = next
                            decimate = true
                            zeroRun = 0
                            buf = ByteArray(CHUNK_BYTES * 3 * chansNow)
                            continue
                        }
                        Log.w(TAG, "silent capture and the $FALLBACK_RATE Hz fallback failed to open; keeping the silent capture")
                    }
                } else {
                    zeroRun = 0
                    if (decimate && !announcedFallbackAudio) {
                        announcedFallbackAudio = true
                        Log.i(TAG, "$FALLBACK_RATE Hz fallback capture is delivering audio")
                    }
                }
                val chunk = when {
                    decimate -> decimate3(mono ?: buf, monoLen)
                    mono != null -> mono
                    else -> buf.copyOf(read)
                }
                if (gain != 1.0) amplify(chunk, chunk.size, gain)
                mainHandler.post {
                    if (recording) sink.success(chunk)
                }
            }
        }
    }

    /**
     * Open a capture at the given rate and channel count, or null when it
     * cannot be had. Multichannel opens use a channel index mask (channels in
     * wire order, no positional meaning) because that is what USB arrays
     * are: numbered outputs, not a left and a right.
     */
    private fun openRecord(source: Int, rateHz: Int, channels: Int): AudioRecord? {
        val minBuf = AudioRecord.getMinBufferSize(
            rateHz,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
        ) * channels
        val chunk = CHUNK_BYTES * (rateHz / SAMPLE_RATE) * channels
        val format = AudioFormat.Builder()
            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
            .setSampleRate(rateHz)
            .apply {
                if (channels > 1) {
                    setChannelIndexMask((1 shl channels) - 1)
                } else {
                    setChannelMask(AudioFormat.CHANNEL_IN_MONO)
                }
            }
            .build()
        val rec = try {
            AudioRecord.Builder()
                .setAudioSource(source)
                .setAudioFormat(format)
                .setBufferSizeInBytes(max(minBuf, chunk * 4))
                .build()
        } catch (e: SecurityException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, "AudioRecord open at $rateHz Hz x$channels failed: ${e.message}")
            return null
        }
        if (rec.state != AudioRecord.STATE_INITIALIZED) {
            rec.release()
            return null
        }
        return rec
    }

    /**
     * One channel of an interleaved PCM16 buffer as a fresh mono buffer.
     * [channelIdx] beyond the frame (stale selection, fallback-narrowed
     * capture) clamps to the last channel rather than reading past the frame.
     */
    private fun extractChannel(
        buf: ByteArray,
        length: Int,
        channels: Int,
        channelIdx: Int,
    ): ByteArray {
        val idx = channelIdx.coerceIn(0, channels - 1)
        val frames = length / 2 / channels
        val out = ByteArray(frames * 2)
        var si = idx * 2
        var oi = 0
        val stride = channels * 2
        repeat(frames) {
            out[oi] = buf[si]
            out[oi + 1] = buf[si + 1]
            si += stride
            oi += 2
        }
        return out
    }

    private fun allZero(buf: ByteArray, length: Int): Boolean {
        for (i in 0 until length) {
            if (buf[i] != 0.toByte()) return false
        }
        return true
    }

    /**
     * 48 kHz mono PCM16 to 16 kHz by averaging sample triplets. The fallback
     * stream is AudioFlinger's 3x upsample of a 16 kHz device, so the average
     * is near-transparent; on a genuinely 48 kHz device it doubles as a mild
     * anti-alias filter.
     */
    private fun decimate3(buf: ByteArray, length: Int): ByteArray {
        val outSamples = length / 2 / 3
        val out = ByteArray(outSamples * 2)
        var si = 0
        var oi = 0
        repeat(outSamples) {
            var acc = 0
            repeat(3) {
                acc += ((buf[si + 1].toInt() shl 8) or (buf[si].toInt() and 0xFF)).toShort().toInt()
                si += 2
            }
            val v = acc / 3
            out[oi] = (v and 0xFF).toByte()
            out[oi + 1] = ((v shr 8) and 0xFF).toByte()
            oi += 2
        }
        return out
    }

    /**
     * Multiply 16-bit little-endian samples in place, saturating at full
     * scale. Clipping rather than wrapping matters: a wrapped sample flips
     * sign and reads to a wake word model as an impulse, which is worse than
     * the flat top clipping gives.
     */
    private fun amplify(buf: ByteArray, length: Int, gain: Double) {
        var i = 0
        val end = length - 1
        while (i < end) {
            val sample = ((buf[i + 1].toInt() shl 8) or (buf[i].toInt() and 0xFF)).toShort()
            var scaled = (sample * gain).toInt()
            if (scaled > Short.MAX_VALUE.toInt()) scaled = Short.MAX_VALUE.toInt()
            if (scaled < Short.MIN_VALUE.toInt()) scaled = Short.MIN_VALUE.toInt()
            buf[i] = (scaled and 0xFF).toByte()
            buf[i + 1] = ((scaled shr 8) and 0xFF).toByte()
            i += 2
        }
    }

    /** Settings value to AudioSource, defaulting to the one we have always used. */
    private fun audioSource(name: String?): Int = when (name) {
        "mic" -> MediaRecorder.AudioSource.MIC
        "voice_recognition" -> MediaRecorder.AudioSource.VOICE_RECOGNITION
        else -> MediaRecorder.AudioSource.VOICE_COMMUNICATION
    }

    private fun sourceName(source: Int): String = when (source) {
        MediaRecorder.AudioSource.MIC -> "mic"
        MediaRecorder.AudioSource.VOICE_RECOGNITION -> "voice_recognition"
        else -> "voice_communication"
    }

    /**
     * Decibels to a linear factor, clamped to the range the settings slider
     * offers so a bad value from an import cannot blow the signal apart.
     * Negative values attenuate, for microphones that run too hot.
     */
    private fun gainFactor(db: Double): Double {
        if (db == 0.0) return 1.0
        return Math.pow(10.0, db.coerceIn(-24.0, 24.0) / 20.0)
    }

    private fun gainDbOf(factor: Double): Double =
        if (factor == 1.0) 0.0 else 20.0 * Math.log10(factor)

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
            // setCommunicationDevice only accepts entries from
            // availableCommunicationDevices - the route handle, not the
            // input device we resolved. Passing the input is silently
            // refused (returns false) and capture stays on a dead SCO
            // input, which reads as a mic that hears nothing.
            val comm = am.availableCommunicationDevices.firstOrNull {
                it.type == device.type && it.address == device.address
            } ?: am.availableCommunicationDevices.firstOrNull { it.type == device.type }
            commDeviceSet = try {
                comm != null && am.setCommunicationDevice(comm)
            } catch (e: IllegalArgumentException) {
                Log.w(TAG, "setCommunicationDevice rejected: ${e.message}")
                false
            }
            if (!commDeviceSet) {
                Log.w(
                    TAG,
                    "bluetooth capture link refused (comm device " +
                        "${if (comm == null) "not offered" else "rejected"}); " +
                        "capture will likely be silent",
                )
            }
            AudioRouting.micHoldsCommDevice = commDeviceSet
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
    private fun applyDsp(sessionId: Int, wantAgc: Boolean) {
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
        // AGC is off unless the user asked for it: it pumps the level between
        // utterances, which is exactly what the wake models were not trained
        // on. It exists as a setting for devices whose capture is so quiet
        // that a shifting level beats an inaudible one.
        if (AutomaticGainControl.isAvailable()) {
            agc = try {
                AutomaticGainControl.create(sessionId)?.also { it.setEnabled(wantAgc) }
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
            AudioRouting.micHoldsCommDevice = false
        }
    }
}
