package me.jxl.kiosk_satellite.plugins

/** Only KS's own declared grants can be changed. No caller-provided commands or package names. */
internal object ShizukuPermissionPlan {
    fun commands(key: String, sdk: Int, packageName: String): List<Array<String>> {
        require(packageName.matches(Regex("[a-zA-Z0-9_.]+")))
        fun grant(vararg permissions: String) = permissions.map { arrayOf("/system/bin/pm", "grant", packageName, "android.permission.$it") }
        fun appop(op: String) = listOf(arrayOf("/system/bin/appops", "set", packageName, op, "allow"))
        return when (key) {
            "microphone" -> grant("RECORD_AUDIO")
            "camera" -> grant("CAMERA")
            "notification" -> if (sdk >= 33) grant("POST_NOTIFICATIONS") else emptyList()
            "location" -> grant("ACCESS_COARSE_LOCATION", "ACCESS_FINE_LOCATION")
            "bluetooth" -> if (sdk >= 31) grant("BLUETOOTH_SCAN", "BLUETOOTH_CONNECT") else emptyList()
            "batteryUnrestricted" -> listOf(arrayOf("/system/bin/dumpsys", "deviceidle", "whitelist", "+$packageName"))
            "displayOverOtherApps" -> appop("SYSTEM_ALERT_WINDOW")
            "writeSettings" -> appop("WRITE_SETTINGS")
            "allFiles" -> if (sdk >= 30) appop("MANAGE_EXTERNAL_STORAGE") else grant("READ_EXTERNAL_STORAGE", "WRITE_EXTERNAL_STORAGE")
            "usageAccess" -> appop("GET_USAGE_STATS")
            "deviceAdmin" -> listOf(arrayOf("/system/bin/dpm", "set-active-admin", "$packageName/.KioskAdminReceiver"))
            "uiGuard" -> listOf(arrayOf("/system/bin/settings", "get", "secure", "enabled_accessibility_services"))
            else -> throw IllegalArgumentException("Unsupported Shizuku permission action")
        }
    }

    fun enableUiGuard(packageName: String, current: String): List<Array<String>> {
        require(packageName.matches(Regex("[a-zA-Z0-9_.]+")))
        val existing = current.trim().takeUnless { it == "null" }.orEmpty()
        require(existing.length <= 3500 && '\n' !in existing && '\r' !in existing && '\u0000' !in existing) { "Cannot safely read existing accessibility services" }
        val own = "$packageName/.KioskAccessibilityService"
        val entries = existing.split(':').filter { it.isNotEmpty() }
        val includesOwn = entries.any { it == own || it == "$packageName/$packageName.KioskAccessibilityService" }
        val updated = if (includesOwn) existing else (entries + own).joinToString(":")
        return listOf(
            arrayOf("/system/bin/settings", "put", "secure", "enabled_accessibility_services", updated),
            arrayOf("/system/bin/settings", "put", "secure", "accessibility_enabled", "1"),
        )
    }
}
