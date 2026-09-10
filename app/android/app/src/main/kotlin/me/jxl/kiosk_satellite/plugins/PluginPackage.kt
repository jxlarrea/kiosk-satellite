package me.jxl.kiosk_satellite.plugins

import java.io.ByteArrayInputStream
import java.io.File
import java.io.FileOutputStream
import java.security.MessageDigest
import java.util.zip.ZipInputStream
import org.json.JSONObject

/** Extract only the SDK 1 files into a new private directory. No plugin code runs here. */
object PluginPackage {
    const val MAX_BYTES = 4 * 1024 * 1024
    private val allowed = setOf("manifest.json", "plugin.jar", "LICENSE")

    fun verifyManifest(actual: PluginManifest, expected: String) {
        val reviewed = PluginManifest(JSONObject(expected))
        require(jsonValue(actual.json) == jsonValue(reviewed.json)) {
            "Package manifest does not match the reviewed repository manifest"
        }
    }

    fun extract(bytes: ByteArray, destination: File): PluginManifest {
        require(bytes.size in 1..MAX_BYTES) { "Plugin ZIP must be at most 4 MB" }
        require(!destination.exists()) { "Staging directory already exists" }
        check(destination.mkdirs()) { "Cannot create plugin directory" }
        try {
            var expanded = 0
            val seen = mutableSetOf<String>()
            ZipInputStream(ByteArrayInputStream(bytes)).use { zip ->
                while (true) {
                    val entry = zip.nextEntry ?: break
                    require(!entry.isDirectory && entry.name in allowed && seen.add(entry.name)) { "Unexpected or duplicate ZIP entry: ${entry.name}" }
                    val file = File(destination, entry.name)
                    FileOutputStream(file).use { output ->
                        // Android 14 requires DEX containers to be read-only before writing.
                        check(file.setReadOnly()) { "Cannot protect plugin file" }
                        val buffer = ByteArray(8192)
                        var fileSize = 0
                        while (true) {
                            val count = zip.read(buffer)
                            if (count < 0) break
                            expanded += count
                            fileSize += count
                            require(expanded <= MAX_BYTES) { "Expanded plugin exceeds 4 MB" }
                            require(entry.name != "manifest.json" || fileSize <= 32768) { "Manifest exceeds 32 KB" }
                            output.write(buffer, 0, count)
                        }
                    }
                }
            }
            require(seen == allowed) { "Package needs manifest.json, plugin.jar and LICENSE" }
            validateDex(File(destination, "plugin.jar"))
            return PluginManifest(JSONObject(File(destination, "manifest.json").readText()))
        } catch (error: Throwable) {
            destination.deleteRecursively()
            throw error
        }
    }

    private fun validateDex(jar: File) {
        var expanded = 0
        val seen = mutableSetOf<String>()
        ZipInputStream(jar.inputStream()).use { zip ->
            while (true) {
                val entry = zip.nextEntry ?: break
                require(entry.name.matches(Regex("classes(?:[2-9]|[1-9][0-9]+)?\\.dex")) && seen.add(entry.name)) { "plugin.jar must contain only DEX files" }
                val buffer = ByteArray(8192)
                var fileSize = 0
                while (true) {
                    val count = zip.read(buffer)
                    if (count < 0) break
                    if (fileSize == 0) require(count >= 4 && buffer.copyOfRange(0, 4).contentEquals(byteArrayOf(100, 101, 120, 10))) { "Invalid DEX header" }
                    fileSize += count
                    expanded += count
                    require(expanded <= MAX_BYTES) { "Expanded DEX exceeds 4 MB" }
                }
                require(fileSize > 0) { "Empty DEX file" }
            }
        }
        require("classes.dex" in seen) { "plugin.jar has no classes.dex" }
    }

    fun sha256(bytes: ByteArray): String = MessageDigest.getInstance("SHA-256").digest(bytes).joinToString("") { "%02x".format(it) }
}
