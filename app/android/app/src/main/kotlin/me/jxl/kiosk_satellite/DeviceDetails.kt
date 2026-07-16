package me.jxl.kiosk_satellite

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.util.DisplayMetrics
import android.view.WindowManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * The device facts Android will still tell an app, for the remote admin's
 * Device Info.
 *
 * Read on demand rather than cached: every one of these can change under us
 * (memory, storage, the WebView being updated), and a stale number presented as
 * current is worse than no number.
 *
 * Deliberately only things obtainable without a further grant. MAC addresses
 * and the foreground app used to be here and are gone: Android returns a fixed
 * 02:00:00:00:00:00 for the first (and by 16 not even an adb shell can read the
 * sysfs node), and the second needs the special "Usage access" grant. Both
 * could only ever have rendered as "not available", which is a row that costs
 * space and teaches nothing.
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
}
