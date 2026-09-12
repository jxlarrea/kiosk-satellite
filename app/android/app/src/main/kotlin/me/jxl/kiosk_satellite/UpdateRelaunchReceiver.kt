package me.jxl.kiosk_satellite

import android.app.ActivityManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log

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
        val launch = HomeRole.launchIntent(context) ?: return
        if (launch.hasCategory(Intent.CATEGORY_HOME)) {
            // Package replacement can leave an empty regular task in
            // recents. Opening it would recreate the competing Activity
            // even though this update now launches through HOME.
            val main = ComponentName(context, MainActivity::class.java)
            val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            for (task in manager.appTasks) {
                try {
                    val base = task.taskInfo.baseIntent
                    if (base.component == main && !base.hasCategory(Intent.CATEGORY_HOME)) {
                        task.finishAndRemoveTask()
                    }
                } catch (e: Exception) {
                    Log.w("UpdateRelaunch", "could not remove an old app task", e)
                }
            }
        }
        context.startActivity(launch)
    }
}
