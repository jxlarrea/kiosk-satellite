package me.jxl.kiosk_satellite

import android.accessibilityservice.AccessibilityService
import android.os.Build
import android.view.accessibility.AccessibilityEvent

/**
 * The System UI guard: an accessibility service that closes the two system
 * surfaces the kiosk cannot otherwise reach, the moment they open.
 *
 * Everything else the kiosk defends is an app-level surface: back is
 * swallowed in dispatchKeyEvent, touches die on the shield, a lost
 * foreground is reclaimed. The notification shade and the recents screen
 * are SystemUI's own windows — an app can watch them appear but cannot
 * touch them, and the pre-12 tricks for slamming the shade shut
 * (StatusBarManager.collapsePanels reflection, ACTION_CLOSE_SYSTEM_DIALOGS)
 * are blocked on modern Android. What Android offers instead, to
 * accessibility services only, is [GLOBAL_ACTION_DISMISS_NOTIFICATION_SHADE]
 * (API 31). This is the same route the commercial kiosk vendors take, and
 * unlike screen pinning it shows nobody a consent dialog: the owner enables
 * the service once in Android's Accessibility settings and it stays.
 *
 * The service reads no window content ([canRetrieveWindowContent] is off in
 * its XML config) and reacts only to window-state changes: SystemUI showing
 * a window while the shade guard is armed, or a recents surface appearing
 * while the recents guard is.
 *
 * Arming rides the same flag push as every other kiosk protection
 * (KioskLock forwards it from the Dart bundle into the statics below — the
 * service runs in the app's process, so statics are enough). At boot the
 * system binds this service before any Activity exists; [onServiceConnected]
 * seeds from the settings mirror so a kiosk that starts on boot is guarded
 * from the first frame.
 */
class KioskAccessibilityService : AccessibilityService() {
    companion object {
        /// Close the notification shade / quick settings whenever they open.
        @Volatile
        var guardShade = false

        /// Back straight out of the recents screen whenever it opens.
        @Volatile
        var guardRecents = false

        /// Bound and live. The system binds enabled accessibility services
        /// for as long as the process runs, so this doubles as "the owner
        /// has enabled the guard in Accessibility settings".
        @Volatile
        var running = false
            private set
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        running = true
        if (!guardShade && !guardRecents) {
            val prefs =
                getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
            val lockdown =
                prefs.getBoolean("flutter.ks.lockdown.enabled", false)
            val kioskShade =
                prefs.getBoolean("flutter.ks.kiosk.enabled", false) &&
                    prefs.getBoolean(
                        "flutter.ks.kiosk.disable_status_bar", false)
            guardShade = lockdown || kioskShade
            guardRecents = lockdown
        }
    }

    override fun onUnbind(intent: android.content.Intent?): Boolean {
        running = false
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        running = false
        super.onDestroy()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            return
        }
        val pkg = event.packageName?.toString() ?: return
        val cls = event.className?.toString() ?: ""
        // Any SystemUI window while armed: the dismiss is a no-op unless
        // the shade or quick settings are actually open, so firing it on
        // a volume panel or a transient bar costs nothing.
        if (guardShade && pkg == "com.android.systemui") {
            if (Build.VERSION.SDK_INT >= 31) {
                performGlobalAction(GLOBAL_ACTION_DISMISS_NOTIFICATION_SHADE)
            } else {
                // Best effort below 31: back collapses an open shade.
                performGlobalAction(GLOBAL_ACTION_BACK)
            }
        }
        // Recents is quickstep's RecentsActivity on stock, Samsung and most
        // OEM launchers alike. Back returns to the task below it: us.
        if (guardRecents && cls.contains("RecentsActivity")) {
            performGlobalAction(GLOBAL_ACTION_BACK)
        }
    }

    override fun onInterrupt() {}
}
