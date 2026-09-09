package me.jxl.kiosk_satellite

import org.junit.Assert.assertEquals
import org.junit.Test

class CallVolumeBaselineTest {
    @Test fun subsequentPlaybackAndSliderUpdatesPreserveUserAdjustment() {
        val baseline = CallVolumeBaseline()
        var volume = 9
        baseline.setEnabled(true)
        baseline.initialize { volume = 15; true }
        assertEquals(15, volume)
        volume = 6
        baseline.setEnabled(true)
        baseline.initialize { volume = 15; true }
        assertEquals(6, volume)
    }

    @Test fun disabledSettingDoesNotWriteOrRestoreCallVolume() {
        val baseline = CallVolumeBaseline()
        var writes = 0
        baseline.initialize { writes++; true }
        baseline.setEnabled(true)
        baseline.initialize { writes++; true }
        baseline.setEnabled(false)
        baseline.initialize { writes++; true }
        assertEquals(1, writes)
    }

    @Test fun explicitlyReenablingAllowsOneNewInitialization() {
        val baseline = CallVolumeBaseline()
        var writes = 0
        baseline.setEnabled(true)
        baseline.initialize { writes++; true }
        baseline.setEnabled(false)
        baseline.setEnabled(true)
        baseline.initialize { writes++; true }
        baseline.initialize { writes++; true }
        assertEquals(2, writes)
    }

    @Test fun failedWriteCanBeRetriedWithoutAffectingPlayback() {
        val baseline = CallVolumeBaseline()
        var writes = 0
        baseline.setEnabled(true)
        baseline.initialize { writes++; false }
        baseline.initialize { writes++; true }
        baseline.initialize { writes++; true }
        assertEquals(2, writes)
    }
}
