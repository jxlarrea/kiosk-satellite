package me.jxl.kiosk_satellite.sendspin.transport

/**
 * Transport abstraction for SendSpin communication. Only the direct
 * WebSocket (local network) transport is implemented in Kiosk Satellite;
 * the interface is kept so the client code ports cleanly from the
 * SendspinDroid reference.
 *
 * ## Transport Lifecycle
 * ```
 * [Created] -> connect() -> [Connecting] -> [Connected] -> close() -> [Closed]
 *                              |              |
 *                           [Failed]     [Disconnected]
 * ```
 */
interface SendSpinTransport {

    /** Current connection state of the transport. */
    val state: TransportState

    /** Whether the transport is currently connected and can send messages. */
    val isConnected: Boolean
        get() = state == TransportState.Connected

    /** Initiate connection. Asynchronous; results delivered via [Listener]. */
    fun connect()

    /**
     * Send a text message (JSON protocol messages).
     * @return true if the message was queued for sending
     */
    fun send(text: String): Boolean

    /**
     * Send binary data.
     * @return true if the data was queued for sending
     */
    fun send(bytes: ByteArray): Boolean

    /**
     * Close the transport connection.
     * @param code Close code (1000 = normal, others indicate errors)
     * @param reason Human-readable close reason
     */
    fun close(code: Int = 1000, reason: String = "")

    /** Release all resources associated with this transport. */
    fun destroy()

    /** Set the listener for transport events. */
    fun setListener(listener: Listener?)

    /**
     * Listener interface for transport events. Callbacks are delivered on
     * the transport's IO threads, never the main thread.
     */
    interface Listener {
        fun onConnected()
        fun onMessage(text: String)
        fun onMessage(bytes: ByteArray)
        fun onClosing(code: Int, reason: String)
        fun onClosed(code: Int, reason: String)
        fun onFailure(error: Throwable, isRecoverable: Boolean)
    }
}

/** Connection state for transports. */
enum class TransportState {
    /** Initial state, not connected */
    Disconnected,

    /** Connection in progress */
    Connecting,

    /** Connected and ready to send/receive */
    Connected,

    /** Connection failed */
    Failed,

    /** Connection was closed (either by us or remote) */
    Closed
}
