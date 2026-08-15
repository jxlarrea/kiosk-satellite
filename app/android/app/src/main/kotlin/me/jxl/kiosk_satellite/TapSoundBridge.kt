package me.jxl.kiosk_satellite

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.SoundPool
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * The system tap sound for dashboard touches, for the tap-sound setting
 * (see haptics_script.dart, which detects the touches, and HapticsBridge,
 * which is this bridge's vibration twin).
 *
 * The sample is the platform's own touch-sound click (Effect_Tick.ogg,
 * what View.playSoundEffect plays for SoundEffectConstants.CLICK and
 * therefore the exact sound the app's Flutter buttons make), but it is
 * played from our own SoundPool rather than through playSoundEffect: the
 * framework path is silently vetoed by the system's "touch sounds"
 * setting, the same hidden-second-toggle trap the haptics bridge avoids
 * with the vibrator. The pool uses USAGE_ASSISTANCE_SONIFICATION, so the
 * click rides the system stream at its volume, exactly like the
 * framework's own touch sounds.
 *
 * Two kinds: a button 'tap' at full sample volume and a slider 'tick' at
 * a fraction of it, so a drag across steps reads as a soft ratchet rather
 * than a burst of full clicks.
 *
 * If the sample file is missing (an OEM that relocated it), playback
 * falls back to AudioManager.playSoundEffect with an explicit volume,
 * the one overload that skips the touch-sounds settings check, after
 * asking the service to load its effects.
 */
class TapSoundBridge(
    private val context: Context,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, "kiosk_satellite/tap_sound")

    private var soundId = 0
    @Volatile private var loaded = false

    private val pool: SoundPool? = try {
        SoundPool.Builder()
            .setMaxStreams(2)
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
            .build()
    } catch (_: Exception) {
        null
    }

    init {
        try {
            pool?.setOnLoadCompleteListener { _, id, status ->
                if (status == 0 && id == soundId) loaded = true
            }
            val sample = CLICK_SAMPLES.firstOrNull { File(it).exists() }
            if (sample != null && pool != null) {
                soundId = pool.load(sample, 1)
            }
        } catch (_: Exception) {
            // Fall through to the playSoundEffect fallback per play.
        }
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> {
                    play(call.argument<String>("kind") ?: "tap")
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun play(kind: String) {
        val volume = if (kind == "tick") TICK_VOLUME else 1f
        try {
            if (loaded && pool != null) {
                pool.play(soundId, volume, volume, 1, 0, 1f)
            } else {
                val am = context.getSystemService(Context.AUDIO_SERVICE)
                    as? AudioManager ?: return
                // The service may have never loaded its effects (it unloads
                // them while touch sounds are off); the first play after a
                // load request can be silent, every later one lands.
                am.loadSoundEffects()
                am.playSoundEffect(AudioManager.FX_KEY_CLICK, volume)
            }
        } catch (_: Exception) {
            // A click that declines is a silent tap, never an error.
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        try {
            pool?.release()
        } catch (_: Exception) {
        }
    }

    companion object {
        // FX_KEY_CLICK's sample in AOSP, plus the partitions OEMs move the
        // ui sounds to.
        private val CLICK_SAMPLES = listOf(
            "/system/media/audio/ui/Effect_Tick.ogg",
            "/product/media/audio/ui/Effect_Tick.ogg",
            "/system_ext/media/audio/ui/Effect_Tick.ogg",
        )
        private const val TICK_VOLUME = 0.3f
    }
}
