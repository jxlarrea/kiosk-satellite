package me.jxl.kiosk_satellite

import android.content.Context
import android.content.SharedPreferences
import android.media.AudioManager
import android.os.Handler
import android.os.Looper
import java.util.concurrent.CopyOnWriteArrayList
import kotlin.math.roundToInt

/**
 * The single authority for volume, modeled as a three-fader mixer
 * (issues #62, #69, #79):
 *
 *  - MASTER is the device volume: STREAM_MUSIC on ordinary Android, a
 *    persisted software gain on fixed-volume devices (Chromebooks,
 *    Android Automotive: [AudioManager.isVolumeFixed]) where
 *    setStreamVolume is a platform no-op. Hardware buttons and the ESPHome
 *    Volume entity move this and only this.
 *  - MEDIA scales playback under the master ceiling: SendSpin's
 *    AudioTrack, the DLNA overlay's player. Music Assistant's volume
 *    commands land here - its slider is the music's, not the device's.
 *  - ASSISTANT scales Voice Satellite sounds (TTS, chimes) under the same
 *    ceiling, independent of MEDIA, so music can roam quiet or loud
 *    without the assistant whispering or shouting along with it.
 *
 * Media and assistant live in Dart settings (persisted, exported,
 * rendered by both settings UIs); Dart pushes them here so the values are
 * available synchronously on the audio paths and to SendSpin's native
 * volume reporting. Nothing but master ever touches the stream: no
 * temporary overrides, no compensation, and therefore none of the level
 * wobble those caused.
 *
 * All percents map to linear amplitude through a squared taper: sink gain
 * APIs are linear, and a linear slider crams all the audible change into
 * its bottom fifth.
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

    // Master, fixed-volume devices only (ordinary devices keep master in
    // the stream itself).
    @Volatile private var softPercent = DEFAULT_PERCENT
    @Volatile private var softMuted = false

    // The media and assistant faders, pushed from Dart settings. Media
    // mute is SendSpin's server-commanded mute: volatile, not persisted,
    // never the stream's.
    @Volatile private var mediaPct = 100
    @Volatile private var assistPct = 100
    @Volatile private var mediaMutedFlag = false

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
     * Notified on the main thread whenever any gain a sink applies may
     * have moved (a fader push from Dart, a SendSpin media command, a
     * fixed-volume master change). Listeners re-read [mediaGain] or
     * [assistGain]. Called inline when already on the main thread.
     */
    fun addListener(listener: () -> Unit) {
        listeners.add(listener)
    }

    private fun curve(pct: Int): Float = (pct / 100f).let { it * it }

    /** The master multiplier software sinks owe on fixed-volume devices;
     *  1.0 elsewhere, where the stream applies master in hardware. */
    private fun masterSoftGain(): Float = when {
        !isFixed -> 1f
        softMuted -> 0f
        else -> curve(softPercent)
    }

    // ── Master ────────────────────────────────────────────────────────

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

    // ── Media and assistant faders ────────────────────────────────────

    /** The Dart settings arriving; both at once, one notification. */
    fun setMix(media: Int, assistant: Int) {
        val m = media.coerceIn(0, 100)
        val a = assistant.coerceIn(0, 100)
        if (m == mediaPct && a == assistPct) return
        mediaPct = m
        assistPct = a
        notifyChanged()
    }

    /** SendSpin's server-commanded media volume, applied natively for
     *  snappiness; Dart persists it into the setting on the echo. */
    fun setMediaPercent(percent: Int) {
        val pct = percent.coerceIn(0, 100)
        if (pct == mediaPct) return
        mediaPct = pct
        notifyChanged()
    }

    fun mediaPercent(): Int = mediaPct

    fun setMediaMuted(muted: Boolean) {
        if (muted == mediaMutedFlag) return
        mediaMutedFlag = muted
        notifyChanged()
    }

    fun mediaMuted(): Boolean = mediaMutedFlag

    /**
     * Linear amplitude every MEDIA sink multiplies in: SendSpin's
     * AudioTrack, the DLNA overlay's player (via getVolume's gain field).
     */
    val mediaGain: Float
        get() {
            if (mediaMutedFlag) return 0f
            return masterSoftGain() * curve(mediaPct)
        }

    /** Linear amplitude for Voice Satellite sounds (SoundPlayer). */
    val assistGain: Float
        get() = masterSoftGain() * curve(assistPct)

    private fun notifyChanged() {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            for (l in listeners) l()
        } else {
            mainHandler.post { for (l in listeners) l() }
        }
    }
}
