package me.jxl.kiosk_satellite

import android.media.AudioDeviceInfo
import android.media.MediaRecorder
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class MicCaptureLadderTest {
    private val mic = MediaRecorder.AudioSource.MIC
    private val recognition = MediaRecorder.AudioSource.VOICE_RECOGNITION
    private val call = MediaRecorder.AudioSource.VOICE_COMMUNICATION
    private val builtIn = AudioDeviceInfo.TYPE_BUILTIN_MIC
    private val usb = AudioDeviceInfo.TYPE_USB_DEVICE
    private val bluetooth = AudioDeviceInfo.TYPE_BLUETOOTH_SCO

    @Test
    fun echoImageBuiltInMicIsFixed() {
        assertTrue(MicRecorder.fixedCapture(true, null, listOf(builtIn)))
        assertTrue(MicRecorder.fixedCapture(true, builtIn, listOf(builtIn)))
    }

    @Test
    fun echoImageBluetoothAndUsbMicsKeepTheLadder() {
        assertFalse(MicRecorder.fixedCapture(true, usb, listOf(builtIn, usb)))
        assertFalse(MicRecorder.fixedCapture(true, bluetooth, listOf(builtIn, bluetooth)))
    }

    @Test
    fun automaticRoutingWithAUsbMicConnectedKeepsTheLadder() {
        // Android records from the USB mic, not the built-in one.
        assertFalse(MicRecorder.fixedCapture(true, null, listOf(builtIn, usb)))
    }

    @Test
    fun automaticRoutingWithABluetoothHeadsetConnectedIsFixed() {
        // The mic source reaches a Bluetooth headset only when it is selected.
        assertTrue(MicRecorder.fixedCapture(true, null, listOf(builtIn, bluetooth)))
    }

    @Test
    fun otherDevicesAreNeverFixed() {
        assertFalse(MicRecorder.fixedCapture(false, null, listOf(builtIn)))
        assertFalse(MicRecorder.fixedCapture(false, builtIn, listOf(builtIn)))
    }

    @Test
    fun fixedLadderIsMicAt16kHzMonoWhateverWasAsked() {
        val only = listOf(MicRecorder.Shape(16000, 1, mic))
        assertEquals(only, MicRecorder.captureLadder(mic, false, 1, false, fixed = true))
        assertEquals(only, MicRecorder.captureLadder(call, true, 1, false, fixed = true))
    }

    @Test
    fun ladderWalksFormatsThenTheOtherSources() {
        assertEquals(
            listOf(
                MicRecorder.Shape(16000, 1, mic),
                MicRecorder.Shape(48000, 2, mic),
                MicRecorder.Shape(48000, 1, mic),
                MicRecorder.Shape(16000, 1, recognition),
                MicRecorder.Shape(16000, 1, call),
            ),
            MicRecorder.captureLadder(mic, false, 1, false),
        )
    }

    @Test
    fun aRungThatStartsGatingNeverWalksOnZeros() {
        // The fixed capture's walk: ten minutes of silence before an
        // in-place reopen, and no fresh two second limit before that.
        val walk = CaptureWalk(1, 0, setOf(0))
        assertTrue(walk.gating)
        assertEquals(CaptureWalk.GATING_ZERO_BYTES, walk.zeroLimitBytes)
        assertFalse(walk.audible(CaptureWalk.TRUSTED_ZERO_BYTES))
        assertTrue(walk.gating)
        // Errors and stalls still reopen the one rung there is.
        assertEquals(0, walk.exhausted(0))
    }
}
