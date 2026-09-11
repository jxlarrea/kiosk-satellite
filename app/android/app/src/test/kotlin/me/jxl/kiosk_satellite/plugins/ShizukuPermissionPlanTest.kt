package me.jxl.kiosk_satellite.plugins

import org.junit.Assert.*
import org.junit.Test

class ShizukuPermissionPlanTest {
    @Test fun actionsTargetOnlyTheAppAndRespectAndroidVersions() {
        val pkg = "me.jxl.kiosk_satellite"
        assertTrue(ShizukuPermissionPlan.commands("notification", 32, pkg).isEmpty())
        assertEquals("android.permission.POST_NOTIFICATIONS", ShizukuPermissionPlan.commands("notification", 33, pkg).single().last())
        assertTrue(ShizukuPermissionPlan.commands("bluetooth", 30, pkg).isEmpty())
        assertEquals(2, ShizukuPermissionPlan.commands("bluetooth", 31, pkg).size)
        assertEquals("MANAGE_EXTERNAL_STORAGE", ShizukuPermissionPlan.commands("allFiles", 30, pkg).single()[3])
        assertEquals(2, ShizukuPermissionPlan.commands("allFiles", 29, pkg).size)
        for (key in listOf("microphone", "camera", "notification", "location", "bluetooth", "batteryUnrestricted", "displayOverOtherApps", "writeSettings", "allFiles", "usageAccess")) {
            val commands = ShizukuPermissionPlan.commands(key, 35, pkg)
            assertTrue(commands.all { it.contains(pkg) || it.contains("+$pkg") })
        }
        assertThrows(IllegalArgumentException::class.java) { ShizukuPermissionPlan.commands("shell", 35, pkg) }
        assertThrows(IllegalArgumentException::class.java) { ShizukuPermissionPlan.commands("camera", 35, "app; reboot") }
        assertArrayEquals(arrayOf("/system/bin/dpm", "set-active-admin", "$pkg/.KioskAdminReceiver"), ShizukuPermissionPlan.commands("deviceAdmin", 35, pkg).single())
    }

    @Test fun enablingUiGuardPreservesOtherServicesAndAvoidsDuplicates() {
        val pkg = "me.jxl.kiosk_satellite"
        val other = "com.example/com.example.Reader"
        val own = "$pkg/.KioskAccessibilityService"
        assertEquals("$other:$own", ShizukuPermissionPlan.enableUiGuard(pkg, "$other\n").first().last())
        assertEquals(own, ShizukuPermissionPlan.enableUiGuard(pkg, "null\n").first().last())
        assertEquals("$other:$own", ShizukuPermissionPlan.enableUiGuard(pkg, "$other:$own").first().last())
        val full = "$pkg/$pkg.KioskAccessibilityService"
        assertEquals(full, ShizukuPermissionPlan.enableUiGuard(pkg, full).first().last())
        assertThrows(IllegalArgumentException::class.java) { ShizukuPermissionPlan.enableUiGuard(pkg, "bad\nvalue") }
        assertThrows(IllegalArgumentException::class.java) { ShizukuPermissionPlan.enableUiGuard(pkg, "x".repeat(3501)) }
    }
}
