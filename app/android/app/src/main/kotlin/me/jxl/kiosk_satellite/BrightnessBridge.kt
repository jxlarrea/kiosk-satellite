package me.jxl.kiosk_satellite

import android.content.Context
import android.content.Intent
import android.database.ContentObserver
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

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
 * Writing needs the "Modify system settings" grant (a special appop, not a
 * runtime permission); [canWrite]/[requestWrite] expose the state and
 * Android's grant screen. Reading and observing need nothing.
 */
class BrightnessBridge(
    private val context: Context,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, "kiosk_satellite/brightness")

    private fun read(): Double = try {
        Settings.System.getInt(
            context.contentResolver, Settings.System.SCREEN_BRIGHTNESS,
        ).coerceIn(0, 255) / 255.0
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
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "get" -> result.success(read().takeIf { it >= 0 })
                "set" -> {
                    val level = (call.argument<Number>("level"))?.toDouble()
                    result.success(level != null && write(level))
                }
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
            Settings.System.putInt(
                context.contentResolver,
                Settings.System.SCREEN_BRIGHTNESS,
                (level.coerceIn(0.0, 1.0) * 255).toInt(),
            )
            true
        } catch (_: Exception) {
            false
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        context.contentResolver.unregisterContentObserver(observer)
    }
}
