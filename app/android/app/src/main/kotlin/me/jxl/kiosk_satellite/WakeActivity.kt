package me.jxl.kiosk_satellite

import android.app.Activity
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.WindowManager

/**
 * A transparent, self-finishing Activity whose only job is to be launched:
 * the launch turns the display on.
 *
 * The screen-on command's first route is a wake lock flagged
 * ACQUIRE_CAUSES_WAKEUP (BackgroundBridge.wakeScreen). Some devices accept
 * that lock and leave the panel dark all the same, with nothing in the
 * app's own logs to show for it (issue #305, a Galaxy Tab S7+). Android's
 * other door is an Activity flagged turn-screen-on and show-when-locked:
 * the system lights the panel for such an Activity when it resumes or lays
 * out its window while the display sleeps. That is how alarm and
 * incoming-call screens wake a phone, so it is the route every vendor keeps
 * working. The flags are declared in the manifest as well as set here: the
 * manifest ones are on record before the system decides whether to resume
 * this Activity at all, and the window flags are all Android 8.0 and older
 * have.
 *
 * It sits over MainActivity in the kiosk's own task for as long as the
 * system needs to act on the launch, then finishes; noHistory in the
 * manifest guarantees it never lingers if that finish is missed.
 */
class WakeActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= 27) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
                        or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        }
    }

    override fun onResume() {
        super.onResume()
        // The wake is the system's reaction to this Activity resuming and
        // laying out its window, so it gets a frame in before going away;
        // a finish in the same pass can be ordered ahead of the layout.
        Handler(Looper.getMainLooper()).postDelayed({
            if (!isFinishing) finish()
        }, 400)
    }
}
