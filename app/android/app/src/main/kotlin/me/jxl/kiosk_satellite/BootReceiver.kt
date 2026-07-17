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
 * description sends the user to that permission.
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
        context.startActivity(
            Intent(context, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        )
    }
}
