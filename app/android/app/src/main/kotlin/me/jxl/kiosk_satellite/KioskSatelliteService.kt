package me.jxl.kiosk_satellite

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

/**
 * The one foreground service that keeps the app alive, whatever it is
 * doing.
 *
 * Android freezes cached processes whole: put the kiosk behind another app
 * or turn the panel off for long enough and the Home Assistant websocket,
 * the MQTT session, the ESPHome server, the wake-word engine and the remote
 * admin all stop on the same breath, with the process still nominally
 * there. OEM battery managers go one further and kill a backgrounded app
 * outright, which is how a kiosk reads "unavailable" in Home Assistant for
 * good a few hours into the night. A process with a running foreground
 * service is the exemption from both, and because the freeze is
 * process-wide, one exemption thaws everything at once.
 *
 * It used to be three services, each started by the feature that wanted
 * the exemption (background listening, the ESPHome server, the crash
 * guard) and each carrying its own notification, exit dance and lock. A
 * kiosk that used none of them, the common install, had no keep-alive at
 * all. This one runs unconditionally from the first resume, and the
 * features only contribute *reasons*: labels for the status page, and the
 * foreground-service types Android needs declared for what they do
 * (microphone for listening, camera for motion detection, connectedDevice
 * for BLE scanning). The base type is specialUse, for the connections the
 * kiosk holds open regardless.
 *
 * Two locks ride with it. The Wi-Fi lock for its whole lifetime (see
 * [WifiLockHolder]), and a partial wake lock while the panel is off, so the
 * CPU does not suspend between interrupts and the Dart timers behind the
 * keepalives fire on time; the latter is a setting (service.cpu_awake),
 * since it costs battery on an unplugged tablet.
 *
 * The reasons and the wake-lock preference are persisted here, not only
 * pushed from Dart: a sticky restart after a crash and the boot receiver
 * both bring the service up before Dart has run, and the types it declares
 * then must already be right.
 *
 * The notification is not optional: that is the deal Android offers for
 * the exemption, and it is the right deal for a device that may be
 * listening to a room. Its text says what the service is currently doing.
 */
class KioskSatelliteService : Service() {
    companion object {
        private const val TAG = "KioskSatelliteService"
        private const val CHANNEL_ID = "kiosk_satellite_service"
        private const val NOTIFICATION_ID = 0x4B53 // 'KS'
        private const val PREFS = "ks_service"
        private const val KEY_REASONS = "reasons"
        private const val KEY_CPU_AWAKE = "cpu_awake"
        private const val KEY_LAST_ERROR = "last_error"

        /// Reason ids, shared with the Dart ServiceManager, which computes
        /// them from the settings. [REASON_SESSIONS] is the floor: the
        /// service exists for it on a clean install with nothing else on.
        const val REASON_SESSIONS = "sessions"
        const val REASON_REMOTE = "remote"
        const val REASON_MQTT = "mqtt"
        const val REASON_ESPHOME = "esphome"
        const val REASON_BLUETOOTH = "bluetooth"
        const val REASON_LISTENING = "listening"
        const val REASON_CAMERA = "camera"
        const val REASON_KIOSK = "kiosk"
        const val REASON_LOCATION = "location"

        /// Live while the service is up, so the exit path knows whose
        /// onDestroy gets to end the process.
        @Volatile
        var isRunning = false
            private set

        /// Whether startForeground took: the exemption itself. False for a
        /// service that came up but was refused the foreground state, in
        /// which case it stops itself (see [refresh]).
        @Volatile
        var isForeground = false
            private set

        /// Set by the exit path just before stopping: onDestroy then ends
        /// the process. Killing from there, after the service has actually
        /// left its started state, is what START_STICKY cannot undo.
        /// Killing on a timer instead, while the stop is still in flight,
        /// let Android treat it as a crash and revive the whole process.
        @Volatile
        var exiting = false

        @Volatile
        private var instance: KioskSatelliteService? = null

        @Volatile
        private var startedAt = 0L

        @Volatile
        private var activeTypes = 0

        /**
         * Bring the service up, or leave it up. Safe from anywhere: a
         * background start Android refuses (12+, without the overlay grant
         * or the battery exemption) is logged and reported through
         * [status], not thrown.
         */
        fun ensureRunning(context: Context) {
            try {
                ContextCompat.startForegroundService(
                    context, Intent(context, KioskSatelliteService::class.java),
                )
            } catch (e: Exception) {
                Log.w(TAG, "start refused: $e")
                context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                    .putString(KEY_LAST_ERROR, "${e.javaClass.simpleName}: ${e.message}")
                    .apply()
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, KioskSatelliteService::class.java))
        }

        /**
         * The Dart side's push: which features want the process held up,
         * and whether to hold the CPU through screen-off. Persisted first
         * so a restart before the next push comes up right, then applied
         * to the live service, or the service is started if it is not up.
         */
        fun apply(context: Context, reasons: Set<String>, cpuAwake: Boolean) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putStringSet(KEY_REASONS, reasons + REASON_SESSIONS)
                .putBoolean(KEY_CPU_AWAKE, cpuAwake)
                .apply()
            val live = instance
            if (live != null) {
                live.mainHandler.post { live.refresh() }
            } else {
                ensureRunning(context)
            }
        }

        /** Everything the status page shows, in one read. */
        fun status(context: Context): Map<String, Any?> {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val live = instance
            return mapOf(
                "running" to isRunning,
                "foreground" to isForeground,
                "reasons" to (reasonsOf(prefs)).toList(),
                "types" to typeNames(activeTypes),
                "cpuAwake" to prefs.getBoolean(KEY_CPU_AWAKE, true),
                "cpuLockHeld" to (live?.cpuLock?.isHeld == true),
                "wifiLockHeld" to WifiLockHolder.isHeld,
                "screenInteractive" to pm.isInteractive,
                "uptimeMs" to if (isRunning) SystemClock.elapsedRealtime() - startedAt else null,
                "notificationsEnabled" to
                    NotificationManagerCompat.from(context).areNotificationsEnabled(),
                "error" to prefs.getString(KEY_LAST_ERROR, null),
            )
        }

        private fun reasonsOf(prefs: android.content.SharedPreferences): Set<String> =
            (prefs.getStringSet(KEY_REASONS, null) ?: emptySet()) + REASON_SESSIONS

        private fun typeNames(types: Int): List<String> {
            val names = mutableListOf<String>()
            if (Build.VERSION.SDK_INT >= 34 &&
                types and ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE != 0
            ) names.add("specialUse")
            if (Build.VERSION.SDK_INT >= 30 &&
                types and ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE != 0
            ) names.add("microphone")
            if (Build.VERSION.SDK_INT >= 30 &&
                types and ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA != 0
            ) names.add("camera")
            if (Build.VERSION.SDK_INT >= 29 &&
                types and ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE != 0
            ) names.add("connectedDevice")
            if (Build.VERSION.SDK_INT >= 29 &&
                types and ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION != 0
            ) names.add("location")
            return names
        }
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private var cpuLock: PowerManager.WakeLock? = null
    private var screenReceiver: BroadcastReceiver? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        isRunning = true
        startedAt = SystemClock.elapsedRealtime()
        createChannel()
        // The Wi-Fi hold for the service's lifetime: the service exists
        // precisely while the app must stay reachable without a screen.
        WifiLockHolder.acquire(this)
        registerScreenReceiver()
        refresh()
    }

    /**
     * Re-read the persisted reasons and put the service in the foreground
     * with the types they call for. Called on create and on every push
     * from Dart; startForeground may be repeated to change the types.
     *
     * The base type alone is retried when the full set is refused: on
     * Android 14 a microphone or camera type asked for from the background
     * is refused as a while-in-use violation, and that must not cost the
     * exemption itself. If even the base type is refused (a background
     * start without any of the grants that permit one), the service stops
     * itself at once: a started service that never reaches the foreground
     * is a crash on Android 8+ five seconds later, and the next resume of
     * the Activity starts it again from a context that is always allowed.
     */
    private fun refresh() {
        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val reasons = reasonsOf(prefs)
        val notification = buildNotification(reasons)
        val wanted = typesFor(reasons)
        val base = typesFor(setOf(REASON_SESSIONS))
        if (!startForegroundWith(notification, wanted, prefs) &&
            (wanted == base || !startForegroundWith(notification, base, prefs))
        ) {
            isForeground = false
            Log.w(TAG, "foreground refused; stopping until the next resume")
            stopSelf()
            return
        }
        syncCpuLock(prefs.getBoolean(KEY_CPU_AWAKE, true))
    }

    private fun startForegroundWith(
        notification: Notification,
        types: Int,
        prefs: android.content.SharedPreferences,
    ): Boolean = try {
        if (Build.VERSION.SDK_INT >= 29) {
            startForeground(NOTIFICATION_ID, notification, types)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        isForeground = true
        activeTypes = types
        prefs.edit().remove(KEY_LAST_ERROR).apply()
        true
    } catch (e: Exception) {
        Log.w(TAG, "startForeground(types=$types) failed: $e")
        prefs.edit()
            .putString(KEY_LAST_ERROR, "${e.javaClass.simpleName}: ${e.message}")
            .apply()
        false
    }

    /**
     * The foreground-service types the reasons call for, each gated on the
     * permission Android requires behind it: from Android 14, startForeground
     * throws for a typed service whose gating permission is missing, and the
     * microphone, camera and Bluetooth are all optional for this app.
     *
     * specialUse is the base on 14+, where every foreground service must
     * declare a type; older releases accept none.
     */
    private fun typesFor(reasons: Set<String>): Int {
        var types = 0
        if (Build.VERSION.SDK_INT >= 34) {
            types = types or ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
        }
        if (REASON_LISTENING in reasons && Build.VERSION.SDK_INT >= 30 &&
            granted(android.Manifest.permission.RECORD_AUDIO)
        ) {
            types = types or ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
        }
        // The camera bit is what lets motion detection keep the camera when
        // the panel powers off: without it, modern Android soft-denies the
        // camera app-op the moment the app leaves TOP (Tab S8 / Android 16
        // revokes ~5s after screen-off). Not absolute: One UI 11 suspends
        // the capture session seconds after screen-off despite this type,
        // silently, which CameraMotion's frame watchdog is what notices.
        if (REASON_CAMERA in reasons && Build.VERSION.SDK_INT >= 30 &&
            granted(android.Manifest.permission.CAMERA)
        ) {
            types = types or ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA
        }
        // connectedDevice keeps BLE scan callbacks flowing in the background
        // on Android 14+.
        if (REASON_BLUETOOTH in reasons && Build.VERSION.SDK_INT >= 29 &&
            (Build.VERSION.SDK_INT < 31 ||
                granted(android.Manifest.permission.BLUETOOTH_SCAN))
        ) {
            types = types or ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE
        }
        // Location keeps GPS fixes arriving off screen: from Android 10 a
        // backgrounded app only receives location through a service of
        // this type (or the background location grant, which the app
        // never asks for).
        if (REASON_LOCATION in reasons && Build.VERSION.SDK_INT >= 29 &&
            granted(android.Manifest.permission.ACCESS_FINE_LOCATION)
        ) {
            types = types or ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
        }
        return types
    }

    private fun granted(permission: String): Boolean =
        ContextCompat.checkSelfPermission(this, permission) ==
            PackageManager.PERMISSION_GRANTED

    /**
     * Hold the CPU while the panel is off and the setting asks for it. A
     * lit panel holds the CPU on its own, so the lock is released on
     * screen-on rather than held for nothing.
     */
    private fun syncCpuLock(wanted: Boolean) {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        val hold = wanted && !pm.isInteractive
        if (hold) {
            if (cpuLock?.isHeld == true) return
            try {
                cpuLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "ks:service")
                    .also {
                        it.setReferenceCounted(false)
                        it.acquire()
                    }
            } catch (e: Exception) {
                Log.w(TAG, "cpu wake lock failed: $e")
            }
        } else {
            cpuLock?.let { if (it.isHeld) it.release() }
            cpuLock = null
        }
    }

    private fun registerScreenReceiver() {
        if (screenReceiver != null) return
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                syncCpuLock(
                    getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                        .getBoolean(KEY_CPU_AWAKE, true),
                )
            }
        }
        screenReceiver = receiver
        registerReceiver(
            receiver,
            IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_SCREEN_OFF)
            },
        )
    }

    // A null intent is Android redelivering nothing after a crash: the
    // sticky-restart signature, and the moment the kiosk UI may need
    // bringing back too. The gates and the relaunch live in CrashSelfHeal.
    //
    // Sticky only while the foreground state took (issue #94 follow-up):
    // on a dozing Fire tablet, app standby killed each post-crash restart
    // of a background service at birth, and STICKY made Android retry that
    // doomed spin-up every ~32 seconds for 21 minutes, each cycle paying a
    // full engine start. A restart that reached the foreground is safe to
    // keep sticky; one that did not takes its single attempt, and the
    // heartbeat alarm is the retry.
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) {
            if (!exiting) CrashSelfHeal.maybeRelaunch(this)
            return if (isForeground) START_STICKY else START_NOT_STICKY
        }
        return START_STICKY
    }

    // "Close all" in recents (or a swipe-away) removes the task without
    // stopping this service, and it is the one escape the Activity side
    // cannot answer: by the time the Dart lifecycle watchdog would act,
    // the Activity may already be gone. Under lockdown or kiosk mode,
    // relaunch straight from here. A deliberate exit is not this (the exit
    // path raises [exiting] first, and leaving kiosk mode goes through the
    // gesture and PIN before the exit is reachable). The overlay grant is
    // the same gate every background relaunch in this app answers to;
    // without it Android discards the start anyway.
    override fun onTaskRemoved(rootIntent: Intent?) {
        val prefs =
            getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        val guarded =
            prefs.getBoolean("flutter.ks.lockdown.enabled", false) ||
                prefs.getBoolean("flutter.ks.kiosk.enabled", false)
        if (!exiting && guarded &&
            android.provider.Settings.canDrawOverlays(this)
        ) {
            packageManager.getLaunchIntentForPackage(packageName)?.let {
                it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                try {
                    startActivity(it)
                } catch (e: Exception) {
                    Log.w(TAG, "lockdown relaunch failed: $e")
                }
            }
        }
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        super.onDestroy()
        screenReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (_: Exception) {
            }
        }
        screenReceiver = null
        cpuLock?.let { if (it.isHeld) it.release() }
        cpuLock = null
        WifiLockHolder.release()
        instance = null
        isRunning = false
        isForeground = false
        activeTypes = 0
        if (exiting) {
            exiting = false
            android.os.Process.killProcess(android.os.Process.myPid())
        }
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        // The channels the three earlier services used: gone with them, so
        // an install that saw them does not keep two dead entries in its
        // notification settings.
        for (old in listOf("wake_word_listening", "bluetooth_proxy")) {
            try {
                manager.deleteNotificationChannel(old)
            } catch (_: Exception) {
            }
        }
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Kiosk Satellite Service",
            // LOW: no sound, no heads-up. It is a permanent status, not news.
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Shown while the Kiosk Satellite Service keeps the " +
                "app running with the screen off or behind another app."
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }

    /** What the service is doing, as the notification's one line. */
    private fun summary(reasons: Set<String>): String {
        val labels = mutableListOf<String>()
        if (REASON_LISTENING in reasons) labels.add("listening for a wake word")
        if (REASON_ESPHOME in reasons) labels.add("serving ESPHome")
        if (REASON_BLUETOOTH in reasons) labels.add("relaying Bluetooth devices")
        if (REASON_MQTT in reasons) labels.add("publishing over MQTT")
        if (REASON_CAMERA in reasons) labels.add("watching the camera")
        if (REASON_LOCATION in reasons) labels.add("reporting the location")
        if (REASON_REMOTE in reasons) labels.add("serving the remote admin")
        if (REASON_KIOSK in reasons) labels.add("guarding kiosk mode")
        labels.add("keeping Home Assistant connected")
        val text = labels.joinToString(", ")
        return text.replaceFirstChar { it.uppercase() } + "."
    }

    private fun buildNotification(reasons: Set<String>): Notification {
        val open = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            },
            PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Kiosk Satellite Service")
            .setContentText(summary(reasons))
            .setSmallIcon(R.drawable.ic_launcher_monochrome)
            .setContentIntent(open)
            .setOngoing(true)
            .setShowWhen(false)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }
}
