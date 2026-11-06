package me.jxl.kiosk_satellite

import org.junit.Assert.assertNull
import org.junit.Test
import java.util.concurrent.atomic.AtomicBoolean

class EchoReferenceTest {
    private object Player : EchoReference.Source {
        override fun take(): ShortArray? = null
    }

    /**
     * Kotlin's toSet reads a one item list by size and then get(0), so a live
     * list that lost its item in between threw on the mic thread and took
     * the app down.
     */
    @Test
    fun aSourceLeavingWhileTheCancellerReadsDoesNotThrow() {
        val running = AtomicBoolean(true)
        val churn = Thread {
            while (running.get()) {
                EchoReference.add(Player)
                EchoReference.remove(Player)
            }
        }.apply { start() }
        var thrown: Throwable? = null
        val until = System.nanoTime() + 5_000_000_000L
        try {
            while (thrown == null && System.nanoTime() < until) {
                try {
                    EchoReference.sources().toSet()
                } catch (e: IndexOutOfBoundsException) {
                    thrown = e
                }
            }
        } finally {
            running.set(false)
            churn.join()
            EchoReference.remove(Player)
        }
        assertNull(thrown)
    }
}
