package me.jxl.kiosk_satellite

import org.junit.Assert.*
import org.junit.Test

class ClipDrainTest {
    @Test fun stalledTimestampCannotPostponeCompletionForever() {
        val drain = ClipDrain(36000, 48000)
        assertFalse(drain.complete(800_000_000, 36000, 24000, 800_000_000, 100_000_000))
        assertTrue(drain.complete(1_070_000_000, 36000, 24000, 1_070_000_000, 100_000_000))
    }

    @Test fun elapsedClipDurationDoesNotMeanBufferedAudioHasPlayed() {
        val drain = ClipDrain(36000, 48000)
        assertFalse(drain.complete(800_000_000, 24000, 20000, 800_000_000, 100_000_000))
    }

    @Test fun mixerCompletionWaitsForSpeakerPresentation() {
        val drain = ClipDrain(36000, 48000)
        assertFalse(drain.complete(800_000_000, 36000, 24000, 800_000_000, 100_000_000))
        assertFalse(drain.complete(1_060_000_000, 36000, 24000, 800_000_000, 100_000_000))
        assertTrue(drain.complete(1_070_000_000, 36000, 24000, 800_000_000, 100_000_000))
    }

    @Test fun missingTimestampAllowsOutputLatencyAfterHeadReachesEnd() {
        val drain = ClipDrain(36000, 48000)
        assertFalse(drain.complete(800_000_000, 36000, null, null, 200_000_000))
        assertFalse(drain.complete(999_000_000, 36000, null, null, 200_000_000))
        assertTrue(drain.complete(1_000_000_000, 36000, null, null, 200_000_000))
    }
}
