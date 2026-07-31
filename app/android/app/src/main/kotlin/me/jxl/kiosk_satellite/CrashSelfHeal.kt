package me.jxl.kiosk_satellite

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.provider.Settings

/**
 * Brings the kiosk back after a whole-process death it did not ask for.
 *
 * A WebView native crash (issue #94: Fire OS aborts inside AAudio's timestamp
 * path, called from Amazon's WebView audio code) takes the process down with a
 * signal, below anything Java or Dart can catch. Recovery therefore has to be
 * arranged with the OS in advance, and two arrangements are made whenever the
 * kiosk Activity is on screen:
 *
 *  - [CrashGuardService], a do-nothing START_STICKY service. Android restarts
 *    a sticky service after its process dies, and that restart is the hook
 *    that relaunches the Activity. Historically this ride came only with
 *    [WakeWordService], so kiosks that never enabled background listening
 *    (the default) had no self-heal at all; the guard service is that same
 *    hook without the microphone, the notification, or the settings.
 *
 *  - a heartbeat alarm, because sticky restarts are a promise some OEMs keep
 *    loosely and Fire OS is one of them. Alarms are held by the system, so
 *    they survive the process and recreate it to deliver. Each beat checks
 *    "should the kiosk be on screen, and is it?" and reschedules itself only
 *    while the answer to the first half is yes.
 *
 * Both funnel into [maybeRelaunch], which is also what the wake-word
 * service's own sticky restart calls. Its gates keep the cure from being
 * worse than the disease: never yank the app the user deliberately switched
 * to, never fight a kiosk that is already up, never relaunch-loop an app
 * broken enough to crash at startup.
 *
 * The relaunch itself is a background activity start, which Android 10+ only
 * honors with the "Display over other apps" grant. The setup wizard requests
 * it and both settings UIs nag under "Auto-reload on error" while it is
 * missing.
 */
object CrashSelfHeal {
    private const val TAG = "CrashSelfHeal"

    /// How often the heartbeat re-checks a kiosk that should be on screen.
    /// Inexact by design (no exact-alarm grant needed); in doze Android may
    /// stretch it to ten minutes or so, which still beats a wall of ads
    /// until a human walks past.
    private const val HEARTBEAT_MS = 3 * 60_000L

    /**
     * Arm both recovery hooks, or stand them down where auto-reload is off.
     * Called from the Activity's onResume: the flag it persists there
     * (ks.crash.was_foreground) is what separates "died on screen" from
     * "user left", so arming is only meaningful from the same place.
     */
    fun arm(context: Context) {
        if (!autoReloadEnabled(context)) {
            disarm(context)
            return
        }
        CrashGuardService.start(context)
        scheduleHeartbeat(context)
    }

    /** A deliberate exit: nothing should bring the kiosk back. */
    fun disarm(context: Context) {
        cancelHeartbeat(context)
        CrashGuardService.stop(context)
    }

    /**
     * Relaunch the kiosk if, and only if, it died while it was the thing on
     * screen. Shared by every recovery hook; see the class comment on
     * [WakeWordService] for the original rationale of each gate:
     *  - the auto-reload toggle is on (it already covers renderer crashes;
     *    a whole-process crash is the same promise kept one level deeper),
     *  - the app was on screen when it died (never yank whatever app the
     *    user deliberately switched to),
     *  - no Activity is up yet (boot receiver or a sibling hook may have
     *    won the race),
     *  - the last self-heal was over two minutes ago, so an app broken
     *    enough to crash at startup cannot relaunch-loop forever.
     */
    fun maybeRelaunch(context: Context) {
        if (ActivityState.resumed) return
        val prefs = context.getSharedPreferences(
            "FlutterSharedPreferences", Context.MODE_PRIVATE)
        if (!prefs.getBoolean("flutter.ks.browser.auto_reload_on_error", true)) return
        if (!prefs.getBoolean("flutter.ks.crash.was_foreground", false)) return
        val now = System.currentTimeMillis()
        val last = prefs.getLong("flutter.ks.crash.last_self_heal", 0L)
        if (now - last < 120_000) return
        prefs.edit().putLong("flutter.ks.crash.last_self_heal", now).apply()
        val launch = context.packageManager
            .getLaunchIntentForPackage(context.packageName) ?: return
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            // Without the overlay grant Android discards this silently, so
            // say so ourselves; the attempt is still made because a few ROMs
            // are more permissive than stock.
            if (!Settings.canDrawOverlays(context)) {
                android.util.Log.w(TAG,
                    "relaunching without the overlay grant; Android may drop it")
            }
            context.startActivity(launch)
            android.util.Log.i(TAG, "relaunched the kiosk after a crash")
        } catch (e: Exception) {
            android.util.Log.w(TAG, "crash self-heal failed: $e")
        }
    }

    fun scheduleHeartbeat(context: Context) {
        try {
            val alarms = context.getSystemService(Context.ALARM_SERVICE)
                as AlarmManager
            alarms.setAndAllowWhileIdle(
                AlarmManager.ELAPSED_REALTIME_WAKEUP,
                SystemClock.elapsedRealtime() + HEARTBEAT_MS,
                heartbeatIntent(context),
            )
        } catch (e: Exception) {
            android.util.Log.w(TAG, "heartbeat schedule failed: $e")
        }
    }

    private fun cancelHeartbeat(context: Context) {
        try {
            val alarms = context.getSystemService(Context.ALARM_SERVICE)
                as AlarmManager
            alarms.cancel(heartbeatIntent(context))
        } catch (_: Exception) {
        }
    }

    private fun heartbeatIntent(context: Context): PendingIntent =
        PendingIntent.getBroadcast(
            context, 0,
            Intent(context, CrashHeartbeatReceiver::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    fun autoReloadEnabled(context: Context): Boolean =
        context.getSharedPreferences(
            "FlutterSharedPreferences", Context.MODE_PRIVATE)
            .getBoolean("flutter.ks.browser.auto_reload_on_error", true)
}

/**
 * The heartbeat's landing point. Delivery recreates the process when the
 * crash killed it, which is the entire trick: this code runs even when
 * nothing of ours survived.
 *
 * The chain re-arms itself only while the kiosk is supposed to be on screen
 * (was_foreground still true). A deliberate departure, a clean exit or the
 * toggle going off all end it; the next Activity resume starts a fresh one.
 */
class CrashHeartbeatReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (!CrashSelfHeal.autoReloadEnabled(context)) return
        val prefs = context.getSharedPreferences(
            "FlutterSharedPreferences", Context.MODE_PRIVATE)
        if (!prefs.getBoolean("flutter.ks.crash.was_foreground", false)) return
        CrashSelfHeal.scheduleHeartbeat(context)
        CrashSelfHeal.maybeRelaunch(context)
    }
}
