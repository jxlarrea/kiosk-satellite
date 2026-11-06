package me.jxl.kiosk_satellite

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ResolveInfo
import android.os.Build
import android.util.Log

/**
 * Moves the screen to the device's other launcher just before a silent update
 * replaces the kiosk, on Android 10 while the kiosk is the HOME app.
 *
 * With nothing else to show, Android answers the kiosk's death by restarting
 * HOME, which is the kiosk, while its package is frozen for the install. Each
 * start fails and is force stopped, about 200 times in 3 seconds on a Meta
 * Portal Go. If a start lands as the freeze lifts, the new process can outlive
 * the cleanup of a stale record and end up with no UID record in the Activity
 * Manager. That process looks healthy but is cut off: Android reports its UID
 * as idle to the sensor, audio and camera services, so light readings stop and
 * the mic reads zeros, and startForeground throws (see
 * [KioskSatelliteService.isOrphanedUid], the net for an install this path
 * does not cover).
 *
 * With another app's Activity in front, the kiosk's death needs no HOME start.
 * Measured on a Portal Go: 2 frozen errors per install instead of about 200.
 * [UpdateRelaunchReceiver] brings the kiosk back when the install finishes.
 *
 * The kiosk stays behind the launcher rather than returning on top of it.
 * Leaving and returning can crash the Portal's GL driver, so only a failed
 * install returns.
 *
 * The role itself is never touched: disabling HomeAlias would hand the role to
 * the other launcher, and only a person can give it back on most devices.
 */
object UpdateHomeHandoff {
    private const val TAG = "UpdateHomeHandoff"

    @Volatile
    private var steppedAside = false

    /** Whether a silent update on this device will move to another launcher. */
    fun wanted(context: Context): Boolean =
        Build.VERSION.SDK_INT == Build.VERSION_CODES.Q &&
            HomeRole.isHeld(context) &&
            otherLauncher(context) != null

    /** Called right before the commit, once nothing else can fail first. */
    fun stepAside(context: Context) {
        if (!wanted(context)) return
        val launcher = otherLauncher(context) ?: return
        try {
            context.startActivity(
                Intent(Intent.ACTION_MAIN)
                    .setComponent(launcher)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
            steppedAside = true
            Log.i(TAG, "stepped aside to ${launcher.flattenToShortString()} for the update")
        } catch (e: Exception) {
            Log.w(TAG, "could not step aside for the update: $e")
        }
    }

    /** The install failed, so the process lives on and the kiosk must return. */
    fun comeBack(context: Context) {
        if (!steppedAside) return
        steppedAside = false
        try {
            HomeRole.launchIntent(context)?.let {
                it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(it)
            }
        } catch (e: Exception) {
            Log.w(TAG, "could not return after a failed update: $e")
        }
    }

    private fun otherLauncher(context: Context): ComponentName? =
        pickLauncher(
            context.packageManager.queryIntentActivities(
                Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME),
                0,
            ),
            context.packageName,
        )

    /** A negative priority is Android's FallbackHome, which finishes itself
     *  as soon as the device is unlocked and so holds nothing in front. */
    internal fun pickLauncher(candidates: List<ResolveInfo>, self: String): ComponentName? =
        candidates.firstOrNull {
            val activity = it.activityInfo
            activity != null && activity.exported &&
                activity.packageName != self && it.priority >= 0
        }?.activityInfo?.let { ComponentName(it.packageName, it.name) }
}
