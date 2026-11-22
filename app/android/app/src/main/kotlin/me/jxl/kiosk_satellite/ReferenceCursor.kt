package me.jxl.kiosk_satellite

/**
 * Where the canceller reads one source's reference, in 16 kHz samples of
 * that source's stream. Each capture chunk says where the clocks place it
 * ([place]) and the cursor follows on from the last chunk unless the
 * clocks have strayed from it.
 *
 * How far they may stray depends on how long ago the cursor was placed
 * from scratch. A track that has just started reports its speaker tens of
 * milliseconds from where it is, and its next readings put it right. With
 * one tolerance for the whole sound, a first place 9 ms out was inside it
 * and stayed until the sound ended: on a Galaxy Tab S8+ two realtime
 * answers in seven played with the echo 137 ms behind the reference
 * instead of 128, the canceller took 5 dB off their first second instead
 * of 14 to 19 while it learned the room again, and again for the sound
 * after. So for [SETTLING] after a fresh place the cursor follows the
 * clocks once they stray [SETTLED], and only then does it hold on.
 */
internal class ReferenceCursor {
    /** The next sample to read, [UNPLACED] before the first chunk. */
    var at = UNPLACED
        private set

    /** Samples left of the settling after a fresh place. */
    private var settling = 0

    /**
     * The chunk the clocks place at [start]: where it is read from. True
     * when the cursor moved there, false when it followed on.
     */
    fun place(start: Long): Boolean {
        val strayed = if (at == UNPLACED) Long.MAX_VALUE else kotlin.math.abs(start - at)
        if (strayed > SLACK) {
            settling = SETTLING
        } else if (settling <= 0 || strayed <= SETTLED) {
            return false
        }
        at = start
        return true
    }

    /** The chunk of [length] samples was read. */
    fun advance(length: Int) {
        at += length
        if (settling > 0) settling -= length
    }

    companion object {
        const val UNPLACED = Long.MIN_VALUE

        /**
         * How far a chunk's place by the clock may stray from where the last
         * chunk ended and still follow on from it. A track's position comes in
         * mixer-sized steps a few milliseconds apart: jumping on each of them
         * would cut the reference into pieces the canceller cannot follow.
         */
        const val SLACK = EchoReference.RATE * 10 / 1000

        /** How long after a fresh place the cursor still follows the clocks closely, 500 ms. */
        const val SETTLING = EchoReference.RATE / 2

        /** How far the clocks may stray while settling, 2 ms. */
        const val SETTLED = EchoReference.RATE * 2 / 1000
    }
}
