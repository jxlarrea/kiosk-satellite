package me.jxl.kiosk_satellite.plugins

import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.file.Files
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

class PluginPackageTest {
    @Test fun displayGroupsValidateReferencesAndSettingGroups() {
        fun grouped(group: JSONObject): JSONObject = manifest().put("groups", org.json.JSONArray().put(group))
        val group = JSONObject().put("title", "Settings").put("readingsTitle", "Device readings")
            .put("readings", org.json.JSONArray().put("sensor.wave")).put("charts", org.json.JSONArray().put("demo"))
        PluginManifest(grouped(group))
        rejects { PluginManifest(manifest().put("groups", "invalid")) }
        rejects { PluginManifest(grouped(JSONObject(group.toString()).put("title", "Missing group"))) }
        rejects { PluginManifest(grouped(JSONObject(group.toString()).put("readings", org.json.JSONArray().put("invalid.wave")))) }
        rejects { PluginManifest(grouped(JSONObject(group.toString()).put("readings", org.json.JSONArray().put("sensor.wave").put("sensor.wave")))) }
        rejects { PluginManifest(grouped(JSONObject(group.toString()).put("charts", org.json.JSONArray().put("Bad key")))) }
        rejects { PluginManifest(manifest().put("groups", org.json.JSONArray().put(group).put(group))) }
    }

    @Test fun entitySettingsAndEventsAcceptOnlyExactEntityIds() {
        val setting = JSONObject().put("key", "entity").put("title", "Entity").put("type", "entity").put("default", "")
        val value = PluginManifest(manifest().put("settings", org.json.JSONArray().put(setting)))
        assertEquals("sensor.room", value.config(JSONObject().put("entity", "sensor.room"))["entity"])
        for (id in listOf("sensor.*", "../config", "sensor.room?token=x", "sensor.room/more")) {
            rejects { value.config(JSONObject().put("entity", id)) }
            assertFalse(PluginHostPolicy.validEvent("ha.entity.$id"))
        }
        assertTrue(PluginHostPolicy.validEvent("ha.entity.sensor.room"))
        assertTrue(PluginHostPolicy.validEvent("device.light"))
        assertFalse(PluginHostPolicy.validEvent("ha.entity."))
    }

    @Test fun firstPublicSdkSupportsAllExplicitCapabilities() {
        for (capability in listOf("overlay", "native", "entities", "host.read", "host.control", "shizuku")) {
            assertTrue(capability in PluginManifest(manifest().put("capabilities", org.json.JSONArray(listOf(capability)))).capabilities)
        }
        for (version in listOf(0, 2, 3, 4)) {
            rejects { PluginManifest(manifest().put("apiVersion", version)) }
        }
    }
    @Test fun asynchronousReadBudgetBoundsPendingAndRate() {
        val budget = PluginCommandBudget()
        val now = 2_000_000_000L
        repeat(8) { budget.acquire(now) }
        try { budget.acquire(now); fail("Pending limit") } catch (_: IllegalStateException) {}
        repeat(8) { budget.release() }
        repeat(12) { budget.acquire(now); budget.release() }
        try { budget.acquire(now); fail("Rate limit") } catch (_: IllegalStateException) {}
        budget.acquire(now + 1_000_000_000L)
        budget.release()
    }

    @Test fun actionPlacementsValidateAndSurviveOnlyForRetainedCommands() {
        val manifest = PluginManifest(manifest())
        val options = PluginActionOptions.configure(manifest, null,
            mapOf("command" to "show", "drawer" to true, "homeAssistant" to false))
        assertTrue(options.getJSONObject("show").getBoolean("drawer"))
        assertFalse(options.getJSONObject("show").getBoolean("homeAssistant"))
        options.put("removed", JSONObject().put("drawer", true))
        val retained = PluginActionOptions.retain(manifest, options)
        assertTrue(retained.has("show"))
        assertFalse(retained.has("removed"))
        assertEquals(0, PluginActionOptions.retain(manifest, null).length())
        rejects { PluginActionOptions.configure(manifest, options, mapOf("command" to "removed", "drawer" to true, "homeAssistant" to true)) }
        rejects { PluginActionOptions.configure(manifest, options, mapOf("command" to "show", "drawer" to "true", "homeAssistant" to true)) }
    }
    private fun manifest() = JSONObject("""{
      "schemaVersion":1,"apiVersion":1,"id":"hello-world","name":"Hello World",
      "version":"1.0.0","minAndroidSdk":24,"entryClass":"example.Hello",
      "description":"Example","author":"Example","license":"Apache-2.0",
      "capabilities":["overlay"],"commands":[{"id":"show","title":"Show"}],
      "settings":[{"key":"message","type":"string","title":"Greeting","default":"Hello"},
                  {"key":"enabled","type":"boolean","title":"Enabled","default":true}]
    }""")
    private fun zip(vararg entries: Pair<String, ByteArray>): ByteArray {
        val bytes = ByteArrayOutputStream()
        ZipOutputStream(bytes).use { zip -> entries.forEach { (name, value) ->
            zip.putNextEntry(ZipEntry(name)); zip.write(value); zip.closeEntry()
        } }
        return bytes.toByteArray()
    }
    private fun packageBytes(manifest: JSONObject = manifest(), dex: ByteArray = "dex\n035\u0000test".toByteArray()) = zip(
        "kiosk-satellite-plugin.json" to manifest.toString().toByteArray(),
        "plugin.jar" to zip("classes.dex" to dex),
        "LICENSE" to "Apache-2.0".toByteArray(),
    )
    private fun inTemp(action: (File) -> Unit) {
        val root = Files.createTempDirectory("plugin-test").toFile()
        try { action(File(root, "staged")) } finally { root.deleteRecursively() }
    }
    private fun rejects(action: () -> Unit) {
        try { action(); fail("Expected invalid input to be rejected") } catch (_: IllegalArgumentException) {}
    }
    @Test fun reviewedManifestMustMatchEveryPackagedField() {
        val actual = PluginManifest(manifest())
        PluginPackage.verifyManifest(actual, manifest().toString())
        rejects { PluginPackage.verifyManifest(actual, manifest().put("description", "Changed after review").toString()) }
        val changed = manifest()
        changed.getJSONArray("settings").getJSONObject(0).put("default", "Unexpected greeting")
        rejects { PluginPackage.verifyManifest(actual, changed.toString()) }
    }
    @Test fun reviewedManifestComparisonIgnoresObjectKeyOrder() {
        val actual = manifest()
        val reversed = JSONObject()
        actual.keys().asSequence().toList().reversed().forEach { reversed.put(it, actual.get(it)) }
        PluginPackage.verifyManifest(PluginManifest(actual), reversed.toString())
    }
    @Test fun assetsExtractAndTheirStoredDigestsDetectChanges() = inTemp { dir ->
        val data = ByteArray(300000) { 42 }
        PluginPackage.extract(zip(
            "kiosk-satellite-plugin.json" to manifest().toString().toByteArray(),
            "plugin.jar" to zip("classes.dex" to "dex\n035\u0000test".toByteArray()),
            "LICENSE" to "Apache-2.0".toByteArray(),
            "assets/photos/photo.png" to data,
        ), dir)
        val file = PluginPackage.assetFile(dir, "photos/photo.png")
        assertArrayEquals(data, file.readBytes())
        val digests = JSONObject().put("assets/photos/photo.png", PluginPackage.sha256(data))
        PluginPackage.verifyAssets(dir, digests)
        file.setWritable(true)
        file.writeText("changed")
        rejects { PluginPackage.verifyAssets(dir, digests) }
        rejects { PluginPackage.assetFile(dir, "../plugin.jar") }
    }
    @Test fun assetTraversalAndSymlinksAreRejected() = inTemp { dir ->
        for (path in listOf("assets/../outside", "assets//file", "assets/a/../../file", "assets/%2e%2e/file", "assets/a\\file")) {
            rejects { PluginPackage.extract(zip(path to byteArrayOf(1)), dir) }
            assertFalse(dir.exists())
        }
        File(dir, "assets").mkdirs()
        val outside = File(dir.parentFile, "outside").apply { writeText("private") }
        Files.createSymbolicLink(File(dir, "assets/link").toPath(), outside.toPath())
        rejects { PluginPackage.assetFiles(dir) }
    }

    @Test fun packageExtractsWithoutLoadingCode() = inTemp { dir ->
        val manifest = PluginPackage.extract(packageBytes(), dir)
        assertEquals("hello-world", manifest.id)
        assertEquals(setOf("LICENSE", "kiosk-satellite-plugin.json", "plugin.jar"), dir.list()!!.toSet())
    }
    @Test fun oldPackagesAreRejectedForNewInstalls() = inTemp { dir ->
        rejects { PluginPackage.extract(zip(
            "manifest.json" to manifest().toString().toByteArray(),
            "plugin.jar" to zip("classes.dex" to "dex\n035\u0000test".toByteArray()),
            "LICENSE" to "Apache-2.0".toByteArray(),
        ), dir) }
        assertFalse(dir.exists())
    }
    @Test fun existingPackagesKeepTheirManifestAndDigest() = inTemp { dir ->
        dir.mkdirs()
        val original = manifest().toString().toByteArray()
        File(dir, "manifest.json").writeBytes(original)
        val stored = PluginPackage.installedManifest(dir)
        assertEquals("hello-world", PluginManifest(JSONObject(stored.readText())).id)
        assertEquals(PluginPackage.sha256(original), PluginPackage.sha256(stored.readBytes()))
        File(dir, PluginPackage.MANIFEST_NAME).writeText(manifest().put("version", "1.0.1").toString())
        assertEquals("1.0.1", PluginManifest(JSONObject(PluginPackage.installedManifest(dir).readText())).version)
    }
    @Test fun traversalAndUnexpectedFilesNeverEscapeStaging() = inTemp { dir ->
        for (name in listOf("../outside", "/tmp/outside", "nested/plugin.jar", "native/lib.so")) {
            rejects { PluginPackage.extract(zip(name to byteArrayOf(1)), dir) }
            assertFalse(dir.exists())
        }
        assertFalse(File(dir.parentFile, "outside").exists())
    }
    @Test fun missingFilesAndBadDexAreRejected() = inTemp { dir ->
        rejects { PluginPackage.extract(zip("LICENSE" to byteArrayOf(1)), dir) }
        rejects { PluginPackage.extract(packageBytes(dex = "not dex".toByteArray()), dir) }
        assertFalse(dir.exists())
    }
    @Test fun compressedZipBombIsBounded() = inTemp { dir ->
        rejects { PluginPackage.extract(zip("plugin.jar" to ByteArray(PluginPackage.MAX_BYTES + 1)), dir) }
        assertFalse(dir.exists())
    }
    @Test fun nestedDexBombIsBounded() = inTemp { dir ->
        val dex = ByteArray(PluginPackage.MAX_BYTES + 1)
        "dex\n".toByteArray().copyInto(dex)
        rejects { PluginPackage.extract(packageBytes(dex = dex), dir) }
        assertFalse(dir.exists())
    }
    @Test fun unsupportedApiAndCapabilitiesAreRejected() {
        rejects { PluginManifest(manifest().put("apiVersion", 4)) }
        rejects { PluginManifest(manifest().put("capabilities", org.json.JSONArray("[\"root\"]"))) }
        rejects { PluginManifest(manifest().put("id", "../../host")) }
    }
    @Test fun settingsApplyDefaultsAndValidateTypes() {
        val manifest = PluginManifest(manifest())
        assertEquals(mapOf("message" to "Hello", "enabled" to true), manifest.config(JSONObject()))
        assertEquals("Hi", manifest.config(JSONObject().put("message", "Hi"))["message"])
        rejects { manifest.config(JSONObject().put("enabled", "true")) }
        rejects { manifest.config(JSONObject().put("unknown", 1)) }
        rejects { manifest.config(JSONObject().put("message", "x".repeat(513))) }
    }
    @Test fun duplicateSettingsAndCommandsAreRejected() {
        val settings = manifest()
        settings.getJSONArray("settings").put(settings.getJSONArray("settings").getJSONObject(0))
        rejects { PluginManifest(settings) }
        val commands = manifest()
        commands.getJSONArray("commands").put(commands.getJSONArray("commands").getJSONObject(0))
        rejects { PluginManifest(commands) }
    }
    @Test fun sdkOneValidatesRichSettingsAndNativePackages() = inTemp { dir ->
        val metadata = manifest().put("apiVersion", 1).put("capabilities", org.json.JSONArray("[\"native\",\"entities\"]"))
        metadata.put("settings", org.json.JSONArray("""[
          {"key":"brightness","title":"Brightness","type":"number","min":0,"max":100,"step":1,"default":50},
          {"key":"color","title":"Color","type":"color","default":"#123456"},
          {"key":"effect","title":"Effect","type":"select","options":["None","Pulse"],"default":"None"}
        ]"""))
        val model = PluginManifest(metadata)
        rejects { model.config(JSONObject().put("brightness", 101)) }
        rejects { model.config(JSONObject().put("brightness", 0.5)) }
        rejects { model.config(JSONObject().put("brightness", "50")) }
        rejects { model.config(JSONObject().put("color", "red")) }
        rejects { model.config(JSONObject().put("effect", "Other")) }
        val elf = ByteArray(20)
        byteArrayOf(127,69,76,70,2,1).copyInto(elf); elf[18] = 183.toByte()
        val bytes = zip(
            "kiosk-satellite-plugin.json" to metadata.toString().toByteArray(),
            "plugin.jar" to zip("classes.dex" to "dex\n035\u0000test".toByteArray()),
            "LICENSE" to "Apache-2.0".toByteArray(), "native/arm64-v8a/libtest.so" to elf)
        assertEquals(1, PluginPackage.extract(bytes, dir).apiVersion)
        assertEquals(1, PluginPackage.nativeFiles(dir).size)
    }
    @Test fun rgbStateRejectsUnknownOrInvalidFields() {
        val state = mapOf<String, Any>("on" to true, "brightness" to 0.5, "red" to 1.0, "green" to 0.0, "blue" to 0.2, "effect" to "Pulse")
        assertEquals(state, PluginLightState.validate(state, listOf("Pulse")))
        rejects { PluginLightState.validate(state + ("red" to Double.NaN), listOf("Pulse")) }
        rejects { PluginLightState.validate(state + ("effect" to "Missing"), listOf("Pulse")) }
        rejects { PluginLightState.validate(state + ("other" to 1), listOf("Pulse")) }
    }
    @Test fun digestMatchesKnownVector() {
        assertEquals("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", PluginPackage.sha256("abc".toByteArray()))
    }
}
