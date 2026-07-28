package me.jxl.kiosk_satellite

import android.content.Context
import android.content.SharedPreferences
import android.media.AudioManager
import android.os.Handler
import android.os.Looper
import java.util.concurrent.CopyOnWriteArrayList
import kotlin.math.roundToInt

/**
 * The single authority for the device's media volume.
 *
 * On ordinary Android the percent maps straight onto STREAM_MUSIC, exactly
 * as it always has. On fixed-volume devices (Chromebooks, Android
 * Automotive: [AudioManager.isVolumeFixed]) setStreamVolume is a silent
 * no-op by platform design - ChromeOS routes audio through its own mixer
 * and only the system UI moves the output level. There the percent becomes
 * a persisted software gain that every in-app audio sink applies itself:
 * SendSpin's AudioTrack, SoundPlayer's MediaPlayers (Voice Satellite TTS,
 * chimes, page sounds), and the DLNA overlay's player on the Dart side
 * (issue #62).
 *
 * Both bridges (BackgroundBridge for the MQTT entity and remote admin,
 * SendspinBridge for server-commanded volume) read and write through here,
 * so every control surface sees one number wherever it lives.
 *
 * [gain] maps the percent to linear amplitude through a squared taper:
 * sink gain APIs are linear, and a linear slider crams all the audible
 * change into its bottom fifth. On non-fixed devices gain is always 1.0 -
 * the stream volume does the attenuating - so sinks may apply it
 * unconditionally.
 */
object VolumeController {
    private const val PREFS = "volume_controller"
    private const val KEY_PERCENT = "software_volume"
    private const val KEY_MUTED = "software_muted"
    private const val DEFAULT_PERCENT = 100

    private lateinit var audioManager: AudioManager
    private lateinit var prefs: SharedPreferences
    private val mainHandler = Handler(Looper.getMainLooper())
    private val listeners = CopyOnWriteArrayList<() -> Unit>()

    var isFixed: Boolean = false
        private set

    @Volatile private var softPercent = DEFAULT_PERCENT
    @Volatile private var softMuted = false

    fun init(context: Context) {
        audioManager =
            context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        isFixed = try {
            audioManager.isVolumeFixed
        } catch (_: Exception) {
            false
        }
        prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        softPercent = prefs.getInt(KEY_PERCENT, DEFAULT_PERCENT).coerceIn(0, 100)
        softMuted = prefs.getBoolean(KEY_MUTED, false)
    }

    /**
     * Notified on the main thread whenever the software gain moved (fixed
     * mode only; on ordinary devices the platform's own volume broadcast
     * already covers changes). Listeners re-read [gain].
     */
    fun addListener(listener: () -> Unit) {
        listeners.add(listener)
    }

    /** Current volume as 0-100, whichever mode. */
    fun percent(): Int {
        if (isFixed) return softPercent
        val max = audioManager
            .getStreamMaxVolume(AudioManager.STREAM_MUSIC).coerceAtLeast(1)
        val cur = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
        return (cur * 100.0 / max).roundToInt().coerceIn(0, 100)
    }

    /**
     * (level, max) as the getVolume channel method reports them. Fixed mode
     * reports percent out of 100, which the Dart side's level/max math
     * passes through unchanged.
     */
    fun levelAndMax(): Pair<Int, Int> {
        if (isFixed) return softPercent to 100
        return audioManager.getStreamVolume(AudioManager.STREAM_MUSIC) to
            audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
    }

    /** Set by raw level against [levelAndMax]'s max (the channel contract). */
    fun setLevel(level: Int) {
        if (isFixed) {
            setPercent(level)
            return
        }
        val max = audioManager
            .getStreamMaxVolume(AudioManager.STREAM_MUSIC).coerceAtLeast(1)
        try {
            audioManager.setStreamVolume(
                AudioManager.STREAM_MUSIC, level.coerceIn(0, max), 0,
            )
        } catch (e: SecurityException) {
            android.util.Log.w("VolumeController", "setStreamVolume rejected: ${e.message}")
        }
    }

    fun setPercent(percent: Int) {
        val pct = percent.coerceIn(0, 100)
        if (isFixed) {
            if (pct == softPercent) return
            softPercent = pct
            prefs.edit().putInt(KEY_PERCENT, pct).apply()
            notifyChanged()
            return
        }
        val max = audioManager
            .getStreamMaxVolume(AudioManager.STREAM_MUSIC).coerceAtLeast(1)
        val index = (pct / 100.0 * max).roundToInt().coerceIn(0, max)
        try {
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, index, 0)
        } catch (e: SecurityException) {
            android.util.Log.w("VolumeController", "setStreamVolume rejected: ${e.message}")
        }
    }

    fun muted(): Boolean {
        if (isFixed) return softMuted
        return audioManager.isStreamMute(AudioManager.STREAM_MUSIC)
    }

    fun setMuted(muted: Boolean) {
        if (isFixed) {
            if (muted == softMuted) return
            softMuted = muted
            prefs.edit().putBoolean(KEY_MUTED, muted).apply()
            notifyChanged()
            return
        }
        try {
            audioManager.adjustStreamVolume(
                AudioManager.STREAM_MUSIC,
                if (muted) AudioManager.ADJUST_MUTE else AudioManager.ADJUST_UNMUTE,
                0,
            )
        } catch (e: SecurityException) {
            android.util.Log.w("VolumeController", "adjustStreamVolume rejected: ${e.message}")
        }
    }

    /**
     * Linear amplitude every in-app sink multiplies in. 1.0 on ordinary
     * devices; the squared software percent (0 when soft-muted) on fixed
     * ones.
     */
    val gain: Float
        get() {
            if (!isFixed) return 1f
            if (softMuted) return 0f
            val p = softPercent / 100f
            return p * p
        }

    private fun notifyChanged() {
        mainHandler.post { for (l in listeners) l() }
    }
}
