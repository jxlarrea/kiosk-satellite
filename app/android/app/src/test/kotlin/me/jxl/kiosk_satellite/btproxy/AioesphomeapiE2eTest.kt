package me.jxl.kiosk_satellite.btproxy

import java.io.File
import java.util.Base64
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.test.Test
import kotlin.test.assertEquals
import org.junit.Assume.assumeTrue

/**
 * End-to-end proof against the real client: aioesphomeapi (the exact library
 * Home Assistant's ESPHome integration uses) performs the Noise handshake,
 * hello/login, device info, and a raw-advertisement subscription against a
 * live [ApiServer], over a real socket.
 *
 * This is the test that catches what unit tests structurally cannot: a
 * mirrored crypto bug, a wrong field number, a framing byte HA's parser
 * rejects. Every prior Android proxy shipped breakage in exactly this layer.
 *
 * Runs when a Python interpreter with aioesphomeapi is available: either
 * KS_AIOESPHOME_PYTHON pointing at one, or plain python3 with the module
 * installed. Skips (not fails) otherwise, so a clean checkout still passes.
 */
class AioesphomeapiE2eTest {
    private val script = """
        import asyncio, sys

        async def main():
            from aioesphomeapi import APIClient
            port = int(sys.argv[1]); psk = sys.argv[2]
            cli = APIClient("127.0.0.1", port, None, noise_psk=psk)
            await cli.connect(login=True)
            info = await cli.device_info()
            assert info.name == "kiosk-satellite-test", info.name
            assert info.bluetooth_proxy_feature_flags == 0x61, hex(info.bluetooth_proxy_feature_flags)
            print("DEVICEINFO_OK", info.esphome_version, flush=True)

            loop = asyncio.get_running_loop()
            got = loop.create_future()

            def on_adv(advs):
                items = getattr(advs, "advertisements", advs)
                try:
                    first = items[0]
                except (TypeError, IndexError):
                    first = items
                if not got.done():
                    got.set_result(first)

            cli.subscribe_bluetooth_le_raw_advertisements(on_adv)
            adv = await asyncio.wait_for(got, 15)
            addr = getattr(adv, "address", None)
            rssi = getattr(adv, "rssi", None)
            assert addr == 0x112233445566, hex(addr) if addr else addr
            assert rssi == -63, rssi
            print("ADV_OK", flush=True)
            await cli.disconnect()

        asyncio.run(main())
    """.trimIndent()

    private val gattScript = """
        import asyncio, sys

        async def main():
            from aioesphomeapi import APIClient
            port = int(sys.argv[1]); psk = sys.argv[2]
            cli = APIClient("127.0.0.1", port, None, noise_psk=psk)
            await cli.connect(login=True)
            info = await cli.device_info()
            assert info.bluetooth_proxy_feature_flags & 0x02, hex(info.bluetooth_proxy_feature_flags)
            print("FLAGS_OK", flush=True)

            addr = 0x1122
            loop = asyncio.get_running_loop()
            state = loop.create_future()

            def on_state(connected, mtu, error):
                if not state.done():
                    state.set_result((connected, mtu, error))

            await cli.bluetooth_device_connect(
                addr, on_state, timeout=10, address_type=0,
                feature_flags=info.bluetooth_proxy_feature_flags)
            connected, mtu, error = await asyncio.wait_for(state, 10)
            assert connected and error == 0, (connected, mtu, error)
            assert mtu == 247, mtu
            print("CONNECT_OK", flush=True)

            services = await cli.bluetooth_gatt_get_services(addr)
            tree = services.services
            assert len(tree) == 2, tree
            characteristic = tree[0].characteristics[0]
            assert characteristic.handle == 2, characteristic
            assert characteristic.descriptors[0].handle == 3, characteristic
            print("SERVICES_OK", flush=True)

            data = await cli.bluetooth_gatt_read(addr, 2)
            assert bytes(data) == b"\x64", data
            await cli.bluetooth_gatt_write(addr, 2, b"\x2a", True)
            print("READ_WRITE_OK", flush=True)

            notified = loop.create_future()

            def on_notify(handle, payload):
                if not notified.done():
                    notified.set_result((handle, bytes(payload)))

            await cli.bluetooth_gatt_start_notify(addr, 2, on_notify)
            handle, payload = await asyncio.wait_for(notified, 10)
            assert handle == 2 and payload == b"\x2a", (handle, payload)
            print("NOTIFY_OK", flush=True)

            await cli.bluetooth_device_disconnect(addr)
            await cli.disconnect()

        asyncio.run(main())
    """.trimIndent()

    private val entitiesScript = """
        import asyncio, sys

        async def main():
            from aioesphomeapi import APIClient
            port = int(sys.argv[1]); psk = sys.argv[2]
            cli = APIClient("127.0.0.1", port, None, noise_psk=psk)
            await cli.connect(login=True)
            entities, services = await cli.list_entities_services()
            by_obj = {e.object_id: e for e in entities}
            expected = {"battery", "charging", "ipv4", "screensaver",
                        "brightness", "view", "reload"}
            assert set(by_obj) == expected, sorted(by_obj)
            sensor = by_obj["battery"]
            assert sensor.unit_of_measurement == "%", sensor
            assert sensor.device_class == "battery", sensor
            number = by_obj["brightness"]
            assert abs(number.max_value - 100.0) < 1e-6, number
            assert abs(number.step - 1.0) < 1e-6, number
            select = by_obj["view"]
            assert list(select.options) == ["Home", "Cameras"], select
            print("LIST_OK", flush=True)

            loop = asyncio.get_running_loop()
            states = {}
            switch_on = loop.create_future()

            def on_state(st):
                states[st.key] = st
                if (st.key == by_obj["screensaver"].key
                        and getattr(st, "state", False)
                        and not switch_on.done()):
                    switch_on.set_result(st)

            cli.subscribe_states(on_state)
            await asyncio.sleep(1.0)
            bat = states.get(sensor.key)
            assert bat is not None and abs(bat.state - 87.0) < 1e-6, bat
            ip = states.get(by_obj["ipv4"].key)
            assert ip is not None and ip.state == "192.168.1.5", ip
            print("STATES_OK", flush=True)

            cli.switch_command(by_obj["screensaver"].key, True)
            await asyncio.wait_for(switch_on, 10)
            print("SWITCH_ECHO_OK", flush=True)
            cli.number_command(number.key, 55.0)
            cli.select_command(select.key, "Cameras")
            cli.button_command(by_obj["reload"].key)
            await asyncio.sleep(0.5)
            await cli.disconnect()

        asyncio.run(main())
    """.trimIndent()

    @Test
    fun realClientEntitiesRoundTrip() {
        val python = System.getenv("KS_AIOESPHOME_PYTHON") ?: "python3"
        val available = runCatching {
            ProcessBuilder(python, "-c", "import aioesphomeapi")
                .redirectErrorStream(true).start()
                .let { it.waitFor(30, TimeUnit.SECONDS) && it.exitValue() == 0 }
        }.getOrDefault(false)
        assumeTrue("aioesphomeapi not available for $python; skipping", available)

        val psk = ByteArray(32) { (it * 11 + 5).toByte() }
        val identity = ProxyIdentity(
            name = "kiosk-satellite-test",
            friendlyName = "Test Kiosk",
            macAddress = "02:11:22:33:44:55",
            esphomeVersion = "2026.8.0",
            model = "Test",
            manufacturer = "KS",
            projectName = "kiosk_satellite.bluetooth_proxy",
            projectVersion = "1.0",
        )
        val backend = object : ScannerBackend {
            override fun onScanDemand(mode: ScannerMode) {}
            override fun onScanRelease() {}
        }
        val commands = java.util.concurrent.CopyOnWriteArrayList<Pair<String, Any?>>()
        lateinit var hub: EntityHub
        hub = EntityHub(listOf(
            EspEntity.Sensor("battery", "Battery", deviceClass = "battery",
                category = 2, unit = "%", stateClass = 1),
            EspEntity.BinarySensor("charging", "Charging",
                deviceClass = "battery_charging", category = 2),
            EspEntity.TextSensor("ipv4", "IP address", category = 2),
            EspEntity.Switch("screensaver", "Screensaver"),
            EspEntity.Number("brightness", "Screen brightness", min = 0f,
                max = 100f, step = 1f, unit = "%", mode = 2),
            EspEntity.Select("view", "View", options = listOf("Home", "Cameras")),
            EspEntity.Button("reload", "Reload dashboard"),
        )) { objectId, value ->
            commands.add(objectId to value)
            // The Dart side echoes real state after acting on a command;
            // mirror that so the client sees its switch flip.
            if (objectId == "screensaver") hub.updateState(objectId, value)
        }
        hub.updateState("battery", 87)
        hub.updateState("ipv4", "192.168.1.5")
        val server = ApiServer(identity, "02:AA:BB:CC:DD:EE", 0, psk, backend,
            log = {}, entities = hub)
        server.start()
        try {
            val scriptFile = File.createTempFile("btproxy_entities_e2e", ".py").apply {
                writeText(entitiesScript)
                deleteOnExit()
            }
            val process = ProcessBuilder(
                python, scriptFile.absolutePath,
                server.boundPort.toString(),
                Base64.getEncoder().encodeToString(psk),
            ).redirectErrorStream(true).start()
            val finished = process.waitFor(60, TimeUnit.SECONDS)
            val output = process.inputStream.bufferedReader().readText()
            if (!finished) process.destroyForcibly()
            assertEquals(0, if (finished) process.exitValue() else -1,
                "aioesphomeapi entities round trip failed:\n$output")
            assertEquals(
                listOf<Pair<String, Any?>>(
                    "screensaver" to true,
                    "brightness" to 55f,
                    "view" to "Cameras",
                    "reload" to null,
                ),
                commands.toList(),
            )
        } finally {
            server.stop()
        }
    }

    @Test
    fun realClientGattRoundTrip() {
        val python = System.getenv("KS_AIOESPHOME_PYTHON") ?: "python3"
        val available = runCatching {
            ProcessBuilder(python, "-c", "import aioesphomeapi")
                .redirectErrorStream(true).start()
                .let { it.waitFor(30, TimeUnit.SECONDS) && it.exitValue() == 0 }
        }.getOrDefault(false)
        assumeTrue("aioesphomeapi not available for $python; skipping", available)

        val psk = ByteArray(32) { (it * 5 + 1).toByte() }
        val identity = ProxyIdentity(
            name = "kiosk-satellite-test",
            friendlyName = "Test Kiosk",
            macAddress = "02:11:22:33:44:55",
            esphomeVersion = "2026.8.0",
            model = "Test",
            manufacturer = "KS",
            projectName = "kiosk_satellite.bluetooth_proxy",
            projectVersion = "1.0",
        )
        val scanner = object : ScannerBackend {
            override fun onScanDemand(mode: ScannerMode) {}
            override fun onScanRelease() {}
        }
        val gatt = ScriptedGatt()
        val server = ApiServer(identity, "02:AA:BB:CC:DD:EE", 0, psk, scanner,
            log = {}, gatt = gatt)
        gatt.server = server
        server.start()
        try {
            val scriptFile = File.createTempFile("btproxy_gatt_e2e", ".py").apply {
                writeText(gattScript)
                deleteOnExit()
            }
            val process = ProcessBuilder(
                python, scriptFile.absolutePath,
                server.boundPort.toString(),
                Base64.getEncoder().encodeToString(psk),
            ).redirectErrorStream(true).start()
            val finished = process.waitFor(60, TimeUnit.SECONDS)
            val output = process.inputStream.bufferedReader().readText()
            if (!finished) process.destroyForcibly()
            assertEquals(0, if (finished) process.exitValue() else -1,
                "aioesphomeapi GATT round trip failed:\n$output")
        } finally {
            server.stop()
        }
    }

    @Test
    fun realHomeAssistantClientRoundTrip() {
        val python = System.getenv("KS_AIOESPHOME_PYTHON") ?: "python3"
        val available = runCatching {
            ProcessBuilder(python, "-c", "import aioesphomeapi")
                .redirectErrorStream(true).start()
                .let { it.waitFor(30, TimeUnit.SECONDS) && it.exitValue() == 0 }
        }.getOrDefault(false)
        assumeTrue("aioesphomeapi not available for $python; skipping", available)

        val psk = ByteArray(32) { (it * 7 + 3).toByte() }
        val identity = ProxyIdentity(
            name = "kiosk-satellite-test",
            friendlyName = "Test Kiosk",
            macAddress = "02:11:22:33:44:55",
            esphomeVersion = "2026.8.0",
            model = "Test",
            manufacturer = "KS",
            projectName = "kiosk_satellite.bluetooth_proxy",
            projectVersion = "1.0",
        )
        val backend = object : ScannerBackend {
            override fun onScanDemand(mode: ScannerMode) {}
            override fun onScanRelease() {}
        }
        val server = ApiServer(identity, "02:AA:BB:CC:DD:EE", 0, psk, backend, log = {})
        server.start()

        // Feed a steady advertisement so whenever the client subscribes there
        // is something to forward within one flush interval.
        val advData = byteArrayOf(0x02, 0x01, 0x06)
        val stop = AtomicBoolean(false)
        val feeder = Thread {
            while (!stop.get()) {
                server.publishAdvertisement(BleAdvertisement(0x112233445566L, -63, 0, advData))
                Thread.sleep(200)
            }
        }.apply { isDaemon = true; start() }

        try {
            val scriptFile = File.createTempFile("btproxy_e2e", ".py").apply {
                writeText(script)
                deleteOnExit()
            }
            val process = ProcessBuilder(
                python, scriptFile.absolutePath,
                server.boundPort.toString(),
                Base64.getEncoder().encodeToString(psk),
            ).redirectErrorStream(true).start()
            val finished = process.waitFor(60, TimeUnit.SECONDS)
            val output = process.inputStream.bufferedReader().readText()
            if (!finished) process.destroyForcibly()
            assertEquals(0, if (finished) process.exitValue() else -1,
                "aioesphomeapi round trip failed:\n$output")
        } finally {
            stop.set(true)
            feeder.join(1_000)
            server.stop()
        }
    }
}
