package me.jxl.kiosk_satellite.btproxy

import java.util.concurrent.CopyOnWriteArrayList

/**
 * A deterministic in-JVM GATT backend for protocol tests: answers every
 * request instantly and records the calls. What the Android engine must
 * feed, minus Android.
 */
internal class ScriptedGatt : GattBackend {
    override val connectionLimit = 2
    val calls = CopyOnWriteArrayList<String>()
    var server: ApiServer? = null

    override fun connect(address: Long, addressType: Int?, withCache: Boolean) {
        calls.add("connect:$address:cache=$withCache")
        server?.deliverGattEvent(GattEvent.Connected(address, 247))
    }

    override fun disconnect(address: Long) {
        calls.add("disconnect:$address")
        server?.deliverGattEvent(GattEvent.Disconnected(address))
    }

    override fun getServices(address: Long) {
        calls.add("services:$address")
        // Battery service tree with real Bluetooth base-UUID halves.
        val baseLo = 0x800000805F9B34FBuL.toLong()
        server?.deliverGattEvent(GattEvent.Services(address, listOf(
            GattService(0x0000180F_00001000L, baseLo, 1, listOf(
                GattCharacteristic(0x00002A19_00001000L, baseLo, 2,
                    0x12, listOf(GattDescriptor(0x00002902_00001000L, baseLo, 3))),
            )),
            GattService(0x0000180A_00001000L, baseLo, 4, emptyList()),
        )))
    }

    override fun read(address: Long, handle: Int) {
        server?.deliverGattEvent(
            GattEvent.ReadResult(address, handle, byteArrayOf(0x64)))
    }

    override fun write(address: Long, handle: Int, data: ByteArray, withResponse: Boolean) {
        calls.add("write:$address:$handle:${data.size}:rsp=$withResponse")
        if (withResponse) {
            server?.deliverGattEvent(GattEvent.WriteDone(address, handle))
        }
    }

    override fun readDescriptor(address: Long, handle: Int) {
        server?.deliverGattEvent(
            GattEvent.ReadResult(address, handle, byteArrayOf(0x01, 0x00)))
    }

    override fun writeDescriptor(address: Long, handle: Int, data: ByteArray) {
        server?.deliverGattEvent(GattEvent.WriteDone(address, handle))
    }

    override fun setNotify(address: Long, handle: Int, enable: Boolean) {
        calls.add("notify:$address:$handle:$enable")
        server?.deliverGattEvent(GattEvent.NotifyStateDone(address, handle))
        if (enable) {
            server?.deliverGattEvent(
                GattEvent.NotifyData(address, handle, byteArrayOf(0x2A)))
        }
    }

    override fun pair(address: Long) {
        server?.deliverGattEvent(GattEvent.PairResult(address, true, 0))
    }

    override fun unpair(address: Long) {
        server?.deliverGattEvent(GattEvent.UnpairResult(address, true, 0))
    }

    override fun clearCache(address: Long) {
        server?.deliverGattEvent(GattEvent.ClearCacheResult(address, true, 0))
    }

    override fun disconnectAll() { calls.add("disconnectAll") }
}
