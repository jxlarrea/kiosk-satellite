package me.jxl.kiosk_satellite

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class MemAvailableTest {
    @Test
    fun readsTheKernelLine() {
        val reading = MemAvailable.parse(
            """
            MemTotal:        3844136 kB
            MemFree:          120000 kB
            MemAvailable:    1500000 kB
            Active(file):     400000 kB
            """.trimIndent(),
        )
        assertEquals(MemAvailable.Reading(1500000L * 1024, estimated = false), reading)
    }

    // The /proc/meminfo of the Galaxy View in issue #1429, a 3.10 kernel.
    @Test
    fun estimatesWithoutTheKernelLine() {
        val reading = MemAvailable.parse(
            """
            MemTotal:        1886304 kB
            MemFree:           53924 kB
            Buffers:            7724 kB
            Cached:           522044 kB
            Active(file):     187156 kB
            Inactive(file):   234244 kB
            SReclaimable:      65976 kB
            VmallocUsed:           0 kB
            """.trimIndent(),
        )
        assertEquals(
            MemAvailable.Reading((53924L + 187156 + 234244 + 65976) * 1024, estimated = true),
            reading,
        )
    }

    @Test
    fun nothingToReadIsNull() {
        assertNull(MemAvailable.parse(""))
        assertNull(MemAvailable.parse("MemTotal: 1886304 kB"))
    }
}
