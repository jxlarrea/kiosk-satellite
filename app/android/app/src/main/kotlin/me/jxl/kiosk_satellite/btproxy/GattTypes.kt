package me.jxl.kiosk_satellite.btproxy

/**
 * The seam between the protocol layer and the platform's GATT stack.
 *
 * [ApiServer] calls down through [GattBackend]; the platform answers up
 * through [GattEvent]s, which the server relays to the owning client in
 * arrival order. The interface is Android-free so every message sequence
 * (connect gating, service batching, the done marker's ordering) runs
 * under plain JVM tests with a scripted backend, and the real engine only
 * has to get Android right, not the protocol.
 *
 * Events MUST be delivered from a single thread in causal order. The wire
 * has no sequence numbers: a notification that overtakes its enable-ack,
 * or a services-done that overtakes the last service, corrupts the
 * client's view in ways that read as "flaky device", never as the proxy's
 * fault.
 */
internal interface GattBackend {
    /** Concurrent connection budget advertised to Home Assistant. */
    val connectionLimit: Int

    fun connect(address: Long, addressType: Int?, withCache: Boolean)
    fun disconnect(address: Long)

    /** Answered with [GattEvent.Services]; from cache after first discovery. */
    fun getServices(address: Long)

    fun read(address: Long, handle: Int)
    fun write(address: Long, handle: Int, data: ByteArray, withResponse: Boolean)
    fun readDescriptor(address: Long, handle: Int)
    fun writeDescriptor(address: Long, handle: Int, data: ByteArray)
    fun setNotify(address: Long, handle: Int, enable: Boolean)
    fun pair(address: Long)
    fun unpair(address: Long)
    fun clearCache(address: Long)

    /** Session teardown and shutdown: drop every connection this backend holds. */
    fun disconnectAll()
}

internal sealed class GattEvent {
    abstract val address: Long

    /** Link is up and, for uncached connects, services are freshly discovered. */
    class Connected(override val address: Long, val mtu: Int) : GattEvent()

    /** Connect attempt failed terminally (after the engine's own retry). */
    class ConnectFailed(override val address: Long, val error: Int) : GattEvent()

    /** Link dropped, by request or by the device. */
    class Disconnected(override val address: Long, val error: Int = 0) : GattEvent()

    /** The full service tree, already carrying synthetic handles. */
    class Services(
        override val address: Long,
        val services: List<GattService>,
    ) : GattEvent()

    /** Characteristic or descriptor read result (both answer as a read). */
    class ReadResult(
        override val address: Long,
        val handle: Int,
        val data: ByteArray,
    ) : GattEvent()

    class WriteDone(override val address: Long, val handle: Int) : GattEvent()

    class NotifyStateDone(override val address: Long, val handle: Int) : GattEvent()

    class NotifyData(
        override val address: Long,
        val handle: Int,
        val data: ByteArray,
    ) : GattEvent()

    /** An operation failed; [handle] 0 when it was not handle-specific. */
    class OperationError(
        override val address: Long,
        val handle: Int,
        val error: Int,
    ) : GattEvent()

    class PairResult(
        override val address: Long,
        val paired: Boolean,
        val error: Int,
    ) : GattEvent()

    class UnpairResult(
        override val address: Long,
        val success: Boolean,
        val error: Int,
    ) : GattEvent()

    class ClearCacheResult(
        override val address: Long,
        val success: Boolean,
        val error: Int,
    ) : GattEvent()
}

/**
 * A discovered GATT tree node set. Handles are synthetic, assigned by the
 * engine in discovery order, stable for the life of the connection, and
 * NEVER Android's instanceId: ESPHome clients treat these as real ATT
 * handles and key every read, write, and notification on them.
 */
internal class GattService(
    val uuidHi: Long,
    val uuidLo: Long,
    val handle: Int,
    val characteristics: List<GattCharacteristic>,
)

internal class GattCharacteristic(
    val uuidHi: Long,
    val uuidLo: Long,
    val handle: Int,
    /** The Bluetooth property bitmask, verbatim from the device. */
    val properties: Int,
    val descriptors: List<GattDescriptor>,
)

internal class GattDescriptor(
    val uuidHi: Long,
    val uuidLo: Long,
    val handle: Int,
)

internal object GattCodec {
    class DeviceRequest(
        val address: Long,
        val requestType: Int,
        val addressType: Int?,
    )

    fun parseDeviceRequest(payload: ByteArray): DeviceRequest {
        var address = 0L
        var type = 0
        var hasAddressType = false
        var addressType = 0
        val r = ProtoReader(payload)
        while (r.next()) when (r.field) {
            1 -> address = r.asLong()
            2 -> type = r.asInt()
            3 -> hasAddressType = r.asBool()
            4 -> addressType = r.asInt()
        }
        return DeviceRequest(address, type, if (hasAddressType) addressType else null)
    }

    /** The address-only requests: get-services (70). */
    fun parseAddress(payload: ByteArray): Long {
        val r = ProtoReader(payload)
        while (r.next()) if (r.field == 1) return r.asLong()
        return 0
    }

    class HandleRequest(val address: Long, val handle: Int)

    /** Read (73) and read-descriptor (76): 1=address, 2=handle. */
    fun parseHandleRequest(payload: ByteArray): HandleRequest {
        var address = 0L
        var handle = 0
        val r = ProtoReader(payload)
        while (r.next()) when (r.field) {
            1 -> address = r.asLong()
            2 -> handle = r.asInt()
        }
        return HandleRequest(address, handle)
    }

    class WriteRequest(
        val address: Long,
        val handle: Int,
        val response: Boolean,
        val data: ByteArray,
    )

    /** Write (75): 1=address, 2=handle, 3=response, 4=data. */
    fun parseWriteRequest(payload: ByteArray): WriteRequest {
        var address = 0L
        var handle = 0
        var response = false
        var data = ByteArray(0)
        val r = ProtoReader(payload)
        while (r.next()) when (r.field) {
            1 -> address = r.asLong()
            2 -> handle = r.asInt()
            3 -> response = r.asBool()
            4 -> data = r.asBytes()
        }
        return WriteRequest(address, handle, response, data)
    }

    /** Write-descriptor (77): 1=address, 2=handle, 3=data. Always with response. */
    fun parseWriteDescriptor(payload: ByteArray): WriteRequest {
        var address = 0L
        var handle = 0
        var data = ByteArray(0)
        val r = ProtoReader(payload)
        while (r.next()) when (r.field) {
            1 -> address = r.asLong()
            2 -> handle = r.asInt()
            3 -> data = r.asBytes()
        }
        return WriteRequest(address, handle, true, data)
    }

    class NotifyRequest(val address: Long, val handle: Int, val enable: Boolean)

    /** Notify (78): 1=address, 2=handle, 3=enable. */
    fun parseNotifyRequest(payload: ByteArray): NotifyRequest {
        var address = 0L
        var handle = 0
        var enable = false
        val r = ProtoReader(payload)
        while (r.next()) when (r.field) {
            1 -> address = r.asLong()
            2 -> handle = r.asInt()
            3 -> enable = r.asBool()
        }
        return NotifyRequest(address, handle, enable)
    }

    /** BluetoothDeviceConnectionResponse (69). */
    fun connectionResponse(address: Long, connected: Boolean, mtu: Int, error: Int): ByteArray =
        ProtoWriter().run {
            varint(1, address)
            bool(2, connected)
            varint(3, mtu)
            varint(4, error)
            toByteArray()
        }

    /**
     * BluetoothGATTGetServicesResponse (71), one service per message. The
     * 128-bit UUID travels as two uint64s, high half first; clients
     * reassemble and compare against the Bluetooth base UUID themselves.
     */
    fun servicesResponse(address: Long, service: GattService): ByteArray = ProtoWriter().run {
        varint(1, address)
        message(2, ProtoWriter().run {
            varint(1, service.uuidHi)
            varint(1, service.uuidLo)
            varint(2, service.handle)
            for (characteristic in service.characteristics) {
                message(3, ProtoWriter().run {
                    varint(1, characteristic.uuidHi)
                    varint(1, characteristic.uuidLo)
                    varint(2, characteristic.handle)
                    varint(3, characteristic.properties)
                    for (descriptor in characteristic.descriptors) {
                        message(4, ProtoWriter().run {
                            varint(1, descriptor.uuidHi)
                            varint(1, descriptor.uuidLo)
                            varint(2, descriptor.handle)
                            toByteArray()
                        })
                    }
                    toByteArray()
                })
            }
            toByteArray()
        })
        toByteArray()
    }

    fun servicesDone(address: Long): ByteArray = ProtoWriter().run {
        varint(1, address)
        toByteArray()
    }

    fun readResponse(address: Long, handle: Int, data: ByteArray): ByteArray =
        ProtoWriter().run {
            varint(1, address)
            varint(2, handle)
            bytes(3, data)
            toByteArray()
        }

    fun writeResponse(address: Long, handle: Int): ByteArray = ProtoWriter().run {
        varint(1, address)
        varint(2, handle)
        toByteArray()
    }

    fun notifyResponse(address: Long, handle: Int): ByteArray = ProtoWriter().run {
        varint(1, address)
        varint(2, handle)
        toByteArray()
    }

    fun notifyData(address: Long, handle: Int, data: ByteArray): ByteArray =
        ProtoWriter().run {
            varint(1, address)
            varint(2, handle)
            bytes(3, data)
            toByteArray()
        }

    fun gattError(address: Long, handle: Int, error: Int): ByteArray = ProtoWriter().run {
        varint(1, address)
        varint(2, handle)
        varint(3, error)
        toByteArray()
    }

    fun pairingResponse(address: Long, paired: Boolean, error: Int): ByteArray =
        ProtoWriter().run {
            varint(1, address)
            bool(2, paired)
            varint(3, error)
            toByteArray()
        }

    fun unpairingResponse(address: Long, success: Boolean, error: Int): ByteArray =
        ProtoWriter().run {
            varint(1, address)
            bool(2, success)
            varint(3, error)
            toByteArray()
        }

    fun clearCacheResponse(address: Long, success: Boolean, error: Int): ByteArray =
        ProtoWriter().run {
            varint(1, address)
            bool(2, success)
            varint(3, error)
            toByteArray()
        }

    fun connectionsFree(free: Int, limit: Int, allocated: List<Long>): ByteArray =
        ProtoWriter().run {
            varint(1, free)
            varint(2, limit)
            for (address in allocated) varint(3, address)
            toByteArray()
        }
}
