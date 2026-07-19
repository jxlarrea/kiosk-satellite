package me.jxl.kiosk_satellite

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
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
 * Uses the application context, not an Activity: the whole point of
 * [bringToFront] is to run when no Activity of ours is on screen (the Activity
 * may have been destroyed while the foreground service kept the process alive),
 * and an Activity reference would be stale exactly then. Starting an Activity
 * from a non-Activity context needs [Intent.FLAG_ACTIVITY_NEW_TASK].
 *
 * Each of the three grants is separate, each is refusable, and none can be
 * assumed — see the comments per method for what happens when one is missing.
 */
class BackgroundBridge(
    private val context: Context,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, "kiosk_satellite/background")

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    WakeWordService.start(context)
                    result.success(true)
                }
                "stop" -> {
                    WakeWordService.stop(context)
                    result.success(true)
                }
                // Can we start our own Activity while another app is in front?
                // Android 10 forbids it, and "Display over other apps" is the
                // exemption that gets it back. Without it the wake word is heard
                // and nothing happens, which is worse than not listening.
                "canBringToFront" -> result.success(canDrawOverlays())
                "requestBringToFront" -> {
                    context.startActivity(
                        Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:${context.packageName}"),
                        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                    )
                    result.success(null)
                }
                "bringToFront" -> result.success(bringToFront())
                // "Screen on" from the admin or the screensaver: light a
                // genuinely sleeping panel. Brightness restore alone cannot.
                "wakeScreen" -> result.success(wakeScreen())
                // True panel off. Android only grants this to an active
                // device admin (lockNow); plain apps have no API for it.
                "screenOff" -> result.success(screenOff())
                "isScreenOffAvailable" -> result.success(isAdminActive())
                // The standard grant flow: Android's own "activate device
                // admin app?" screen, one tap to approve. Opened on the
                // device whenever "Screen off" is pressed without the grant.
                "requestScreenOffAdmin" -> {
                    context.startActivity(
                        Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                            putExtra(
                                DevicePolicyManager.EXTRA_DEVICE_ADMIN,
                                ComponentName(context, KioskAdminReceiver::class.java),
                            )
                            putExtra(
                                DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                                "Lets Kiosk Satellite turn the screen off on request.",
                            )
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        },
                    )
                    result.success(null)
                }
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
        Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(context)

    private fun isAdminActive(): Boolean = try {
        val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        dpm.isAdminActive(ComponentName(context, KioskAdminReceiver::class.java))
    } catch (_: Exception) {
        false
    }

    private fun screenOff(): Boolean = try {
        val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        if (dpm.isAdminActive(ComponentName(context, KioskAdminReceiver::class.java))) {
            dpm.lockNow()
            true
        } else {
            false
        }
    } catch (_: Exception) {
        false
    }

    private fun wakeScreen(): Boolean {
        return try {
            val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            if (!pm.isInteractive) {
                @Suppress("DEPRECATION")
                pm.newWakeLock(
                    PowerManager.SCREEN_BRIGHT_WAKE_LOCK
                            or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                    "ks:screenWake",
                ).acquire(5000)
                true
            } else {
                false
            }
        } catch (_: Exception) {
            false
        }
    }

    private fun bringToFront(): Boolean {
        // A sleeping panel first: starting the Activity does not wake the
        // display, so a wake word heard with the screen off would answer
        // into darkness. Same wake-lock pattern as the kiosk's power-button
        // re-wake — and deliberately before the overlay-grant check, since
        // waking the screen needs no grant at all (the common case is the
        // kiosk still frontmost, just dark).
        wakeScreen()
        if (!canDrawOverlays()) return false
        return try {
            // Resume the existing task exactly the way tapping the launcher icon
            // does. The running Activity (singleTop) and its live WebView are
            // reused — the card session survives.
            //
            // The previous explicit-component intent with NEW_TASK + the empty
            // taskAffinity could instead spawn a *second* MainActivity instance
            // in a separate task; its fresh WebView reloaded the page and the
            // original session was lost. The launcher intent targets the app's
            // one task deterministically and never does that.
            val launch = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
                ?: return false
            launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(launch)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun isBatteryUnrestricted(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val power = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        return power.isIgnoringBatteryOptimizations(context.packageName)
    }

    @Suppress("BatteryLife") // The point of the app is to listen continuously.
    private fun requestBatteryUnrestricted() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        context.startActivity(
            Intent(
                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                Uri.parse("package:${context.packageName}"),
            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        )
    }

    fun dispose() = channel.setMethodCallHandler(null)
}
