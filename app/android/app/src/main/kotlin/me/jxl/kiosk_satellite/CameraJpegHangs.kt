package me.jxl.kiosk_satellite

import android.content.Context
import android.os.Build

/**
 * The cameras on this system build whose HAL never answered a JPEG capture
 * (issue #1304, a SHIELD Tablet on LineageOS 15.1). Closing such a camera can
 * hang inside the HAL until the device reboots, and a process restart does
 * not help, so the next capture must not repeat the request. These cameras
 * take their stills from analysis frames instead, the rule outlives the
 * process and a new system build starts clean because it can fix the HAL.
 *
 * [read] and [write] hold one stored string: the build and then the camera
 * ids, one per line.
 */
internal class CameraJpegHangs(
    private val build: String,
    private val read: () -> String?,
    private val write: (String) -> Unit,
) {
    private fun cameras(): List<String> {
        val lines = read()?.lines() ?: return emptyList()
        return if (lines.firstOrNull() == build) lines.drop(1) else emptyList()
    }

    fun hung(camera: String): Boolean = camera in cameras()

    fun remember(camera: String) {
        val known = cameras()
        if (camera !in known) write((listOf(build) + known + camera).joinToString("\n"))
    }

    companion object {
        private const val PREFS = "camera_jpeg_hangs"
        private const val KEY = "hung"

        fun of(context: Context): CameraJpegHangs {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            return CameraJpegHangs(
                Build.FINGERPRINT,
                { prefs.getString(KEY, null) },
                { prefs.edit().putString(KEY, it).apply() },
            )
        }
    }
}
