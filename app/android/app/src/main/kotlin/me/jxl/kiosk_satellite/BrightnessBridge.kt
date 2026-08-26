package me.jxl.kiosk_satellite

import android.content.Context
import android.content.Intent
import android.content.res.Resources
import android.database.ContentObserver
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs

/**
 * The panel's real brightness — the system setting quick-settings moves — as
 * opposed to the app-window override the Flutter plugin controls.
 *
 * The distinction matters to anyone watching from outside: the window
 * override dims what the fullscreen kiosk shows, but the system slider (and
 * anything reading it, like the MQTT brightness state) never moves, and a
 * brightness change made in quick settings never reaches the app. This
 * bridge reads and writes the system value and pushes every external change
 * to Dart, so the remote admin and Home Assistant see what the panel is
 * actually doing.
 *
 * Levels cross the channel as 0..1; what they mean in the units the
 * setting itself stores is a per-device range, and lives in
 * [BrightnessScale].
 *
 * Writing needs the "Modify system settings" grant (a special appop, not a
 * runtime permission); [canWrite]/[requestWrite] expose the state and
 * Android's grant screen. Reading and observing need nothing.
 */
class BrightnessBridge(
    private val context: Context,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, "kiosk_satellite/brightness")

    // What a 0..1 level means in the units this panel's setting stores; see
    // [BrightnessScale]. Read once from the framework constants, and widened
    // if the panel ever shows us a value the scale calls impossible.
    private var scale = BrightnessScale.default

    private fun configInt(name: String): Int? {
        val res = Resources.getSystem()
        val id = res.getIdentifier(name, "integer", "android")
        if (id == 0) return null
        return try {
            res.getInteger(id)
        } catch (_: Exception) {
            null
        }
    }

    private fun pushScale() = channel.invokeMethod(
        "brightnessRange", mapOf("min" to scale.min, "max" to scale.max),
    )

    private fun read(): Double = try {
        val raw = Settings.System.getInt(
            context.contentResolver, Settings.System.SCREEN_BRIGHTNESS,
        )
        scale.widenedTo(raw)?.let {
            scale = it
            pushScale()
        }
        scale.toLevel(raw)
    } catch (_: Exception) {
        -1.0
    }

    private val observer = object : ContentObserver(Handler(Looper.getMainLooper())) {
        override fun onChange(selfChange: Boolean) {
            val level = read()
            if (level >= 0) channel.invokeMethod("brightnessChanged", level)
        }
    }

    init {
        scale = BrightnessScale.of(
            configInt("config_screenBrightnessSettingMinimum"),
            configInt("config_screenBrightnessSettingMaximum"),
        )
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "get" -> result.success(read().takeIf { it >= 0 })
                "set" -> {
                    val level = (call.argument<Number>("level"))?.toDouble()
                    result.success(level != null && write(level))
                }
                "range" ->
                    result.success(mapOf("min" to scale.min, "max" to scale.max))
                "canWrite" -> result.success(canWrite())
                "requestWrite" -> {
                    context.startActivity(
                        Intent(
                            Settings.ACTION_MANAGE_WRITE_SETTINGS,
                            Uri.parse("package:${context.packageName}"),
                        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        context.contentResolver.registerContentObserver(
            Settings.System.getUriFor(Settings.System.SCREEN_BRIGHTNESS),
            false,
            observer,
        )
    }

    private fun canWrite(): Boolean = Settings.System.canWrite(context)

    /** The last raw value asked for, so a late verification knows whether a
     *  newer write has since superseded it. */
    private var lastTarget = -1
    private val main = Handler(Looper.getMainLooper())

    private fun write(level: Double): Boolean {
        if (!canWrite()) return false
        return try {
            // Manual mode first: under adaptive brightness a written value is
            // only a hint the OS drifts away from, and a slider that does not
            // do what it says is worse than leaving auto-brightness behind.
            Settings.System.putInt(
                context.contentResolver,
                Settings.System.SCREEN_BRIGHTNESS_MODE,
                Settings.System.SCREEN_BRIGHTNESS_MODE_MANUAL,
            )
            val target = scale.toRaw(level)
            Settings.System.putInt(
                context.contentResolver,
                Settings.System.SCREEN_BRIGHTNESS,
                target,
            )
            // A value that does not survive the write is the ROM enforcing
            // limits of its own, which is otherwise invisible: the app would
            // report the level it asked for while the panel shows another.
            val stored = Settings.System.getInt(
                context.contentResolver, Settings.System.SCREEN_BRIGHTNESS,
            )
            if (abs(stored - target) > 1) {
                channel.invokeMethod(
                    "brightnessClamped", mapOf("asked" to target, "kept" to stored),
                )
            }
            lastTarget = target
            main.removeCallbacks(verify)
            main.postDelayed(verify, VERIFY_MS)
            true
        } catch (_: Exception) {
            false
        }
    }

    /**
     * The write took at the time, but the framework's brightness
     * synchronizer answers a settings write asynchronously and, once its
     * preferred value is one the panel cannot show (a value under the
     * real floor, from an older build of this app or anyone else), it
     * reverts every later write to the floor and stays that way until
     * adaptive brightness is toggled. Look again once it has had its say;
     * a reverted write gets that toggle and one more try.
     */
    private val verify = Runnable {
        val target = lastTarget
        if (target < 0) return@Runnable
        val stored = try {
            Settings.System.getInt(
                context.contentResolver, Settings.System.SCREEN_BRIGHTNESS,
            )
        } catch (_: Exception) {
            return@Runnable
        }
        if (abs(stored - target) <= 1 || !canWrite()) return@Runnable
        try {
            Settings.System.putInt(
                context.contentResolver,
                Settings.System.SCREEN_BRIGHTNESS_MODE,
                Settings.System.SCREEN_BRIGHTNESS_MODE_AUTOMATIC,
            )
            Settings.System.putInt(
                context.contentResolver,
                Settings.System.SCREEN_BRIGHTNESS_MODE,
                Settings.System.SCREEN_BRIGHTNESS_MODE_MANUAL,
            )
            Settings.System.putInt(
                context.contentResolver, Settings.System.SCREEN_BRIGHTNESS, target,
            )
            channel.invokeMethod(
                "brightnessRecovered", mapOf("asked" to target, "reverted" to stored),
            )
        } catch (_: Exception) {
        }
    }

    private companion object {
        const val VERIFY_MS = 600L
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        context.contentResolver.unregisterContentObserver(observer)
    }
}
