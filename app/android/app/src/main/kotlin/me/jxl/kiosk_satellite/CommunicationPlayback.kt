package me.jxl.kiosk_satellite

import android.content.Context
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.media.audiofx.AcousticEchoCanceler
import android.os.Build
import android.util.Log

/**
 * Supplies the communication playback path required by the microphone AEC.
 * Native capture keeps the built-in speaker route stable between sounds.
 * All session changes run on the main thread.
 */
internal class CommunicationPlayback(context: Context) {
    companion object {
        private var instance: CommunicationPlayback? = null
        fun get(context: Context): CommunicationPlayback =
            instance ?: CommunicationPlayback(context.applicationContext).also { instance = it }

        fun routingChanged() { instance?.refreshCaptureRoute() }

        @Volatile private var playing = false
        @Volatile private var echoTailUntil = 0L

        // AEC can legitimately return digital silence during playback and
        // while its filter settles afterward. That is not a stalled recorder.
        fun maySuppressCapture(): Boolean =
            playing || android.os.SystemClock.elapsedRealtime() < echoTailUntil
    }
    private val am = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val hasAec = AcousticEchoCanceler.isAvailable()
    private var savedMode = AudioManager.MODE_NORMAL
    private var savedSpeaker = false
    private var routeChanged = false
    private val leases = PlaybackLeasePool(::start, ::stop)
    private var captureActive = false
    private var captureLease: AutoCloseable? = null
    private var captureOutputId: Int? = null
    private var sounds = 0
    private var referenceTrack: AudioTrack? = null
    var output: AudioDeviceInfo? = null
        private set

    fun acquire(selected: AudioDeviceInfo?): AutoCloseable? {
        return try {
            refreshCaptureRoute()
            val lease = acquireAvailable(selected) ?: return null
            sounds++
            playing = true
            var closed = false
            AutoCloseable {
                if (!closed) {
                    closed = true
                    sounds--
                    playing = sounds > 0
                    echoTailUntil = android.os.SystemClock.elapsedRealtime() + 2000
                    lease.close()
                    refreshCaptureRoute()
                }
            }
        } catch (e: Exception) {
            Log.w("CommunicationPlayback", "audio route unavailable: ${e.message}")
            null
        }
    }

    fun captureStarted() {
        captureActive = true
        refreshCaptureRoute()
    }

    fun captureStopped() {
        captureActive = false
        captureOutputId = null
        val lease = captureLease
        captureLease = null
        lease?.close()
    }

    private fun refreshCaptureRoute() {
        if (!captureActive) return
        try {
            val selected = AudioRouting.currentOutput()
            val target = chooseOutput(selected)
            val input = AudioRouting.resolve(MicRecorder.inputSelector, source = true)
                ?: am.activeRecordingConfigurations.firstOrNull()?.audioDevice
            val eligible = target?.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER &&
                (input == null || input.type == AudioDeviceInfo.TYPE_BUILTIN_MIC) &&
                !AudioRouting.micHoldsCommDevice
            if (eligible && captureLease != null && captureOutputId == target?.id) return
            val old = captureLease
            captureLease = null
            captureOutputId = null
            old?.close()
            if (eligible) {
                captureLease = acquireAvailable(selected)
                if (captureLease != null) captureOutputId = target?.id
            }
        } catch (e: Exception) {
            Log.w("CommunicationPlayback", "capture route unavailable: ${e.message}")
        }
    }

    init {
        if (Build.VERSION.SDK_INT >= 31) {
            am.addOnModeChangedListener(context.mainExecutor) { mode ->
                // An existing call may have prevented capture from acquiring
                // its route. Retry only after Android returns to normal mode.
                if (mode == AudioManager.MODE_NORMAL) refreshCaptureRoute()
            }
        }
    }

    private fun acquireAvailable(selected: AudioDeviceInfo?): AutoCloseable? {
        if (!hasAec || AudioRouting.micHoldsCommDevice) return null
        if (leases.active && am.mode != AudioManager.MODE_IN_COMMUNICATION) return null
        val input = AudioRouting.resolve(MicRecorder.inputSelector, source = true)
            ?: am.activeRecordingConfigurations.firstOrNull()?.audioDevice
        // Selecting a communication output also selects its paired input.
        // Preserve an external microphone and its own echo processing.
        if (input != null && input.type != AudioDeviceInfo.TYPE_BUILTIN_MIC) return null
        val target = chooseOutput(selected) ?: return null
        if (leases.active && target.id != output?.id) return null
        if (!leases.active) output = target
        return leases.acquire()
    }

    private fun chooseOutput(selected: AudioDeviceInfo?): AudioDeviceInfo? {
        val outputs = am.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
        // External media routes such as A2DP and HDMI must keep their output.
        // Their playback cannot be moved to a phone-call route implicitly.
        val target = selected ?: outputs.firstOrNull { it.type !in setOf(
            AudioDeviceInfo.TYPE_BUILTIN_SPEAKER,
            AudioDeviceInfo.TYPE_BUILTIN_EARPIECE,
            AudioDeviceInfo.TYPE_TELEPHONY,
            24, // Built-in safe speaker.
        ) } ?: outputs.firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER }
        target ?: return null
        if (target.type !in setOf(
                AudioDeviceInfo.TYPE_BUILTIN_SPEAKER,
                AudioDeviceInfo.TYPE_BUILTIN_EARPIECE,
                AudioDeviceInfo.TYPE_WIRED_HEADSET,
                AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
                AudioDeviceInfo.TYPE_USB_HEADSET,
                AudioDeviceInfo.TYPE_USB_DEVICE,
            )) return null
        if (Build.VERSION.SDK_INT >= 31) {
            return am.availableCommunicationDevices.firstOrNull {
                it.type == target.type && it.address == target.address
            }
        }
        return target
    }

    private fun start(): Boolean {
        savedMode = am.mode
        // Do not take ownership from a phone call or another VoIP client.
        if (savedMode != AudioManager.MODE_NORMAL) return false
        echoTailUntil = android.os.SystemClock.elapsedRealtime() + 2000
        return try {
            @Suppress("DEPRECATION")
            savedSpeaker = am.isSpeakerphoneOn
            am.mode = AudioManager.MODE_IN_COMMUNICATION
            if (Build.VERSION.SDK_INT >= 31) {
                check(am.setCommunicationDevice(output!!)) { "communication output refused" }
            } else {
                @Suppress("DEPRECATION")
                am.isSpeakerphoneOn = output?.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER
            }
            routeChanged = true
            if (captureActive && output?.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER) {
                openReferenceOutput()
            }
            // Initialize only after safely acquiring the built-in speaker.
            // Leave later user adjustments alone, including during another call.
            // This is an intentional baseline, never a temporary override.
            if (output?.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER &&
                !VolumeController.isFixed) {
                VolumeController.assistantCallVolume.initialize {
                    try {
                        val max = am.getStreamMaxVolume(AudioManager.STREAM_VOICE_CALL)
                        am.setStreamVolume(AudioManager.STREAM_VOICE_CALL, max, 0)
                        am.getStreamVolume(AudioManager.STREAM_VOICE_CALL) == max
                    } catch (e: Exception) {
                        Log.w("CommunicationPlayback", "call volume initialization failed: ${e.message}")
                        false
                    }
                }
            }
            Log.i("CommunicationPlayback", "AEC route acquired (output=${output?.type})")
            true
        } catch (e: Exception) {
            Log.w("CommunicationPlayback", "communication playback unavailable: ${e.message}")
            stop()
            false
        }
    }

    private fun openReferenceOutput() {
        // Keep the HAL's communication output open between chimes and TTS.
        // Otherwise creating its first track can briefly mute media even
        // though the app has already established communication mode.
        try {
            val silence = ByteArray(4800 * 2)
            val track = AudioTrack.Builder()
                .setAudioAttributes(AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build())
                .setAudioFormat(AudioFormat.Builder().setSampleRate(48000)
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO).build())
                .setTransferMode(AudioTrack.MODE_STATIC)
                .setBufferSizeInBytes(silence.size).build()
            referenceTrack = track
            track.setVolume(0f)
            if (Build.VERSION.SDK_INT >= 28) track.preferredDevice = output
            check(track.write(silence, 0, silence.size) == silence.size)
            check(track.setLoopPoints(0, 4800, -1) == AudioTrack.SUCCESS)
            track.play()
        } catch (e: Exception) {
            referenceTrack?.let { runCatching { it.release() } }
            referenceTrack = null
            Log.w("CommunicationPlayback", "reference output unavailable: ${e.message}")
        }
    }

    private fun stop() {
        echoTailUntil = android.os.SystemClock.elapsedRealtime() + 2000
        val track = referenceTrack
        referenceTrack = null
        if (track != null) kotlin.concurrent.thread(name = "ks-aec-release") {
            runCatching { track.stop() }
            runCatching { track.release() }
        }
        fun restore(action: () -> Unit) {
            try { action() } catch (e: Exception) {
                Log.w("CommunicationPlayback", "audio state restore failed: ${e.message}")
            }
        }
        if (routeChanged && !AudioRouting.micHoldsCommDevice) {
            restore {
                if (Build.VERSION.SDK_INT >= 31) am.clearCommunicationDevice()
                else {
                    @Suppress("DEPRECATION")
                    am.isSpeakerphoneOn = savedSpeaker
                }
            }
        }
        routeChanged = false
        restore { am.mode = savedMode }
        Log.i("CommunicationPlayback", "AEC route released")
    }
}
