package me.jxl.kiosk_satellite

import org.junit.Assert.*
import org.junit.Test

class PlaybackLeasePoolTest {
    @Test fun captureKeepsRouteAcrossChimeSpeechAndTheGapBetweenThem() {
        var starts = 0
        var stops = 0
        val pool = PlaybackLeasePool({ starts++; true }, { stops++ })
        val capture = pool.acquire()!!
        pool.acquire()!!.close()
        assertEquals(0, stops)
        pool.acquire()!!.close()
        assertEquals(1, starts)
        assertEquals(0, stops)
        capture.close()
        assertEquals(1, stops)
    }

    @Test fun overlappingSoundsRestoreOnlyAfterTheLastRelease() {
        var starts = 0
        var stops = 0
        val pool = PlaybackLeasePool({ starts++; true }, { stops++ })
        val chime = pool.acquire()!!
        val speech = pool.acquire()!!
        chime.close()
        assertTrue(pool.active)
        assertEquals(1, starts)
        assertEquals(0, stops)
        speech.close()
        assertFalse(pool.active)
        assertEquals(1, stops)
    }

    @Test fun repeatedCompletionCannotReleaseAnotherSoundsSession() {
        var stops = 0
        val pool = PlaybackLeasePool({ true }, { stops++ })
        val old = pool.acquire()!!
        val replacement = pool.acquire()!!
        old.close()
        old.close()
        assertTrue(pool.active)
        assertEquals(0, stops)
        replacement.close()
        assertEquals(1, stops)
    }

    @Test fun refusedSessionCanBeRetriedAfterAnotherCallEnds() {
        var available = false
        var starts = 0
        var stops = 0
        val pool = PlaybackLeasePool({ starts++; available }, { stops++ })
        assertNull(pool.acquire())
        assertFalse(pool.active)
        available = true
        pool.acquire()!!.close()
        pool.acquire()!!.close()
        assertEquals(3, starts)
        assertEquals(2, stops)
    }
}
