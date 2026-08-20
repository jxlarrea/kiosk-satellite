package me.jxl.kiosk_satellite

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class WifiMacTest {
    @Test
    fun normalizeCanonicalizesCaseAndSeparators() {
        assertEquals("80:30:49:CD:D6:5F", WifiMac.normalize("80:30:49:cd:d6:5f"))
        assertEquals("80:30:49:CD:D6:5F", WifiMac.normalize(" 80-30-49-CD-D6-5F "))
    }

    @Test
    fun normalizeRejectsStubsAndJunk() {
        assertNull(WifiMac.normalize(null))
        assertNull(WifiMac.normalize(""))
        assertNull(WifiMac.normalize("02:00:00:00:00:00")) // Android's privacy stub
        assertNull(WifiMac.normalize("00:00:00:00:00:00"))
        assertNull(WifiMac.normalize("80:30:49:CD:D6")) // short
        assertNull(WifiMac.normalize("not a mac"))
        // Multicast bit: never an interface's own address.
        assertNull(WifiMac.normalize("01:00:5E:00:00:FB"))
    }

    @Test
    fun normalizeKeepsLocallyAdministeredAddresses() {
        // A randomized per-network MAC is locally administered and is exactly
        // the address the router sees; rejecting it would defeat the feature
        // on every Android 10+ network with randomization on.
        assertEquals("DA:A1:19:12:34:56", WifiMac.normalize("da:a1:19:12:34:56"))
    }

    @Test
    fun fromBytesFormatsAndValidates() {
        assertEquals(
            "80:30:49:CD:D6:5F",
            WifiMac.fromBytes(byteArrayOf(
                0x80.toByte(), 0x30, 0x49, 0xCD.toByte(), 0xD6.toByte(), 0x5F)),
        )
        assertNull(WifiMac.fromBytes(null))
        assertNull(WifiMac.fromBytes(ByteArray(0)))
        assertNull(WifiMac.fromBytes(ByteArray(6))) // all zeros
    }
}
