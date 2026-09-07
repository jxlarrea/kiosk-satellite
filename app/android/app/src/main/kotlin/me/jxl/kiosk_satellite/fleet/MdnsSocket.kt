package me.jxl.kiosk_satellite.fleet

import android.os.ParcelFileDescriptor
import android.system.Os
import android.system.OsConstants
import java.net.MulticastSocket

/** Keeps the TTL descriptor alive for exactly as long as its socket. */
internal class MdnsSocket(port: Int = 0) : MulticastSocket(port) {
    private var descriptor: ParcelFileDescriptor? = null

    @Synchronized
    fun setUnicastTtl() {
        check(!isClosed)
        // Before API 29 this wrapper shares the socket's descriptor. Losing
        // the wrapper to GC or closing it here would close the live socket.
        val owner = descriptor ?: ParcelFileDescriptor.fromDatagramSocket(this)
            .also { descriptor = it }
        val fd = owner.fileDescriptor
        Os.setsockoptInt(fd, OsConstants.IPPROTO_IP, OsConstants.IP_TTL, 255)
        Os.setsockoptInt(fd, OsConstants.IPPROTO_IPV6, OsConstants.IPV6_UNICAST_HOPS, 255)
    }

    @Synchronized
    override fun close() {
        // Close through DatagramSocket first to wake blocked receivers and
        // invalidate the shared descriptor on old Android. New Android has
        // a separate duplicate that must also be released.
        try {
            super.close()
        } finally {
            try {
                descriptor?.close()
            } finally {
                descriptor = null
            }
        }
    }
}
