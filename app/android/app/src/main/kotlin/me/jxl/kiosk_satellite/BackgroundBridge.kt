package me.jxl.kiosk_satellite

import android.app.AlarmManager
import android.app.DownloadManager
import android.app.admin.DevicePolicyManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.database.ContentObserver
import android.hardware.display.DisplayManager
import android.net.ConnectivityManager
import android.net.Network
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.view.Display
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Dart's handle on the three OS grants that background listening needs, and on
 * bringing the app back to the front when it hears something.
 *
 * Uses the application context, not an Activity: the whole point of
 * [bringToFront] is to run when no Activity of ours is on screen (the Activity
 * may have been destroyed while the foreground service kept the process alive),
 * and an Activity reference would be stale exactly then. Starting an Activity
 * from a non-Activity context needs [Intent.FLAG_ACTIVITY_NEW_TASK].
 *
 * Each of the three grants is separate, each is refusable, and none can be
 * assumed — see the comments per method for what happens when one is missing.
 */
class BackgroundBridge(
    private val context: Context,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, "kiosk_satellite/background")

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    WakeWordService.start(context)
                    result.success(true)
                }
                "stop" -> {
                    WakeWordService.stop(context)
                    result.success(true)
                }
                // A real quit, not SystemNavigator.pop (which only finishes the
                // Activity and leaves the foreground service holding the process
                // alive in the background). Stop the service so START_STICKY will
                // not resurrect us, drop the task from recents, then end the
                // process. Runs from the application context so it also works
                // when triggered with no Activity on screen (the remote admin).
                "exit" -> {
                    exitApp()
                    result.success(true)
                }
                "isActivityResumed" -> result.success(ActivityState.resumed)
                "isActivityAttached" -> result.success(ActivityState.attached)
                // Open another app by package name (issue #44). The kiosk
                // stays running behind it; whatever brings the kiosk back —
                // the return gesture, a wake word, an automation — finds it
                // where it was.
                "launchApp" -> result.success(
                    launchApp(call.argument<String>("package")),
                )
                // Every launchable app on the device, for the app launcher's
                // whitelist pickers (issue #114). Visibility comes from the
                // manifest's LAUNCHER <queries> filter, no QUERY_ALL_PACKAGES.
                // Off the main thread: loading a label per app across a
                // hundred packages is a noticeable stall.
                "listApps" -> Thread {
                    val apps = listApps()
                    Handler(Looper.getMainLooper()).post { result.success(apps) }
                }.start()
                // One app's launcher icon as PNG bytes, for the launcher grid
                // and the on-device picker. Null when the package is gone.
                "appIcon" -> {
                    val pkg = call.argument<String>("package")
                    Thread {
                        val bytes = appIcon(pkg)
                        Handler(Looper.getMainLooper()).post { result.success(bytes) }
                    }.start()
                }
                // A deep link or custom URI for a gesture action (issue #99):
                // whatever app claims the scheme opens over the kiosk.
                "openUri" -> result.success(
                    openUri(call.argument<String>("uri")),
                )
                // The system settings app, for a gesture action (issue #99).
                "openSystemSettings" -> result.success(openSystemSettings())
                // The device's next alarm, as the clock app set it
                // (issue #42).
                "nextAlarm" -> result.success(nextAlarm())
                // Whether a default network exists RIGHT NOW, for seeding
                // the Dart side's picture of it: the network callback only
                // reports transitions, and a device that starts offline
                // gets no callback at all until one arrives.
                "networkUp" -> result.success(networkUp())
                // The panel's real state, for seeding the logical flag at
                // start: a device that boots (or reinstalls) with its screen
                // already off must not report it as on.
                "isScreenInteractive" -> result.success(
                    (context.getSystemService(Context.POWER_SERVICE)
                        as android.os.PowerManager).isInteractive,
                )
                // Whether the panel is lit, as opposed to whether the device
                // is awake. They disagree on anything with an always-on or
                // ambient display: lockNow sleeps the device and the ROM
                // keeps the panel showing a dim clock (issue #51).
                "displayState" -> result.success(displayState())
                "ambientDisplaySetting" -> result.success(ambientDisplaySetting())
                // The File Manager's shared-storage root. On Android 11+
                // this is "All files access", a settings screen: request()
                // opens it for this app and the person toggles it there.
                // Before 11 no such screen exists and the same door is the
                // legacy storage runtime pair, requested from the Dart side;
                // answering true unconditionally there reported a root the
                // OS then refused to list (issue #175).
                "hasAllFilesAccess" -> result.success(
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        android.os.Environment.isExternalStorageManager()
                    } else {
                        context.checkSelfPermission(
                            android.Manifest.permission.READ_EXTERNAL_STORAGE,
                        ) == android.content.pm.PackageManager.PERMISSION_GRANTED &&
                            context.checkSelfPermission(
                                android.Manifest.permission.WRITE_EXTERNAL_STORAGE,
                            ) == android.content.pm.PackageManager.PERMISSION_GRANTED
                    },
                )
                "requestAllFilesAccess" -> {
                    try {
                        context.startActivity(
                            Intent(
                                android.provider.Settings
                                    .ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                                android.net.Uri.parse("package:${context.packageName}"),
                            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("files", e.message, null)
                    }
                }
                // MASTER volume: no permission involved. The MQTT volume
                // entity reads and writes through these. VolumeController
                // decides whether that means STREAM_MUSIC or, on
                // fixed-volume devices (Chromebooks), the software master
                // every in-app player applies (issue #62). The media gain
                // rides along for the Dart-side players (the DLNA overlay),
                // media fader and fixed master included.
                "getVolume" -> {
                    val (level, max) = VolumeController.levelAndMax()
                    result.success(mapOf(
                        "level" to level,
                        "max" to max,
                        "fixed" to VolumeController.isFixed,
                        "gain" to VolumeController.mediaGain.toDouble(),
                    ))
                }
                "setVolume" -> {
                    VolumeController.setLevel(
                        (call.argument<Number>("level"))?.toInt() ?: 0,
                    )
                    result.success(true)
                }
                // The media and assistant faders, pushed from the Dart
                // settings at start and on every slider move (issue #79).
                "setVolumeMix" -> {
                    VolumeController.setMix(
                        (call.argument<Number>("media"))?.toInt() ?: 100,
                        (call.argument<Number>("assistant"))?.toInt() ?: 100,
                    )
                    result.success(true)
                }
                // Kill and relaunch the whole process. The recovery of last
                // resort for a wedged renderer (see the Dart frame watchdog):
                // an Activity relaunch and a WebView rebuild both leave a
                // failed engine re-attach stuck on the splash screen, while a
                // clean process restart reliably comes back.
                "restartProcess" -> {
                    // A restart wants the app BACK, so the self-heal throttle
                    // must not stand in its way. This matters most on the
                    // watchdog path: an Activity that attaches to an engine
                    // that settled headless (a heartbeat relaunch minutes
                    // after a crash) wedges on the splash, and only an attach
                    // during engine boot recovers - which is exactly what the
                    // crash guard's instant fresh-process relaunch provides,
                    // unless a self-heal within the last two minutes (the
                    // wedged relaunch itself) throttles it. On Android 12+
                    // the alarm below is deferred for minutes, so the guard
                    // is the relaunch that actually lands; throttled, the
                    // wedge repeats every heartbeat instead of ending here.
                    // commit(), not apply(): the process dies on the next
                    // line but one.
                    context.getSharedPreferences(
                        "FlutterSharedPreferences", Context.MODE_PRIVATE)
                        .edit().remove("flutter.ks.crash.last_self_heal").commit()
                    val alarm = context.getSystemService(Context.ALARM_SERVICE)
                        as android.app.AlarmManager
                    val launch = context.packageManager
                        .getLaunchIntentForPackage(context.packageName)!!
                        .addFlags(
                            Intent.FLAG_ACTIVITY_NEW_TASK or
                                Intent.FLAG_ACTIVITY_CLEAR_TASK,
                        )
                    val restart = android.app.PendingIntent.getActivity(
                        context, 7391, launch,
                        android.app.PendingIntent.FLAG_CANCEL_CURRENT or
                            android.app.PendingIntent.FLAG_IMMUTABLE,
                    )
                    alarm.set(
                        android.app.AlarmManager.RTC,
                        System.currentTimeMillis() + 800,
                        restart,
                    )
                    result.success(true)
                    android.os.Process.killProcess(android.os.Process.myPid())
                }
                // WebView downloads (an APK from GitHub, a camera clip):
                // handed to Android's DownloadManager. The kiosk hides the
                // status bar, so the system notification is invisible —
                // completion is pushed BACK to Dart (see the receiver below)
                // for in-app feedback, and openDownload launches the file.
                "download" -> {
                    try {
                        result.success(download(call))
                    } catch (e: Exception) {
                        result.error("download", e.message, null)
                    }
                }
                "openDownload" -> {
                    try {
                        result.success(openDownload(
                            (call.argument<Number>("id"))?.toLong() ?: -1L))
                    } catch (e: Exception) {
                        result.error("openDownload", e.message, null)
                    }
                }
                // Can we start our own Activity while another app is in front?
                // Android 10 forbids it, and "Display over other apps" is the
                // exemption that gets it back. Without it the wake word is heard
                // and nothing happens, which is worse than not listening.
                "canBringToFront" -> result.success(canDrawOverlays())
                "requestBringToFront" -> {
                    context.startActivity(
                        Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:${context.packageName}"),
                        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                    )
                    result.success(null)
                }
                "bringToFront" -> result.success(bringToFront())
                // "Screen on" from the admin or the screensaver: light a
                // genuinely sleeping panel. Brightness restore alone cannot.
                "wakeScreen" -> result.success(wakeScreen())
                // True panel off. Android only grants this to an active
                // device admin (lockNow); plain apps have no API for it.
                "screenOff" -> result.success(screenOff())
                "isScreenOffAvailable" -> result.success(isAdminActive())
                // The standard grant flow: Android's own "activate device
                // admin app?" screen, one tap to approve. Opened on the
                // device whenever "Screen off" is pressed without the grant.
                "requestScreenOffAdmin" -> {
                    context.startActivity(
                        Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                            putExtra(
                                DevicePolicyManager.EXTRA_DEVICE_ADMIN,
                                ComponentName(context, KioskAdminReceiver::class.java),
                            )
                            putExtra(
                                DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                                "Lets Kiosk Satellite turn the screen off on request.",
                            )
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        },
                    )
                    result.success(null)
                }
                // Samsung in particular will stop the service after a few hours
                // of "unused app" regardless of what the foreground-service rules
                // say. This is the only reliable way to be left alone.
                "isBatteryUnrestricted" -> result.success(isBatteryUnrestricted())
                "requestBatteryUnrestricted" -> {
                    requestBatteryUnrestricted()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    // Completion events for enqueued downloads, pushed to Dart so the kiosk
    // can show IN-APP feedback: with the status bar hidden by immersive mode,
    // the DownloadManager notification is never seen.
    private val downloadReceiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context?, intent: Intent?) {
            val id = intent?.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, -1L) ?: return
            if (id < 0) return
            val dm = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
            var status = -1
            var title: String? = null
            try {
                dm.query(DownloadManager.Query().setFilterById(id)).use { c ->
                    if (c.moveToFirst()) {
                        status = c.getInt(
                            c.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS),
                        )
                        title = c.getString(
                            c.getColumnIndexOrThrow(DownloadManager.COLUMN_TITLE),
                        )
                    }
                }
            } catch (_: Exception) {
            }
            channel.invokeMethod(
                "downloadComplete",
                mapOf(
                    "id" to id,
                    "success" to (status == DownloadManager.STATUS_SUCCESSFUL),
                    "filename" to title,
                ),
            )
        }
    }

    // Hardware volume changes (rocker, other apps), pushed to Dart so the
    // MQTT volume entity tracks reality instead of drifting until the next
    // poll. The extra filters to STREAM_MUSIC: ring/alarm changes are not
    // the media volume the entity models.
    private val volumeReceiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context?, intent: Intent?) {
            val stream = intent?.getIntExtra(
                "android.media.EXTRA_VOLUME_STREAM_TYPE", -1) ?: return
            if (stream != android.media.AudioManager.STREAM_MUSIC) return
            channel.invokeMethod("volumeChanged", null)
        }
    }

    // The display going to sleep or waking by any route other than this app:
    // the power button, the OS idle timeout, another app, a lock screen. Dart
    // keeps a logical on/off flag that only its own screenOn/screenOff moved,
    // so every mirror of it (the MQTT light, the remote admin) went stale the
    // moment someone touched the power button (issue #41).
    //
    // ACTION_SCREEN_ON/OFF report interactivity rather than literal panel
    // power, which is the honest signal here: a dozing panel is off to the
    // person looking at it, and doze-capable hardware keeps reporting its
    // display as powered while dozing.
    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context?, intent: Intent?) {
            val on = when (intent?.action) {
                Intent.ACTION_SCREEN_ON -> true
                Intent.ACTION_SCREEN_OFF -> false
                else -> return
            }
            channel.invokeMethod("screenStateChanged", mapOf("on" to on))
        }
    }

    // The always-on display preference, watched rather than read once: it is
    // changed in Android's own settings while this app is running, and the
    // Home Assistant screen entity withdraws or returns on the answer
    // (issue #51).
    private val dozeObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
        override fun onChange(selfChange: Boolean) {
            channel.invokeMethod(
                "ambientDisplayChanged",
                mapOf("setting" to ambientDisplaySetting()),
            )
        }
    }

    // The system tells us when the next alarm changes, so the sensor follows
    // an alarm set, moved or dismissed without polling for it.
    private val alarmReceiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context?, intent: Intent?) {
            channel.invokeMethod("nextAlarmChanged", nextAlarm())
        }
    }

    // Default-network transitions, pushed to Dart so a manager holding a
    // dead connection retries NOW instead of waiting out its own timers
    // (MQTT after an offline boot, a stale HA page, the glance socket).
    //
    // registerDefaultNetworkCallback replays onAvailable immediately when a
    // network already exists at registration. That replay is not an outage
    // ending, so it is flagged `initial` for the Dart side to drop — but
    // only when a network really was up at registration. When the app boots
    // offline, the first onAvailable IS the recovery, and swallowing it
    // would leave every consumer to its slow path (the Sendspin bridge's
    // blanket skip-the-first had exactly that bug).
    @Volatile private var expectInitialNetworkReplay = false

    /**
     * Whether a default network exists right now. Deliberately the same test
     * the callback registration uses (`activeNetwork`), so a seeded value and
     * a callback-driven one can never disagree. Validation is NOT required: a
     * LAN with no internet still reaches Home Assistant, and demanding
     * NET_CAPABILITY_VALIDATED would report a perfectly usable kiosk offline.
     * Fails open — an unanswerable question must not raise an outage.
     */
    private fun networkUp(): Boolean = try {
        (context.getSystemService(Context.CONNECTIVITY_SERVICE)
            as ConnectivityManager).activeNetwork != null
    } catch (e: Exception) {
        true
    }

    private val networkCallback = object : ConnectivityManager.NetworkCallback() {
        override fun onAvailable(network: Network) {
            val initial = expectInitialNetworkReplay
            expectInitialNetworkReplay = false
            // NetworkCallback fires on a binder thread; the channel must be
            // driven from the platform main thread.
            Handler(Looper.getMainLooper()).post {
                channel.invokeMethod(
                    "networkChanged",
                    mapOf("up" to true, "initial" to initial),
                )
            }
        }

        override fun onLost(network: Network) {
            expectInitialNetworkReplay = false
            Handler(Looper.getMainLooper()).post {
                channel.invokeMethod(
                    "networkChanged",
                    mapOf("up" to false, "initial" to false),
                )
            }
        }
    }

    // A second init block on purpose: initializers run in declaration order,
    // so downloadReceiver exists by the time this registers it. EXPORTED
    // because ACTION_DOWNLOAD_COMPLETE is not a protected system broadcast;
    // NOT_EXPORTED would silently never receive it on Android 14+.
    init {
        ContextCompat.registerReceiver(
            context,
            downloadReceiver,
            IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE),
            ContextCompat.RECEIVER_EXPORTED,
        )
        // VOLUME_CHANGED_ACTION is a system broadcast: NOT_EXPORTED
        // receivers still get those, and nothing else may spoof it.
        ContextCompat.registerReceiver(
            context,
            volumeReceiver,
            IntentFilter("android.media.VOLUME_CHANGED_ACTION"),
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
        // Software-gain changes on fixed-volume devices never hit the
        // system broadcast above (there is no stream change to announce),
        // so relay them to Dart the same way - one path regardless of who
        // moved the volume (MQTT, remote admin, SendSpin server).
        VolumeController.addListener {
            channel.invokeMethod("volumeChanged", null)
        }
        // ACTION_NEXT_ALARM_CLOCK_CHANGED is a protected system broadcast.
        ContextCompat.registerReceiver(
            context,
            alarmReceiver,
            IntentFilter(AlarmManager.ACTION_NEXT_ALARM_CLOCK_CHANGED),
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
        try {
            context.contentResolver.registerContentObserver(
                Settings.Secure.getUriFor("doze_always_on"),
                false,
                dozeObserver,
            )
        } catch (e: Exception) {
            android.util.Log.w("kiosk_satellite", "doze observer failed", e)
        }
        // Screen on/off are protected system broadcasts, and they are only
        // ever delivered to receivers registered in code like this one.
        ContextCompat.registerReceiver(
            context,
            screenReceiver,
            IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_SCREEN_OFF)
            },
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
        try {
            val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE)
                as ConnectivityManager
            // Read BEFORE registering: this is what tells the registration
            // replay apart from a genuine network arrival (offline boot).
            expectInitialNetworkReplay = cm.activeNetwork != null
            cm.registerDefaultNetworkCallback(networkCallback)
        } catch (e: Exception) {
            // Callback limit reached or no such service: network events
            // simply never fire and every consumer keeps its own timers.
            android.util.Log.w("kiosk_satellite", "network callback failed", e)
        }
    }

    // Enqueue a WebView download; returns the DownloadManager id so the
    // completion broadcast above can be matched back to this request.
    private fun download(call: MethodCall): Long {
        val url = call.argument<String>("url")
            ?: throw IllegalArgumentException("url required")
        val filename = call.argument<String>("filename").let {
            if (it.isNullOrBlank()) "download" else it
        }
        fun build(publicDir: Boolean): DownloadManager.Request =
            DownloadManager.Request(Uri.parse(url)).apply {
                setNotificationVisibility(
                    DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED,
                )
                setTitle(filename)
                if (publicDir) {
                    setDestinationInExternalPublicDir(
                        android.os.Environment.DIRECTORY_DOWNLOADS, filename,
                    )
                } else {
                    val dir = context.getExternalFilesDir(
                        android.os.Environment.DIRECTORY_DOWNLOADS,
                    ) ?: throw IllegalStateException("no external files dir")
                    setDestinationUri(Uri.fromFile(java.io.File(dir, filename)))
                }
                call.argument<String>("userAgent")?.takeIf { it.isNotBlank() }
                    ?.let { addRequestHeader("User-Agent", it) }
                // Authenticated hosts (the HA instance itself): forward the
                // WebView's cookies so the download is the logged-in user's.
                android.webkit.CookieManager.getInstance().getCookie(url)
                    ?.let { addRequestHeader("Cookie", it) }
                call.argument<String>("mimeType")?.takeIf { it.isNotBlank() }
                    ?.let { setMimeType(it) }
            }
        val dm = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        return try {
            dm.enqueue(build(publicDir = true))
        } catch (_: Exception) {
            // Pre-Android-10 without the storage grant cannot write the
            // public Downloads folder; the app's own external dir always can.
            dm.enqueue(build(publicDir = false))
        }
    }

    // Launch a completed download: the "Open" action on the in-app snackbar.
    // The DownloadManager hands out a content:// uri with the right grants,
    // so an APK goes straight to the package installer and anything else to
    // its default viewer.
    private fun openDownload(id: Long): Boolean {
        if (id < 0) return false
        val dm = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        val uri = dm.getUriForDownloadedFile(id) ?: return false
        val mime = dm.getMimeTypeForDownloadedFile(id)
        return try {
            context.startActivity(
                Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(uri, mime ?: "*/*")
                    addFlags(
                        Intent.FLAG_ACTIVITY_NEW_TASK
                                or Intent.FLAG_GRANT_READ_URI_PERMISSION,
                    )
                },
            )
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun exitApp() {
        // Finish every Activity of ours and clear the task from recents. Works
        // without an Activity reference, so it is valid from this app-context
        // bridge whether or not the kiosk is currently on screen.
        try {
            val am = context.getSystemService(Context.ACTIVITY_SERVICE)
                as android.app.ActivityManager
            for (task in am.appTasks) task.finishAndRemoveTask()
        } catch (_: Exception) {
        }
        val handler = android.os.Handler(android.os.Looper.getMainLooper())
        // A real quit also stands down the crash recovery hooks, or the
        // heartbeat alarm would count the kill as a crash worth undoing.
        CrashSelfHeal.disarm(context)
        if (WakeWordService.isRunning) {
            // The keep-alive foreground service is what fights a clean exit: kill
            // the process on a timer while it is still started and START_STICKY
            // revives everything. So stop it and let its onDestroy end the
            // process, by which point it has left its started state for good.
            // The guard service was stopped first (disarm above), so by the
            // time this onDestroy runs, both have left their started state.
            WakeWordService.exiting = true
            WakeWordService.stop(context)
            // Safety net only: if onDestroy never lands, still leave. Long enough
            // that the clean path always wins the race.
            handler.postDelayed({
                android.os.Process.killProcess(android.os.Process.myPid())
            }, 2000)
        } else if (CrashGuardService.isRunning) {
            // Same dance when only the crash guard holds a started state:
            // its onDestroy ends the process once the stop has landed.
            CrashGuardService.exiting = true
            CrashGuardService.stop(context)
            handler.postDelayed({
                android.os.Process.killProcess(android.os.Process.myPid())
            }, 2000)
        } else {
            // Nothing keeping the process alive; end it once the task-removal
            // above has drained off the main looper.
            handler.postDelayed({
                android.os.Process.killProcess(android.os.Process.myPid())
            }, 200)
        }
    }

    /// Bring another app to the front. Returns false when the package is
    /// not installed or exposes no launchable activity, so the caller can
    /// say so rather than appearing to do nothing.
    private fun launchApp(packageName: String?): Boolean {
        if (packageName.isNullOrBlank()) return false
        val intent = context.packageManager.getLaunchIntentForPackage(packageName)
            ?: return false
        return try {
            // NEW_TASK because this may be launched with no Activity of ours
            // on screen at all (an automation over MQTT, the remote admin).
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            android.util.Log.w("kiosk_satellite", "launchApp $packageName failed", e)
            false
        }
    }

    /// Every app with a launcher activity, as [{package, label}] sorted by
    /// label. The set a home screen shows — which is also exactly the set
    /// [launchApp] can start, so nothing offered here can fail to open.
    private fun listApps(): List<Map<String, String>> = try {
        val pm = context.packageManager
        val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        @Suppress("DEPRECATION")
        val activities = pm.queryIntentActivities(launcher, 0)
        activities
            .mapNotNull { info ->
                val pkg = info.activityInfo?.packageName ?: return@mapNotNull null
                if (pkg == context.packageName) return@mapNotNull null
                pkg to info.loadLabel(pm).toString()
            }
            // Apps with several launcher activities appear once, by their
            // first (usually main) entry, matching what launchApp opens.
            .distinctBy { it.first }
            .sortedBy { it.second.lowercase() }
            .map { mapOf("package" to it.first, "label" to it.second) }
    } catch (e: Exception) {
        android.util.Log.w("kiosk_satellite", "listApps failed", e)
        emptyList()
    }

    /// One app's launcher icon rendered to PNG bytes, or null when the
    /// package is missing. Rendered through a canvas rather than read as a
    /// resource because adaptive icons are layered drawables, not bitmaps.
    private fun appIcon(packageName: String?): ByteArray? {
        if (packageName.isNullOrBlank()) return null
        return try {
            val drawable = context.packageManager.getApplicationIcon(packageName)
            val size = 96
            val bitmap = android.graphics.Bitmap.createBitmap(
                size, size, android.graphics.Bitmap.Config.ARGB_8888,
            )
            val canvas = android.graphics.Canvas(bitmap)
            drawable.setBounds(0, 0, size, size)
            drawable.draw(canvas)
            val out = java.io.ByteArrayOutputStream()
            bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, out)
            bitmap.recycle()
            out.toByteArray()
        } catch (e: Exception) {
            android.util.Log.w("kiosk_satellite", "appIcon $packageName failed", e)
            null
        }
    }

    /// Open a URI with whatever app claims it (ACTION_VIEW). Returns false
    /// when nothing on the device can handle it, so the caller can say so.
    private fun openUri(uri: String?): Boolean {
        if (uri.isNullOrBlank()) return false
        return try {
            val intent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse(uri))
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            android.util.Log.w("kiosk_satellite", "openUri $uri failed", e)
            false
        }
    }

    /// Open the Android Settings app.
    private fun openSystemSettings(): Boolean = try {
        val intent = Intent(Settings.ACTION_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        true
    } catch (e: Exception) {
        android.util.Log.w("kiosk_satellite", "openSystemSettings failed", e)
        false
    }

    /// The next alarm clock set on the device, whichever app set it: this is
    /// the same value the status bar's alarm icon reflects. Null when none is
    /// set. The package is reported alongside so an automation can tell the
    /// clock app's alarm from some other app's.
    private fun nextAlarm(): Map<String, Any?>? {
        return try {
            val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val info = alarms.nextAlarmClock ?: return null
            mapOf(
                "triggerTime" to info.triggerTime,
                "package" to info.showIntent?.creatorPackage,
            )
        } catch (e: Exception) {
            android.util.Log.w("kiosk_satellite", "nextAlarm read failed", e)
            null
        }
    }

    private fun canDrawOverlays(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(context)

    private fun isAdminActive(): Boolean = try {
        val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        dpm.isAdminActive(ComponentName(context, KioskAdminReceiver::class.java))
    } catch (_: Exception) {
        false
    }

    private fun screenOff(): Boolean = try {
        val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        if (dpm.isAdminActive(ComponentName(context, KioskAdminReceiver::class.java))) {
            // Before the lock, not after: the SCREEN_OFF broadcast it causes
            // is what kiosk mode's power-button defence listens for, and it
            // must recognise this one as ours and leave the panel off.
            KioskLock.noteAppScreenOff()
            dpm.lockNow()
            true
        } else {
            false
        }
    } catch (_: Exception) {
        false
    }

    /**
     * The default display's power state: [Display.STATE_OFF] when the panel
     * is genuinely dark, DOZE or ON when something is still lighting it.
     */
    private fun displayState(): Int = try {
        val displays = context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
        displays.getDisplay(Display.DEFAULT_DISPLAY)?.state ?: Display.STATE_UNKNOWN
    } catch (e: Exception) {
        Display.STATE_UNKNOWN
    }

    /**
     * The always-on display preference: 1 on, 0 off, -1 never set.
     *
     * -1 is the interesting case and the reason [displayState] exists: it
     * means the ROM's own default applies, which is not readable and is on
     * for some (the Echo Show 5 among them).
     */
    private fun ambientDisplaySetting(): Int = try {
        Settings.Secure.getInt(context.contentResolver, "doze_always_on", -1)
    } catch (e: Exception) {
        -1
    }

    private fun wakeScreen(): Boolean {
        return try {
            val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            if (!pm.isInteractive) {
                @Suppress("DEPRECATION")
                pm.newWakeLock(
                    PowerManager.SCREEN_BRIGHT_WAKE_LOCK
                            or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                    "ks:screenWake",
                ).acquire(5000)
                true
            } else {
                false
            }
        } catch (_: Exception) {
            false
        }
    }

    private fun bringToFront(): Boolean {
        // A sleeping panel first: starting the Activity does not wake the
        // display, so a wake word heard with the screen off would answer
        // into darkness. Same wake-lock pattern as the kiosk's power-button
        // re-wake — and deliberately before the overlay-grant check, since
        // waking the screen needs no grant at all (the common case is the
        // kiosk still frontmost, just dark).
        wakeScreen()
        if (!canDrawOverlays()) return false
        return try {
            // Resume the existing task exactly the way tapping the launcher icon
            // does. The running Activity (singleTop) and its live WebView are
            // reused — the card session survives.
            //
            // The previous explicit-component intent with NEW_TASK + the empty
            // taskAffinity could instead spawn a *second* MainActivity instance
            // in a separate task; its fresh WebView reloaded the page and the
            // original session was lost. The launcher intent targets the app's
            // one task deterministically and never does that.
            val launch = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
                ?: return false
            launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(launch)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun isBatteryUnrestricted(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val power = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        return power.isIgnoringBatteryOptimizations(context.packageName)
    }

    @Suppress("BatteryLife") // The point of the app is to listen continuously.
    private fun requestBatteryUnrestricted() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        context.startActivity(
            Intent(
                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                Uri.parse("package:${context.packageName}"),
            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        )
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        try {
            context.unregisterReceiver(downloadReceiver)
        } catch (_: Exception) {
        }
        try {
            context.unregisterReceiver(volumeReceiver)
        } catch (_: Exception) {
        }
        try {
            context.unregisterReceiver(screenReceiver)
        } catch (_: Exception) {
        }
        try {
            context.unregisterReceiver(alarmReceiver)
        } catch (_: Exception) {
        }
        try {
            context.contentResolver.unregisterContentObserver(dozeObserver)
        } catch (_: Exception) {
        }
        try {
            (context.getSystemService(Context.CONNECTIVITY_SERVICE)
                as ConnectivityManager).unregisterNetworkCallback(networkCallback)
        } catch (_: Exception) {
        }
    }
}
