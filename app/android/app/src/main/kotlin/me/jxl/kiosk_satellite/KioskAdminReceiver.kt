package me.jxl.kiosk_satellite

import android.app.admin.DeviceAdminReceiver

/**
 * Exists so the app can be made device owner
 * (`adb shell dpm set-device-owner me.jxl.kiosk_satellite/.KioskAdminReceiver`)
 * on dedicated tablets. With that grant, "Disable home button" uses full
 * lock-task mode instead of screen pinning — see KioskLock.setPinned. No
 * callbacks are needed; holding the role is the entire job.
 */
class KioskAdminReceiver : DeviceAdminReceiver()
