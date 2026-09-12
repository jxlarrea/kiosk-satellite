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
    const val MANIFEST_NAME = "kiosk-satellite-plugin.json"

    // Previously installed packages retain their original filename and integrity digest.
    fun installedManifest(directory: File): File = File(directory, MANIFEST_NAME).let { current ->
        if (current.exists()) current else File(directory, "manifest.json")
    }

    private val allowed = setOf("kiosk-satellite-plugin.json", "plugin.jar", "LICENSE")

    private val nativePath = Regex("native/(arm64-v8a|armeabi-v7a|x86_64)/lib[a-zA-Z0-9_]+\\.so")
    fun nativeFiles(directory: File): List<File> = File(directory, "native").walkTopDown().filter { it.isFile }.toList()

    fun validAssetPath(path: String): Boolean = path.length in 1..240 &&
        path.split('/').all { it != "." && it != ".." && it.matches(Regex("[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}")) }

    fun assetFile(directory: File, path: String): File {
        require(validAssetPath(path)) { "Invalid asset path" }
        val base = File(directory.canonicalFile, "assets")
        val file = File(base, path)
        require(base.canonicalFile == base.absoluteFile && file.canonicalFile == file.absoluteFile && file.isFile) { "Asset is missing or outside its package" }
        return file
    }

    fun assetFiles(directory: File): List<File> {
        val base = File(directory.canonicalFile, "assets")
        require(base.canonicalFile == base.absoluteFile) { "Asset directory cannot be a symbolic link" }
        return base.walkTopDown().onEnter {
            require(it.canonicalFile == it.absoluteFile) { "Asset directories cannot be symbolic links" }; true
        }.filter { it.isFile }.map {
            assetFile(directory, it.relativeTo(base).invariantSeparatorsPath)
        }.toList()
    }

    fun verifyAssets(directory: File, digests: JSONObject) {
        val files = assetFiles(directory)
        require(files.size == digests.length()) { "Installed assets failed their integrity check" }
        for (file in files) require(sha256(file.readBytes()) == digests.getString(file.relativeTo(directory.canonicalFile).invariantSeparatorsPath)) { "Installed asset failed its integrity check" }
    }

    fun verifyManifest(actual: PluginManifest, expected: String) {
        val reviewed = PluginManifest(JSONObject(expected))
        require(jsonValue(actual.json) == jsonValue(reviewed.json)) {
            "Package manifest does not match the reviewed release manifest"
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
                    require(!entry.isDirectory && (entry.name in allowed || nativePath.matches(entry.name) || (entry.name.startsWith("assets/") && validAssetPath(entry.name.removePrefix("assets/")))) && seen.add(entry.name)) { "Unexpected or duplicate ZIP entry: ${entry.name}" }
                    require(seen.size <= 512) { "At most 512 package files are supported" }
                    val file = File(destination, entry.name)
                    file.parentFile!!.mkdirs()
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
                            require(entry.name != "kiosk-satellite-plugin.json" || fileSize <= 32768) { "Manifest exceeds 32 KB" }
                            output.write(buffer, 0, count)
                        }
                    }
                }
            }
            require(seen.containsAll(allowed)) { "Package needs kiosk-satellite-plugin.json, plugin.jar and LICENSE" }
            validateDex(File(destination, "plugin.jar"))
            val manifest = PluginManifest(JSONObject(File(destination, MANIFEST_NAME).readText()))
            val native = nativeFiles(destination)
            require(native.size <= 12 && (native.isEmpty() || ("native" in manifest.capabilities))) { "Native libraries require native capability" }
            for (file in native) {
                val header = file.readBytes().take(20).toByteArray()
                require(header.size == 20 && header.take(4) == listOf<Byte>(127, 69, 76, 70) && header[5] == 1.toByte()) { "Invalid native ELF library" }
                val abi = file.parentFile!!.name
                val machine = (header[18].toInt() and 255) or ((header[19].toInt() and 255) shl 8)
                require(machine == when (abi) { "arm64-v8a" -> 183; "armeabi-v7a" -> 40; else -> 62 } &&
                    header[4].toInt() == if (abi == "armeabi-v7a") 1 else 2) { "Native library ABI does not match its directory" }
            }
            return manifest
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
