package me.jxl.kiosk_satellite.sendspin.transport

import android.util.Log
import me.jxl.kiosk_satellite.sendspin.network.WebSocketUrlBuilder
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import okio.ByteString

/**
 * Plain OkHttp WebSocket transport for local network SendSpin connections.
 *
 * Replaces the reference app's Ktor transport with identical callback
 * semantics: text frames carry JSON protocol messages, binary frames carry
 * raw audio/artwork payloads, a 15 s protocol-level ping keeps the socket
 * alive, and connection attempts time out after 5 s.
 *
 * ## Connection URL
 * Format: `ws://host:port/path` (e.g., `ws://192.168.1.100:8927/sendspin`)
 *
 * @param address Server address in "host:port" format
 * @param path WebSocket path (default: "/sendspin")
 */
class OkHttpWebSocketTransport(
    private val address: String,
    private val path: String = "/sendspin",
) : SendSpinTransport {

    companion object {
        private const val TAG = "sendspin"
        private const val PING_INTERVAL_SECONDS = 15L
        private const val CONNECT_TIMEOUT_MS = 5000L

        // One shared client for all transports: connection attempts are cheap
        // to configure per-request, and OkHttp's pooled threads idle out on
        // their own. Never call close/shutdown on this.
        private val sharedClient: OkHttpClient by lazy {
            OkHttpClient.Builder()
                .connectTimeout(CONNECT_TIMEOUT_MS, TimeUnit.MILLISECONDS)
                .pingInterval(PING_INTERVAL_SECONDS, TimeUnit.SECONDS)
                // Streaming socket: no read timeout, frames may be sparse when idle.
                .readTimeout(0, TimeUnit.MILLISECONDS)
                .build()
        }
    }

    private val _state = AtomicReference(TransportState.Disconnected)
    override val state: TransportState get() = _state.get()

    @Volatile
    private var listener: SendSpinTransport.Listener? = null

    @Volatile
    private var webSocket: WebSocket? = null

    override fun setListener(listener: SendSpinTransport.Listener?) {
        this.listener = listener
    }

    override fun connect() {
        if (!_state.compareAndSet(TransportState.Disconnected, TransportState.Connecting) &&
            !_state.compareAndSet(TransportState.Failed, TransportState.Connecting) &&
            !_state.compareAndSet(TransportState.Closed, TransportState.Connecting)
        ) {
            Log.w(TAG, "Transport cannot connect: already $state")
            return
        }

        val wsUrl = WebSocketUrlBuilder.build(address, path)
        Log.d(TAG, "Transport connecting to: $wsUrl")

        // OkHttp's Request.Builder silently rewrites ws:// to http:// for the
        // upgrade request, so the ws URL can be passed straight through.
        val request = Request.Builder().url(wsUrl).build()
        webSocket = sharedClient.newWebSocket(request, SocketListener())
    }

    override fun send(text: String): Boolean {
        if (!isConnected) {
            Log.w(TAG, "Transport cannot send text: not connected (state=$state)")
            return false
        }
        return webSocket?.send(text) ?: false
    }

    override fun send(bytes: ByteArray): Boolean {
        if (!isConnected) {
            Log.w(TAG, "Transport cannot send bytes: not connected (state=$state)")
            return false
        }
        return webSocket?.send(ByteString.of(*bytes)) ?: false
    }

    override fun close(code: Int, reason: String) {
        Log.d(TAG, "Closing WebSocket: code=$code reason=$reason")
        val ws = webSocket
        if (ws != null) {
            if (code == 1000) {
                // Graceful shutdown: send a Close frame and let the handshake finish.
                val closed = try {
                    ws.close(1000, reason.take(120))
                } catch (_: IllegalArgumentException) {
                    false
                }
                if (!closed) ws.cancel()
            } else {
                // Forced teardown (stall watchdog etc.): a dead peer would never
                // acknowledge a Close frame, so cancel outright. This surfaces as
                // a recoverable onFailure, which drives the reconnect path.
                ws.cancel()
            }
        }
    }

    override fun destroy() {
        webSocket?.cancel()
        webSocket = null
        _state.set(TransportState.Closed)
    }

    /**
     * Check if an error is likely temporary (network glitch) vs. permanent
     * (config error or a leaked programming bug). Defaults to NOT recoverable
     * for unknown errors so a misbehaving client cannot reconnect forever
     * against a server that was already fine.
     */
    private fun isRecoverableError(t: Throwable): Boolean {
        val cause = t.cause ?: t
        val message = t.message?.lowercase() ?: ""
        val causeName = cause::class.simpleName?.lowercase() ?: ""

        return when {
            // Network errors that might resolve themselves
            causeName.contains("socketexception") -> true
            causeName.contains("eofexception") -> true
            causeName.contains("sockettimeoutexception") -> true
            causeName.contains("timeoutexception") -> true
            message.contains("reset") -> true
            message.contains("abort") -> true
            message.contains("broken pipe") -> true
            message.contains("connection closed") -> true
            message.contains("timeout") -> true
            message.contains("canceled") -> true

            // Configuration errors that won't fix themselves
            causeName.contains("unknownhostexception") -> false
            causeName.contains("sslhandshakeexception") -> false
            causeName.contains("connectexception") -> false
            causeName.contains("noroutetohostexception") -> false
            message.contains("refused") -> false
            message.contains("unknown host") -> false
            message.contains("no route") -> false

            else -> {
                Log.d(TAG, "isRecoverableError: unrecognized throwable $causeName msg='$message' -> unrecoverable")
                false
            }
        }
    }

    private inner class SocketListener : WebSocketListener() {
        override fun onOpen(webSocket: WebSocket, response: Response) {
            Log.d(TAG, "WebSocket connected")
            _state.set(TransportState.Connected)
            listener?.onConnected()
        }

        override fun onMessage(webSocket: WebSocket, text: String) {
            listener?.onMessage(text)
        }

        override fun onMessage(webSocket: WebSocket, bytes: ByteString) {
            listener?.onMessage(bytes.toByteArray())
        }

        override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
            Log.d(TAG, "WebSocket closing: $code $reason")
            listener?.onClosing(code, reason)
            // Acknowledge the server's Close frame so onClosed fires.
            try {
                webSocket.close(1000, null)
            } catch (_: Exception) {
            }
        }

        override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
            Log.d(TAG, "WebSocket closed: $code $reason")
            _state.set(TransportState.Closed)
            listener?.onClosed(code, reason)
        }

        override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
            Log.e(TAG, "WebSocket failure: ${t.message}")
            _state.set(TransportState.Failed)
            listener?.onFailure(t, isRecoverableError(t))
        }
    }
}
