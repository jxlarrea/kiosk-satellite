package me.jxl.kiosk_satellite

import android.app.ActivityManager
import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Environment
import android.os.Process
import android.os.StatFs
import android.util.DisplayMetrics
import android.view.WindowManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.net.NetworkInterface

/**
 * The device facts Android will still tell an app, for the remote admin's
 * Device Info.
 *
 * Read on demand rather than cached: every one of these can change under us
 * (memory, storage, the WebView being updated), and a stale number presented as
 * current is worse than no number.
 *
 * A value we cannot get is reported as null and rendered as unavailable, with
 * the reason. That matters more than it sounds — several of these are things
 * Android has taken away over the years, and a plausible-looking placeholder
 * (the famous 02:00:00:00:00:00 MAC) is a lie that costs someone an afternoon.
 */
class DeviceDetails(
    private val context: Context,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, "kiosk_satellite/device_details")

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "read" -> result.success(read())
                else -> result.notImplemented()
            }
        }
    }

    fun dispose() = channel.setMethodCallHandler(null)

    private fun read(): Map<String, Any?> = mapOf(
        "brand" to Build.BRAND,
        "manufacturer" to Build.MANUFACTURER,
        "model" to Build.MODEL,
        "androidBuild" to Build.DISPLAY,
        "fingerprint" to Build.FINGERPRINT,
        "ram" to ram(),
        "storage" to storage(),
        "screen" to screen(),
        "webview" to webview(),
        "macAddresses" to macAddresses(),
        "foregroundApp" to foregroundApp(),
        "hasUsageAccess" to hasUsageAccess(),
    )

    private fun ram(): Map<String, Any> {
        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val info = ActivityManager.MemoryInfo()
        am.getMemoryInfo(info)
        return mapOf("free" to info.availMem, "total" to info.totalMem, "low" to info.lowMemory)
    }

    private fun storage(): Map<String, Any> {
        val stat = StatFs(Environment.getDataDirectory().path)
        return mapOf(
            "free" to stat.availableBytes,
            "total" to stat.totalBytes,
        )
    }

    private fun screen(): Map<String, Any> {
        val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val b = wm.currentWindowMetrics.bounds
            mapOf(
                "width" to b.width(),
                "height" to b.height(),
                "density" to context.resources.displayMetrics.density,
            )
        } else {
            @Suppress("DEPRECATION")
            val dm = DisplayMetrics().also { wm.defaultDisplay.getRealMetrics(it) }
            mapOf("width" to dm.widthPixels, "height" to dm.heightPixels, "density" to dm.density)
        }
    }

    /** The WebView implementation actually in use — the thing rendering the card. */
    private fun webview(): Map<String, Any?> {
        return try {
            val pkg = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                android.webkit.WebView.getCurrentWebViewPackage()
            } else {
                null
            }
            mapOf("package" to pkg?.packageName, "version" to pkg?.versionName)
        } catch (e: Exception) {
            mapOf("package" to null, "version" to null)
        }
    }

    /**
     * Hardware addresses, which on any modern Android means: none.
     *
     * Android 6 started returning a fixed 02:00:00:00:00:00 to apps, Android 11
     * closed the sysfs fallback, and on Android 16 `/sys/class/net/wlan0/address`
     * is unreadable even from an adb shell. Returning an empty list is the true
     * answer; returning the placeholder would look like a MAC and be a lie.
     */
    private fun macAddresses(): List<String> {
        return try {
            NetworkInterface.getNetworkInterfaces().toList()
                .mapNotNull { nic ->
                    val mac = nic.hardwareAddress ?: return@mapNotNull null
                    val text = mac.joinToString(":") { "%02X".format(it) }
                    // The one Android hands out instead of the real thing.
                    if (text == "02:00:00:00:00:00") null else "${nic.name}: $text"
                }
        } catch (e: Exception) {
            emptyList()
        }
    }

    /** Whether the user has given us "Usage access" in the OS settings. */
    private fun hasUsageAccess(): Boolean {
        return try {
            val ops = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = ops.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName,
            )
            mode == AppOpsManager.MODE_ALLOWED
        } catch (e: Exception) {
            false
        }
    }

    /**
     * What is on top right now. Null without "Usage access", which is a special
     * grant the user gives on an OS settings screen — there is no other way to
     * ask this question since Android 5.
     */
    private fun foregroundApp(): String? {
        if (!hasUsageAccess()) return null
        return try {
            val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val now = System.currentTimeMillis()
            // A short window: we want what is in front, not what was popular.
            val stats = usm.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY, now - 60_000, now,
            )
            stats?.maxByOrNull { it.lastTimeUsed }?.packageName
        } catch (e: Exception) {
            null
        }
    }
}
