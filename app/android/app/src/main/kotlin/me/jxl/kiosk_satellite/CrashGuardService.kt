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
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) CrashSelfHeal.maybeRelaunch(this)
        return START_STICKY
    }
}
