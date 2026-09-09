package me.jxl.kiosk_satellite

import android.content.Context
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.media.audiofx.AcousticEchoCanceler
import android.os.Build
import android.util.Log

/**
 * Supplies the communication playback path required by the microphone AEC.
 * Owned only while sounds play. All session changes run on the main thread.
 */
internal class CommunicationPlayback(context: Context) {
    companion object {
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
    var output: AudioDeviceInfo? = null
        private set

    fun acquire(selected: AudioDeviceInfo?): AutoCloseable? {
        return try { acquireAvailable(selected) } catch (e: Exception) {
            Log.w("CommunicationPlayback", "audio route unavailable: ${e.message}")
            null
        }
    }

    private fun acquireAvailable(selected: AudioDeviceInfo?): AutoCloseable? {
        if (!hasAec || AudioRouting.micHoldsCommDevice) return null
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
        playing = true
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
            Log.i("CommunicationPlayback", "AEC playback started (output=${output?.type})")
            true
        } catch (e: Exception) {
            Log.w("CommunicationPlayback", "communication playback unavailable: ${e.message}")
            stop()
            false
        }
    }

    private fun stop() {
        echoTailUntil = android.os.SystemClock.elapsedRealtime() + 2000
        playing = false
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
        Log.i("CommunicationPlayback", "AEC playback released")
    }
}
