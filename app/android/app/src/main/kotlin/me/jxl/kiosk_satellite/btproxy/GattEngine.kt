package me.jxl.kiosk_satellite.btproxy

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import java.util.UUID

/**
 * The Android side of GATT proxying: everything [ApiServer] needs through
 * [GattBackend], built around how Android GATT actually fails.
 *
 * Discipline encoded here, each rule a documented field failure of some
 * prior Android proxy:
 *
 *  - Everything runs on one main-looper handler: backend calls post in,
 *    stack callbacks post in, events go out in causal order. GATT
 *    notification streams have no sequence numbers; ordering is the
 *    correctness model.
 *  - One operation in flight across ALL connections, pumped from a global
 *    queue, each with a timeout. The API permits concurrency across GATT
 *    clients; real stacks refuse it with a bare false.
 *  - MTU is requested immediately on link-up (delaying it interrupts
 *    encryption setup on bonded devices) but every other operation waits
 *    for the MTU result or a short timeout.
 *  - An uncached connect only reports "connected" after fresh service
 *    discovery; reporting earlier hands the client an empty table it will
 *    cache and trust.
 *  - Status 133 gets one quick retry, then the address enters a doubling
 *    cooldown. Home Assistant retries aggressively, every retry burns an
 *    Android GATT client handle, and exhausting those wedges the stack
 *    for every app on the device.
 *  - Disconnects arm a watchdog: some stacks never deliver the callback,
 *    and an undelivered disconnect is a leaked slot forever. A teardown
 *    guard makes exactly one disconnected event per link, because doubles
 *    desync the client's slot accounting.
 *  - Scanning pauses during connection establishment: connects racing a
 *    LOW_LATENCY scan fail disproportionately on shared-antenna radios.
 *
 * Handles exported to the wire are synthetic (sequential per connection),
 * never Android's instanceId: ESPHome clients treat them as ATT handles.
 */
internal class GattEngine(
    private val context: Context,
    private val deliver: (GattEvent) -> Unit,
    private val scanPause: (Boolean) -> Unit,
) : GattBackend {
    private companion object {
        const val TAG = "KsBtProxy"
        const val CONNECT_TIMEOUT_MS = 10_000L
        const val MTU_TIMEOUT_MS = 1_500L
        const val DISCOVER_TIMEOUT_MS = 10_000L
        const val OPERATION_TIMEOUT_MS = 10_000L
        const val DISCONNECT_WATCHDOG_MS = 4_000L
        const val RETRY_133_DELAY_MS = 600L
        // Gentle by design: the cooldown exists to break rapid 133 retry
        // loops, not to punish a device that was merely busy. EcoFlows
        // accept one central at a time and evict the proxy whenever the
        // vendor app is open; with the old 30s-doubling-to-5min ladder,
        // closing the app still left Home Assistant locked out for
        // minutes and every entity unavailable.
        const val COOLDOWN_BASE_MS = 10_000L
        const val COOLDOWN_MAX_MS = 60_000L
        const val REQUESTED_MTU = 517
        /** ATT error for "not connected / not ready", what bleak expects. */
        const val ERROR_NOT_CONNECTED = 0x81
        val CCCD_UUID: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
    }

    // Old Android GATT stacks (the Echo Shows are API 30) flake above a
    // couple of concurrent links; modern ones are fine with a third.
    override val connectionLimit: Int =
        if (Build.VERSION.SDK_INT <= 30) 2 else 3

    private val handler = Handler(Looper.getMainLooper())
    private val connections = HashMap<Long, Connection>()

    // ONE operation in flight across ALL connections, not one per
    // connection: the Android API permits concurrent operations on
    // separate GATT clients, but real stacks (the API 30 Echo Shows
    // first among them) refuse the second one with a bare false. Found
    // live: an EcoFlow CCCD write failed with error 129 the moment a
    // second device's operation was mid-flight on the other slot.
    private val opQueue = ArrayDeque<Pair<Connection, Op>>()
    private var inFlightConnection: Connection? = null
    private var inFlightOp: Op? = null
    private var opTimeout: Runnable? = null
    private val cooldownUntil = HashMap<Long, Long>()
    private val cooldownStep = HashMap<Long, Long>()
    private var bondReceiverRegistered = false
    private var pendingPairAddress: Long? = null

    private enum class State { CONNECTING, MTU_WAIT, DISCOVERING, READY, DISCONNECTING }

    private sealed class Op {
        class Read(val handle: Int) : Op()
        class Write(val handle: Int, val data: ByteArray, val withResponse: Boolean) : Op()
        class ReadDescriptor(val handle: Int) : Op()
        class WriteDescriptor(val handle: Int, val data: ByteArray) : Op()
        class Notify(val handle: Int, val enable: Boolean) : Op()
    }

    private inner class Connection(val address: Long, val withCache: Boolean) {
        var gatt: BluetoothGatt? = null
        var state = State.CONNECTING
        var mtu = 23
        var retried133 = false
        var disconnectedDelivered = false
        /**
         * Whether this connection holds the scan pause. Tracked here, not
         * derived from [state]: disconnectInternal overwrites the state to
         * DISCONNECTING, so a phase-based release check misses connections
         * torn down mid-connect and leaks the hold - which is a permanently
         * stopped scanner, found live when a retry storm on one EcoFlow
         * left a kiosk relaying nothing until app restart.
         */
        var holdsScanPause = false

        fun takeScanPause() {
            if (!holdsScanPause) {
                holdsScanPause = true
                scanPause(true)
            }
        }

        fun releaseScanPause() {
            if (holdsScanPause) {
                holdsScanPause = false
                scanPause(false)
            }
        }
        var servicesTree: List<GattService>? = null
        var servicesRequested = false
        val handleToCharacteristic = HashMap<Int, BluetoothGattCharacteristic>()
        val handleToDescriptor = HashMap<Int, BluetoothGattDescriptor>()
        val characteristicToHandle = HashMap<BluetoothGattCharacteristic, Int>()
        var timeout: Runnable? = null
        var opTimeout: Runnable? = null

        fun armTimeout(ms: Long, onExpiry: () -> Unit) {
            timeout?.let(handler::removeCallbacks)
            timeout = Runnable { onExpiry() }.also { handler.postDelayed(it, ms) }
        }

        fun clearTimeout() {
            timeout?.let(handler::removeCallbacks)
            timeout = null
        }
    }

    // --- GattBackend entry points: all hop to the handler thread ---

    override fun connect(address: Long, addressType: Int?, withCache: Boolean) {
        handler.post { connectInternal(address, withCache) }
    }

    override fun disconnect(address: Long) {
        handler.post { disconnectInternal(address, requested = true) }
    }

    override fun getServices(address: Long) {
        handler.post {
            val connection = connections[address]
            when {
                connection == null || connection.state != State.READY ->
                    deliver(GattEvent.OperationError(address, 0, ERROR_NOT_CONNECTED))
                connection.servicesTree != null ->
                    deliver(GattEvent.Services(address, connection.servicesTree!!))
                else -> {
                    // A cached connect that gets asked anyway: discover now
                    // and answer from the discovery callback.
                    connection.servicesRequested = true
                    startDiscovery(connection)
                }
            }
        }
    }

    override fun read(address: Long, handle: Int) =
        enqueueOp(address, Op.Read(handle))

    override fun write(address: Long, handle: Int, data: ByteArray, withResponse: Boolean) =
        enqueueOp(address, Op.Write(handle, data, withResponse))

    override fun readDescriptor(address: Long, handle: Int) =
        enqueueOp(address, Op.ReadDescriptor(handle))

    override fun writeDescriptor(address: Long, handle: Int, data: ByteArray) =
        enqueueOp(address, Op.WriteDescriptor(handle, data))

    override fun setNotify(address: Long, handle: Int, enable: Boolean) =
        enqueueOp(address, Op.Notify(handle, enable))

    override fun pair(address: Long) {
        handler.post { pairInternal(address) }
    }

    @SuppressLint("MissingPermission")
    override fun unpair(address: Long) {
        handler.post {
            try {
                val device = remoteDevice(address)
                // Hidden API, the only unpair Android offers; stable since
                // API 1 in practice.
                val removed = device.javaClass.getMethod("removeBond")
                    .invoke(device) as? Boolean ?: false
                deliver(GattEvent.UnpairResult(address, removed, 0))
            } catch (e: Exception) {
                Log.w(TAG, "unpair failed: $e")
                deliver(GattEvent.UnpairResult(address, false, ERROR_NOT_CONNECTED))
            }
        }
    }

    override fun clearCache(address: Long) {
        handler.post {
            val gatt = connections[address]?.gatt
            val success = if (gatt != null) {
                // The hidden refresh() drops Android's own service cache so
                // the next discovery reads the device, not the cache.
                runCatching {
                    gatt.javaClass.getMethod("refresh").invoke(gatt) as? Boolean ?: false
                }.getOrDefault(false)
            } else {
                false
            }
            connections[address]?.servicesTree = null
            deliver(GattEvent.ClearCacheResult(address, success, 0))
        }
    }

    override fun disconnectAll() {
        handler.post {
            for (address in connections.keys.toList()) {
                disconnectInternal(address, requested = true)
            }
        }
    }

    // --- Connection lifecycle, handler thread only ---

    @SuppressLint("MissingPermission")
    private fun connectInternal(address: Long, withCache: Boolean) {
        val now = android.os.SystemClock.elapsedRealtime()
        val cooledUntil = cooldownUntil[address] ?: 0
        if (now < cooledUntil) {
            // Refusing fast during cooldown beats feeding the 133 cascade;
            // HA treats it like any failed attempt and backs off.
            Log.i(TAG, "connect refused, cooling down ${(cooledUntil - now) / 1000}s")
            deliver(GattEvent.ConnectFailed(address, 133))
            return
        }
        if (connections.containsKey(address)) {
            // A stale attempt is in some phase; tear it down first, connect
            // fresh on the next request from the client's retry.
            disconnectInternal(address, requested = true)
            deliver(GattEvent.ConnectFailed(address, 133))
            return
        }
        val adapter = (context.getSystemService(Context.BLUETOOTH_SERVICE)
            as? BluetoothManager)?.adapter
        if (adapter == null || !adapter.isEnabled) {
            deliver(GattEvent.ConnectFailed(address, ERROR_NOT_CONNECTED))
            return
        }
        val connection = Connection(address, withCache)
        connections[address] = connection
        connection.takeScanPause()
        try {
            connection.gatt = remoteDevice(address).connectGatt(
                context, false, callbackFor(connection), BluetoothDevice.TRANSPORT_LE)
        } catch (e: Exception) {
            Log.w(TAG, "connectGatt threw: $e")
            connections.remove(address)
            connection.releaseScanPause()
            deliver(GattEvent.ConnectFailed(address, ERROR_NOT_CONNECTED))
            return
        }
        connection.armTimeout(CONNECT_TIMEOUT_MS) {
            Log.w(TAG, "connect timeout for ${formatAddress(address)}")
            failConnect(connection, 133)
        }
    }

    @SuppressLint("MissingPermission")
    private fun failConnect(connection: Connection, error: Int) {
        connection.clearTimeout()
        runCatching { connection.gatt?.close() }
        connections.remove(connection.address)
        connection.releaseScanPause()
        if (error == 133 && !connection.retried133) {
            // One quick retry absorbs the everyday 133; more retries only
            // feed the cascade, so afterwards the address cools down.
            Log.i(TAG, "retrying ${formatAddress(connection.address)} after 133")
            handler.postDelayed({
                val retry = Connection(connection.address, connection.withCache)
                retry.retried133 = true
                connections[connection.address] = retry
                retry.takeScanPause()
                try {
                    retry.gatt = remoteDevice(retry.address).connectGatt(
                        context, false, callbackFor(retry), BluetoothDevice.TRANSPORT_LE)
                    retry.armTimeout(CONNECT_TIMEOUT_MS) { failConnect(retry, 133) }
                } catch (e: Exception) {
                    connections.remove(retry.address)
                    retry.releaseScanPause()
                    startCooldown(retry.address, 133)
                    deliver(GattEvent.ConnectFailed(retry.address, 133))
                }
            }, RETRY_133_DELAY_MS)
            return
        }
        startCooldown(connection.address, error)
        deliver(GattEvent.ConnectFailed(connection.address, error))
    }

    private fun startCooldown(address: Long, error: Int) {
        // Only stack-level 133 escalates: that is the failure mode where
        // rapid retries genuinely make things worse. A peer that hung up
        // (19) or timed out gets one flat, short breather.
        val step = if (error == 133) {
            ((cooldownStep[address] ?: (COOLDOWN_BASE_MS / 2)) * 2)
                .coerceAtMost(COOLDOWN_MAX_MS)
        } else {
            COOLDOWN_BASE_MS
        }
        cooldownStep[address] = step
        cooldownUntil[address] = android.os.SystemClock.elapsedRealtime() + step
    }

    @SuppressLint("MissingPermission")
    private fun disconnectInternal(address: Long, requested: Boolean) {
        val connection = connections[address] ?: return
        if (connection.state == State.DISCONNECTING) return
        connection.state = State.DISCONNECTING
        connection.clearTimeout()
        runCatching { connection.gatt?.disconnect() }
        // The watchdog is the guarantee: if Android never delivers the
        // disconnect callback, the slot still frees and the client still
        // hears about it, exactly once.
        connection.armTimeout(DISCONNECT_WATCHDOG_MS) {
            Log.w(TAG, "disconnect watchdog fired for ${formatAddress(address)}")
            finalizeDisconnect(connection, 0)
        }
    }

    @SuppressLint("MissingPermission")
    private fun finalizeDisconnect(connection: Connection, error: Int) {
        if (connection.disconnectedDelivered) return
        connection.disconnectedDelivered = true
        connection.clearTimeout()
        if (inFlightConnection === connection) {
            opTimeout?.let(handler::removeCallbacks)
            opTimeout = null
            inFlightConnection = null
            inFlightOp = null
            handler.post { pump() }
        }
        opQueue.removeAll { it.first === connection }
        runCatching { connection.gatt?.close() }
        connections.remove(connection.address)
        connection.releaseScanPause()
        deliver(GattEvent.Disconnected(connection.address, error))
    }

    @SuppressLint("MissingPermission")
    private fun startDiscovery(connection: Connection) {
        connection.state = State.DISCOVERING
        connection.armTimeout(DISCOVER_TIMEOUT_MS) {
            Log.w(TAG, "discovery timeout for ${formatAddress(connection.address)}")
            failConnect(connection, ERROR_NOT_CONNECTED)
        }
        if (connection.gatt?.discoverServices() != true) {
            failConnect(connection, ERROR_NOT_CONNECTED)
        }
    }

    private fun becomeReady(connection: Connection) {
        connection.clearTimeout()
        connection.state = State.READY
        // Success clears the address's cooldown history.
        cooldownStep.remove(connection.address)
        cooldownUntil.remove(connection.address)
        connection.releaseScanPause()
        deliver(GattEvent.Connected(connection.address, connection.mtu))
        if (connection.servicesRequested) {
            connection.servicesRequested = false
            connection.servicesTree?.let {
                deliver(GattEvent.Services(connection.address, it))
            }
        }
    }

    // --- The operation queue, one in flight per connection ---

    private fun enqueueOp(address: Long, op: Op) {
        handler.post {
            val connection = connections[address]
            if (connection == null || connection.state != State.READY) {
                deliver(GattEvent.OperationError(address, handleOf(op), ERROR_NOT_CONNECTED))
                return@post
            }
            opQueue.addLast(connection to op)
            pump()
        }
    }

    private fun handleOf(op: Op): Int = when (op) {
        is Op.Read -> op.handle
        is Op.Write -> op.handle
        is Op.ReadDescriptor -> op.handle
        is Op.WriteDescriptor -> op.handle
        is Op.Notify -> op.handle
    }

    @Suppress("DEPRECATION")
    @SuppressLint("MissingPermission")
    private fun pump() {
        if (inFlightOp != null) return
        // Skip ops whose connection died while they queued; their futures
        // resolve through the disconnect the client already saw.
        var next: Pair<Connection, Op>? = null
        while (opQueue.isNotEmpty()) {
            val candidate = opQueue.removeFirst()
            if (candidate.first.state == State.READY &&
                connections[candidate.first.address] === candidate.first) {
                next = candidate
                break
            }
        }
        val (connection, op) = next ?: return
        inFlightConnection = connection
        inFlightOp = op
        opTimeout = Runnable {
            Log.w(TAG, "operation timeout for ${formatAddress(connection.address)}")
            deliver(GattEvent.OperationError(
                connection.address, handleOf(op), ERROR_NOT_CONNECTED))
            inFlightConnection = null
            inFlightOp = null
            pump()
        }.also { handler.postDelayed(it, OPERATION_TIMEOUT_MS) }

        val gatt = connection.gatt
        val started = when (op) {
            is Op.Read -> {
                val characteristic = connection.handleToCharacteristic[op.handle]
                characteristic != null && gatt?.readCharacteristic(characteristic) == true
            }
            is Op.Write -> {
                val characteristic = connection.handleToCharacteristic[op.handle]
                if (characteristic == null) false else {
                    // The pre-33 write API works on every supported level;
                    // the 33+ variant exists for apps that need the result
                    // code, which the op timeout already covers.
                    characteristic.writeType = if (op.withResponse) {
                        BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
                    } else {
                        BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
                    }
                    characteristic.value = op.data
                    gatt?.writeCharacteristic(characteristic) == true
                }
            }
            is Op.ReadDescriptor -> {
                val descriptor = connection.handleToDescriptor[op.handle]
                descriptor != null && gatt?.readDescriptor(descriptor) == true
            }
            is Op.WriteDescriptor -> {
                val descriptor = connection.handleToDescriptor[op.handle]
                if (descriptor == null) false else {
                    descriptor.value = op.data
                    gatt?.writeDescriptor(descriptor) == true
                }
            }
            is Op.Notify -> {
                val characteristic = connection.handleToCharacteristic[op.handle]
                if (characteristic == null ||
                    gatt?.setCharacteristicNotification(characteristic, op.enable) != true) {
                    false
                } else {
                    val cccd = characteristic.getDescriptor(CCCD_UUID)
                    if (cccd == null) {
                        // No CCCD to write: the enable is already complete.
                        completeOp()
                        deliver(GattEvent.NotifyStateDone(connection.address, op.handle))
                        return
                    }
                    cccd.value = when {
                        !op.enable -> BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE
                        characteristic.properties and
                            BluetoothGattCharacteristic.PROPERTY_NOTIFY != 0 ->
                            BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                        else -> BluetoothGattDescriptor.ENABLE_INDICATION_VALUE
                    }
                    gatt.writeDescriptor(cccd)
                }
            }
        }
        if (!started) {
            Log.w(TAG, "op ${op.javaClass.simpleName} refused for " +
                "${formatAddress(connection.address)} handle=${handleOf(op)} " +
                "(unknown handle or stack refusal)")
            opTimeout?.let(handler::removeCallbacks)
            opTimeout = null
            deliver(GattEvent.OperationError(
                connection.address, handleOf(op), ERROR_NOT_CONNECTED))
            inFlightConnection = null
            inFlightOp = null
            pump()
        }
    }

    private fun completeOp() {
        opTimeout?.let(handler::removeCallbacks)
        opTimeout = null
        inFlightConnection = null
        inFlightOp = null
        handler.post { pump() }
    }

    // --- Stack callbacks: re-posted to the handler thread ---

    private fun callbackFor(connection: Connection) = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            handler.post {
                if (connections[connection.address] !== connection) return@post
                when {
                    newState == BluetoothProfile.STATE_CONNECTED && status == 0 -> {
                        connection.clearTimeout()
                        connection.state = State.MTU_WAIT
                        connection.armTimeout(MTU_TIMEOUT_MS) { afterMtuPhase(connection) }
                        @SuppressLint("MissingPermission")
                        if (gatt.requestMtu(REQUESTED_MTU) != true) afterMtuPhase(connection)
                    }
                    newState == BluetoothProfile.STATE_DISCONNECTED -> {
                        if (connection.state == State.CONNECTING ||
                            connection.state == State.MTU_WAIT ||
                            connection.state == State.DISCOVERING) {
                            failConnect(connection, if (status == 0) 133 else status)
                        } else {
                            finalizeDisconnect(connection, status)
                        }
                    }
                }
            }
        }

        override fun onMtuChanged(gatt: BluetoothGatt, mtu: Int, status: Int) {
            handler.post {
                if (connections[connection.address] !== connection) return@post
                if (status == 0) connection.mtu = mtu
                if (connection.state == State.MTU_WAIT) afterMtuPhase(connection)
            }
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            handler.post {
                if (connections[connection.address] !== connection) return@post
                if (connection.state != State.DISCOVERING) return@post
                if (status != 0) {
                    failConnect(connection, status)
                    return@post
                }
                buildServiceTree(connection, gatt)
                becomeReady(connection)
            }
        }

        @Suppress("DEPRECATION")
        override fun onCharacteristicRead(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            status: Int,
        ) {
            val data = characteristic.value ?: ByteArray(0)
            handler.post {
                if (connections[connection.address] !== connection) return@post
                if (inFlightConnection !== connection) return@post
                val op = inFlightOp as? Op.Read ?: return@post
                if (status == 0) {
                    deliver(GattEvent.ReadResult(connection.address, op.handle, data))
                } else {
                    deliver(GattEvent.OperationError(connection.address, op.handle, status))
                }
                completeOp()
            }
        }

        override fun onCharacteristicWrite(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            status: Int,
        ) {
            handler.post {
                if (connections[connection.address] !== connection) return@post
                if (inFlightConnection !== connection) return@post
                val op = inFlightOp as? Op.Write ?: return@post
                if (status != 0) {
                    deliver(GattEvent.OperationError(connection.address, op.handle, status))
                } else if (op.withResponse) {
                    deliver(GattEvent.WriteDone(connection.address, op.handle))
                }
                completeOp()
            }
        }

        @Suppress("DEPRECATION")
        override fun onDescriptorRead(
            gatt: BluetoothGatt,
            descriptor: BluetoothGattDescriptor,
            status: Int,
        ) {
            val data = descriptor.value ?: ByteArray(0)
            handler.post {
                if (connections[connection.address] !== connection) return@post
                if (inFlightConnection !== connection) return@post
                val op = inFlightOp as? Op.ReadDescriptor ?: return@post
                if (status == 0) {
                    deliver(GattEvent.ReadResult(connection.address, op.handle, data))
                } else {
                    deliver(GattEvent.OperationError(connection.address, op.handle, status))
                }
                completeOp()
            }
        }

        override fun onDescriptorWrite(
            gatt: BluetoothGatt,
            descriptor: BluetoothGattDescriptor,
            status: Int,
        ) {
            handler.post {
                if (connections[connection.address] !== connection) return@post
                if (inFlightConnection !== connection) return@post
                when (val op = inFlightOp) {
                    is Op.WriteDescriptor -> {
                        if (status == 0) {
                            deliver(GattEvent.WriteDone(connection.address, op.handle))
                        } else {
                            deliver(GattEvent.OperationError(
                                connection.address, op.handle, status))
                        }
                        completeOp()
                    }
                    is Op.Notify -> {
                        if (status == 0) {
                            deliver(GattEvent.NotifyStateDone(connection.address, op.handle))
                        } else {
                            deliver(GattEvent.OperationError(
                                connection.address, op.handle, status))
                        }
                        completeOp()
                    }
                    else -> Unit
                }
            }
        }

        @Suppress("DEPRECATION")
        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
        ) {
            val data = characteristic.value ?: ByteArray(0)
            handler.post {
                if (connections[connection.address] !== connection) return@post
                val handle = connection.characteristicToHandle[characteristic] ?: return@post
                deliver(GattEvent.NotifyData(connection.address, handle, data))
            }
        }
    }

    private fun afterMtuPhase(connection: Connection) {
        connection.clearTimeout()
        if (connection.state != State.MTU_WAIT) return
        // Discovery runs on cached connects too. The cache flag spares the
        // CLIENT its services request; it cannot spare us discovery, because
        // operations route through this connection's handle maps and only
        // discovery populates them. Skipping it here left every op on a
        // cached reconnect failing 0x81 with an empty map - found live the
        // first night Home Assistant reconnected EcoFlows with a warm
        // services cache and could never re-establish them. Android keeps
        // its own GATT database cache, so the on-air cost is small.
        startDiscovery(connection)
    }

    private fun buildServiceTree(connection: Connection, gatt: BluetoothGatt) {
        connection.handleToCharacteristic.clear()
        connection.handleToDescriptor.clear()
        connection.characteristicToHandle.clear()
        var nextHandle = 1
        val tree = ArrayList<GattService>()
        for (service in gatt.services) {
            val serviceHandle = nextHandle++
            val characteristics = ArrayList<GattCharacteristic>()
            for (characteristic in service.characteristics) {
                val characteristicHandle = nextHandle++
                connection.handleToCharacteristic[characteristicHandle] = characteristic
                connection.characteristicToHandle[characteristic] = characteristicHandle
                val descriptors = ArrayList<GattDescriptor>()
                for (descriptor in characteristic.descriptors) {
                    val descriptorHandle = nextHandle++
                    connection.handleToDescriptor[descriptorHandle] = descriptor
                    descriptors.add(GattDescriptor(
                        descriptor.uuid.mostSignificantBits,
                        descriptor.uuid.leastSignificantBits,
                        descriptorHandle,
                    ))
                }
                characteristics.add(GattCharacteristic(
                    characteristic.uuid.mostSignificantBits,
                    characteristic.uuid.leastSignificantBits,
                    characteristicHandle,
                    characteristic.properties,
                    descriptors,
                ))
            }
            tree.add(GattService(
                service.uuid.mostSignificantBits,
                service.uuid.leastSignificantBits,
                serviceHandle,
                characteristics,
            ))
        }
        connection.servicesTree = tree
    }

    // --- Pairing ---

    @SuppressLint("MissingPermission")
    private fun pairInternal(address: Long) {
        if (!bondReceiverRegistered) {
            bondReceiverRegistered = true
            context.registerReceiver(
                bondReceiver, IntentFilter(BluetoothDevice.ACTION_BOND_STATE_CHANGED))
        }
        val device = remoteDevice(address)
        when {
            device.bondState == BluetoothDevice.BOND_BONDED ->
                deliver(GattEvent.PairResult(address, true, 0))
            device.createBond() -> {
                pendingPairAddress = address
                handler.postDelayed({
                    if (pendingPairAddress == address) {
                        pendingPairAddress = null
                        deliver(GattEvent.PairResult(address, false, ERROR_NOT_CONNECTED))
                    }
                }, 15_000)
            }
            else -> deliver(GattEvent.PairResult(address, false, ERROR_NOT_CONNECTED))
        }
    }

    // The adapter dying takes every link with it, but whether Android
    // still delivers per-connection disconnect callbacks afterwards is
    // stack-dependent. This makes the outcome deterministic: finalize
    // every connection the moment the adapter reports off (close, free
    // the slot, tell the client), instead of leaving Home Assistant to
    // find out one operation timeout at a time. No STATE_ON branch here:
    // reconnection is the client's move, and connectInternal already
    // refuses cleanly until the adapter is really back.
    private val adapterReceiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context, intent: Intent) {
            if (intent.action != BluetoothAdapter.ACTION_STATE_CHANGED) return
            if (intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, -1)
                != BluetoothAdapter.STATE_OFF) return
            handler.post {
                if (connections.isEmpty()) return@post
                Log.w(TAG, "adapter off, dropping ${connections.size} GATT connection(s)")
                for (address in connections.keys.toList()) {
                    connections[address]?.let {
                        finalizeDisconnect(it, ERROR_NOT_CONNECTED)
                    }
                }
            }
        }
    }

    init {
        context.registerReceiver(
            adapterReceiver, IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED))
    }

    private val bondReceiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context, intent: Intent) {
            if (intent.action != BluetoothDevice.ACTION_BOND_STATE_CHANGED) return
            val device = intent.getParcelableExtra<BluetoothDevice>(
                BluetoothDevice.EXTRA_DEVICE) ?: return
            val state = intent.getIntExtra(BluetoothDevice.EXTRA_BOND_STATE, -1)
            handler.post {
                val address = pendingPairAddress ?: return@post
                if (device.address != formatAddress(address)) return@post
                when (state) {
                    BluetoothDevice.BOND_BONDED -> {
                        pendingPairAddress = null
                        deliver(GattEvent.PairResult(address, true, 0))
                    }
                    BluetoothDevice.BOND_NONE -> {
                        pendingPairAddress = null
                        deliver(GattEvent.PairResult(address, false, ERROR_NOT_CONNECTED))
                    }
                }
            }
        }
    }

    fun shutdown() {
        handler.post {
            for (address in connections.keys.toList()) {
                connections[address]?.let { finalizeDisconnect(it, 0) }
            }
            if (bondReceiverRegistered) {
                bondReceiverRegistered = false
                runCatching { context.unregisterReceiver(bondReceiver) }
            }
            runCatching { context.unregisterReceiver(adapterReceiver) }
        }
    }

    private fun remoteDevice(address: Long): BluetoothDevice {
        val adapter = (context.getSystemService(Context.BLUETOOTH_SERVICE)
            as BluetoothManager).adapter
        return adapter.getRemoteDevice(formatAddress(address))
    }

    private fun formatAddress(address: Long): String =
        (5 downTo 0).joinToString(":") { "%02X".format((address shr (it * 8)) and 0xFF) }
}
