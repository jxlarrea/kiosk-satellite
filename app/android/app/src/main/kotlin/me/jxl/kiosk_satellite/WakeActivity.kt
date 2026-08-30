package me.jxl.kiosk_satellite

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.WindowManager

/**
 * A transparent, self-finishing Activity whose only job is to be launched:
 * the launch turns the display on, and clears an unsecured lock screen.
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
 * The same Activity is the app's way past the keyguard (issue #372). The
 * screen-off command is device-admin lockNow, and lockNow arms the lock
 * screen whether or not one is set up: a device with no PIN still raises
 * the swipe-away keyguard. Whichever route then lights the panel lights it
 * on that lock screen, with the kiosk paused underneath, and the keyguard's
 * own timeout puts the panel back to sleep seconds later, which unattended
 * repeats forever. An Activity showing when locked may ask the keyguard to
 * go, and an unsecured one goes without anyone touching the screen, so
 * this one asks whenever it finds an unsecured keyguard up. A secured
 * keyguard (PIN, pattern, password) is never asked: the request would put
 * the credential prompt up instead, and the person's lock is theirs.
 *
 * It sits over MainActivity in the kiosk's own task for as long as the
 * system needs to act on the launch, then finishes; noHistory in the
 * manifest guarantees it never lingers if that finish is missed.
 */
class WakeActivity : Activity() {
    private var dismissing = false

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
        // Before 8.0 the dismissal is a window flag, honoured when the
        // window shows; the request API below is 8.0 and newer.
        if (Build.VERSION.SDK_INT < 26 && insecureKeyguardUp(this)) {
            dismissing = true
            @Suppress("DEPRECATION")
            window.addFlags(WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD)
        }
    }

    override fun onResume() {
        super.onResume()
        if (Build.VERSION.SDK_INT >= 26 && insecureKeyguardUp(this)) {
            dismissing = true
            val km = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            km.requestDismissKeyguard(this, object : KeyguardManager.KeyguardDismissCallback() {
                override fun onDismissSucceeded() = done("dismissed")
                override fun onDismissCancelled() = done("dismiss cancelled")
                override fun onDismissError() = done("dismiss failed")
            })
        }
        // The wake is the system's reaction to this Activity resuming and
        // laying out its window, so it gets a frame in before going away;
        // a finish in the same pass can be ordered ahead of the layout. A
        // dismissal in flight gets longer: the callback normally finishes
        // this Activity well before, and the timer is its backstop.
        Handler(Looper.getMainLooper()).postDelayed({
            if (!isFinishing) finish()
        }, if (dismissing) 3000 else 400)
    }

    private fun done(outcome: String) {
        android.util.Log.i("kiosk_satellite", "keyguard $outcome")
        if (!isFinishing) finish()
    }

    companion object {
        /**
         * Whether a lock screen is up that the app may clear on its own:
         * one with no credential behind it.
         */
        fun insecureKeyguardUp(context: Context): Boolean = try {
            val km = context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            km.isKeyguardLocked && !secure(km)
        } catch (_: Exception) {
            false
        }

        fun secure(km: KeyguardManager): Boolean =
            if (Build.VERSION.SDK_INT >= 23) km.isDeviceSecure else km.isKeyguardSecure
    }
}
