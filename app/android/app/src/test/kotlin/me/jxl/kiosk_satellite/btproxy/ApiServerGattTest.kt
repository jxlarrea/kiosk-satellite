package me.jxl.kiosk_satellite.btproxy

import java.io.DataInputStream
import java.net.Socket
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * GATT message sequencing over a real socket with a scripted backend: the
 * connect/slot accounting, per-session routing, services batching with the
 * done marker last, and the read/write/notify round trips. The Android
 * engine is deliberately absent; these tests pin the protocol behavior the
 * engine must feed.
 */
class ApiServerGattTest {

    private val identity = ProxyIdentity(
        name = "kiosk-satellite-test",
        friendlyName = "Test",
        macAddress = "02:11:22:33:44:55",
        esphomeVersion = "2026.8.0",
        model = "Test",
        manufacturer = "KS",
        projectName = "kiosk_satellite.bluetooth_proxy",
        projectVersion = "1.0",
    )

    private var server: ApiServer? = null
    private var client: Client? = null

    @AfterTest
    fun tearDown() {
        client?.close()
        server?.stop()
    }

    private fun start(gatt: ScriptedGatt): ApiServer {
        val backend = object : ScannerBackend {
            override fun onScanDemand(mode: ScannerMode) {}
            override fun onScanRelease() {}
        }
        val s = ApiServer(identity, "02:AA:BB:CC:DD:EE", 0, null, backend,
            log = {}, gatt = gatt)
        gatt.server = s
        s.start()
        server = s
        return s
    }

    private class Client(port: Int) {
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
            check(input.read() == 0x00)
            val length = readVarint()
            val type = readVarint()
            val payload = ByteArray(length)
            input.readFully(payload)
            return ApiFrame(type, payload)
        }

        fun readUntil(type: Int): ApiFrame {
            repeat(30) {
                val frame = read()
                if (frame.type == type) return frame
            }
            error("type $type never arrived")
        }

        fun close() = runCatching { socket.close() }

        private fun readVarint(): Int {
            var shift = 0
            var result = 0
            while (true) {
                val b = input.read()
                check(b >= 0)
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

    private fun connectClient(s: ApiServer): Client =
        Client(s.boundPort).also {
            client = it
            it.send(Msg.HELLO_REQUEST)
            it.read()
        }

    private fun deviceRequest(address: Long, type: Int): ByteArray = ProtoWriter().run {
        varint(1, address)
        varint(2, type)
        toByteArray()
    }

    @Test
    fun deviceInfoAdvertisesConnectionFlags() {
        val c = connectClient(start(ScriptedGatt()))
        c.send(Msg.DEVICE_INFO_REQUEST)
        var flags = 0
        ProtoReader(c.read().payload).let { r ->
            while (r.next()) if (r.field == 15) flags = r.asInt()
        }
        assertEquals(BtProxyFeature.WITH_CONNECTIONS, flags)
    }

    @Test
    fun connectDeliversResponseServicesAndRoundTrips() {
        val gatt = ScriptedGatt()
        val c = connectClient(start(gatt))

        c.send(Msg.BT_DEVICE_REQUEST,
            deviceRequest(0x1122L, BtDeviceRequestType.CONNECT_V3_WITHOUT_CACHE))
        val connection = c.readUntil(Msg.BT_DEVICE_CONNECTION_RESPONSE)
        var connected = false; var mtu = 0
        ProtoReader(connection.payload).let { r ->
            while (r.next()) when (r.field) {
                2 -> connected = r.asBool()
                3 -> mtu = r.asInt()
            }
        }
        assertTrue(connected)
        assertEquals(247, mtu)
        assertTrue(gatt.calls.contains("connect:4386:cache=false"))

        // Services arrive as one message per service, done strictly last.
        c.send(Msg.GATT_GET_SERVICES_REQUEST, ProtoWriter().run {
            varint(1, 0x1122L); toByteArray()
        })
        val first = c.readUntil(Msg.GATT_GET_SERVICES_RESPONSE)
        assertTrue(first.payload.isNotEmpty())
        val second = c.read()
        assertEquals(Msg.GATT_GET_SERVICES_RESPONSE, second.type)
        assertEquals(Msg.GATT_GET_SERVICES_DONE_RESPONSE, c.read().type)

        // Read round trip.
        c.send(Msg.GATT_READ_REQUEST, ProtoWriter().run {
            varint(1, 0x1122L); varint(2, 2); toByteArray()
        })
        val read = c.readUntil(Msg.GATT_READ_RESPONSE)
        var data = ByteArray(0)
        ProtoReader(read.payload).let { r ->
            while (r.next()) if (r.field == 3) data = r.asBytes()
        }
        assertEquals(0x64, data.single().toInt())

        // Notify enable: ack first, then data, in that order.
        c.send(Msg.GATT_NOTIFY_REQUEST, ProtoWriter().run {
            varint(1, 0x1122L); varint(2, 2); bool(3, true); toByteArray()
        })
        assertEquals(Msg.GATT_NOTIFY_RESPONSE, c.readUntil(Msg.GATT_NOTIFY_RESPONSE).type)
        assertEquals(Msg.GATT_NOTIFY_DATA_RESPONSE, c.read().type)
    }

    @Test
    fun slotBudgetRefusesTheThirdConnection() {
        val gatt = ScriptedGatt()
        val c = connectClient(start(gatt))
        c.send(Msg.BT_DEVICE_REQUEST,
            deviceRequest(1, BtDeviceRequestType.CONNECT_V3_WITH_CACHE))
        c.readUntil(Msg.BT_DEVICE_CONNECTION_RESPONSE)
        c.send(Msg.BT_DEVICE_REQUEST,
            deviceRequest(2, BtDeviceRequestType.CONNECT_V3_WITH_CACHE))
        c.readUntil(Msg.BT_DEVICE_CONNECTION_RESPONSE)

        c.send(Msg.BT_DEVICE_REQUEST,
            deviceRequest(3, BtDeviceRequestType.CONNECT_V3_WITH_CACHE))
        val refused = c.readUntil(Msg.BT_DEVICE_CONNECTION_RESPONSE)
        // Proto3 omits false booleans: absence of field 2 IS the refusal.
        var address = 0L; var connected = false; var error = 0
        ProtoReader(refused.payload).let { r ->
            while (r.next()) when (r.field) {
                1 -> address = r.asLong()
                2 -> connected = r.asBool()
                4 -> error = r.asInt()
            }
        }
        assertEquals(3L, address)
        assertEquals(false, connected)
        assertEquals(0x7F, error)
        // The backend never saw the refused address.
        assertTrue(gatt.calls.none { it.startsWith("connect:3") })
    }

    @Test
    fun rssiFloorRefusesWeakDevicesButNotUnknownOnes() {
        val gatt = ScriptedGatt()
        val backend = object : ScannerBackend {
            override fun onScanDemand(mode: ScannerMode) {}
            override fun onScanRelease() {}
        }
        // Address 1 is heard at -92 (below the -85 floor), address 2 at
        // -60, address 3 was never heard at all.
        val s = ApiServer(identity, "02:AA:BB:CC:DD:EE", 0, null, backend,
            log = {}, gatt = gatt, minConnectRssi = -85,
            rssiOf = { addr -> mapOf(1L to -92, 2L to -60)[addr] })
        gatt.server = s
        s.start()
        server = s
        val c = connectClient(s)

        c.send(Msg.BT_DEVICE_REQUEST,
            deviceRequest(1, BtDeviceRequestType.CONNECT_V3_WITH_CACHE))
        val refused = c.readUntil(Msg.BT_DEVICE_CONNECTION_RESPONSE)
        var connected = false; var error = 0
        ProtoReader(refused.payload).let { r ->
            while (r.next()) when (r.field) {
                2 -> connected = r.asBool()
                4 -> error = r.asInt()
            }
        }
        assertEquals(false, connected)
        assertEquals(133, error)
        assertTrue(gatt.calls.none { it.startsWith("connect:1") })

        // Strong and never-heard devices both pass the gate.
        c.send(Msg.BT_DEVICE_REQUEST,
            deviceRequest(2, BtDeviceRequestType.CONNECT_V3_WITH_CACHE))
        c.readUntil(Msg.BT_DEVICE_CONNECTION_RESPONSE)
        c.send(Msg.BT_DEVICE_REQUEST,
            deviceRequest(3, BtDeviceRequestType.CONNECT_V3_WITH_CACHE))
        c.readUntil(Msg.BT_DEVICE_CONNECTION_RESPONSE)
        assertTrue(gatt.calls.any { it.startsWith("connect:2") })
        assertTrue(gatt.calls.any { it.startsWith("connect:3") })
    }

    @Test
    fun connectionsFreeTracksAllocations() {
        val gatt = ScriptedGatt()
        val c = connectClient(start(gatt))
        c.send(Msg.SUBSCRIBE_BT_CONNECTIONS_FREE_REQUEST)
        var free = -1; var limit = -1
        ProtoReader(c.readUntil(Msg.BT_CONNECTIONS_FREE_RESPONSE).payload).let { r ->
            while (r.next()) when (r.field) {
                1 -> free = r.asInt()
                2 -> limit = r.asInt()
            }
        }
        assertEquals(2, free)
        assertEquals(2, limit)

        c.send(Msg.BT_DEVICE_REQUEST,
            deviceRequest(9, BtDeviceRequestType.CONNECT_V3_WITH_CACHE))
        // Allocation broadcast comes before the connect resolves.
        var sawAllocated = false
        for (attempt in 0 until 10) {
            val frame = c.read()
            if (frame.type != Msg.BT_CONNECTIONS_FREE_RESPONSE) continue
            var f = -1; var allocated = 0L
            ProtoReader(frame.payload).let { r ->
                while (r.next()) when (r.field) {
                    1 -> f = r.asInt()
                    3 -> allocated = r.asLong()
                }
            }
            if (f == 1 && allocated == 9L) { sawAllocated = true; break }
        }
        assertTrue(sawAllocated)
    }
}
