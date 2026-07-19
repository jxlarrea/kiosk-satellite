package me.jxl.kiosk_satellite

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

/**
 * Keeps the app running while it is not on screen.
 *
 * This service does nothing. It holds no microphone, runs no loop, and its
 * onStartCommand is empty — its entire purpose is to exist, because a process
 * with a running foreground service is one Android will not freeze.
 *
 * Without it, backgrounding the app stops *everything*: measured on a Galaxy
 * Tab S8 (Android 16), the wake-word engine goes silent and the remote admin's
 * HTTP server stops answering on the same breath — the process is still there,
 * but every thread in it is suspended. It is not a microphone policy and there
 * is no way to opt into the parts you want: Android freezes cached processes
 * whole, so the mic, the WebView running Voice Satellite, its websocket to Home
 * Assistant and our own Dart all stop together.
 *
 * That also makes this cheap. One exemption thaws all of it at once, so the
 * card's session is still live when a wake word fires and can stream from the
 * pre-roll we captured while we were behind another app.
 *
 * [ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE] is the part that makes the
 * microphone real rather than silent, and from Android 14 it must be declared
 * both here and in the manifest, backed by FOREGROUND_SERVICE_MICROPHONE.
 *
 * The notification is not optional and cannot be hidden. That is the deal
 * Android offers for background microphone access, and it is the right deal:
 * a device listening to a room should say so.
 */
class WakeWordService : Service() {
    companion object {
        private const val CHANNEL_ID = "wake_word_listening"
        private const val NOTIFICATION_ID = 0x574B // 'WK'

        /// Live while the foreground service is up. Lets the exit path (see
        /// BackgroundBridge) tell a stop-then-die from a stop-and-stay.
        @Volatile
        var isRunning = false
            private set

        /// Set by the exit path just before stopping: onDestroy then ends the
        /// process. Killing from there — after the service has actually left its
        /// started state — is what START_STICKY cannot undo. Killing on a timer
        /// instead (while the stop is still in flight) let Android treat it as a
        /// crash of a started sticky service and revive the whole process.
        @Volatile
        var exiting = false

        fun start(context: Context) {
            ContextCompat.startForegroundService(
                context, Intent(context, WakeWordService::class.java),
            )
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, WakeWordService::class.java))
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        if (exiting) {
            exiting = false
            android.os.Process.killProcess(android.os.Process.myPid())
        }
    }

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        createChannel()
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
        } else {
            0
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, buildNotification(), type)
        } else {
            startForeground(NOTIFICATION_ID, buildNotification())
        }
    }

    // Nothing to do on each start: being alive is the whole job. START_STICKY so
    // a process death that Android recovers from brings the exemption back with
    // it, rather than leaving a satellite that is running but cannot hear.
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int = START_STICKY

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Wake word listening",
            // LOW: no sound, no heads-up. It is a permanent status, not news.
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Shown while Kiosk Satellite listens for a wake word " +
                "in the background."
            setShowBadge(false)
        }
        getSystemService(NotificationManager::class.java)
            ?.createNotificationChannel(channel)
    }

    private fun buildNotification(): Notification {
        val open = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            },
            PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Listening for a wake word")
            .setContentText("Tap to open Kiosk Satellite.")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setContentIntent(open)
            .setOngoing(true)
            .setShowWhen(false)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }
}
