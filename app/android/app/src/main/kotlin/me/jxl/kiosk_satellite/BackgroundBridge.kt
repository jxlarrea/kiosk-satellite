package me.jxl.kiosk_satellite

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Dart's handle on the three OS grants that background listening needs, and on
 * bringing the app back to the front when it hears something.
 *
 * Each of the three is separate, each is refusable, and none of them can be
 * assumed — see the comments per method for what happens when one is missing.
 */
class BackgroundBridge(
    private val activity: Activity,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, "kiosk_satellite/background")

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    WakeWordService.start(activity)
                    result.success(true)
                }
                "stop" -> {
                    WakeWordService.stop(activity)
                    result.success(true)
                }
                // Can we start our own Activity while another app is in front?
                // Android 10 forbids it, and "Display over other apps" is the
                // exemption that gets it back. Without it the wake word is heard
                // and nothing happens, which is worse than not listening.
                "canBringToFront" -> result.success(canDrawOverlays())
                "requestBringToFront" -> {
                    activity.startActivity(
                        Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:${activity.packageName}"),
                        ),
                    )
                    result.success(null)
                }
                "bringToFront" -> result.success(bringToFront())
                // Samsung in particular will stop the service after a few hours
                // of "unused app" regardless of what the foreground-service rules
                // say. This is the only reliable way to be left alone.
                "isBatteryUnrestricted" -> result.success(isBatteryUnrestricted())
                "requestBatteryUnrestricted" -> {
                    requestBatteryUnrestricted()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun canDrawOverlays(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(activity)

    private fun bringToFront(): Boolean {
        if (!canDrawOverlays()) return false
        return try {
            activity.startActivity(
                Intent(activity, MainActivity::class.java).apply {
                    // REORDER_TO_FRONT rather than a fresh launch: the WebView is
                    // still mounted with the card's session on it, and a relaunch
                    // would reload the page and lose the turn we woke up for.
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                },
            )
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun isBatteryUnrestricted(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val power = activity.getSystemService(Context.POWER_SERVICE) as PowerManager
        return power.isIgnoringBatteryOptimizations(activity.packageName)
    }

    @Suppress("BatteryLife") // The point of the app is to listen continuously.
    private fun requestBatteryUnrestricted() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        activity.startActivity(
            Intent(
                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                Uri.parse("package:${activity.packageName}"),
            ),
        )
    }

    fun dispose() = channel.setMethodCallHandler(null)
}
