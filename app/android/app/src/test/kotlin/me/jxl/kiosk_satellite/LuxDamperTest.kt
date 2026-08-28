package me.jxl.kiosk_satellite

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/** The light sensor damping, and in particular the trailing edge the rate
 *  limit must not lose (an Echo Show reading 29 lx all night). */
class LuxDamperTest {
    private var clock = 0L
    private var scheduled: Long? = null
    private val sent = mutableListOf<Float>()
    private val damper = LuxDamper(
        now = { clock },
        schedule = { delay -> scheduled = delay },
        cancel = { scheduled = null },
        send = { sent.add(it) },
    )

    private fun runFlush() {
        scheduled = null
        damper.flush()
    }

    @Test
    fun `the first reading always passes`() {
        damper.offer(43f)
        assertEquals(listOf(43f), sent)
    }

    @Test
    fun `a move inside the deadband is not sent`() {
        damper.offer(43f)
        clock = 5000
        damper.offer(40f) // 3 lx is under 10% of 43
        damper.offer(43.5f)
        assertEquals(listOf(43f), sent)
        assertNull(scheduled)
    }

    @Test
    fun `a move past the deadband after the window is sent at once`() {
        damper.offer(43f)
        clock = 5000
        damper.offer(29f)
        assertEquals(listOf(43f, 29f), sent)
        assertNull(scheduled)
    }

    @Test
    fun `lights going out keeps the last reading of the ramp`() {
        damper.offer(43f)
        // The room sat at 43 for a while; the lights go out at 5 s.
        clock = 5000
        damper.offer(29f)
        assertEquals(listOf(43f, 29f), sent)
        // The rest of the ramp lands inside the window after the 29.
        for ((i, lux) in listOf(17f, 12f, 8f, 6f, 5f, 4f, 3f, 2f).withIndex()) {
            clock = 5200 + i * 200L
            damper.offer(lux)
        }
        assertEquals(listOf(43f, 29f), sent)
        // Scheduled once, for the window's close, not once per reading.
        assertEquals(1800L, scheduled)
        clock = 7200
        runFlush()
        assertEquals(listOf(43f, 29f, 2f), sent)
    }

    @Test
    fun `a reading back inside the deadband drops what was parked`() {
        damper.offer(29f)
        clock = 300
        damper.offer(2f)
        assertEquals(1700L, scheduled)
        clock = 600
        damper.offer(28f) // a passing shadow, back to what was sent
        assertNull(scheduled)
        clock = 2200
        runFlush()
        assertEquals(listOf(29f), sent)
    }

    @Test
    fun `a parked reading superseded by a sendable one after the window is not sent twice`() {
        damper.offer(29f)
        clock = 300
        damper.offer(2f)
        clock = 2500
        damper.offer(1f)
        assertEquals(listOf(29f, 1f), sent)
        assertNull(scheduled)
        runFlush()
        assertEquals(listOf(29f, 1f), sent)
    }

    @Test
    fun `a flush whose parked reading no longer passes stays quiet`() {
        damper.offer(29f)
        clock = 300
        damper.offer(2f)
        // Nothing else arrived; the flush sends it.
        clock = 2200
        runFlush()
        assertEquals(listOf(29f, 2f), sent)
        // A later flush with nothing parked does nothing.
        runFlush()
        assertEquals(listOf(29f, 2f), sent)
    }

    @Test
    fun `reset makes the next reading a first`() {
        damper.offer(29f)
        clock = 300
        damper.offer(2f)
        damper.reset()
        assertNull(scheduled)
        damper.offer(29.5f)
        assertEquals(listOf(29f, 29.5f), sent)
    }
}
