package me.jxl.kiosk_satellite

import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.IBinder

/**
 * A do-nothing START_STICKY service whose restart is the crash self-heal's
 * hook (see [CrashSelfHeal]).
 *
 * Not a foreground service, on purpose. [WakeWordService] pays for its
 * immortality with a permanent notification because it holds a microphone;
 * this service holds nothing and needs nothing while the app is alive, so it
 * costs nothing to keep started. Its one moment of usefulness is after the
 * process dies: Android re-creates a sticky service (with a null intent, the
 * restart signature), and that restart runs early enough to put the kiosk
 * back before anyone notices the launcher. Being a background service does
 * make the restart promise softer than a foreground one, which is why the
 * heartbeat alarm in [CrashSelfHeal] backs it up.
 *
 * The exit dance is inherited from [WakeWordService]: a deliberate quit must
 * kill the process only after this service has left its started state, or
 * START_STICKY treats the kill as a crash and resurrects everything the exit
 * just tore down.
 */
class CrashGuardService : Service() {
    companion object {
        /// Live while the service is up, so the exit path knows whose
        /// onDestroy gets to end the process.
        @Volatile
        var isRunning = false
            private set

        /// Set by the exit path just before stopping: onDestroy then ends
        /// the process, at which point the service has genuinely stopped
        /// and START_STICKY has nothing left to revive.
        @Volatile
        var exiting = false

        fun start(context: Context) {
            try {
                context.startService(
                    Intent(context, CrashGuardService::class.java))
            } catch (e: Exception) {
                // A background start (should not happen; we arm from
                // onResume) or an OEM quirk. The heartbeat still covers us.
                android.util.Log.w("CrashGuardService", "start failed: $e")
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, CrashGuardService::class.java))
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        isRunning = true
    }

    // "Close all" in recents (or a swipe-away) removes the task without
    // stopping this service, and it is the one escape the Activity side
    // cannot answer: by the time the Dart lifecycle watchdog would act,
    // the Activity may already be gone. Under lockdown, relaunch straight
    // from here — this service runs whenever the app is alive, background
    // listening on or off. The overlay grant is the same gate every
    // background relaunch in this app answers to; without it Android
    // discards the start anyway.
    override fun onTaskRemoved(rootIntent: Intent?) {
        if (!exiting &&
            getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
                .getBoolean("flutter.ks.lockdown.enabled", false) &&
            android.provider.Settings.canDrawOverlays(this)
        ) {
            packageManager.getLaunchIntentForPackage(packageName)?.let {
                it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                try {
                    startActivity(it)
                } catch (e: Exception) {
                    android.util.Log.w("CrashGuardService",
                        "lockdown relaunch failed: $e")
                }
            }
        }
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        if (exiting) {
            exiting = false
            android.os.Process.killProcess(android.os.Process.myPid())
        }
    }

    // A null intent is Android redelivering nothing after a crash: the
    // sticky-restart signature, and the only event this service exists for.
    //
    // The restart path returns START_NOT_STICKY, and that asymmetry is
    // deliberate (issue #94 follow-up): on a dozing Fire tablet, app standby
    // kills each post-crash restart at birth ("Stopping service due to app
    // idle") before the relaunch can land, and STICKY made Android retry
    // that doomed spin-up every ~32 seconds for 21 minutes, each cycle
    // paying a full engine start - a RAM sawtooth that thrashed the whole
    // device. One restart attempt is taken here; if the OS strangles it,
    // the heartbeat alarm (delivered even in doze, at the next maintenance
    // window) is the retry. A successful relaunch re-arms stickiness via
    // the Activity's onResume.
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) {
            CrashSelfHeal.maybeRelaunch(this)
            return START_NOT_STICKY
        }
        return START_STICKY
    }
}
