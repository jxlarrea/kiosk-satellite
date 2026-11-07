package me.jxl.kiosk_satellite

import java.util.concurrent.CountDownLatch
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class LegacyCameraShimTest {
    private fun shim(names: List<String>, marks: MutableList<Unit> = mutableListOf()) =
        LegacyCameraShim({ names }, { marks.isNotEmpty() }, { marks.add(Unit) })

    @Test
    fun `a HAL3 device never spends the budget and is never marked`() {
        val marks = mutableListOf<Unit>()
        val shim = shim(List(1_500) { "Thread-$it" } + "CameraX-core_camera_0", marks)
        assertNull(shim.spent())
        assertTrue(marks.isEmpty())
    }

    @Test
    fun `an open HAL1 camera marks the device once and goes ahead`() {
        val marks = mutableListOf<Unit>()
        val shim = shim(listOf("main", LegacyCameraShim.CALLBACK_THREAD, "Thread-9"), marks)
        assertNull(shim.spent())
        assertNull(shim.spent())
        assertEquals(1, marks.size)
    }

    @Test
    fun `the first frame marks a HAL1 device and leaves a HAL3 device alone`() {
        val hal1 = mutableListOf<Unit>()
        shim(listOf(LegacyCameraShim.CALLBACK_THREAD), hal1).markIfShim()
        assertEquals(1, hal1.size)
        val hal3 = mutableListOf<Unit>()
        shim(listOf("CameraX-core_camera_0"), hal3).markIfShim()
        assertTrue(hal3.isEmpty())
    }

    @Test
    fun `the budget is spent once the leaked callback threads reach the limit`() {
        val limit = LegacyCameraShim.LEAK_LIMIT
        assertNull(shim(List(limit - 1) { LegacyCameraShim.CALLBACK_THREAD }).spent())
        assertEquals(limit, shim(List(limit) { LegacyCameraShim.CALLBACK_THREAD }).spent())
    }

    @Test
    fun `the budget restarts well below where the field crash came`() {
        // 2 leaked threads per callback thread plus the app's usual 100 or so
        // must stay under the lowest thread exhaustion seen, about 1,000.
        assertTrue(LegacyCameraShim.LEAK_LIMIT * 2 + 100 < 1_000)
    }

    @Test
    fun `the restart reason names the camera watchdog for the journal`() {
        // analytics/crash_journal.dart reports a deliberate restart as a
        // watchdog restart by this phrase.
        assertTrue(LegacyCameraShim.restartReason(400).contains("camera watchdog"))
    }

    @Test
    fun `only the exact callback name counts`() {
        val shim = shim(listOf("LegacyCameraCallbackX", "LegacyCameraLooper", "legacycameracallback"))
        assertEquals(0, shim.callbackThreads())
    }

    @Test
    fun `live thread names include a parked thread with the shim's name`() {
        val release = CountDownLatch(1)
        val started = CountDownLatch(3)
        val threads = List(3) {
            Thread({ started.countDown(); release.await() }, LegacyCameraShim.CALLBACK_THREAD).apply { start() }
        }
        try {
            started.await()
            val names = LegacyCameraShim.liveThreadNames()
            assertTrue(names.count { it == LegacyCameraShim.CALLBACK_THREAD } >= 3)
            assertTrue(Thread.currentThread().name in names)
        } finally {
            release.countDown()
            threads.forEach { it.join() }
        }
        assertFalse(LegacyCameraShim.liveThreadNames().contains(LegacyCameraShim.CALLBACK_THREAD))
    }
}
