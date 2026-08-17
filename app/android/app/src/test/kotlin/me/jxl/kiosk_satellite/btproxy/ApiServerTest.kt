package me.jxl.kiosk_satellite.btproxy

import java.io.DataInputStream
import java.net.Socket
import java.util.concurrent.CopyOnWriteArrayList
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * Session-level tests over a real localhost socket with a scripted plaintext
 * client. Plaintext keeps the frames inspectable; the Noise path is covered
 * by [NoiseVectorTest] (crypto) and the aioesphomeapi E2E test (full stack).
 */
class ApiServerTest {
    private class RecordingBackend : ScannerBackend {
        val calls = CopyOnWriteArrayList<String>()
        override fun onScanDemand(mode: ScannerMode) { calls.add("demand:$mode") }
        override fun onScanRelease() { calls.add("release") }
    }

    private val identity = ProxyIdentity(
        name = "kiosk-satellite-test",
        friendlyName = "Test Kiosk",
        macAddress = "02:11:22:33:44:55",
        esphomeVersion = "2026.8.0",
        model = "Test",
        manufacturer = "KS",
        projectName = "kiosk_satellite.bluetooth_proxy",
        projectVersion = "1.0",
    )

    private var server: ApiServer? = null
    private var client: PlainClient? = null

    @AfterTest
    fun tearDown() {
        client?.close()
        server?.stop()
    }

    private fun startServer(backend: ScannerBackend, psk: ByteArray? = null): ApiServer =
        ApiServer(identity, "02:AA:BB:CC:DD:EE", 0, psk, backend, log = {}).also {
            it.start()
            server = it
        }

    private class PlainClient(port: Int) {
        private val socket = Socket("127.0.0.1", port).apply { soTimeout = 5_000 }
        private val input = DataInputStream(socket.getInputStream())
        private val output = socket.getOutputStream()

        fun send(type: Int, payload: ByteArray = ByteArray(0)) {
            val head = java.io.ByteArrayOutputStream()
            head.write(0x00)
            writeVarint(head, payload.size)
            writeVarint(head, type)
            head.write(payload)
            output.write(head.toByteArray())
            output.flush()
        }

        fun read(): ApiFrame {
            check(input.read() == 0x00) { "bad preamble" }
            val length = readVarint()
            val type = readVarint()
            val payload = ByteArray(length)
            input.readFully(payload)
            return ApiFrame(type, payload)
        }

        /** Reads frames until one of [type] arrives (skipping others). */
        fun readUntil(type: Int): ApiFrame {
            repeat(20) {
                val frame = read()
                if (frame.type == type) return frame
            }
            error("frame type $type never arrived")
        }

        fun setTimeout(ms: Int) { socket.soTimeout = ms }

        fun close() = runCatching { socket.close() }

        private fun readVarint(): Int {
            var shift = 0
            var result = 0
            while (true) {
                val b = input.read()
                check(b >= 0) { "eof" }
                result = result or ((b and 0x7F) shl shift)
                if (b and 0x80 == 0) return result
                shift += 7
            }
        }

        private fun writeVarint(out: java.io.ByteArrayOutputStream, value: Int) {
            var v = value
            while (true) {
                val bits = v and 0x7F
                v = v ushr 7
                if (v == 0) { out.write(bits); return }
                out.write(bits or 0x80)
            }
        }
    }

    private fun connect(server: ApiServer): PlainClient =
        PlainClient(server.boundPort).also { client = it }

    @Test
    fun helloConnectDeviceInfo() {
        val backend = RecordingBackend()
        val c = connect(startServer(backend))

        c.send(Msg.HELLO_REQUEST, ProtoWriter().run {
            string(1, "test client"); varint(2, 1); varint(3, 10); toByteArray()
        })
        val hello = c.read()
        assertEquals(Msg.HELLO_RESPONSE, hello.type)
        var major = 0; var minor = 0; var name = ""
        ProtoReader(hello.payload).let { r ->
            while (r.next()) when (r.field) {
                1 -> major = r.asInt()
                2 -> minor = r.asInt()
                4 -> name = r.asString()
            }
        }
        assertEquals(1, major)
        assertEquals(10, minor)
        assertEquals("kiosk-satellite-test", name)

        c.send(Msg.CONNECT_REQUEST)
        assertEquals(Msg.CONNECT_RESPONSE, c.read().type)

        c.send(Msg.DEVICE_INFO_REQUEST)
        val info = c.read()
        assertEquals(Msg.DEVICE_INFO_RESPONSE, info.type)
        var flags = 0; var legacy = 0; var btMac = ""
        ProtoReader(info.payload).let { r ->
            while (r.next()) when (r.field) {
                11 -> legacy = r.asInt()
                15 -> flags = r.asInt()
                18 -> btMac = r.asString()
            }
        }
        // Passive-only promise: passive scan + raw advertisements + state/mode
        // and nothing else, so HA never routes GATT work here.
        assertEquals(BtProxyFeature.V1, flags)
        assertEquals(0, flags and BtProxyFeature.ACTIVE_CONNECTIONS)
        assertEquals(5, legacy)
        assertEquals("02:AA:BB:CC:DD:EE", btMac)

        c.send(Msg.LIST_ENTITIES_REQUEST)
        assertEquals(Msg.LIST_ENTITIES_DONE_RESPONSE, c.read().type)
    }

    @Test
    fun subscribeForwardsAdvertisementsAndDedupsRssiOnly() {
        val backend = RecordingBackend()
        val s = startServer(backend)
        val c = connect(s)
        c.send(Msg.HELLO_REQUEST); c.read()

        c.send(Msg.SUBSCRIBE_BLE_ADVERTISEMENTS_REQUEST, ProtoWriter().run {
            varint(1, 1); toByteArray()
        })
        // Scanner state replay arrives first, then the scan demand lands.
        assertEquals(Msg.BT_SCANNER_STATE_RESPONSE, c.read().type)
        waitFor { backend.calls == listOf("demand:PASSIVE") }

        val advData = byteArrayOf(0x02, 0x01, 0x06, 0x03, 0x03, 0xD2.toByte(), 0xFC.toByte())
        s.publishAdvertisement(BleAdvertisement(0x112233445566L, -63, 0, advData))
        val batch = c.readUntil(Msg.BLE_RAW_ADVERTISEMENTS_RESPONSE)
        var address = 0L; var rssiRaw = 0L; var data = ByteArray(0)
        ProtoReader(batch.payload).let { outer ->
            assertTrue(outer.next())
            val inner = ProtoReader(outer.asBytes())
            while (inner.next()) when (inner.field) {
                1 -> address = inner.asLong()
                2 -> rssiRaw = inner.asLong()
                4 -> data = inner.asBytes()
            }
        }
        assertEquals(0x112233445566L, address)
        assertEquals(-63L, (rssiRaw ushr 1) xor -(rssiRaw and 1L))
        assertContentEquals(advData, data)

        // Same payload again immediately: suppressed (RSSI refresh interval
        // has not elapsed), so no frame should arrive.
        s.publishAdvertisement(BleAdvertisement(0x112233445566L, -70, 0, advData))
        c.setTimeout(400)
        val suppressed = runCatching { c.read() }.isFailure
        assertTrue(suppressed, "unchanged payload inside refresh window must not be forwarded")
        c.setTimeout(5_000)

        // Changed payload: forwarded at once.
        val changed = advData.copyOf().also { it[2] = 0x04 }
        s.publishAdvertisement(BleAdvertisement(0x112233445566L, -70, 0, changed))
        assertEquals(Msg.BLE_RAW_ADVERTISEMENTS_RESPONSE,
            c.readUntil(Msg.BLE_RAW_ADVERTISEMENTS_RESPONSE).type)
    }

    @Test
    fun setModeMatchingModeAcksWithoutScannerChurn() {
        val backend = RecordingBackend()
        val s = startServer(backend)
        val c = connect(s)
        c.send(Msg.HELLO_REQUEST); c.read()
        c.send(Msg.SUBSCRIBE_BLE_ADVERTISEMENTS_REQUEST)
        c.read() // scanner state
        waitFor { backend.calls.size == 1 }

        // HA sends set-mode right after subscribing (its configured mode).
        // Matching mode: pure ack, no new backend demand: this exact exchange
        // put earlier Android proxies into an endless restart loop.
        c.send(Msg.BT_SCANNER_SET_MODE_REQUEST, ProtoWriter().run {
            varint(1, ScannerMode.PASSIVE.wire); toByteArray()
        })
        assertEquals(Msg.BT_SCANNER_STATE_RESPONSE, c.read().type)
        assertEquals(listOf("demand:PASSIVE"), backend.calls)

        // Different mode: one new demand with the new mode, no release.
        c.send(Msg.BT_SCANNER_SET_MODE_REQUEST, ProtoWriter().run {
            varint(1, ScannerMode.ACTIVE.wire); toByteArray()
        })
        waitFor { backend.calls == listOf("demand:PASSIVE", "demand:ACTIVE") }

        c.send(Msg.UNSUBSCRIBE_BLE_ADVERTISEMENTS_REQUEST)
        waitFor { backend.calls.last() == "release" }
    }

    @Test
    fun scannerStateChangeIsBroadcastToSubscribers() {
        val backend = RecordingBackend()
        val s = startServer(backend)
        val c = connect(s)
        c.send(Msg.HELLO_REQUEST); c.read()
        c.send(Msg.SUBSCRIBE_BLE_ADVERTISEMENTS_REQUEST)
        c.read()

        s.reportScannerState(ScannerState.RUNNING, ScannerMode.PASSIVE)
        val state = c.readUntil(Msg.BT_SCANNER_STATE_RESPONSE)
        var wireState = 0
        ProtoReader(state.payload).let { r ->
            while (r.next()) if (r.field == 1) wireState = r.asInt()
        }
        assertEquals(ScannerState.RUNNING.wire, wireState)
    }

    @Test
    fun plaintextClientOnNoiseEndpointGetsEncryptionHint() {
        val backend = RecordingBackend()
        val s = startServer(backend, psk = ByteArray(32) { it.toByte() })
        val socket = Socket("127.0.0.1", s.boundPort).apply { soTimeout = 5_000 }
        // A plaintext HelloRequest against the encrypted endpoint.
        socket.getOutputStream().apply { write(byteArrayOf(0x00, 0x00, 0x01)); flush() }
        val hint = ByteArray(3)
        DataInputStream(socket.getInputStream()).readFully(hint)
        // The empty Noise hello: aioesphomeapi's plaintext helper turns this
        // into requires-encryption, so HA prompts for the key.
        assertContentEquals(REQUIRES_ENCRYPTION_HINT, hint)
        socket.close()
    }

    @Test
    fun disconnectRequestIsAcknowledged() {
        val backend = RecordingBackend()
        val c = connect(startServer(backend))
        c.send(Msg.HELLO_REQUEST); c.read()
        c.send(Msg.DISCONNECT_REQUEST)
        assertEquals(Msg.DISCONNECT_RESPONSE, c.read().type)
    }

    private fun waitFor(deadlineMs: Long = 3_000, condition: () -> Boolean) {
        val end = System.currentTimeMillis() + deadlineMs
        while (System.currentTimeMillis() < end) {
            if (condition()) return
            Thread.sleep(20)
        }
        assertTrue(condition(), "condition not met within ${deadlineMs}ms")
    }
}
