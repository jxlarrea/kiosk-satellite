package me.jxl.kiosk_satellite

import android.content.Context
import me.jxl.kiosk_satellite.updates.HelperProtocol
import java.io.DataInputStream
import java.io.DataOutputStream
import java.io.File
import java.io.IOException
import java.security.SecureRandom

/** The bootstrap secret stays in private app storage and is disclosed only to ADB. */
class UpdateHelperClient(private val context: Context) {
    companion object {
        const val START_COMMAND =
            "adb shell \"content read --uri content://me.jxl.kiosk_satellite.update-helper/start | sh\""

        @Synchronized
        fun token(context: Context): String {
            val prefs = context.getSharedPreferences("update_helper", Context.MODE_PRIVATE)
            prefs.getString("token", null)?.let { return it }
            val bytes = ByteArray(32).also { SecureRandom().nextBytes(it) }
            val token = bytes.joinToString("") { "%02x".format(it) }
            check(prefs.edit().putString("token", token).commit())
            return token
        }
    }

    private fun connect(operation: String) = HelperProtocol.connect(
        context.applicationInfo.uid, token(context), operation)

    fun status(): String = try {
        connect("PING").use { DataInputStream(it.getInputStream()).readUTF() }
            .takeIf { it == "ready" || it == "busy" } ?: "unavailable"
    } catch (_: IOException) {
        "unavailable"
    }

    fun stop(): String = connect("STOP").use {
        DataInputStream(it.getInputStream()).readUTF()
    }

    /**
     * False means no commit was sent, so falling back to Android is safe.
     * An error after COMMIT has an uncertain outcome and must never retry
     * automatically. A successful self-update usually kills this caller.
     */
    fun install(apk: File): Boolean {
        var committed = false
        try {
            connect("INSTALL").use { socket ->
                socket.soTimeout = 180000
                val input = DataInputStream(socket.getInputStream())
                val output = DataOutputStream(socket.getOutputStream())
                val ready = input.readUTF()
                check(ready != "busy") { "The update helper is already installing an update" }
                check(ready == "upload") { ready }
                output.writeLong(apk.length())
                apk.inputStream().use { it.copyTo(output, 65536) }
                output.flush()
                val prepared = input.readUTF()
                check(prepared == "prepared") { prepared }
                // Mark before writing: a failed write can still have reached
                // the helper, so the outcome is uncertain from this point.
                committed = true
                output.writeUTF("COMMIT")
                output.flush()
                val accepted = input.readUTF()
                check(accepted == "accepted") { accepted }
                val result = input.readUTF()
                check(result == "installed") { result }
                return true
            }
        } catch (e: IOException) {
            if (!committed) return false
            throw IOException("Lost contact with the update helper after committing. " +
                "Check the installed version before trying again.", e)
        }
    }
}
