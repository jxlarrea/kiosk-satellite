package me.jxl.kiosk_satellite.sendspin.protocol.message

import me.jxl.kiosk_satellite.sendspin.protocol.SendSpinProtocol
import android.util.Log

object BinaryMessageParser {
    private const val TAG = "BinaryMessageParser"
    private const val HEADER_SIZE = SendSpinProtocol.BINARY_HEADER_SIZE_BYTES

    sealed class BinaryMessage {
        data class Audio(
            val timestampMicros: Long,
            val payload: ByteArray
        ) : BinaryMessage() {
            override fun equals(other: Any?): Boolean {
                if (this === other) return true
                if (other !is Audio) return false
                if (timestampMicros != other.timestampMicros) return false
                if (!payload.contentEquals(other.payload)) return false
                return true
            }

            override fun hashCode(): Int {
                var result = timestampMicros.hashCode()
                result = 31 * result + payload.contentHashCode()
                return result
            }
        }

        data class Artwork(
            val channel: Int,
            val timestampMicros: Long,
            val payload: ByteArray
        ) : BinaryMessage() {
            override fun equals(other: Any?): Boolean {
                if (this === other) return true
                if (other !is Artwork) return false
                if (channel != other.channel) return false
                if (timestampMicros != other.timestampMicros) return false
                if (!payload.contentEquals(other.payload)) return false
                return true
            }

            override fun hashCode(): Int {
                var result = channel
                result = 31 * result + timestampMicros.hashCode()
                result = 31 * result + payload.contentHashCode()
                return result
            }
        }

        data class Visualizer(
            val timestampMicros: Long,
            val payload: ByteArray
        ) : BinaryMessage() {
            override fun equals(other: Any?): Boolean {
                if (this === other) return true
                if (other !is Visualizer) return false
                if (timestampMicros != other.timestampMicros) return false
                if (!payload.contentEquals(other.payload)) return false
                return true
            }

            override fun hashCode(): Int {
                var result = timestampMicros.hashCode()
                result = 31 * result + payload.contentHashCode()
                return result
            }
        }

        data class Unknown(
            val type: Int,
            val timestampMicros: Long,
            val payload: ByteArray
        ) : BinaryMessage() {
            override fun equals(other: Any?): Boolean {
                if (this === other) return true
                if (other !is Unknown) return false
                if (type != other.type) return false
                if (timestampMicros != other.timestampMicros) return false
                if (!payload.contentEquals(other.payload)) return false
                return true
            }

            override fun hashCode(): Int {
                var result = type
                result = 31 * result + timestampMicros.hashCode()
                result = 31 * result + payload.contentHashCode()
                return result
            }
        }
    }

    /**
     * Parse binary message from a ByteArray.
     */
    fun parse(bytes: ByteArray): BinaryMessage? {
        if (bytes.size < HEADER_SIZE) {
            Log.w(TAG, "Binary message too short: ${bytes.size} bytes")
            return null
        }

        val msgType = bytes[0].toInt() and 0xFF

        // Extract timestamp (big-endian int64) from bytes 1-8
        val timestampMicros = ((bytes[1].toLong() and 0xFF) shl 56) or
                ((bytes[2].toLong() and 0xFF) shl 48) or
                ((bytes[3].toLong() and 0xFF) shl 40) or
                ((bytes[4].toLong() and 0xFF) shl 32) or
                ((bytes[5].toLong() and 0xFF) shl 24) or
                ((bytes[6].toLong() and 0xFF) shl 16) or
                ((bytes[7].toLong() and 0xFF) shl 8) or
                (bytes[8].toLong() and 0xFF)

        // Get payload (everything after header)
        val payload = bytes.copyOfRange(HEADER_SIZE, bytes.size)

        return createMessage(msgType, timestampMicros, payload)
    }

    private fun createMessage(msgType: Int, timestampMicros: Long, payload: ByteArray): BinaryMessage {
        return when (msgType) {
            SendSpinProtocol.BinaryType.AUDIO -> {
                BinaryMessage.Audio(timestampMicros, payload)
            }
            in SendSpinProtocol.BinaryType.ARTWORK_BASE..(SendSpinProtocol.BinaryType.ARTWORK_BASE + 3) -> {
                val channel = msgType - SendSpinProtocol.BinaryType.ARTWORK_BASE
                BinaryMessage.Artwork(channel, timestampMicros, payload)
            }
            SendSpinProtocol.BinaryType.VISUALIZER -> {
                BinaryMessage.Visualizer(timestampMicros, payload)
            }
            else -> {
                Log.v(TAG, "Unknown binary message type: $msgType")
                BinaryMessage.Unknown(msgType, timestampMicros, payload)
            }
        }
    }
}
