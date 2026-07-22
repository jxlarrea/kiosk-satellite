package me.jxl.kiosk_satellite

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Relaunches the kiosk after its own package was replaced.
 *
 * A silent self-update (see ApkInstaller) kills the process mid-swap and
 * Android does not bring apps back on its own, so without this a hands-free
 * update would end on the launcher: exactly the wall-tablet failure the
 * update entity exists to avoid. Same background-start reasoning as
 * BootReceiver: the launch is honored because the app holds the
 * draw-over-apps grant. Unconditional on purpose - the app was running when
 * it updated itself, so coming back is always the right call.
 */
class UpdateRelaunchReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_MY_PACKAGE_REPLACED) return
        val launch = context.packageManager
            .getLaunchIntentForPackage(context.packageName) ?: return
        context.startActivity(launch)
    }
}
