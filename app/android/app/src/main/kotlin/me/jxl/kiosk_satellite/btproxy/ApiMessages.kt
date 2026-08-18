package me.jxl.kiosk_satellite.btproxy

/**
 * The ESPHome native API message subset the Bluetooth proxy speaks, with
 * field numbers straight from aioesphomeapi's api.proto.
 *
 * v1 is advertisement-only on purpose: the feature flags below promise Home
 * Assistant passive scanning and raw advertisement batches and nothing else,
 * so HA never routes GATT connections, pairing, or cache operations through
 * this device. Advertising capabilities the implementation cannot honor is
 * how other Android proxies earn their "unreliable" reputation: HA
 * dutifully tries to connect devices through them and the failures surface
 * as broken locks and unreachable sensors. Active connections are a later
 * phase with their own feature bits.
 *
 * Anything not listed here is answered per [ApiServer]'s dispatch rules:
 * known-but-ignorable subscriptions get their required acks, unknown types
 * are skipped silently. HA adds message types every release; dropping the
 * session over one (the strict-parse approach) breaks the proxy on every HA
 * upgrade.
 */
internal object Msg {
    const val HELLO_REQUEST = 1
    const val HELLO_RESPONSE = 2
    const val CONNECT_REQUEST = 3
    const val CONNECT_RESPONSE = 4
    const val DISCONNECT_REQUEST = 5
    const val DISCONNECT_RESPONSE = 6
    const val PING_REQUEST = 7
    const val PING_RESPONSE = 8
    const val DEVICE_INFO_REQUEST = 9
    const val DEVICE_INFO_RESPONSE = 10
    const val LIST_ENTITIES_REQUEST = 11
    const val LIST_ENTITIES_BINARY_SENSOR_RESPONSE = 12
    const val LIST_ENTITIES_SENSOR_RESPONSE = 16
    const val LIST_ENTITIES_SWITCH_RESPONSE = 17
    const val LIST_ENTITIES_TEXT_SENSOR_RESPONSE = 18
    const val LIST_ENTITIES_DONE_RESPONSE = 19
    const val SUBSCRIBE_STATES_REQUEST = 20
    const val BINARY_SENSOR_STATE_RESPONSE = 21
    const val SENSOR_STATE_RESPONSE = 25
    const val SWITCH_STATE_RESPONSE = 26
    const val TEXT_SENSOR_STATE_RESPONSE = 27
    const val SWITCH_COMMAND_REQUEST = 33
    const val LIST_ENTITIES_NUMBER_RESPONSE = 49
    const val NUMBER_STATE_RESPONSE = 50
    const val NUMBER_COMMAND_REQUEST = 51
    const val LIST_ENTITIES_SELECT_RESPONSE = 52
    const val SELECT_STATE_RESPONSE = 53
    const val SELECT_COMMAND_REQUEST = 54
    const val LIST_ENTITIES_BUTTON_RESPONSE = 61
    const val BUTTON_COMMAND_REQUEST = 62
    const val SUBSCRIBE_LOGS_REQUEST = 28
    const val SUBSCRIBE_HOMEASSISTANT_SERVICES_REQUEST = 34
    const val GET_TIME_REQUEST = 36
    const val GET_TIME_RESPONSE = 37
    const val SUBSCRIBE_HOME_ASSISTANT_STATES_REQUEST = 38
    const val SUBSCRIBE_BLE_ADVERTISEMENTS_REQUEST = 66
    const val BT_DEVICE_REQUEST = 68
    const val BT_DEVICE_CONNECTION_RESPONSE = 69
    const val GATT_GET_SERVICES_REQUEST = 70
    const val GATT_GET_SERVICES_RESPONSE = 71
    const val GATT_GET_SERVICES_DONE_RESPONSE = 72
    const val GATT_READ_REQUEST = 73
    const val GATT_READ_RESPONSE = 74
    const val GATT_WRITE_REQUEST = 75
    const val GATT_READ_DESCRIPTOR_REQUEST = 76
    const val GATT_WRITE_DESCRIPTOR_REQUEST = 77
    const val GATT_NOTIFY_REQUEST = 78
    const val GATT_NOTIFY_DATA_RESPONSE = 79
    const val SUBSCRIBE_BT_CONNECTIONS_FREE_REQUEST = 80
    const val BT_CONNECTIONS_FREE_RESPONSE = 81
    const val GATT_ERROR_RESPONSE = 82
    const val GATT_WRITE_RESPONSE = 83
    const val GATT_NOTIFY_RESPONSE = 84
    const val BT_DEVICE_PAIRING_RESPONSE = 85
    const val BT_DEVICE_UNPAIRING_RESPONSE = 86
    const val UNSUBSCRIBE_BLE_ADVERTISEMENTS_REQUEST = 87
    const val BT_DEVICE_CLEAR_CACHE_RESPONSE = 88
    const val BLE_RAW_ADVERTISEMENTS_RESPONSE = 93
    const val BT_SCANNER_STATE_RESPONSE = 126
    const val BT_SCANNER_SET_MODE_REQUEST = 127
}

/** BluetoothDeviceRequest.request_type values (api.proto). */
internal object BtDeviceRequestType {
    const val CONNECT = 0
    const val DISCONNECT = 1
    const val PAIR = 2
    const val UNPAIR = 3
    const val CONNECT_V3_WITH_CACHE = 4
    const val CONNECT_V3_WITHOUT_CACHE = 5
    const val CLEAR_CACHE = 6
}

/** DeviceInfoResponse.bluetooth_proxy_feature_flags bits (api.proto). */
internal object BtProxyFeature {
    const val PASSIVE_SCAN = 1 shl 0
    const val ACTIVE_CONNECTIONS = 1 shl 1
    const val REMOTE_CACHING = 1 shl 2
    const val PAIRING = 1 shl 3
    const val CACHE_CLEARING = 1 shl 4
    const val RAW_ADVERTISEMENTS = 1 shl 5
    const val STATE_AND_MODE = 1 shl 6

    /** Everything the advertisement-only mode honors. */
    const val V1 = PASSIVE_SCAN or RAW_ADVERTISEMENTS or STATE_AND_MODE

    /**
     * With connections enabled: everything V1 promises plus active GATT
     * connections, the v3 cached/uncached connect variants, pairing, and
     * cache clearing. Still only what the engine actually implements.
     */
    const val WITH_CONNECTIONS =
        V1 or ACTIVE_CONNECTIONS or REMOTE_CACHING or PAIRING or CACHE_CLEARING
}

/** BluetoothScannerStateResponse.state values. */
internal enum class ScannerState(val wire: Int) {
    IDLE(0), STARTING(1), RUNNING(2), FAILED(3), STOPPING(4), STOPPED(5)
}

/** BluetoothScannerMode: ESPHome semantics: send scan requests or not. */
internal enum class ScannerMode(val wire: Int) {
    PASSIVE(0), ACTIVE(1);

    companion object {
        fun fromWire(value: Int): ScannerMode = if (value == 1) ACTIVE else PASSIVE
    }
}

/**
 * Static identity the server reports in HelloResponse / DeviceInfoResponse.
 * Supplied by the Android layer; the protocol core never touches platform
 * APIs so it can run under plain JVM tests.
 */
internal class ProxyIdentity(
    /** mDNS/API node name, e.g. "kiosk-satellite-a1b2c3". */
    val name: String,
    /** Display name shown in HA, e.g. the device's kiosk name. */
    val friendlyName: String,
    /** Synthetic but stable MAC, formatted "AA:BB:CC:DD:EE:FF". */
    val macAddress: String,
    /**
     * The ESPHome version string HA compares against its minimum-supported
     * table. Must track current ESPHome releases: HA raises repair issues
     * against proxies reporting versions it considers outdated.
     */
    val esphomeVersion: String,
    val model: String,
    val manufacturer: String,
    /** Marks the origin without pretending to be an esphome-built firmware. */
    val projectName: String,
    val projectVersion: String,
)

internal object ApiCodec {
    /** HelloRequest: 1=client_info, 2=api_version_major, 3=api_version_minor. */
    class Hello(val clientInfo: String, val major: Int, val minor: Int)

    fun parseHello(payload: ByteArray): Hello {
        var info = ""
        var major = 0
        var minor = 0
        val r = ProtoReader(payload)
        while (r.next()) when (r.field) {
            1 -> info = r.asString()
            2 -> major = r.asInt()
            3 -> minor = r.asInt()
        }
        return Hello(info, major, minor)
    }

    /**
     * API version 1.10: new enough that every Bluetooth message this proxy
     * uses (raw batches, scanner state/mode) predates it, old enough that
     * any aioesphomeapi from the last several years accepts it without a
     * "server version newer than client" warning.
     */
    fun helloResponse(identity: ProxyIdentity): ByteArray = ProtoWriter().run {
        varint(1, 1) // api_version_major
        varint(2, 10) // api_version_minor
        string(3, "Kiosk Satellite ${identity.projectVersion}")
        string(4, identity.name)
        toByteArray()
    }

    /** ConnectResponse: 1=invalid_password. Noise replaced passwords; never invalid. */
    fun connectResponse(): ByteArray = ProtoWriter().toByteArray()

    fun deviceInfoResponse(
        identity: ProxyIdentity,
        bluetoothMac: String,
        featureFlags: Int,
    ): ByteArray =
        ProtoWriter().run {
            bool(1, false) // uses_password
            string(2, identity.name)
            string(3, identity.macAddress)
            string(4, identity.esphomeVersion)
            string(6, identity.model)
            string(8, identity.projectName)
            string(9, identity.projectVersion)
            // legacy_bluetooth_proxy_version: the pre-flags capability number;
            // 5 is the last value the legacy field ever carried, and HA still
            // reads it before trusting the flags field.
            varint(11, 5)
            string(12, identity.manufacturer)
            string(13, identity.friendlyName)
            varint(15, featureFlags)
            string(18, bluetoothMac)
            bool(19, true) // api_encryption_supported
            toByteArray()
        }

    /** GetTimeResponse: 1=epoch_seconds (fixed32). */
    fun getTimeResponse(epochSeconds: Long): ByteArray = ProtoWriter().run {
        fixed32(1, epochSeconds.toInt())
        toByteArray()
    }

    /** SubscribeBluetoothLEAdvertisementsRequest: 1=flags. */
    fun parseBleSubscribeFlags(payload: ByteArray): Int {
        val r = ProtoReader(payload)
        while (r.next()) if (r.field == 1) return r.asInt()
        return 0
    }

    /** BluetoothScannerSetModeRequest: 1=mode. */
    fun parseScannerSetMode(payload: ByteArray): ScannerMode {
        val r = ProtoReader(payload)
        while (r.next()) if (r.field == 1) return ScannerMode.fromWire(r.asInt())
        return ScannerMode.PASSIVE
    }

    /** BluetoothScannerStateResponse: 1=state, 2=mode. */
    fun scannerStateResponse(state: ScannerState, mode: ScannerMode): ByteArray =
        ProtoWriter().run {
            varint(1, state.wire)
            varint(2, mode.wire)
            toByteArray()
        }

    /** BluetoothConnectionsFreeResponse: 1=free, 2=limit. Zero slots in v1. */
    fun connectionsFreeResponse(): ByteArray = ProtoWriter().toByteArray()

    /**
     * BluetoothLERawAdvertisementsResponse: repeated advertisements(1), each
     * 1=address (uint64), 2=rssi (sint32), 3=address_type, 4=data (<=62 B).
     */
    fun rawAdvertisementsResponse(batch: List<BleAdvertisement>): ByteArray {
        val out = ProtoWriter()
        for (adv in batch) {
            out.message(1, ProtoWriter().run {
                varint(1, adv.address)
                sint32(2, adv.rssi)
                varint(3, adv.addressType)
                bytes(4, adv.data)
                toByteArray()
            })
        }
        return out.toByteArray()
    }
}

/**
 * One observed advertisement. [address] is the 48-bit MAC as a uint64,
 * [data] is the raw AD-structure payload capped at ESPHome's 62-byte limit
 * (31 advertisement + 31 scan-response bytes).
 */
internal class BleAdvertisement(
    val address: Long,
    val rssi: Int,
    val addressType: Int,
    val data: ByteArray,
)
