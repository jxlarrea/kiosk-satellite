package me.jxl.kiosk_satellite.sendspin.network

/**
 * Builds syntactically valid WebSocket URLs from user-entered addresses.
 * Handles IPv6 literal bracket-wrapping per RFC 3986.
 *
 * ## Address forms accepted by [build]
 * - `host` or `host:port` where host is a hostname or IPv4 literal
 * - `[ipv6]` or `[ipv6]:port` - bracketed IPv6 with optional port
 * - bare IPv6 literal (2+ colons, no brackets) - treated as no port, wrapped
 *
 * ## Ambiguity convention
 * A bare string with 2+ colons is treated as an IPv6 literal with no port.
 * To combine an IPv6 literal with a port, the caller must bracket-wrap:
 * `[2001:db8::1]:8927`. This matches RFC 3986 authority syntax.
 */
object WebSocketUrlBuilder {

    /**
     * Build a WebSocket URL from a user-facing address plus path.
     *
     * @param address host or host:port, with IPv6 literals optionally in brackets
     * @param path request path (leading slash added if missing; empty path produces no trailing slash)
     * @param scheme URL scheme (default "ws"; use "wss" for TLS)
     */
    fun build(address: String, path: String, scheme: String = "ws"): String {
        val authority = formatAuthority(address)
        val pathPart = normalizePath(path)
        return "$scheme://$authority$pathPart"
    }

    /**
     * Build a WebSocket URL when host and port are already separated.
     * Wraps IPv6 literals in brackets; passes hostnames and IPv4 through unchanged.
     */
    fun buildFromHostPort(host: String, port: Int, path: String, scheme: String = "ws"): String {
        val hostPart = wrapIfIpv6Literal(stripBrackets(host))
        val pathPart = normalizePath(path)
        return "$scheme://$hostPart:$port$pathPart"
    }

    /**
     * Ensure a user-entered address has a port. Appends `:defaultPort` if none is present.
     * Handles IPv6 literals correctly, distinguishing bare-IPv6-2+-colons from host:port.
     *
     * Examples:
     * - `host` -> `host:8927`
     * - `host:8080` -> `host:8080` (unchanged)
     * - `192.168.1.1` -> `192.168.1.1:8927`
     * - `2001:db8::1` (bare IPv6) -> `[2001:db8::1]:8927`
     * - `[2001:db8::1]` (bracketed, no port) -> `[2001:db8::1]:8927`
     * - `[2001:db8::1]:8080` (bracketed with port) -> `[2001:db8::1]:8080` (unchanged)
     */
    fun ensureDefaultPort(address: String, defaultPort: Int): String {
        if (address.startsWith("[")) {
            val closeIdx = address.indexOf(']')
            val hasPort = closeIdx >= 0 && closeIdx < address.length - 1 &&
                          address[closeIdx + 1] == ':'
            return if (hasPort) address else "$address:$defaultPort"
        }
        val colonCount = address.count { it == ':' }
        return when {
            colonCount == 0 -> "$address:$defaultPort"       // hostname/IPv4 bare
            colonCount == 1 -> address                        // host:port already
            else -> "[$address]:$defaultPort"                 // bare IPv6 literal
        }
    }

    /**
     * Extract just the host portion of an address string, discarding any port and
     * unwrapping IPv6 brackets. The returned value is suitable for passing to
     * [buildFromHostPort] (which will re-wrap IPv6 literals as needed).
     *
     * Examples:
     * - `192.168.1.1` -> `192.168.1.1`
     * - `192.168.1.1:8927` -> `192.168.1.1`
     * - `host.example.com` -> `host.example.com`
     * - `host.example.com:8080` -> `host.example.com`
     * - `2001:db8::1` (bare IPv6) -> `2001:db8::1`
     * - `[2001:db8::1]` -> `2001:db8::1`
     * - `[2001:db8::1]:8927` -> `2001:db8::1`
     */
    fun extractHost(address: String): String {
        if (address.startsWith("[")) {
            val closeIdx = address.indexOf(']')
            if (closeIdx >= 0) {
                return address.substring(1, closeIdx)
            }
            // Malformed bracketed input - return as-is
            return address
        }
        val colonCount = address.count { it == ':' }
        return when {
            colonCount == 0 -> address                        // bare host
            colonCount == 1 -> address.substringBefore(':')   // host:port
            else -> address                                   // bare IPv6 literal - no port possible
        }
    }

    /**
     * Normalize an address string into an RFC 3986 authority component
     * (i.e. host or host:port, with IPv6 literals bracket-wrapped).
     */
    private fun formatAuthority(address: String): String {
        // Callers are responsible for stripping whitespace at the input boundary
        // (e.g. the wizard ViewModel). Don't silently swallow it here - that would
        // mask copy-paste issues that don't survive in other contexts.

        // Already bracketed? Keep as-is. Note: this is a pass-through for any
        // "[..." prefix; malformed bracketed input (no closing bracket) would
        // produce a malformed URL. Acceptable given trusted wizard inputs.
        if (address.startsWith("[")) {
            return address
        }

        val colonCount = address.count { it == ':' }
        return when {
            // No colons: bare hostname or IPv4, no port
            colonCount == 0 -> address

            // Exactly one colon: host:port (hostname or IPv4 with port)
            colonCount == 1 -> address

            // 2+ colons and no brackets: bare IPv6 literal, no port
            // Wrap the whole thing in brackets
            else -> "[$address]"
        }
    }

    private fun wrapIfIpv6Literal(host: String): String {
        return if (host.contains(':')) "[$host]" else host
    }

    private fun stripBrackets(host: String): String {
        return if (host.startsWith("[") && host.endsWith("]")) {
            host.substring(1, host.length - 1)
        } else {
            host
        }
    }

    private fun normalizePath(path: String): String {
        return when {
            path.isEmpty() -> ""
            path.startsWith("/") -> path
            else -> "/$path"
        }
    }
}
