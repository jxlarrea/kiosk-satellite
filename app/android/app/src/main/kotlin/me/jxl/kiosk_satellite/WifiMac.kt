package me.jxl.kiosk_satellite

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import java.net.NetworkInterface

/**
 * The device's real Wi-Fi hardware address, where Android still reveals it
 * (issue #252). Home Assistant merges device registry entries by their
 * connections MAC, so reporting the real address links this kiosk with the
 * same device as seen by router and network integrations; the synthetic
 * address the ESPHome identity otherwise uses can never match anything.
 *
 * Two doors, tried in order:
 *  - The interface itself: readable by any app below Android 10, and it is
 *    the address actually in use on the network, so it is preferred where
 *    both doors open. Android 11 makes getHardwareAddress return null.
 *  - The device-owner API (DevicePolicyManager.getWifiMacAddress), open on
 *    every Android version this app runs on, but returning the factory
 *    address: on Android 10+ networks using per-network MAC randomization
 *    the router sees a different address and no link forms. Kiosk fleets
 *    routinely pin DHCP reservations and turn randomization off, which is
 *    exactly when this door delivers.
 *
 * Null when neither answers; the caller keeps the synthetic identity.
 */
object WifiMac {
    fun read(context: Context): String? =
        interfaceMac() ?: deviceOwnerMac(context)

    private fun interfaceMac(): String? = try {
        fromBytes(NetworkInterface.getByName("wlan0")?.hardwareAddress)
            ?: NetworkInterface.getNetworkInterfaces()?.toList()
                ?.filter { it.name.startsWith("wlan") }
                ?.firstNotNullOfOrNull { fromBytes(it.hardwareAddress) }
    } catch (e: Exception) {
        null
    }

    private fun deviceOwnerMac(context: Context): String? = try {
        val dpm = context.getSystemService(DevicePolicyManager::class.java)
        if (dpm != null && dpm.isDeviceOwnerApp(context.packageName)) {
            normalize(dpm.getWifiMacAddress(
                ComponentName(context, KioskAdminReceiver::class.java)))
        } else {
            null
        }
    } catch (e: Exception) {
        null
    }

    private val SHAPE = Regex("^[0-9A-F]{2}(:[0-9A-F]{2}){5}$")

    /**
     * Canonical uppercase colon form, or null for anything that is not a
     * usable interface address: Android's 02:00:00:00:00:00 privacy stub,
     * all zeros, multicast bit set. Locally-administered addresses pass on
     * purpose — a randomized per-network MAC is locally administered and is
     * precisely the address the router sees.
     */
    internal fun normalize(raw: String?): String? {
        val mac = raw?.trim()?.uppercase()?.replace('-', ':') ?: return null
        if (!SHAPE.matches(mac)) return null
        if (mac == "00:00:00:00:00:00" || mac == "02:00:00:00:00:00") return null
        if (mac.substring(0, 2).toInt(16) and 0x01 != 0) return null
        return mac
    }

    internal fun fromBytes(bytes: ByteArray?): String? {
        if (bytes == null || bytes.size != 6) return null
        return normalize(bytes.joinToString(":") { "%02X".format(it) })
    }
}
