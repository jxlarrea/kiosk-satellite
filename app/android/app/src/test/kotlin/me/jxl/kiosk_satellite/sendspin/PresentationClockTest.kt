package me.jxl.kiosk_satellite.sendspin

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class PresentationClockTest {
    private val clock = PresentationClock().also { it.reset(1_000_000_000L, 80_000) }

    private fun sample(ms: Long, presented: Long?, head: Long, stampMs: Long = ms): Long =
        clock.position(ms * 1_000_000, head, 480_000, 48_000, presented, stampMs * 1_000_000)

    private fun establishTimestamp() {
        sample(1_100, 4_800, 10_800)
        sample(1_120, 5_760, 11_760)
        sample(1_140, 6_720, 12_720)
        assertEquals("timestamp", clock.source)
    }

    @Test fun validatedTimestampOverridesTheInitialLatencyEstimate() {
        establishTimestamp()
        assertEquals(125_000, clock.latencyUs)
        assertEquals(7_200, sample(1_150, 6_720, 13_200, stampMs = 1_140))
    }

    @Test fun repeatedTimestampsDoNotCountAsValidation() {
        repeat(10) { sample(1_100L + it, 4_800, 10_800, stampMs = 1_100) }
        assertEquals("warming_up", clock.source)
    }

    @Test fun missingTimestampsUseTheHeadAfterABoundedStartupWait() {
        assertEquals(0, sample(1_100, null, 4_800))
        assertEquals(10_560, sample(1_300, null, 14_400))
        assertEquals("playback_head", clock.source)
        assertEquals("timestamp_unavailable", clock.fallbackReason)
    }

    @Test fun frozenTimestampFallsBackWithItsMeasuredLatency() {
        establishTimestamp()
        val result = sample(1_700, 6_720, 39_600, stampMs = 1_140)
        assertEquals("playback_head", clock.source)
        assertEquals("stalled_timestamp", clock.fallbackReason)
        assertEquals(33_600, result)
        assertEquals(125_000, clock.latencyUs)
        sample(1_720, 34_560, 40_560)
        assertEquals("playback_head", clock.source)
    }

    @Test fun aSlowStartingDriverCanEstablishItsTimestampAfterPriming() {
        sample(1_300, null, 14_400)
        assertEquals("playback_head", clock.source)
        sample(1_400, 19_200, 25_200)
        sample(1_420, 20_160, 26_160)
        assertEquals(21_120, sample(1_440, 21_120, 27_120))
        assertEquals("timestamp", clock.source)
        assertEquals(null, clock.fallbackReason)
    }

    @Test fun unavailableTimestampsAreNotPolledForever() {
        sample(3_000, null, 96_000)
        assertEquals(false, clock.canPollTimestamp)
    }

    @Test fun backwardTimestampCannotPoisonThePlaybackPosition() {
        establishTimestamp()
        val result = sample(1_160, 5_760, 13_680, stampMs = 1_120)
        assertEquals("playback_head", clock.source)
        assertEquals("inconsistent_timestamp", clock.fallbackReason)
        assertEquals(7_680, result)
    }

    @Test fun aTimestampWithTheWrongRateIsRejected() {
        establishTimestamp()
        sample(1_160, 15_000, 20_000)
        assertEquals("inconsistent_timestamp", clock.fallbackReason)
    }

    @Test fun timestampsFromThePreviousStreamAreIgnored() {
        sample(1_100, 48_000, 5_000, stampMs = 900)
        sample(1_120, 48_960, 6_000, stampMs = 920)
        sample(1_140, 49_920, 7_000, stampMs = 940)
        assertEquals("warming_up", clock.source)
    }

    @Test fun extrapolationNeverReportsUnwrittenAudio() {
        establishTimestamp()
        val position = clock.position(1_150_000_000, 7_000, 7_000, 48_000, null, null)
        assertEquals(7_000, position)
    }

    @Test fun resetRevalidatesTheNewStream() {
        establishTimestamp()
        clock.reset(2_000_000_000, 112_000)
        assertEquals("warming_up", clock.source)
        assertEquals(0, sample(2_050, null, 0))
        assertTrue(clock.fallbackReason == null)
    }
}
