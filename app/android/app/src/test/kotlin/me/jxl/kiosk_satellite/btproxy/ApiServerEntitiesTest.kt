package me.jxl.kiosk_satellite.btproxy

import java.io.DataInputStream
import java.net.Socket
import java.util.concurrent.CopyOnWriteArrayList
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * The kiosk-entity surface over a real socket: ListEntities descriptions,
 * the states replay on subscribe, live state broadcasts, and command
 * dispatch back out of the hub. Wire-format fidelity beyond field numbers
 * is pinned by the aioesphomeapi E2E test; this one pins the sequencing.
 */
class ApiServerEntitiesTest {

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
    private val commands = CopyOnWriteArrayList<Pair<String, Any?>>()

    private val catalog = listOf(
        EspEntity.Sensor("battery", "Battery", deviceClass = "battery",
            category = 2, unit = "%", stateClass = 1),
        EspEntity.BinarySensor("charging", "Charging",
            deviceClass = "battery_charging", category = 2),
        EspEntity.TextSensor("ipv4", "IP address", category = 2),
        EspEntity.Switch("screensaver", "Screensaver", icon = "mdi:sleep"),
        EspEntity.Number("brightness", "Screen brightness", min = 0f,
            max = 100f, step = 1f, unit = "%", mode = 2, category = 1),
        EspEntity.Select("view", "View", options = listOf("Home", "Cameras")),
        EspEntity.Button("reload", "Reload dashboard"),
    )

    @AfterTest
    fun tearDown() {
        client?.close()
        server?.stop()
    }

    private fun start(): Pair<ApiServer, EntityHub> {
        val backend = object : ScannerBackend {
            override fun onScanDemand(mode: ScannerMode) {}
            override fun onScanRelease() {}
        }
        val hub = EntityHub(catalog) { objectId, value ->
            commands.add(objectId to value)
        }
        val s = ApiServer(identity, "02:AA:BB:CC:DD:EE", 0, null, backend,
            log = {}, entities = hub)
        s.start()
        server = s
        return s to hub
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

    @Test
    fun listEntitiesDescribesTheWholeCatalogThenDone() {
        val (s, _) = start()
        val c = connectClient(s)
        c.send(Msg.LIST_ENTITIES_REQUEST)
        val seen = mutableListOf<ApiFrame>()
        while (true) {
            val frame = c.read()
            if (frame.type == Msg.LIST_ENTITIES_DONE_RESPONSE) break
            seen.add(frame)
        }
        assertEquals(
            listOf(
                Msg.LIST_ENTITIES_SENSOR_RESPONSE,
                Msg.LIST_ENTITIES_BINARY_SENSOR_RESPONSE,
                Msg.LIST_ENTITIES_TEXT_SENSOR_RESPONSE,
                Msg.LIST_ENTITIES_SWITCH_RESPONSE,
                Msg.LIST_ENTITIES_NUMBER_RESPONSE,
                Msg.LIST_ENTITIES_SELECT_RESPONSE,
                Msg.LIST_ENTITIES_BUTTON_RESPONSE,
            ),
            seen.map { it.type },
        )
        // Spot-check the sensor description's fields.
        var objectId = ""; var key = 0; var name = ""; var unit = ""
        var deviceClass = ""; var stateClass = -1; var category = -1
        ProtoReader(seen.first().payload).let { r ->
            while (r.next()) when (r.field) {
                1 -> objectId = r.asString()
                2 -> key = r.asFixed32()
                3 -> name = r.asString()
                6 -> unit = r.asString()
                9 -> deviceClass = r.asString()
                10 -> stateClass = r.asInt()
                13 -> category = r.asInt()
            }
        }
        assertEquals("battery", objectId)
        assertEquals(EspEntity.fnv1a("battery"), key)
        assertEquals("Battery", name)
        assertEquals("%", unit)
        assertEquals("battery", deviceClass)
        assertEquals(1, stateClass)
        assertEquals(2, category)
        // The select carries its options.
        val select = seen[5]
        val options = mutableListOf<String>()
        ProtoReader(select.payload).let { r ->
            while (r.next()) if (r.field == 6) options.add(r.asString())
        }
        assertEquals(listOf("Home", "Cameras"), options)
    }

    @Test
    fun subscribeReplaysKnownStatesAndBroadcastsUpdates() {
        val (s, hub) = start()
        hub.updateState("battery", 87)
        hub.updateState("screensaver", false)
        hub.updateState("ipv4", "192.168.1.5")
        val c = connectClient(s)
        c.send(Msg.SUBSCRIBE_STATES_REQUEST)

        // The replay: every stateful entity reports, set or missing.
        val replay = HashMap<Int, ApiFrame>()
        repeat(6) {
            val frame = c.read()
            replay[frame.type] = frame
        }
        var battery = 0f
        ProtoReader(replay.getValue(Msg.SENSOR_STATE_RESPONSE).payload).let { r ->
            while (r.next()) if (r.field == 2) battery = r.asFloat()
        }
        assertEquals(87f, battery)
        var ip = ""
        ProtoReader(replay.getValue(Msg.TEXT_SENSOR_STATE_RESPONSE).payload).let { r ->
            while (r.next()) if (r.field == 2) ip = r.asString()
        }
        assertEquals("192.168.1.5", ip)
        // Never-touched select reports missing_state, not a phantom value.
        var missing = false
        ProtoReader(replay.getValue(Msg.SELECT_STATE_RESPONSE).payload).let { r ->
            while (r.next()) if (r.field == 3) missing = r.asBool()
        }
        assertTrue(missing)

        // A live update reaches the subscribed session.
        hub.updateState("battery", 42)
        val update = c.readUntil(Msg.SENSOR_STATE_RESPONSE)
        var updated = 0f
        ProtoReader(update.payload).let { r ->
            while (r.next()) if (r.field == 2) updated = r.asFloat()
        }
        assertEquals(42f, updated)
    }

    @Test
    fun commandsDispatchWithTheirTypedValues() {
        val (s, _) = start()
        val c = connectClient(s)

        fun command(type: Int, key: Int, write: ProtoWriter.() -> Unit) {
            val w = ProtoWriter()
            w.fixed32(1, key)
            w.write()
            c.send(type, w.toByteArray())
        }
        command(Msg.SWITCH_COMMAND_REQUEST, EspEntity.fnv1a("screensaver")) {
            bool(2, true)
        }
        command(Msg.NUMBER_COMMAND_REQUEST, EspEntity.fnv1a("brightness")) {
            float(2, 55f)
        }
        command(Msg.SELECT_COMMAND_REQUEST, EspEntity.fnv1a("view")) {
            string(2, "Cameras")
        }
        command(Msg.BUTTON_COMMAND_REQUEST, EspEntity.fnv1a("reload")) {}
        // The socket gives no ack; poll the recorder.
        val deadline = System.currentTimeMillis() + 3_000
        while (commands.size < 4 && System.currentTimeMillis() < deadline) {
            Thread.sleep(20)
        }
        assertEquals(
            listOf<Pair<String, Any?>>(
                "screensaver" to true,
                "brightness" to 55f,
                "view" to "Cameras",
                "reload" to null,
            ),
            commands.toList(),
        )
    }

    @Test
    fun pureEntityDeviceClaimsNoBluetoothCapability() {
        val backend = object : ScannerBackend {
            override fun onScanDemand(mode: ScannerMode) {}
            override fun onScanRelease() {}
        }
        val hub = EntityHub(catalog) { _, _ -> }
        val s = ApiServer(identity, "02:AA:BB:CC:DD:EE", 0, null, backend,
            log = {}, bluetoothProxy = false, entities = hub)
        s.start()
        server = s
        val c = connectClient(s)
        c.send(Msg.DEVICE_INFO_REQUEST)
        var flags = -1
        var legacySeen = false
        ProtoReader(c.read().payload).let { r ->
            while (r.next()) when (r.field) {
                11 -> legacySeen = true
                15 -> flags = r.asInt()
            }
        }
        // Proto3 zero-omission: no Bluetooth capability means neither the
        // flags field nor the legacy version field appears at all.
        assertEquals(-1, flags)
        assertEquals(false, legacySeen)
        // The entity surface still serves.
        c.send(Msg.LIST_ENTITIES_REQUEST)
        assertEquals(Msg.LIST_ENTITIES_SENSOR_RESPONSE, c.read().type)
    }

    @Test
    fun entitylessServerStillAnswersListEntitiesWithBareDone() {
        val backend = object : ScannerBackend {
            override fun onScanDemand(mode: ScannerMode) {}
            override fun onScanRelease() {}
        }
        val s = ApiServer(identity, "02:AA:BB:CC:DD:EE", 0, null, backend, log = {})
        s.start()
        server = s
        val c = connectClient(s)
        c.send(Msg.LIST_ENTITIES_REQUEST)
        assertEquals(Msg.LIST_ENTITIES_DONE_RESPONSE, c.read().type)
    }
}
