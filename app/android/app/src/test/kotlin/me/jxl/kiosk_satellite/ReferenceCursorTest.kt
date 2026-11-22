package me.jxl.kiosk_satellite

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ReferenceCursorTest {
    /** An 80 ms capture chunk at 16 kHz. */
    private val chunk = 1280

    private fun ms(value: Int) = value * 16L

    @Test fun aFirstPlaceNineMillisecondsOutIsPutRightByTheNextChunk() {
        val cursor = ReferenceCursor()
        // A track that has just started places its speaker 9 ms early, and
        // its next reading is right. Inside the 10 ms slack that stayed for
        // the whole sound.
        assertTrue(cursor.place(ms(-9)))
        cursor.advance(chunk)
        assertTrue(cursor.place(chunk.toLong()))
        assertEquals(chunk.toLong(), cursor.at)
        cursor.advance(chunk)
        assertFalse(cursor.place(2L * chunk))
    }

    @Test fun aFirstPlaceFarOutIsPutRightAndSoIsTheSmallErrorAfterIt() {
        val cursor = ReferenceCursor()
        // Two corrections, as streamed sounds showed: 34 ms, then 17 ms.
        cursor.place(ms(-51))
        cursor.advance(chunk)
        assertTrue(cursor.place(chunk - ms(17)))
        cursor.advance(chunk)
        assertTrue(cursor.place(2L * chunk))
        assertEquals(2L * chunk, cursor.at)
    }

    @Test fun whileSettlingAReadingWithinTwoMillisecondsFollowsOn() {
        val cursor = ReferenceCursor()
        cursor.place(0)
        cursor.advance(chunk)
        assertFalse(cursor.place(chunk + ms(2)))
        assertFalse(cursor.place(chunk - ms(2)))
        assertEquals(chunk.toLong(), cursor.at)
    }

    @Test fun onceSettledMixerStepsDoNotMoveIt() {
        val cursor = ReferenceCursor()
        cursor.place(0)
        // Half a second of chunks the clocks agree with.
        var expected = 0L
        repeat(7) {
            cursor.advance(chunk)
            expected += chunk
            assertFalse(cursor.place(expected))
        }
        cursor.advance(chunk)
        expected += chunk
        // The head moves in steps a few milliseconds apart: the reference
        // stays in one piece through them.
        for (step in intArrayOf(9, -9, 5, -3, 10, -10)) {
            assertFalse("a step of $step ms", cursor.place(expected + ms(step)))
            cursor.advance(chunk)
            expected += chunk
        }
        assertEquals(expected, cursor.at)
    }

    @Test fun aJumpPastTheSlackMovesItAndSettlesAgain() {
        val cursor = ReferenceCursor()
        cursor.place(0)
        var expected = 0L
        repeat(8) {
            cursor.advance(chunk)
            expected += chunk
        }
        // The track ran dry and started again 40 ms later, a first reading
        // again: 6 ms out, and the one after it right.
        assertTrue(cursor.place(expected + ms(46)))
        cursor.advance(chunk)
        expected += chunk + ms(46)
        assertTrue(cursor.place(expected - ms(6)))
        assertEquals(expected - ms(6), cursor.at)
    }

    @Test fun nothingIsPlacedBeforeTheFirstChunk() {
        assertEquals(ReferenceCursor.UNPLACED, ReferenceCursor().at)
    }
}
