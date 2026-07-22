package me.jxl.kiosk_satellite

import android.app.PendingIntent
import android.app.admin.DevicePolicyManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageInstaller
import android.os.Build
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

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

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context, intent: Intent) {
            if (intent.action != ACTION_STATUS) return
            when (val status = intent.getIntExtra(
                    PackageInstaller.EXTRA_STATUS, PackageInstaller.STATUS_FAILURE)) {
                PackageInstaller.STATUS_PENDING_USER_ACTION -> {
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
                    confirm.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    try {
                        ctx.startActivity(confirm)
                    } catch (e: Exception) {
                        Log.w(TAG, "could not show the install confirmation: $e")
                        channel.invokeMethod(
                            "installFailed",
                            "could not show the install confirmation: ${e.message}",
                        )
                    }
                }
                PackageInstaller.STATUS_SUCCESS ->
                    // A self-update never gets here: Android kills the process
                    // as it swaps the code. Reachable only in odd edge cases.
                    Log.i(TAG, "install reported success")
                else -> {
                    val message = intent.getStringExtra(
                        PackageInstaller.EXTRA_STATUS_MESSAGE) ?: "status $status"
                    // The person canceling Android's confirm screen is a normal
                    // outcome, not an error worth alarming anyone over.
                    val aborted = status == PackageInstaller.STATUS_FAILURE_ABORTED
                    Log.w(TAG, "install failed: $message")
                    channel.invokeMethod(
                        if (aborted) "installDeclined" else "installFailed", message)
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
                    try {
                        result.success(install(File(call.argument<String>("path")!!)))
                    } catch (e: Exception) {
                        result.error("install", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Whether this install can complete with no confirmation on screen. */
    private fun canInstallSilently(): Boolean {
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

    /** Returns 'silent' or 'confirm', matching what the session will do. */
    private fun install(apk: File): String {
        val installer = context.packageManager.packageInstaller
        val params = PackageInstaller.SessionParams(
            PackageInstaller.SessionParams.MODE_FULL_INSTALL)
        params.setAppPackageName(context.packageName)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            params.setRequireUserAction(
                PackageInstaller.SessionParams.USER_ACTION_NOT_REQUIRED)
        }
        val silent = canInstallSilently()
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
            session.commit(status.intentSender)
        }
        Log.i(TAG, "session $sessionId committed (${if (silent) "silent" else "confirm"})")
        return if (silent) "silent" else "confirm"
    }

    fun dispose() {
        try { context.unregisterReceiver(receiver) } catch (_: Exception) {}
        channel.setMethodCallHandler(null)
    }
}
