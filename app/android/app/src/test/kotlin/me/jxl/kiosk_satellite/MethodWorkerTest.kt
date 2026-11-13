package me.jxl.kiosk_satellite

import android.app.Application
import android.os.Looper
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.LooperMode

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, application = Application::class, sdk = [28])
@LooperMode(LooperMode.Mode.PAUSED)
class MethodWorkerTest {
    private class Reply : MethodChannel.Result {
        var calls = 0
        var value: Any? = null
        var error: String? = null
        override fun success(result: Any?) {
            assertSame(Looper.getMainLooper(), Looper.myLooper())
            calls++
            value = result
        }
        override fun error(code: String, message: String?, details: Any?) {
            assertSame(Looper.getMainLooper(), Looper.myLooper())
            calls++
            error = code
        }
        override fun notImplemented() = fail("Unexpected reply")
    }

    @Test fun overloadAndReadFailuresReplyOnceAndAllowAnotherRead() {
        val worker = MethodWorker("test-query")
        val entered = CountDownLatch(1)
        val release = CountDownLatch(1)
        val first = Reply()
        val second = Reply()
        try {
            worker.read(first) { entered.countDown(); release.await(); 42 }
            assertTrue(entered.await(3, TimeUnit.SECONDS))
            worker.read(second) { throw IllegalStateException("read failed") }
            repeat(100) {
                val busy = Reply()
                worker.read(busy) { fail("Rejected operation ran") }
                assertEquals("busy", busy.error)
                assertEquals(1, busy.calls)
            }
            release.countDown()
            val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(3)
            while (second.calls == 0 && System.nanoTime() < deadline) {
                shadowOf(Looper.getMainLooper()).idle()
                Thread.sleep(5)
            }
            assertEquals(42, first.value)
            assertEquals(1, first.calls)
            assertEquals("read_failed", second.error)
            assertEquals(1, second.calls)
            val next = Reply()
            worker.read(next) { null }
            val retryDeadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(3)
            while (next.calls == 0 && System.nanoTime() < retryDeadline) {
                shadowOf(Looper.getMainLooper()).idle()
                Thread.sleep(5)
            }
            assertEquals(1, next.calls)
            assertNull(next.error)
        } finally {
            release.countDown()
            worker.shutdown()
        }
    }

    private fun idleUntil(condition: () -> Boolean) {
        val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(3)
        while (!condition() && System.nanoTime() < deadline) {
            shadowOf(Looper.getMainLooper()).idle()
            Thread.sleep(5)
        }
        assertTrue(condition())
    }

    @Test fun sharedReadAnswersABurstWithOneLaterReadAndNeverRunsOnTheCaller() {
        val entered = CountDownLatch(1)
        val release = CountDownLatch(1)
        val reads = java.util.concurrent.atomic.AtomicInteger()
        val main = Thread.currentThread()
        val shared = SharedRead("test-shared") {
            assertNotSame(main, Thread.currentThread())
            val read = reads.incrementAndGet()
            if (read == 1) { entered.countDown(); release.await() }
            if (read == 3) throw IllegalStateException("read failed")
            read
        }
        try {
            val first = Reply()
            shared.read(first)
            assertTrue(entered.await(3, TimeUnit.SECONDS))
            // Asked while the first read is stuck: none is refused, and all
            // of them share the one read that starts after it.
            val burst = List(100) { Reply().also(shared::read) }
            assertEquals(0, first.calls)
            assertTrue(burst.all { it.calls == 0 })
            release.countDown()
            idleUntil { burst.all { it.calls == 1 } }
            assertEquals(1, first.value)
            assertEquals(1, first.calls)
            assertTrue(burst.all { it.value == 2 && it.error == null })
            assertEquals(2, reads.get())
            // A read that throws answers null, and the next read still runs.
            val failed = Reply()
            shared.read(failed)
            idleUntil { failed.calls == 1 }
            assertNull(failed.value)
            assertNull(failed.error)
            val next = Reply()
            shared.read(next)
            idleUntil { next.calls == 1 }
            assertEquals(4, next.value)
        } finally {
            release.countDown()
            shared.shutdown()
        }
    }
}
