package me.jxl.kiosk_satellite

import android.content.Context
import android.content.res.Resources
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.SoundPool
import android.os.Environment
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import org.xmlpull.v1.XmlPullParser

/**
 * The system tap sound for dashboard touches, for the tap-sound setting
 * (see haptics_script.dart, which detects the touches, and HapticsBridge,
 * which is this bridge's vibration twin).
 *
 * The primary path is the framework itself:
 * AudioManager.playSoundEffect(FX_KEY_CLICK, volume) is the same call the
 * app's Flutter buttons ride (View.playSoundEffect(CLICK) lands there),
 * so whatever sample a vendor maps the click to, including any sound
 * theme their firmware applies, plays identically on the dashboard with
 * no filename knowledge here. The explicit-volume overload is used
 * deliberately: it is the one that skips the system "touch sounds"
 * enabled check, the hidden-second-toggle veto this feature must not sit
 * behind, and it carries the volume slider. The effects are asked to
 * load per play; loading is idempotent and the request only matters
 * right after the system unloaded them.
 *
 * The framework can only play what its own loader finds, and it looks in
 * exactly one place: <root>/media/audio/ui/<file named by the framework's
 * audio_assets.xml>. Some firmwares keep the ui sounds on another
 * partition, leaving that path empty and the framework path silent with
 * no error to observe. When that one file is missing at init, the bridge
 * resolves the same audio_assets.xml mapping itself and plays the file
 * from its own SoundPool (searching the partitions ui sounds live on,
 * with AOSP's Effect_Tick.ogg as the fallback name). The pool uses
 * USAGE_ASSISTANCE_SONIFICATION, so it rides the system stream at its
 * volume, exactly like the framework's own touch sounds.
 *
 * Two kinds: a button 'tap' at the volume the app passes per play (the
 * user's volume slider; the platform itself never plays touch sounds at
 * full scale, so 1.0 here is far louder than the system's own clicks)
 * and a slider 'tick' at a fixed fraction of it, so a drag across steps
 * reads as a soft ratchet rather than a burst of full clicks.
 */
class TapSoundBridge(
    private val context: Context,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, "kiosk_satellite/tap_sound")

    private var soundId = 0
    @Volatile private var loaded = false
    private var useFramework = false

    private val audioManager: AudioManager?
        get() = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager

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
            val mapped = mappedClickFile()
            val frameworkFile = File(
                Environment.getRootDirectory(),
                "media/audio/ui/" + (mapped ?: FALLBACK_SAMPLE),
            )
            if (frameworkFile.exists()) {
                useFramework = true
                audioManager?.loadSoundEffects()
            } else {
                pool?.setOnLoadCompleteListener { _, id, status ->
                    if (status == 0 && id == soundId) loaded = true
                }
                val sample = findClickSample(mapped)
                if (sample != null && pool != null) {
                    soundId = pool.load(sample, 1)
                }
            }
        } catch (_: Exception) {
            // Fall through to the playSoundEffect fallback per play.
        }
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> {
                    play(
                        call.argument<String>("kind") ?: "tap",
                        call.argument<Double>("volume") ?: 1.0,
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun play(kind: String, base: Double) {
        val volume = (base.toFloat() * if (kind == "tick") TICK_VOLUME else 1f)
            .coerceIn(0f, 1f)
        try {
            if (!useFramework && loaded && pool != null) {
                pool.play(soundId, volume, volume, 1, 0, 1f)
            } else {
                val am = audioManager ?: return
                // Idempotent; only matters right after the system unloaded
                // its effects (the play that raced the load stays silent,
                // the next one lands).
                am.loadSoundEffects()
                am.playSoundEffect(AudioManager.FX_KEY_CLICK, volume)
            }
        } catch (_: Exception) {
            // A click that declines is a silent tap, never an error.
        }
    }

    /**
     * The path of the sample this device's framework plays for
     * FX_KEY_CLICK, for firmwares where the framework's own loader finds
     * nothing: the mapped filename searched across the partitions ui
     * sounds live on, with AOSP's Effect_Tick.ogg as the fallback name.
     */
    private fun findClickSample(mapped: String?): String? {
        val names = mutableListOf<String>()
        mapped?.let { names.add(it) }
        if (FALLBACK_SAMPLE !in names) names.add(FALLBACK_SAMPLE)
        for (name in names) {
            if (name.startsWith("/")) {
                if (File(name).exists()) return name
                continue
            }
            for (dir in SOUND_DIRS) {
                val path = "$dir/media/audio/ui/$name"
                if (File(path).exists()) return path
            }
        }
        return null
    }

    /**
     * The filename the framework's audio_assets.xml maps FX_KEY_CLICK
     * to — the same resource the system's sound-effect loader reads.
     * AOSP nests the assets in a <group name="touch_sounds">; some
     * vendors put them at the document root with no group element, so an
     * asset counts when it is at the root or in the touch_sounds group.
     */
    private fun mappedClickFile(): String? = try {
        val res = Resources.getSystem()
        val id = res.getIdentifier("audio_assets", "xml", "android")
        if (id == 0) {
            null
        } else {
            val parser = res.getXml(id)
            var group: String? = null
            var file: String? = null
            try {
                while (file == null) {
                    val event = parser.next()
                    if (event == XmlPullParser.END_DOCUMENT) break
                    if (event == XmlPullParser.END_TAG) {
                        if (parser.name == "group") group = null
                        continue
                    }
                    if (event != XmlPullParser.START_TAG) continue
                    when (parser.name) {
                        "group" -> group = parser.getAttributeValue(null, "name")
                        "asset" -> if ((group == null || group == "touch_sounds") &&
                            parser.getAttributeValue(null, "id") == "FX_KEY_CLICK"
                        ) {
                            file = parser.getAttributeValue(null, "file")
                        }
                    }
                }
            } finally {
                parser.close()
            }
            file
        }
    } catch (_: Exception) {
        null
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        try {
            pool?.release()
        } catch (_: Exception) {
        }
    }

    companion object {
        private val SOUND_DIRS = listOf(
            "/system", "/product", "/system_ext", "/oem", "/odm",
        )
        private const val FALLBACK_SAMPLE = "Effect_Tick.ogg"
        private const val TICK_VOLUME = 0.3f
    }
}
