package me.jxl.kiosk_satellite

import java.security.MessageDigest
import java.security.SecureRandom
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

/**
 * The JPEG behind the ONVIF snapshot URI (issue #1506). Requests that arrive
 * while a capture runs wait for that capture, and a frame younger than a
 * second answers the next request without another capture, so an NVR that
 * polls several times a second never stacks camera work.
 *
 * Authentication is HTTP Digest with the streaming credentials. Every HTTP
 * request on the ONVIF port arrives on its own connection, so the nonce is
 * signed with a key of this instance instead of being tied to a connection.
 */
class CameraOnvifSnapshot(
    private val username: String?,
    private val password: String,
    private val capture: ((ByteArray?, String?) -> Unit) -> Unit,
    private val clock: () -> Long = System::nanoTime,
) {
    data class Result(val jpeg: ByteArray?, val error: String?)

    private class Attempt(val startedNs: Long) {
        val finished = CountDownLatch(1)
        @Volatile var result: Result? = null
    }

    private val key = ByteArray(32).also { SecureRandom().nextBytes(it) }
    private val baseNs = clock()
    private var attempt: Attempt? = null
    private var latest: Result? = null
    private var latestNs = 0L

    fun take(timeoutMs: Long = TIMEOUT_MS): Result {
        val now = clock()
        var start = false
        val current = synchronized(this) {
            // Failures are reused too, so a camera that cannot capture is
            // not asked again by every request in a burst.
            latest?.let { if (now - latestNs < FRESH_NS) return it }
            // A capture that never answered must not hold every later request.
            attempt?.takeIf { now - it.startedNs < ABANDON_NS } ?: Attempt(now).also { attempt = it; start = true }
        }
        if (start) {
            try {
                capture { bytes, error -> finish(current, bytes, error) }
            } catch (e: Exception) {
                finish(current, null, e.message ?: "capture failed")
            }
        }
        if (!current.finished.await(timeoutMs, TimeUnit.MILLISECONDS)) return Result(null, "the camera did not answer in time")
        return current.result ?: Result(null, "capture failed")
    }

    private fun finish(current: Attempt, bytes: ByteArray?, error: String?) {
        synchronized(this) {
            if (current.result != null) return
            val result = if (bytes != null && bytes.isNotEmpty()) Result(bytes, null) else Result(null, error ?: "capture failed")
            current.result = result
            if (attempt === current) {
                attempt = null
                latest = result
                latestNs = clock()
            }
        }
        current.finished.countDown()
    }

    fun authorized(header: String?, method: String, uri: String): Boolean {
        if (username == null) return true
        if (header == null || !header.startsWith("Digest ", ignoreCase = true)) return false
        val fields = Regex("""([a-zA-Z]+)="([^"]*)"|([a-zA-Z]+)=([^, ]+)""")
            .findAll(header.substring(7)).associate {
                if (it.groupValues[1].isNotEmpty()) it.groupValues[1].lowercase() to it.groupValues[2]
                else it.groupValues[3].lowercase() to it.groupValues[4]
            }
        val nonce = fields["nonce"] ?: return false
        val digestUri = fields["uri"] ?: return false
        if (fields["username"] != username || fields["realm"] != REALM || !fresh(nonce) ||
            !sameResource(digestUri, uri) || (fields["algorithm"] != null && !fields["algorithm"].equals("MD5", ignoreCase = true))) return false
        val ha1 = md5("$username:$REALM:$password")
        val ha2 = md5("$method:$digestUri")
        val expected = when (val qop = fields["qop"]) {
            null -> md5("$ha1:$nonce:$ha2")
            "auth" -> {
                val nc = fields["nc"] ?: return false
                val cnonce = fields["cnonce"] ?: return false
                md5("$ha1:$nonce:$nc:$cnonce:$qop:$ha2")
            }
            else -> return false
        }
        return MessageDigest.isEqual(expected.toByteArray(), (fields["response"] ?: "").lowercase().toByteArray())
    }

    /** The challenge for a request without valid credentials. */
    fun challenge(stale: Boolean = false): String =
        "Digest realm=\"$REALM\", qop=\"auth\", nonce=\"${nonce(clock() - baseNs)}\", algorithm=MD5" + if (stale) ", stale=true" else ""

    /** Whether the header carries a nonce this instance signed that has since expired. */
    fun stale(header: String?): Boolean {
        val nonce = header?.let { Regex("""nonce="([^"]*)"""").find(it)?.groupValues?.get(1) } ?: return false
        val issued = nonce.substringBefore('-').toLongOrNull(16) ?: return false
        return nonce == nonce(issued) && !fresh(nonce)
    }

    /** [issuedNs] counts from [baseNs], so the stamp is never negative. */
    private fun nonce(issuedNs: Long): String {
        val stamp = java.lang.Long.toHexString(issuedNs)
        val mac = Mac.getInstance("HmacSHA256").apply { init(SecretKeySpec(key, "HmacSHA256")) }.doFinal(stamp.toByteArray())
        return stamp + "-" + mac.take(16).joinToString("") { "%02x".format(it.toInt() and 255) }
    }

    private fun fresh(nonce: String): Boolean {
        val issued = nonce.substringBefore('-').toLongOrNull(16) ?: return false
        val age = clock() - baseNs - issued
        return age in 0 until NONCE_NS && MessageDigest.isEqual(nonce.toByteArray(), nonce(issued).toByteArray())
    }

    // Clients sign either the request path or the absolute URL.
    private fun sameResource(digestUri: String, uri: String): Boolean {
        if (digestUri == uri) return true
        val path = try { java.net.URI(digestUri).rawPath } catch (_: Exception) { null }
        val requested = try { java.net.URI(uri).rawPath } catch (_: Exception) { null }
        if (path.isNullOrEmpty() || path != requested) return false
        val query = try { java.net.URI(digestUri).rawQuery } catch (_: Exception) { null }
        return query == (try { java.net.URI(uri).rawQuery } catch (_: Exception) { null })
    }

    private fun md5(text: String) = MessageDigest.getInstance("MD5").digest(text.toByteArray())
        .joinToString("") { "%02x".format(it.toInt() and 255) }

    companion object {
        const val REALM = "Kiosk Satellite"
        const val TIMEOUT_MS = 10_000L
        private const val FRESH_NS = 1_000_000_000L
        private const val ABANDON_NS = 25_000_000_000L
        private const val NONCE_NS = 300_000_000_000L
    }
}
