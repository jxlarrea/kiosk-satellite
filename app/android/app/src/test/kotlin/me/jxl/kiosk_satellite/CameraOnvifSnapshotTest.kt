package me.jxl.kiosk_satellite

import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import kotlin.concurrent.thread
import org.junit.Assert.*
import org.junit.Test

class CameraOnvifSnapshotTest {
    private var now = 0L

    @Test fun overlappingRequestsShareOneCapture() {
        val captures = AtomicInteger()
        val started = CountDownLatch(1)
        var finish: ((ByteArray?, String?) -> Unit)? = null
        val snapshot = CameraOnvifSnapshot(null, "", { done -> captures.incrementAndGet(); finish = done; started.countDown() }, { now })
        val results = java.util.concurrent.ConcurrentLinkedQueue<CameraOnvifSnapshot.Result>()
        val first = thread { results.add(snapshot.take(2000)) }
        assertTrue(started.await(2, TimeUnit.SECONDS))
        val second = thread { results.add(snapshot.take(2000)) }
        Thread.sleep(100)
        finish!!(byteArrayOf(1, 2), null)
        first.join(); second.join()
        assertEquals(1, captures.get())
        assertEquals(2, results.size)
        results.forEach { assertArrayEquals(byteArrayOf(1, 2), it.jpeg) }
    }

    @Test fun aFreshFrameAnswersWithoutAnotherCapture() {
        val captures = AtomicInteger()
        val snapshot = CameraOnvifSnapshot(null, "", { done -> done(byteArrayOf(captures.incrementAndGet().toByte()), null) }, { now })
        assertArrayEquals(byteArrayOf(1), snapshot.take().jpeg)
        now += 900_000_000L
        assertArrayEquals(byteArrayOf(1), snapshot.take().jpeg)
        now += 200_000_000L
        assertArrayEquals(byteArrayOf(2), snapshot.take().jpeg)
    }

    @Test fun failuresAreReportedAndRetriedAfterASecond() {
        val captures = AtomicInteger()
        val snapshot = CameraOnvifSnapshot(null, "", { done -> captures.incrementAndGet(); done(null, "camera busy") }, { now })
        assertEquals("camera busy", snapshot.take().error)
        assertNull(snapshot.take().jpeg)
        assertEquals(1, captures.get())
        now += 1_100_000_000L
        snapshot.take()
        assertEquals(2, captures.get())
        val throwing = CameraOnvifSnapshot(null, "", { throw IllegalStateException("no camera") }, { now })
        assertEquals("no camera", throwing.take().error)
    }

    @Test fun aCaptureThatNeverAnswersTimesOutAndIsAbandoned() {
        val captures = AtomicInteger()
        val snapshot = CameraOnvifSnapshot(null, "", { captures.incrementAndGet() }, { now })
        assertNotNull(snapshot.take(50).error)
        snapshot.take(50)
        assertEquals(1, captures.get())
        now += 30_000_000_000L
        snapshot.take(50)
        assertEquals(2, captures.get())
    }

    @Test fun noncesExpireAndAreReportedStale() {
        val snapshot = CameraOnvifSnapshot("viewer", "secret", { it(byteArrayOf(1), null) }, { now })
        val nonce = Regex("nonce=\"([^\"]+)\"").find(snapshot.challenge())!!.groupValues[1]
        fun header(nonce: String): String {
            fun md5(text: String) = java.security.MessageDigest.getInstance("MD5").digest(text.toByteArray()).joinToString("") { "%02x".format(it) }
            val response = md5("${md5("viewer:Kiosk Satellite:secret")}:$nonce:${md5("GET:/onvif/snapshot")}")
            return "Digest username=\"viewer\", realm=\"Kiosk Satellite\", nonce=\"$nonce\", uri=\"/onvif/snapshot\", response=\"$response\""
        }
        assertTrue(snapshot.authorized(header(nonce), "GET", "/onvif/snapshot"))
        assertFalse(snapshot.authorized(header(nonce), "GET", "/onvif/other"))
        assertFalse(snapshot.authorized(null, "GET", "/onvif/snapshot"))
        assertFalse(snapshot.stale(header(nonce)))
        now += 301_000_000_000L
        assertFalse(snapshot.authorized(header(nonce), "GET", "/onvif/snapshot"))
        assertTrue(snapshot.stale(header(nonce)))
        assertTrue(snapshot.challenge(stale = true).endsWith("stale=true"))
        val other = CameraOnvifSnapshot("viewer", "secret", { it(byteArrayOf(1), null) }, { now })
        assertFalse(other.authorized(header(nonce), "GET", "/onvif/snapshot"))
        assertTrue(CameraOnvifSnapshot(null, "", { it(null, null) }).authorized(null, "GET", "/onvif/snapshot"))
    }
}
