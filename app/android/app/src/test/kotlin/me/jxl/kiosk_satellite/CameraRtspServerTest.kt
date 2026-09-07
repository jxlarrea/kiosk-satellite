package me.jxl.kiosk_satellite

import org.junit.Test
import org.junit.Assert.*
import java.net.Socket
import java.io.BufferedInputStream
import java.security.MessageDigest
import java.util.Base64
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit

class CameraRtspServerTest {
    private class Peer(port: Int) : AutoCloseable {
        private val socket = Socket("127.0.0.1", port).apply { soTimeout = 3000 }
        private val input = BufferedInputStream(socket.getInputStream())
        private var seq = 0
        val uri = "rtsp://127.0.0.1:$port/camera"
        fun request(method: String, headers: String = "", target: String = uri): String {
            socket.getOutputStream().write("$method $target RTSP/1.0\r\nCSeq: ${++seq}\r\n$headers\r\n".toByteArray())
            val response = StringBuilder()
            var length = 0
            while (true) {
                val line = StringBuilder()
                while (true) {
                    val b = input.read()
                    check(b >= 0)
                    if (b == 10) break
                    if (b != 13) line.append(b.toChar())
                }
                response.append(line).append('\n')
                if (line.startsWith("Content-Length:")) length = line.toString().substringAfter(':').trim().toInt()
                if (line.isEmpty()) break
            }
            repeat(length) { response.append(input.read().toChar()) }
            return response.toString()
        }
        fun packet(): Pair<Int, ByteArray> {
            assertEquals(36, input.read())
            val channel = input.read()
            val size = input.read() * 256 + input.read()
            val bytes = ByteArray(size)
            for (i in bytes.indices) bytes[i] = input.read().also { check(it >= 0) }.toByte()
            return channel to bytes
        }
        override fun close() { socket.close() }
    }

    private fun server(demand: LinkedBlockingQueue<Boolean>, auth: Boolean = false) = CameraRtspServer(
        0, if (auth) "viewer" else null, "secret", { Base64.getEncoder().encodeToString(it) },
        { demand.offer(it) }, {},
    )
    private val sps = byteArrayOf(0x67, 0x42, 0, 0x1f)
    private val pps = byteArrayOf(0x68, 1, 2)
    private fun md5(s: String) = MessageDigest.getInstance("MD5").digest(s.toByteArray())
        .joinToString("") { "%02x".format(it.toInt() and 255) }

    @Test fun authenticationPrecedesCameraDemand() {
        val demand = LinkedBlockingQueue<Boolean>()
        val server = server(demand, true)
        try {
            Peer(server.localPort).use { peer ->
                val challenge = peer.request("DESCRIBE")
                assertTrue(challenge.startsWith("RTSP/1.0 401"))
                assertNull(demand.poll(100, TimeUnit.MILLISECONDS))
                val nonce = Regex("nonce=\"([^\"]+)\"").find(challenge)!!.groupValues[1]
                val response = md5("${md5("viewer:Kiosk Satellite:secret")}:$nonce:${md5("DESCRIBE:${peer.uri}")}")
                server.config(listOf(sps, pps))
                val ok = peer.request("DESCRIBE", "Authorization: Digest username=\"viewer\", realm=\"Kiosk Satellite\", nonce=\"$nonce\", uri=\"${peer.uri}\", response=\"$response\"\r\n")
                assertTrue(ok.startsWith("RTSP/1.0 200"))
                assertTrue(ok.contains("H264/90000"))
                assertEquals(true, demand.poll(1, TimeUnit.SECONDS))
            }
            assertEquals(false, demand.poll(4, TimeUnit.SECONDS))
        } finally { server.close() }
    }

    @Test fun tcpTransportSessionValidationAndFragmentedKeyframe() {
        val demand = LinkedBlockingQueue<Boolean>()
        val server = server(demand)
        try {
            Peer(server.localPort).use { peer ->
                assertTrue(peer.request("DESCRIBE", target = peer.uri + "-missing").contains("404 Not Found"))
                assertNull(demand.poll())
                assertTrue(peer.request("PLAY").contains("454 Session Not Found"))
                server.config(listOf(sps, pps))
                assertTrue(peer.request("DESCRIBE", "User-Agent: Test Player/1.0\r\n").startsWith("RTSP/1.0 200"))
                val connected = server.clientDetails.single()
                assertEquals("127.0.0.1", connected["ip"])
                assertTrue((connected["port"] as Int) > 0)
                assertEquals("Test Player/1.0", connected["userAgent"])
                assertEquals("TCP", connected["transport"])
                assertEquals(false, connected["playing"])
                assertTrue((connected["connectedSeconds"] as Long) >= 0)
                assertTrue(peer.request("SETUP", "Transport: RTP/AVP;unicast\r\n", peer.uri + "/trackID=0").contains("461 Unsupported Transport"))
                val setup = peer.request("SETUP", "Transport: RTP/AVP/TCP;unicast;interleaved=2-3\r\n", peer.uri + "/trackID=0")
                val session = Regex("Session: ([^;\\n]+)").find(setup)!!.groupValues[1]
                assertTrue(peer.request("PLAY", "Session: $session\r\n").startsWith("RTSP/1.0 200"))
                assertEquals(true, server.clientDetails.single()["playing"])
                assertEquals(connected["id"], server.clientDetails.single()["id"])
                assertEquals("Test Player/1.0", server.clientDetails.single()["userAgent"])
                // A joining viewer receives nothing until an IDR arrives.
                server.frame(listOf(byteArrayOf(0x41, 1, 2)), 1_000_000)
                val key = ByteArray(3500) { (it % 251).toByte() }.also { it[0] = 0x65 }
                server.frame(listOf(key), 1_100_000)
                val report = peer.packet()
                assertEquals(3, report.first)
                assertEquals(200, report.second[1].toInt() and 255)
                val units = mutableListOf<ByteArray>()
                val reconstructed = java.io.ByteArrayOutputStream()
                var markers = 0
                repeat(5) {
                    val (channel, packet) = peer.packet()
                    assertEquals(2, channel)
                    if (packet[1].toInt() and 128 != 0) markers++
                    assertEquals(99000, java.nio.ByteBuffer.wrap(packet, 4, 4).int)
                    val payload = packet.copyOfRange(12, packet.size)
                    if (payload[0].toInt() and 31 == 28) {
                        if (payload[1].toInt() and 128 != 0) reconstructed.write((payload[0].toInt() and 0xe0) or (payload[1].toInt() and 31))
                        reconstructed.write(payload, 2, payload.size - 2)
                    } else units.add(payload)
                }
                assertEquals(1, markers)
                assertArrayEquals(sps, units[0])
                assertArrayEquals(pps, units[1])
                assertArrayEquals(key, reconstructed.toByteArray())
                assertTrue(peer.request("TEARDOWN", "Session: $session\r\n").startsWith("RTSP/1.0 200"))
            }
            assertEquals(true, demand.poll(1, TimeUnit.SECONDS))
            assertEquals(false, demand.poll(4, TimeUnit.SECONDS))
            assertTrue(server.clientDetails.isEmpty())
        } finally { server.close() }
    }

    @Test fun lastViewerReleasesDemandAndPortCanBeReused() {
        val demand = LinkedBlockingQueue<Boolean>()
        val server = server(demand)
        val port = server.localPort
        try {
            server.config(listOf(sps, pps))
            val first = Peer(port)
            val second = Peer(port)
            first.request("DESCRIBE")
            second.request("DESCRIBE")
            assertEquals(true, demand.poll(1, TimeUnit.SECONDS))
            first.close()
            assertNull(demand.poll(2200, TimeUnit.MILLISECONDS))
            second.close()
            assertEquals(false, demand.poll(4, TimeUnit.SECONDS))
        } finally { server.close() }
        CameraRtspServer(port, null, "", { "" }, {}, {}).close()
    }
    @Test fun repeatedRestartClosesAcceptedClientsAndReleasesThePort() {
        val demand = LinkedBlockingQueue<Boolean>()
        var server = server(demand)
        val port = server.localPort
        try {
            repeat(25) {
                val peer = Peer(port)
                server.config(listOf(sps, pps))
                peer.request("DESCRIBE")
                server.close()
                server = CameraRtspServer(port, null, "", { Base64.getEncoder().encodeToString(it) }, {}, {})
                peer.close()
            }
        } finally { server.close() }
    }

}
