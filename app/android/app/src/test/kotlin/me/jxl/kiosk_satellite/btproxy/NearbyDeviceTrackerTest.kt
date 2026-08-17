package me.jxl.kiosk_satellite.btproxy

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class NearbyDeviceTrackerTest {
    private var now = 1_000_000L

    private fun advertisement(address: Long, name: String? = null): BleAdvertisement {
        val data = if (name == null) {
            byteArrayOf(0x02, 0x01, 0x06)
        } else {
            val bytes = name.toByteArray()
            byteArrayOf((bytes.size + 1).toByte(), 0x09) + bytes
        }
        return BleAdvertisement(address, -60, 0, data)
    }

    @Test
    fun parsesNameCompaniesAndUuids() {
        val tracker = NearbyDeviceTracker { now }
        // name "AB" + manufacturer 0x004C frame 0x10 + 16-bit uuid 0xFCD2.
        val data = byteArrayOf(
            0x03, 0x09, 0x41, 0x42,
            0x04, 0xFF.toByte(), 0x4C, 0x00, 0x10,
            0x03, 0x03, 0xD2.toByte(), 0xFC.toByte(),
        )
        tracker.observe(BleAdvertisement(0xAABBCCDDEEFFL, -50, 0, data))
        val device = tracker.snapshot().single()
        assertEquals("AB", device["name"])
        assertEquals("AA:BB:CC:DD:EE:FF", device["address"])
        assertEquals(listOf(76), device["companies"])
        assertEquals(mapOf("76" to 0x10), device["firstBytes"])
        assertEquals(listOf("fcd2"), device["uuids"])
    }

    @Test
    fun staleEntriesExpireFromSnapshotAndCount() {
        val tracker = NearbyDeviceTracker { now }
        tracker.observe(advertisement(1))
        tracker.observe(advertisement(2))
        assertEquals(2, tracker.snapshot().size)

        // Nine minutes on: both still listed.
        now += 9 * 60_000L
        tracker.observe(advertisement(2))
        assertEquals(2, tracker.snapshot().size)

        // Two more: device 1 has been silent past the horizon, device 2 is
        // fresh. The rotated-away appearance disappears instead of pinning
        // the inventory forever (the nine-hour soak's cap saturation).
        now += 2 * 60_000L
        val remaining = tracker.snapshot()
        assertEquals(1, remaining.size)
        assertTrue(remaining.single()["address"].toString().endsWith(":02"))
    }

    @Test
    fun latestPayloadWinsAndCountAccumulates() {
        val tracker = NearbyDeviceTracker { now }
        tracker.observe(advertisement(7))
        tracker.observe(advertisement(7, name = "Late Name"))
        val device = tracker.snapshot().single()
        assertEquals("Late Name", device["name"])
        assertEquals(2L, device["count"])
    }
}
