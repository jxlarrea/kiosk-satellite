package me.jxl.kiosk_satellite

import android.app.PendingIntent
import android.app.admin.DevicePolicyManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageInfo
import android.content.pm.PackageInstaller
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.StatFs
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import me.jxl.kiosk_satellite.btproxy.BluetoothProxyRuntime
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Installs a downloaded update through a [PackageInstaller] session instead of
 * the ACTION_VIEW handoff to the system installer app.
 *
 * The session is what makes hands-free fleet updates possible at all: on
 * Android 12+ a session may skip the user confirmation when the committing app
 * is the installer of record of the package being updated. The first update
 * installed through here still shows Android's confirmation screen (that
 * install is also what makes this app its own installer of record); every
 * update after that installs silently, which is what the Home Assistant
 * update entity needs on a wall tablet nobody is standing next to. A device
 * provisioned with this app as device owner installs silently on any version.
 * Otherwise an available ADB helper installs with shell privileges.
 *
 * When confirmation is still required, the session reports
 * STATUS_PENDING_USER_ACTION with an Intent for Android's confirm screen,
 * which is launched here (the draw-over-apps grant covers launching it from
 * the background). After a successful self-update Android kills the process;
 * [UpdateRelaunchReceiver] brings the kiosk back.
 */
class ApkInstaller(private val context: Context, messenger: BinaryMessenger) {
    companion object {
        private const val TAG = "ApkInstaller"
        private const val ACTION_STATUS = "me.jxl.kiosk_satellite.INSTALL_STATUS"
    }

    private val channel = MethodChannel(messenger, "kiosk_satellite/installer")
    private val helper = UpdateHelperClient(context)
    private val shizuku = ShizukuUpdateClient(context)
    private val worker = Executors.newFixedThreadPool(2) { task -> Thread(task, "ks-apk-installer") }
    private val main = Handler(Looper.getMainLooper())
    private val installing = AtomicBoolean(false)

    /**
     * Sessions committed to install with no confirmation, until Android
     * reports their outcome. An abort of one of these was never a person
     * on the confirm screen: no screen was shown. Xiaomi's MIUI and HyperOS
     * abort these installs within seconds even though stock Android allows
     * them (issue #768), and Dart then retries through the confirm screen.
     */
    private val silentSessions = ConcurrentHashMap.newKeySet<Int>()

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context, intent: Intent) {
            if (intent.action != ACTION_STATUS) return
            val sessionId = intent.getIntExtra(PackageInstaller.EXTRA_SESSION_ID, -1)
            when (val status = intent.getIntExtra(
                    PackageInstaller.EXTRA_STATUS, PackageInstaller.STATUS_FAILURE)) {
                PackageInstaller.STATUS_PENDING_USER_ACTION -> {
                    // Android wants a confirmation after all, so an abort
                    // from here on is the person declining it.
                    silentSessions.remove(sessionId)
                    val confirm: Intent? =
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            intent.getParcelableExtra(Intent.EXTRA_INTENT, Intent::class.java)
                        } else {
                            @Suppress("DEPRECATION")
                            intent.getParcelableExtra(Intent.EXTRA_INTENT)
                        }
                    if (confirm == null) {
                        Log.w(TAG, "pending user action without an intent")
                        return
                    }
                    // A confirmed update kills us without ordinary teardown.
                    // Stop BLE before the screen appears so even a quick tap
                    // cannot strand this process's scanner in a vendor stack.
                    pauseScannerForPackageReplacement()
                    confirm.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    try {
                        ctx.startActivity(confirm)
                    } catch (e: Exception) {
                        resumeScannerAfterPackageReplacementFailure()
                        Log.w(TAG, "could not show the install confirmation: $e")
                        channel.invokeMethod(
                            "installFailed",
                            "could not show the install confirmation: ${e.message}",
                        )
                    }
                }
                PackageInstaller.STATUS_SUCCESS -> {
                    // A self-update never gets here: Android kills the process
                    // as it swaps the code. Reachable only in odd edge cases.
                    silentSessions.remove(sessionId)
                    Log.i(TAG, "install reported success")
                }
                else -> {
                    val message = intent.getStringExtra(
                        PackageInstaller.EXTRA_STATUS_MESSAGE) ?: "status $status"
                    // The person canceling Android's confirm screen is a normal
                    // outcome, not an error worth alarming anyone over. A
                    // package verifier rejecting the APK arrives as ABORTED
                    // too (a Meta Portal ships one that refuses every
                    // certificate but Meta's own), and that one is an error
                    // with a fix, so it is told apart by its message.
                    val verifier = message.contains("VERIFICATION", ignoreCase = true)
                    val aborted =
                        status == PackageInstaller.STATUS_FAILURE_ABORTED && !verifier
                    val silent = silentSessions.remove(sessionId)
                    resumeScannerAfterPackageReplacementFailure()
                    Log.w(TAG, "install failed: $message")
                    channel.invokeMethod(
                        when {
                            aborted && silent -> "silentInstallRefused"
                            aborted -> "installDeclined"
                            else -> "installFailed"
                        },
                        if (verifier) {
                            "a package verifier on this device rejected the " +
                                "update ($message); on a Meta Portal turn it off " +
                                "over adb, see the Meta Portal doc"
                        } else {
                            message
                        },
                    )
                }
            }
        }
    }

    init {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(
                receiver, IntentFilter(ACTION_STATUS), Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            context.registerReceiver(receiver, IntentFilter(ACTION_STATUS))
        }
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "installApk" -> {
                    if (!installing.compareAndSet(false, true)) {
                        result.error("install", "An update is already being installed", null)
                    } else {
                        work(result) {
                            try {
                                install(File(requireNotNull(call.argument<String>("path"))),
                                    call.argument<Boolean>("useSystemInstaller") == true,
                                    call.argument<Boolean>("useShizuku") == true)
                            } finally {
                                installing.set(false)
                            }
                        }
                    }
                }
                // Asked before committing, so Dart can stand the kiosk down
                // first when Android's confirm screen is coming: lock task
                // pinning blocks that screen outright (issue #170), and by
                // the time the session reports PENDING_USER_ACTION the
                // launch has already been refused once.
                // Asked for the same reason: the reclaim and the pin would
                // fight the move to the other launcher.
                "stepsAsideForInstall" -> work(result) { UpdateHomeHandoff.wanted(context) }
                "needsConfirmation" -> work(result) {
                    if (call.argument<Boolean>("useShizuku") == true) { shizuku.requireReady(); false }
                    else !canInstallNativelySilently() && helper.status() != "ready"
                }
                "getInstallerStatus" -> work(result) {
                    mapOf(
                        "nativeSilent" to canInstallNativelySilently(),
                        "shizukuReady" to shizuku.ready(),
                        "helper" to helper.status(),
                        "startCommand" to UpdateHelperClient.START_COMMAND,
                    )
                }
                "stopUpdateHelper" -> work(result) { helper.stop() }
                // An uploaded APK (issue #566) is read before it is offered
                // for install: package, version name and version code, or
                // null when Android cannot parse the file as an APK.
                "inspectApk" -> work(result) {
                    inspect(File(requireNotNull(call.argument<String>("path"))))
                }
                // Free bytes on the cache volume, for the upload's space check.
                "freeSpace" -> work(result) { StatFs(context.cacheDir.path).availableBytes }
                else -> result.notImplemented()
            }
        }
    }

    private fun inspect(apk: File): Map<String, Any>? {
        val info = context.packageManager.getPackageArchiveInfo(apk.path, 0) ?: return null
        val code = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) info.longVersionCode
            else @Suppress("DEPRECATION") info.versionCode.toLong()
        return mapOf(
            "packageName" to info.packageName,
            "versionName" to (info.versionName ?: ""),
            "versionCode" to code,
        )
    }

    /** Whether this install can complete with no confirmation on screen. */
    private fun canInstallNativelySilently(): Boolean {
        val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE)
            as DevicePolicyManager
        if (dpm.isDeviceOwnerApp(context.packageName)) return true
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return false
        // Installer of record of ourselves: true from the first session-based
        // update onward. The system installer holds the role before that.
        return try {
            val source = context.packageManager
                .getInstallSourceInfo(context.packageName)
            source.installingPackageName == context.packageName
        } catch (e: Exception) {
            false
        }
    }

    private fun work(result: MethodChannel.Result, block: () -> Any?) {
        worker.execute {
            try {
                val value = block()
                main.post { result.success(value) }
            } catch (e: Exception) {
                main.post { result.error("install", e.message, null) }
            }
        }
    }

    /** A fallback asks Dart to release kiosk protections before creating a session. */
    private fun install(apk: File, useSystemInstaller: Boolean, useShizuku: Boolean): String {
        try {
            if (useShizuku) {
                Log.i(TAG, "installing through Shizuku")
                return shizuku.install(apk, ::prepareForSilentReplacement)
            }
            val nativeSilent = canInstallNativelySilently()
            if (!nativeSilent && !useSystemInstaller) {
                Log.i(TAG, "trying the update helper")
                if (helper.install(apk, ::prepareForSilentReplacement)) return "silent"
                Log.i(TAG, "update helper unavailable before commit; requesting system installer fallback")
                return "fallback"
            }
            Log.i(TAG, "using Android PackageInstaller (nativeSilent=$nativeSilent)")
            val installer = context.packageManager.packageInstaller
            val params = PackageInstaller.SessionParams(
                PackageInstaller.SessionParams.MODE_FULL_INSTALL)
            params.setAppPackageName(context.packageName)
            // Session params default to INSTALL_LOCATION_INTERNAL_ONLY, and on a
            // tablet whose SD card is formatted as internal (adopted storage)
            // with this app living on it, that makes Android refuse the update
            // outright: "Cannot automatically move <package> from <volume> to
            // internal storage" (issue #424). AUTO keeps an update on whichever
            // volume the app already occupies, which is what the system installer
            // does too.
            params.setInstallLocation(PackageInfo.INSTALL_LOCATION_AUTO)
            params.setSize(apk.length())
            // useSystemInstaller on a device that could install silently is
            // the retry after the silent install was refused, so it asks for
            // the confirm screen outright.
            val silent = nativeSilent && !useSystemInstaller
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                params.setRequireUserAction(
                    if (silent) PackageInstaller.SessionParams.USER_ACTION_NOT_REQUIRED
                    else PackageInstaller.SessionParams.USER_ACTION_REQUIRED)
            }
            val sessionId = installer.createSession(params)
            installer.openSession(sessionId).use { session ->
                session.openWrite("app.apk", 0, apk.length()).use { out ->
                    apk.inputStream().use { it.copyTo(out) }
                    session.fsync(out)
                }
                val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                val status = PendingIntent.getBroadcast(
                    context, sessionId,
                    Intent(ACTION_STATUS).setPackage(context.packageName), flags)
                // Recorded before the commit: the outcome can arrive first.
                if (silent) silentSessions.add(sessionId)
                try {
                    if (silent) prepareForSilentReplacement()
                    session.commit(status.intentSender)
                } catch (e: Exception) {
                    silentSessions.remove(sessionId)
                    throw e
                }
            }
            Log.i(TAG, "session $sessionId committed (${if (silent) "silent" else "confirm"})")
            return if (silent) "silent" else "confirm"
        } catch (e: Exception) {
            resumeScannerAfterPackageReplacementFailure()
            throw e
        }
    }

    /** A confirm screen needs no handoff: it stays in front of the kiosk
     *  until the install is over. */
    private fun prepareForSilentReplacement() {
        pauseScannerForPackageReplacement()
        UpdateHomeHandoff.stepAside(context)
    }

    private fun pauseScannerForPackageReplacement() {
        if (!BluetoothProxyRuntime.pauseScannerForPackageReplacement()) {
            Log.w(TAG, "BLE scanner did not stop before the install commit")
        }
    }

    private fun resumeScannerAfterPackageReplacementFailure() {
        BluetoothProxyRuntime.resumeScannerAfterPackageReplacementFailure()
        UpdateHomeHandoff.comeBack(context)
    }

    fun dispose() {
        try { context.unregisterReceiver(receiver) } catch (_: Exception) {}
        channel.setMethodCallHandler(null)
        worker.shutdownNow()
    }
}
