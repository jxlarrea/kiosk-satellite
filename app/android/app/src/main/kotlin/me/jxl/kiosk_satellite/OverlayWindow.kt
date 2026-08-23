package me.jxl.kiosk_satellite

import android.os.Build
import android.view.WindowManager

/**
 * The window type a draw-over-apps overlay has to be added with.
 *
 * TYPE_APPLICATION_OVERLAY (2038) only exists from Android 8: on 7.x that
 * number falls in the range reserved for the system, so WindowManager
 * refuses it with "permission denied for window type 2038" no matter that
 * the draw-over-apps grant is there (issue #280). Below O the app-usable
 * type is the deprecated TYPE_PHONE, which the same grant covers.
 */
@Suppress("DEPRECATION")
internal fun overlayWindowType(): Int =
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
    } else {
        WindowManager.LayoutParams.TYPE_PHONE
    }
