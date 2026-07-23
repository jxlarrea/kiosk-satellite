package me.jxl.kiosk_satellite

import android.app.DownloadManager
import android.app.admin.DevicePolicyManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
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
                // The File Manager's shared-storage root. "All files access"
                // is a settings screen, not a runtime dialog: request() opens
                // it for this app and the person toggles it there.
                "hasAllFilesAccess" -> result.success(
                    Build.VERSION.SDK_INT < Build.VERSION_CODES.R ||
                        android.os.Environment.isExternalStorageManager(),
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
                // Media volume (STREAM_MUSIC only): no permission involved.
                // The MQTT volume entity reads and writes through these.
                "getVolume" -> {
                    val am = context.getSystemService(Context.AUDIO_SERVICE)
                        as android.media.AudioManager
                    result.success(mapOf(
                        "level" to am.getStreamVolume(
                            android.media.AudioManager.STREAM_MUSIC),
                        "max" to am.getStreamMaxVolume(
                            android.media.AudioManager.STREAM_MUSIC),
                    ))
                }
                "setVolume" -> {
                    val am = context.getSystemService(Context.AUDIO_SERVICE)
                        as android.media.AudioManager
                    val max = am.getStreamMaxVolume(
                        android.media.AudioManager.STREAM_MUSIC)
                    val level = (call.argument<Number>("level"))?.toInt() ?: 0
                    am.setStreamVolume(
                        android.media.AudioManager.STREAM_MUSIC,
                        level.coerceIn(0, max),
                        0,
                    )
                    result.success(true)
                }
                // Kill and relaunch the whole process. The recovery of last
                // resort for a wedged renderer (see the Dart frame watchdog):
                // an Activity relaunch and a WebView rebuild both leave a
                // failed engine re-attach stuck on the splash screen, while a
                // clean process restart reliably comes back.
                "restartProcess" -> {
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
        if (WakeWordService.isRunning) {
            // The keep-alive foreground service is what fights a clean exit: kill
            // the process on a timer while it is still started and START_STICKY
            // revives everything. So stop it and let its onDestroy end the
            // process, by which point it has left its started state for good.
            WakeWordService.exiting = true
            WakeWordService.stop(context)
            // Safety net only: if onDestroy never lands, still leave. Long enough
            // that the clean path always wins the race.
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
            dpm.lockNow()
            true
        } else {
            false
        }
    } catch (_: Exception) {
        false
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
    }
}
