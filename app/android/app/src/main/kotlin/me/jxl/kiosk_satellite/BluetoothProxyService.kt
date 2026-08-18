package me.jxl.kiosk_satellite

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

/**
 * Foreground-service exemption for the Bluetooth proxy, same deal as
 * [WakeWordService]: the service itself does nothing, but a process with a
 * running foreground service is one Android will not freeze, and a frozen
 * process scans nothing and answers no Home Assistant connection. The proxy
 * runtime itself lives in btproxy/BluetoothProxyRuntime and is started by
 * the bridge; this service just keeps it schedulable when the kiosk app is
 * not on screen.
 *
 * The connectedDevice type is the exemption that keeps BLE scan callbacks
 * flowing in the background on Android 14+. It is conditional on the scan
 * permission actually being granted, because startForeground throws for a
 * typed service whose gating permission is missing (the same trap as the
 * camera type in WakeWordService).
 */
class BluetoothProxyService : Service() {
    companion object {
        private const val CHANNEL_ID = "bluetooth_proxy"
        private const val NOTIFICATION_ID = 0x4254 // 'BT'

        @Volatile
        var isRunning = false
            private set

        /**
         * Set by [BackgroundBridge.exitApp] before it stops the service: a
         * sticky restart racing a deliberate quit must not read as a crash
         * worth undoing, or "Exit application" relaunches the app it just
         * closed.
         */
        @Volatile
        var exiting = false

        fun start(context: Context) {
            ContextCompat.startForegroundService(
                context, Intent(context, BluetoothProxyService::class.java),
            )
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, BluetoothProxyService::class.java))
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        createChannel()
        WifiLockHolder.acquire(this)
        val scanGranted = Build.VERSION.SDK_INT < 31 ||
            ContextCompat.checkSelfPermission(this, android.Manifest.permission.BLUETOOTH_SCAN) ==
            PackageManager.PERMISSION_GRANTED
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && scanGranted) {
            startForeground(
                NOTIFICATION_ID, buildNotification(),
                ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE,
            )
        } else {
            startForeground(NOTIFICATION_ID, buildNotification())
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        WifiLockHolder.release()
        isRunning = false
    }

    // START_STICKY so a recovered process death brings the exemption back;
    // the bridge notices the runtime is gone and restarts it on the next
    // settings sync. A null intent is the sticky-restart signature, the same
    // moment the kiosk UI may need reviving.
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null && !exiting) CrashSelfHeal.maybeRelaunch(this)
        return START_STICKY
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Bluetooth proxy",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Shown while Kiosk Satellite relays Bluetooth " +
                "devices to Home Assistant."
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
            .setContentTitle("Bluetooth proxy active")
            .setContentText("Relaying Bluetooth devices to Home Assistant.")
            .setSmallIcon(android.R.drawable.stat_sys_data_bluetooth)
            .setContentIntent(open)
            .setOngoing(true)
            .setShowWhen(false)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }
}
