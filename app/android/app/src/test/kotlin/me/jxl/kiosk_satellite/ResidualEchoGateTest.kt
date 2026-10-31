package me.jxl.kiosk_satellite

import org.junit.Assert.*
import org.junit.Test

class ResidualEchoGateTest {
    @Test fun prototypeRealtimePreservesQuietSpeechUnderLoudPlayback() {
        val gate = ResidualEchoGate()
        gate.set("realtime", ResidualEchoGate.Mode.REALTIME)
        assertTrue(gate.realtime)
        for (left in listOf(20, 100, 250, 500, 1000)) {
            repeat(200) {
                assertFalse(gate.suppress(6000, 8000, left, subtractionOnly = true))
            }
        }
        gate.set("intercom", ResidualEchoGate.Mode.INTERCOM)
        assertTrue(gate.realtime)
        gate.set("realtime", null)
        assertFalse(gate.realtime)
        assertTrue(gate.intercomOnly)
    }

    @Test fun intercomDoesNotMuteQuietNearEndDuringLoudPlayback() {
        val gate = ResidualEchoGate()
        gate.set("intercom", ResidualEchoGate.Mode.INTERCOM)
        // These frames were previously zeroed because the echo was much
        // louder than the nearby source. That is also valid double talk.
        for (left in listOf(20, 100, 250, 500, 1000)) {
            repeat(200) {
                assertFalse(gate.suppress(6000, 8000, left))
            }
        }
        assertTrue(gate.intercomOnly)
    }

    @Test fun realtimeKeepsItsCeilingAcrossAnOverlappingCall() {
        val gate = ResidualEchoGate()
        gate.set("realtime", ResidualEchoGate.Mode.REALTIME)
        gate.set("intercom", ResidualEchoGate.Mode.INTERCOM)
        assertFalse(gate.intercomOnly)
        assertFalse(gate.suppress(2000, 3000, 250))
        gate.set("intercom", null)
        gate.reset()
        assertTrue(gate.suppress(2000, 3000, 100))
    }

    @Test fun stoppingRealtimeReturnsToUngatedCallAudio() {
        val gate = ResidualEchoGate()
        gate.set("intercom", ResidualEchoGate.Mode.INTERCOM)
        gate.set("realtime", ResidualEchoGate.Mode.REALTIME)
        gate.set("realtime", null)
        assertTrue(gate.intercomOnly)
        assertFalse(gate.suppress(2000, 3000, 250))
        gate.set("intercom", null)
        assertFalse(gate.intercomOnly)
        assertFalse(gate.suppress(2000, 3000, 100))
    }

    @Test fun quietReplyAfterPlaybackIsNotTreatedAsAnEchoTail() {
        val gate = ResidualEchoGate()
        gate.set("realtime", ResidualEchoGate.Mode.REALTIME)
        assertFalse(gate.suppress(12000, 3000, 6000))
        repeat(60) { assertTrue(gate.suppress(4000, 3000, 100) || it < 20) }
        assertFalse(gate.suppress(150, 0, 150))
    }

    @Test fun doubleTalkKeepsQuietSyllablesForTheHangover() {
        val gate = ResidualEchoGate()
        gate.set("realtime", ResidualEchoGate.Mode.REALTIME)
        assertTrue(gate.suppress(2000, 3000, 100))
        assertFalse(gate.suppress(3000, 3000, 1000))
        repeat(19) { assertFalse(gate.suppress(2000, 3000, 100)) }
        assertTrue(gate.suppress(2000, 3000, 100))
    }

    @Test fun newSessionDoesNotInheritThePreviousHangover() {
        val gate = ResidualEchoGate()
        gate.set("realtime", ResidualEchoGate.Mode.REALTIME)
        assertFalse(gate.suppress(3000, 3000, 1000))
        gate.set("realtime", null)
        gate.set("realtime", ResidualEchoGate.Mode.REALTIME)
        assertTrue(gate.suppress(2000, 3000, 100))
    }
}
