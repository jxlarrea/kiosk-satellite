package me.jxl.kiosk_satellite

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Launches the kiosk when the device powers on, if the "Start on boot"
 * setting is on. The Flutter engine is not running at boot, so the setting
 * is read straight from the shared_preferences store ("flutter." + the
 * app's "ks." prefix). On Android 10+ a background activity start is only
 * honored because the app holds the draw-over-apps grant — the setting's
 * description sends the user to that permission. The keep-alive service is
 * started first and separately: a boot receiver may always start a
 * foreground service, so the kiosk's connections come up even on a device
 * whose Activity start is dropped.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON" -> Unit
            else -> return
        }
        val prefs = context.getSharedPreferences(
            "FlutterSharedPreferences", Context.MODE_PRIVATE)
        if (!prefs.getBoolean("flutter.ks.kiosk.start_on_boot", false)) return
        KioskSatelliteService.ensureRunning(context)
        // As the device's home app the system has already launched the
        // kiosk itself, before this broadcast arrives; a second start is
        // harmless but log-noisy (issue #219).
        if (HomeRole.isHeld(context)) return
        // The launcher's own intent, not a bare component one: it carries
        // the flags that surface an existing task instead of rooting a
        // duplicate beside it.
        val launch = context.packageManager
            .getLaunchIntentForPackage(context.packageName) ?: return
        context.startActivity(launch)
    }
}
