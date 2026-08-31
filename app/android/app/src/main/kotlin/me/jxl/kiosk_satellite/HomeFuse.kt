package me.jxl.kiosk_satellite

import android.app.Activity
import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * The safety fuse under the home-launcher role (issue #219): a kiosk that
 * crash-loops while it IS the home app would otherwise strand whoever is
 * in front of the device on a black screen, with the system relaunching
 * the same broken home over and over. The fuse counts Activity starts that
 * never reach a Flutter frame and, at [TRIP_AFTER] chained attempts, gives
 * HOME back to the OEM launcher: alias disabled, any device-owner
 * persistent-preferred entry cleared, and the Activity finished so the
 * system re-resolves. Pure Kotlin on purpose, it must work when Dart is
 * exactly what is broken.
 *
 * The constants are load-bearing relative to their neighbors:
 *  - [TRIP_AFTER] sits strictly above RendererGuard.TRIP_AFTER (2), so a
 *    device whose renderer kills the boot gets its Skia fallback on
 *    attempt 3 before the fuse surrenders the role.
 *  - [WINDOW_MS] sits above CrashSelfHeal's 120s relaunch throttle, so a
 *    crash loop paced by that throttle still chains into one window
 *    instead of resetting the count every time.
 *
 * FrameWatchdog wedges count too: its restartProcess brings up a fresh
 * process whose Activity start lands here, and a wedge never reaches the
 * frame that resets the counter. Deliberate restarts (restartApp, a
 * self-update relaunch) reach the first frame and reset.
 */
object HomeFuse {
    private const val TAG = "HomeFuse"
    private const val PREFS = "FlutterSharedPreferences"
    private const val ATTEMPTS = "flutter.ks.home.attempts"
    private const val LAST_ATTEMPT_AT = "flutter.ks.home.last_attempt_at"
    private const val TRIPPED = "flutter.ks.home.fuse_tripped"
    private const val REASON = "flutter.ks.home.fuse_reason"
    private const val ROLE_DENIALS = "flutter.ks.home.role_denials"

    private const val WINDOW_MS = 180_000L
    private const val TRIP_AFTER = 3L

    /** One count per process, however many times the Activity is
     *  re-created inside it (a permission dialog on some builds, memory
     *  pressure): only a fresh process is a fresh boot attempt. */
    @Volatile private var counted = false

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /**
     * Called first thing in MainActivity.onCreate. Returns true when the
     * fuse tripped and the Activity must finish() immediately: the system
     * then hands HOME to the fallback launcher.
     */
    fun noteBootAttempt(activity: Activity): Boolean {
        if (counted) return false
        counted = true
        // Only armed while the role machinery is engaged; after a trip the
        // alias is off, so the crash machinery keeps retrying the app
        // without ever re-tripping.
        if (!HomeRole.aliasEnabled(activity)) return false
        val p = prefs(activity)
        val now = System.currentTimeMillis()
        val last = p.getLong(LAST_ATTEMPT_AT, 0L)
        val attempts =
            if (now - last < WINDOW_MS) p.getLong(ATTEMPTS, 0L) + 1 else 1L
        // commit(), not apply(): the process may be dead before the next
        // frame, and this marker is the only witness the next boot has.
        p.edit().putLong(ATTEMPTS, attempts)
            .putLong(LAST_ATTEMPT_AT, now).commit()
        if (attempts < TRIP_AFTER) return false
        trip(activity, attempts)
        return true
    }

    private fun trip(context: Context, attempts: Long) {
        val stamp = SimpleDateFormat(
            "yyyy-MM-dd HH:mm:ss", Locale.US).format(Date())
        val reason = "home launcher disabled automatically: $attempts starts " +
            "in a row never showed a frame (last at $stamp)"
        HomeRole.release(context, null)
        prefs(context).edit()
            .putBoolean(TRIPPED, true)
            .putString(REASON, reason)
            .remove(ATTEMPTS)
            .remove(LAST_ATTEMPT_AT)
            .commit()
        CrashJournal.note(context, reason)
        Log.e(TAG, reason)
    }

    /** A Flutter frame is on screen: the boot is healthy, stand down. */
    fun noteHealthy(context: Context) {
        prefs(context).edit()
            .remove(ATTEMPTS)
            .remove(LAST_ATTEMPT_AT)
            .apply()
    }

    /** A deliberate (re-)enable is the fuse's reset. */
    fun clear(context: Context) {
        prefs(context).edit()
            .remove(ATTEMPTS)
            .remove(LAST_ATTEMPT_AT)
            .remove(TRIPPED)
            .remove(REASON)
            .remove(ROLE_DENIALS)
            .apply()
    }

    fun tripped(context: Context): Boolean =
        prefs(context).getBoolean(TRIPPED, false)

    fun reason(context: Context): String =
        prefs(context).getString(REASON, null) ?: ""

    /** How many times the role dialog came back unheld: Android quietly
     *  auto-denies it after about two refusals, so past that the UI offers
     *  the system's home settings instead. */
    fun roleDenials(context: Context): Long =
        prefs(context).getLong(ROLE_DENIALS, 0L)

    fun noteRoleResult(context: Context, held: Boolean) {
        val p = prefs(context)
        if (held) {
            p.edit().remove(ROLE_DENIALS).apply()
        } else {
            p.edit().putLong(ROLE_DENIALS, roleDenials(context) + 1).apply()
        }
    }
}
