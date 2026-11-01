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
        // Wildcards claim readings and charts whose keys only exist at runtime.
        PluginManifest(grouped(JSONObject(group.toString()).put("readings", org.json.JSONArray().put("*").put("binary_sensor.*")).put("charts", org.json.JSONArray().put("*"))))
        rejects { PluginManifest(grouped(JSONObject(group.toString()).put("readings", org.json.JSONArray().put("sensor.wave*")))) }
        rejects { PluginManifest(grouped(JSONObject(group.toString()).put("readings", org.json.JSONArray().put("*.wave")))) }
        rejects { PluginManifest(grouped(JSONObject(group.toString()).put("readings", org.json.JSONArray().put("*").put("*")))) }
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

    @Test fun secretSettingsAreMaskedAndKeptWhenEditedUnchanged() {
        val secret = JSONObject().put("key", "token").put("title", "Token").put("type", "secret").put("default", "")
        val name = JSONObject().put("key", "name").put("title", "Name").put("type", "string").put("default", "")
        val value = PluginManifest(manifest().put("settings", org.json.JSONArray().put(secret).put(name)))
        rejects { PluginManifest(manifest().put("settings", org.json.JSONArray().put(JSONObject(secret.toString()).put("default", "hunter2")))) }
        rejects { value.config(JSONObject().put("token", 42)) }
        val saved = JSONObject(value.config(JSONObject().put("token", "hunter2").put("name", "Hall")))
        val masked = value.masked(saved)
        assertEquals(PluginManifest.SECRET_SET, masked.getString("token"))
        assertEquals("Hall", masked.getString("name"))
        assertEquals("", value.masked(JSONObject().put("token", "")).getString("token"))
        // Echoing the masked listing back, or omitting the secret, keeps the saved value.
        assertEquals("hunter2", value.config(value.unmasked(masked.put("name", "Den"), saved))["token"])
        assertEquals("hunter2", value.config(value.unmasked(JSONObject().put("name", "Den"), saved))["token"])
        assertEquals("rotated", value.config(value.unmasked(JSONObject().put("token", "rotated"), saved))["token"])
        assertEquals("", value.config(value.unmasked(JSONObject().put("token", ""), saved))["token"])
    }

    private fun listManifest() = manifest().put("settings", org.json.JSONArray("""[
      {"key":"collapse","type":"select","title":"Collapse","default":"Off","options":["Off","On"]},
      {"key":"after","type":"number","title":"After","default":0,"min":0,"max":60,"visibleWhen":{"key":"collapse","notEquals":"Off"}},
      {"key":"items","type":"list","title":"Items","maxItems":4,"addTitle":"Add item",
       "row":{"title":"label","subtitle":["page","opens"],"icon":"icon"},
       "default":[{"label":"Home","page":"lovelace/0"}],
       "fields":[
         {"key":"label","type":"string","title":"Label","required":true},
         {"key":"icon","type":"icon","title":"Icon"},
         {"key":"opens","type":"select","title":"Opens","options":["Page","Camera view","Menu"]},
         {"key":"page","type":"dashboard","title":"Page","required":true,"visibleWhen":{"key":"opens","equals":"Page"}},
         {"key":"camera","type":"cameraView","title":"Camera","required":true,"visibleWhen":{"key":"opens","equals":"Camera view"}},
         {"key":"entries","type":"list","title":"Entries","minItems":1,"maxItems":16,"visibleWhen":{"key":"opens","equals":"Menu"},
          "fields":[{"key":"label","type":"string","title":"Label","required":true},{"key":"page","type":"dashboard","title":"Page"}]}
       ]}
    ]"""))

    @Test fun listSettingsFillRowsAndReachThePluginAsLists() {
        val value = PluginManifest(listManifest())
        val defaults = value.config(JSONObject())
        val items = defaults["items"] as List<*>
        assertEquals(1, items.size)
        val home = items[0] as Map<*, *>
        assertEquals(setOf("label", "icon", "opens", "page", "camera", "entries"), home.keys)
        assertEquals("Page", home["opens"])
        assertEquals(emptyList<Any>(), home["entries"])
        assertThrows(UnsupportedOperationException::class.java) { (items as MutableList<Any>).add("more") }
        // A row read back from the stored form, the way PluginBridge saves it, is the same row.
        val stored = JSONObject(defaults)
        assertEquals(defaults, value.config(stored))
        val menu = org.json.JSONArray("""[{"label":"Cameras","opens":"Menu","entries":[{"label":"Front","page":"lovelace/front"}]}]""")
        val nested = (value.config(JSONObject().put("items", menu))["items"] as List<*>)[0] as Map<*, *>
        assertEquals("lovelace/front", ((nested["entries"] as List<*>)[0] as Map<*, *>)["page"])
        // Lists arriving from Dart are plain collections.
        assertEquals(1, (value.config(JSONObject(mapOf("items" to listOf(mapOf("label" to "Den", "page" to "/lovelace/den")))))["items"] as List<*>).size)
    }

    @Test fun listSettingsEnforceShownFieldsOnly() {
        val value = PluginManifest(listManifest())
        fun items(json: String) = JSONObject().put("items", org.json.JSONArray(json))
        // A hidden required field may stay empty. A shown one may not.
        value.config(items("""[{"label":"Front","opens":"Camera view","camera":"a1b2c3d4e5f60718293a4b5c6d7e8f90"}]"""))
        rejects { value.config(items("""[{"label":"Front","opens":"Camera view"}]""")) }
        rejects { value.config(items("""[{"label":" ","page":"lovelace/0"}]""")) }
        rejects { value.config(items("""[{"label":"Menu","opens":"Menu","entries":[]}]""")) }
        rejects { value.config(items("""[{"label":"Home","page":"lovelace/0","color":"red"}]""")) }
        rejects { value.config(items("""[{"label":"Home","page":"lovelace/0?x=1"}]""")) }
        rejects { value.config(items("""[{"label":"Home","page":"lovelace/0","icon":"home"}]""")) }
        rejects { value.config(items("[" + List(5) { """{"label":"$it","page":"p"}""" }.joinToString(",") + "]")) }
        rejects { value.config(JSONObject().put("items", "Home = /lovelace/0")) }
        val long = "x".repeat(500)
        rejects { value.config(items("[" + List(4) { """{"label":"$long","opens":"Menu","entries":[${List(16) { """{"label":"$long"}""" }.joinToString(",")}]}""" }.joinToString(",") + "]")) }
        assertEquals(30, value.config(JSONObject().put("collapse", "On").put("after", 30))["after"])
    }

    @Test fun listSchemasAreValidated() {
        fun withItems(change: (JSONObject) -> Unit) = listManifest().also { change(it.getJSONArray("settings").getJSONObject(2)) }
        fun field(index: Int, change: (JSONObject) -> Unit) = withItems { change(it.getJSONArray("fields").getJSONObject(index)) }
        PluginManifest(listManifest())
        rejects { PluginManifest(withItems { it.put("fields", org.json.JSONArray()) }) }
        rejects { PluginManifest(withItems { it.put("maxItems", 33) }) }
        rejects { PluginManifest(withItems { it.put("minItems", 5) }) }
        rejects { PluginManifest(withItems { it.put("row", JSONObject().put("title", "missing")) }) }
        rejects { PluginManifest(withItems { it.put("row", JSONObject().put("icon", "label")) }) }
        rejects { PluginManifest(withItems { it.put("row", JSONObject().put("title", "entries")) }) }
        rejects { PluginManifest(withItems { it.put("default", org.json.JSONArray("""[{"label":""}]""")) }) }
        // Conditions name a field declared earlier, by a supported test.
        rejects { PluginManifest(field(1, { it.put("visibleWhen", JSONObject().put("key", "page").put("equals", "x")) })) }
        rejects { PluginManifest(field(1, { it.put("visibleWhen", JSONObject().put("key", "label").put("matches", "x")) })) }
        rejects { PluginManifest(field(1, { it.put("visibleWhen", JSONObject().put("key", "label").put("notEmpty", false)) })) }
        rejects { PluginManifest(field(1, { it.put("visibleWhen", JSONObject().put("key", "label").put("equals", JSONObject())) })) }
        // No secrets or groups in rows, no list three deep and no required outside a list.
        rejects { PluginManifest(field(0, { it.put("type", "secret") })) }
        rejects { PluginManifest(field(0, { it.put("group", "Look") })) }
        rejects { PluginManifest(field(2, { it.put("required", true) })) }
        rejects { PluginManifest(withItems { it.getJSONArray("fields").getJSONObject(5).getJSONArray("fields").put(JSONObject("""{"key":"deeper","type":"list","title":"Deeper","fields":[{"key":"a","type":"string","title":"A"}]}""")) }) }
        rejects { PluginManifest(listManifest().also { it.getJSONArray("settings").getJSONObject(0).put("required", true) }) }
        rejects { PluginManifest(listManifest().also { it.getJSONArray("settings").getJSONObject(1).put("visibleWhen", JSONObject().put("key", "items").put("notEmpty", true)) }) }
    }

    private fun actionManifest() = manifest().put("settings", org.json.JSONArray("""[
      {"key":"tap","type":"action","title":"Tap","default":{}},
      {"key":"items","type":"list","title":"Items","default":[],
       "row":{"title":"label","subtitle":"action"},
       "fields":[
         {"key":"label","type":"string","title":"Label"},
         {"key":"action","type":"action","title":"Action","required":true}
       ]}
    ]"""))

    @Test fun actionSettingsStoreWhatThePickerChose() {
        val value = PluginManifest(actionManifest())
        assertEquals(emptyMap<String, Any>(), value.config(JSONObject())["tap"])
        val script = JSONObject("""{"type":"ha_script","entityId":"script.doorbell"}""")
        val tap = value.config(JSONObject().put("tap", script))["tap"] as Map<*, *>
        assertEquals("script.doorbell", tap["entityId"])
        assertThrows(UnsupportedOperationException::class.java) { (tap as MutableMap<Any?, Any?>)["entityId"] = "script.other" }
        // A service call carries its data. Actions arriving from Dart are plain maps.
        val service = mapOf("type" to "ha_service", "domain" to "light", "service" to "turn_on", "data" to mapOf("brightness_pct" to 60))
        assertEquals(service, value.config(JSONObject(mapOf("tap" to service)))["tap"])
        for (bad in listOf("ha_script", JSONObject().put("entityId", "script.x"), JSONObject().put("type", "Bad type"),
            JSONObject().put("type", "url").put("bad key", "x"), JSONObject().put("type", "url").put("url", "x".repeat(5000)))) {
            rejects { value.config(JSONObject().put("tap", bad)) }
        }
        // A shown row needs its required action.
        rejects { value.config(JSONObject().put("items", org.json.JSONArray("""[{"label":"Door"}]"""))) }
        value.config(JSONObject().put("items", org.json.JSONArray().put(JSONObject().put("label", "Door").put("action", script))))
    }

    @Test fun aManifestCannotPresetAnAction() {
        fun with(change: (JSONObject) -> Unit) = actionManifest().also { change(it.getJSONArray("settings").getJSONObject(0)) }
        rejects { PluginManifest(with { it.put("default", JSONObject().put("type", "refresh")) }) }
        rejects { PluginManifest(with { it.put("default", "") }) }
        rejects { PluginManifest(actionManifest().also { it.getJSONArray("settings").getJSONObject(1).getJSONArray("fields").getJSONObject(1).put("default", JSONObject().put("type", "refresh")) }) }
        rejects { PluginManifest(actionManifest().also { it.getJSONArray("settings").getJSONObject(1).put("row", JSONObject().put("title", "action")) }) }
        // Nothing can show or hide on an action.
        rejects { PluginManifest(actionManifest().also { it.getJSONArray("settings").put(JSONObject("""{"key":"x","type":"string","title":"X","default":"","visibleWhen":{"key":"tap","notEmpty":true}}""")) }) }
    }

    @Test fun actionPathsNameATopLevelSettingOrAListRowField() {
        val value = PluginManifest(actionManifest())
        assertEquals(setOf("tap", "items"), value.actionKeys)
        assertTrue(value.isActionPath("tap"))
        assertTrue(value.isActionPath("items.0.action"))
        assertTrue(value.isActionPath("items.31.action"))
        for (path in listOf("", "label", "items", "items.action", "items.x.action", "items.01.action", "items.-1.action", "items.0.label", "tap.0", "items.0.action.x")) {
            assertFalse(path, value.isActionPath(path))
        }
        val saved = JSONObject(value.config(JSONObject()
            .put("tap", JSONObject().put("type", "refresh"))
            .put("items", org.json.JSONArray().put(JSONObject().put("label", "Door").put("action", JSONObject().put("type", "now_playing"))))))
        assertEquals("refresh", value.action(saved, "tap")?.getString("type"))
        assertEquals("now_playing", value.action(saved, "items.0.action")?.getString("type"))
        assertNull(value.action(saved, "items.1.action"))
        assertEquals(0, value.action(JSONObject(value.config(JSONObject())), "tap")?.length())
    }

    @Test fun pluginWritesKeepTheUsersActions() {
        val value = PluginManifest(actionManifest().also {
            it.getJSONArray("settings").put(JSONObject("""{"key":"message","type":"string","title":"Message","default":""}"""))
        })
        assertEquals(setOf("tap", "items"), value.actionKeys)
        val saved = JSONObject(value.config(JSONObject().put("tap", JSONObject().put("type", "refresh"))))
        val written = JSONObject().put("message", "Hi").put("tap", JSONObject("""{"type":"ha_service","domain":"lock","service":"unlock"}"""))
            .put("items", org.json.JSONArray().put(JSONObject().put("action", JSONObject().put("type", "voice_wake"))))
        val config = value.config(value.keepActions(written, saved))
        assertEquals("Hi", config["message"])
        assertEquals(mapOf("type" to "refresh"), config["tap"])
        assertEquals(emptyList<Any>(), config["items"])
        // A setting the user never saved falls back to its empty default.
        assertEquals(emptyMap<String, Any>(), value.config(value.keepActions(written, JSONObject()))["tap"])
    }

    @Test fun pickerSettingTypesStoreTheirOwnFormats() {
        val value = PluginManifest(manifest().put("settings", org.json.JSONArray("""[
          {"key":"icon","type":"icon","title":"Icon","default":"mdi:home-outline"},
          {"key":"page","type":"dashboard","title":"Page","default":""},
          {"key":"camera","type":"cameraView","title":"Camera","default":"default"}
        ]""")))
        assertEquals("mdi:garage", value.config(JSONObject().put("icon", "mdi:garage"))["icon"])
        assertEquals("/dashboard-kitchen/lights", value.config(JSONObject().put("page", "/dashboard-kitchen/lights"))["page"])
        for ((key, bad) in listOf("icon" to "garage", "icon" to "mdi:Garage", "page" to "https://example.com", "page" to "a b", "camera" to "../x")) {
            rejects { value.config(JSONObject().put(key, bad)) }
        }
    }

    @Test fun keyEventsSkipTypedText() {
        val time = "2026-10-05T17:00:00.000Z"
        assertEquals(
            mapOf("key" to "VOLUME_UP", "code" to 24, "scanCode" to 115, "action" to "down", "repeat" to 2, "time" to time),
            PluginHostPolicy.keyPayload("KEYCODE_VOLUME_UP", 24, 115, true, 2, false, false, time)
        )
        assertEquals("up", PluginHostPolicy.keyPayload("KEYCODE_UNKNOWN", 0, 240, false, 0, false, false, time)!!["action"])
        assertNull(PluginHostPolicy.keyPayload("KEYCODE_A", 29, 30, true, 0, true, false, time))
        assertNull(PluginHostPolicy.keyPayload("KEYCODE_SHIFT_LEFT", 59, 42, true, 0, false, true, time))
        assertTrue(PluginHostPolicy.validEvent("device.key"))
    }

    @Test fun firstPublicSdkSupportsAllExplicitCapabilities() {
        for (capability in listOf("overlay", "native", "entities", "host.read", "host.control", "shizuku")) {
            assertTrue(capability in PluginManifest(manifest().put("capabilities", org.json.JSONArray(listOf(capability)))).capabilities)
        }
        for (version in listOf(0, 2, 3, 4)) {
            rejects { PluginManifest(manifest().put("apiVersion", version)) }
        }
    }

    @Test fun noiseLevelIsAHostReadOptedIntoOnItsOwn() {
        val noise = PluginManifest(manifest().put("capabilities", org.json.JSONArray(listOf("host.read", "noise"))))
        assertTrue("noise" in noise.capabilities)
        rejects { PluginManifest(manifest().put("capabilities", org.json.JSONArray(listOf("noise")))) }
        rejects { PluginManifest(manifest().put("capabilities", org.json.JSONArray(listOf("host.control", "noise")))) }
        assertTrue(PluginHostPolicy.validEvent("audio.noise"))
    }
    @Test fun voiceSkinsDrawOverlaysAndTheTextIsAHostRead() {
        fun caps(vararg names: String) = manifest().put("capabilities", org.json.JSONArray(names.toList()))
        assertTrue("voice.skin" in PluginManifest(caps("overlay", "host.read", "voice.skin")).capabilities)
        rejects { PluginManifest(caps("voice.skin")) }
        rejects { PluginManifest(caps("overlay", "voice.skin")) }
        rejects { PluginManifest(caps("host.read", "voice.skin")) }
        assertTrue("voice.text" in PluginManifest(caps("host.read", "voice.text")).capabilities)
        rejects { PluginManifest(caps("voice.text")) }
        rejects { PluginManifest(caps("host.control", "voice.text")) }
        for (event in listOf("voice.text", "voice.level", "voice.overlay", "voice.skin", "voice.appearance")) assertTrue(PluginHostPolicy.validEvent(event))
    }
    @Test fun screensaverModeStandsOnItsOwn() {
        fun caps(vararg names: String) = manifest().put("capabilities", org.json.JSONArray(names.toList()))
        assertEquals(setOf("screensaver.mode"), PluginManifest(caps("screensaver.mode")).capabilities)
        assertEquals(setOf("screensaver", "screensaver.mode"), PluginManifest(caps("screensaver", "screensaver.mode")).capabilities)
        rejects { PluginManifest(caps("screensaver.modes")) }
        assertTrue(PluginHostPolicy.validEvent("screensaver.appearance"))
    }
    @Test fun cameraAndBarcodeStandOnTheirOwn() {
        fun caps(vararg names: String) = manifest().put("capabilities", org.json.JSONArray(names.toList()))
        assertEquals(setOf("camera"), PluginManifest(caps("camera")).capabilities)
        assertEquals(setOf("barcode"), PluginManifest(caps("barcode")).capabilities)
        assertFalse(PluginManifest(caps("camera", "barcode")).needsScreen)
    }
    @Test fun aVoiceSkinNamesItsPictureUnderAssets() {
        fun skin(thumbnail: Any?) = manifest()
            .put("capabilities", org.json.JSONArray(listOf("overlay", "host.read", "voice.skin")))
            .put("voiceSkinThumbnail", thumbnail)
        assertEquals("voice-skin.webp", PluginManifest(skin("voice-skin.webp")).voiceSkinThumbnail)
        assertEquals("images/skin.PNG", PluginManifest(skin("images/skin.PNG")).voiceSkinThumbnail)
        assertNull(PluginManifest(manifest()).voiceSkinThumbnail)
        for (bad in listOf("../skin.webp", "skin.svg", "skin", "/skin.png", 7)) rejects { PluginManifest(skin(bad)) }
        // Only a voice skin has a picture in the Skin picker.
        rejects { PluginManifest(manifest().put("voiceSkinThumbnail", "voice-skin.webp")) }
    }
    @Test fun anIconIsAPngUnderAssets() {
        assertEquals("icon.png", PluginManifest(manifest().put("icon", "icon.png")).icon)
        assertEquals("images/Icon.PNG", PluginManifest(manifest().put("icon", "images/Icon.PNG")).icon)
        assertNull(PluginManifest(manifest()).icon)
        for (bad in listOf("../icon.png", "icon.webp", "icon", "/icon.png", 7)) rejects { PluginManifest(manifest().put("icon", bad)) }
    }
    @Test fun aMinimumAppVersionNamesARelease() {
        assertEquals("2026.10.40", PluginManifest(manifest().put("minAppVersion", "2026.10.40")).minAppVersion)
        assertEquals("2026.9.1", PluginManifest(manifest().put("minAppVersion", "2026.9.1")).minAppVersion)
        assertNull(PluginManifest(manifest()).minAppVersion)
        for (bad in listOf("2026.10", "2026.09.1", "2026.13.1", "v2026.10.40", "2026.10.40-beta", "26.10.40", 2026)) {
            rejects { PluginManifest(manifest().put("minAppVersion", bad)) }
        }
    }
    @Test fun comparesAppVersionsByEachNumber() {
        assertTrue(PluginManifest.appVersionAtLeast("2026.10.40", "2026.10.40"))
        assertTrue(PluginManifest.appVersionAtLeast("2026.10.40", "2026.9.12"))
        assertTrue(PluginManifest.appVersionAtLeast("2027.1.1", "2026.12.30"))
        assertFalse(PluginManifest.appVersionAtLeast("2026.10.39", "2026.10.40"))
        assertFalse(PluginManifest.appVersionAtLeast("2026.9.40", "2026.10.1"))
        // Months and releases compare as numbers, not text.
        assertFalse(PluginManifest.appVersionAtLeast("2026.10.9", "2026.10.10"))
        assertTrue(PluginManifest.appVersionAtLeast("2026.10.40+338", "2026.10.40"))
        assertTrue(PluginManifest.appVersionAtLeast("", "2026.10.40"))
    }
    @Test fun readsThePngHeader() {
        fun png(width: Int, height: Int) = byteArrayOf(-119, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13) + "IHDR".toByteArray() +
            java.nio.ByteBuffer.allocate(8).putInt(width).putInt(height).array() + ByteArray(5)
        assertEquals(256 to 256, PluginPackage.pngSize(png(256, 256)))
        assertEquals(512 to 128, PluginPackage.pngSize(png(512, 128)))
        assertNull(PluginPackage.pngSize("GIF89a not a png at all".toByteArray()))
    }
    @Test fun overlaysAndScreensaversNeedAScreenUnlessThePluginGoesWithout() {
        fun caps(vararg names: String) = manifest().put("capabilities", org.json.JSONArray(names.toList()))
        assertTrue(PluginManifest(caps("overlay")).needsScreen)
        assertTrue(PluginManifest(caps("screensaver", "entities")).needsScreen)
        assertFalse(PluginManifest(caps("entities", "ha")).needsScreen)
        assertFalse(PluginManifest(caps("overlay").put("headless", true)).needsScreen)
        assertTrue(PluginManifest(caps("overlay").put("headless", false)).needsScreen)
        rejects { PluginManifest(caps("overlay").put("headless", "yes")) }
    }
    @Test fun homeAssistantAccessIsItsOwnCapability() {
        val ha = PluginManifest(manifest().put("capabilities", org.json.JSONArray(listOf("ha"))))
        assertTrue("ha" in ha.capabilities)
        assertEquals("door", PluginHostPolicy.haSubscriptionKey("ha.subscription.door"))
        assertNull(PluginHostPolicy.haSubscriptionKey("ha.subscription.a b"))
        assertNull(PluginHostPolicy.haSubscriptionKey("ha.entity.light.a"))
        assertFalse(PluginHostPolicy.validEvent("ha.subscription.door"))
    }
    @Test fun musicAssistantAccessIsItsOwnCapability() {
        val ma = PluginManifest(manifest().put("capabilities", org.json.JSONArray(listOf("ma"))))
        assertTrue("ma" in ma.capabilities)
        assertEquals("queue", PluginHostPolicy.maSubscriptionKey("ma.subscription.queue"))
        assertNull(PluginHostPolicy.maSubscriptionKey("ma.subscription.a b"))
        assertNull(PluginHostPolicy.maSubscriptionKey("ha.subscription.queue"))
        assertNull(PluginHostPolicy.haSubscriptionKey("ma.subscription.queue"))
        assertFalse(PluginHostPolicy.validEvent("ma.subscription.queue"))
        assertTrue(PluginHostPolicy.validEvent("sendspin.player"))
        assertEquals(mapOf("events" to listOf("queue_updated")), PluginHostPolicy.maMessage(mapOf("events" to arrayOf("queue_updated"))))
        rejects { PluginHostPolicy.maMessage(mapOf("args" to "x".repeat(40_000))) }
    }
    @Test fun homeAssistantMessagesAreDetachedJson() {
        val nested = mutableMapOf<String, Any>("entity_id" to listOf("light.a", "light.b"))
        val message = mapOf<String, Any>(
            "type" to "call_service", "domain" to "light", "target" to nested,
            "service_data" to mapOf("brightness" to 120, "transition" to 1.5f, "flash" to false),
            "array" to arrayOf("x"), "json" to JSONObject().put("a", JSONObject.NULL),
        )
        val copy = PluginHostPolicy.haMessage(message)
        nested["entity_id"] = "changed"
        assertEquals(listOf("light.a", "light.b"), (copy["target"] as Map<*, *>)["entity_id"])
        assertEquals(1.5, (copy["service_data"] as Map<*, *>)["transition"])
        assertEquals(listOf("x"), copy["array"])
        assertEquals(mapOf("a" to null), copy["json"])
        rejects { PluginHostPolicy.haMessage(mapOf("type" to "x", "bad" to Any())) }
        rejects { PluginHostPolicy.haMessage(mapOf("type" to "x", "n" to Double.NaN)) }
        rejects { PluginHostPolicy.haMessage(mapOf("type" to "x", "data" to "x".repeat(40_000))) }
        var deep: Any = "end"
        repeat(40) { deep = listOf(deep) }
        rejects { PluginHostPolicy.haMessage(mapOf("type" to "x", "deep" to deep)) }
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
    @Test fun allowsUpToFiftySettings() {
        fun withSettings(count: Int) = manifest().put("settings", org.json.JSONArray().apply {
            repeat(count) { put(JSONObject().put("key", "s$it").put("title", "S$it").put("type", "boolean").put("default", false)) }
        })
        assertEquals(PluginManifest.MAX_SETTINGS, PluginManifest(withSettings(PluginManifest.MAX_SETTINGS)).settings.length())
        rejects { PluginManifest(withSettings(PluginManifest.MAX_SETTINGS + 1)) }
    }
    @Test fun triggersAreOptionalAndValidated() {
        assertFalse(PluginManifest(manifest()).hasTrigger("hardTap"))
        val declared = PluginManifest(manifest().put("triggers", org.json.JSONArray("""[{"id":"hardTap","title":"Hard tap"}]""")))
        assertTrue(declared.hasTrigger("hardTap"))
        assertFalse(declared.hasTrigger("show"))
        rejects { PluginManifest(manifest().put("triggers", org.json.JSONArray("""[{"id":"hardTap","title":"A"},{"id":"hardTap","title":"B"}]"""))) }
        rejects { PluginManifest(manifest().put("triggers", org.json.JSONArray("""[{"id":"hard-tap","title":"Hard tap"}]"""))) }
        rejects { PluginManifest(manifest().put("triggers", org.json.JSONArray("""[{"id":"hardTap","title":""}]"""))) }
        val many = org.json.JSONArray()
        repeat(21) { many.put(org.json.JSONObject().put("id", "t$it").put("title", "T$it")) }
        rejects { PluginManifest(manifest().put("triggers", many)) }
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
    @Test fun numbersTypedIntoAFieldTakeAWideRange() {
        fun number(vararg changes: Pair<String, Any>) = manifest().put("settings", org.json.JSONArray().put(
            JSONObject("""{"key":"limit","title":"Limit","type":"number","min":-1000000,"max":1000000,"step":0.5,"default":85}""")
                .also { setting -> for ((key, value) in changes) setting.put(key, value) }))
        val field = PluginManifest(number("input" to "field"))
        assertEquals(123456.5, field.config(JSONObject().put("limit", 123456.5))["limit"])
        assertEquals(-1000000, field.config(JSONObject().put("limit", -1000000))["limit"])
        rejects { field.config(JSONObject().put("limit", 1000000.5)) }
        rejects { field.config(JSONObject().put("limit", 85.25)) }
        rejects { field.config(JSONObject().put("limit", "85")) }
        // A slider keeps its 10000 stops, whether it says so or not.
        rejects { PluginManifest(number()) }
        rejects { PluginManifest(number("input" to "slider")) }
        PluginManifest(number("input" to "slider", "min" to 0, "max" to 100, "step" to 1))
        // A typed field still needs a default on a step, inside a real range.
        rejects { PluginManifest(number("input" to "field", "step" to 0)) }
        rejects { PluginManifest(number("input" to "field", "default" to 85.25)) }
        rejects { PluginManifest(number("input" to "field", "max" to -1000000)) }
        // Only a number takes an input, and only one of the two.
        rejects { PluginManifest(number("input" to "box")) }
        rejects { PluginManifest(number("input" to true)) }
        rejects { PluginManifest(manifest().put("settings", org.json.JSONArray("""[{"key":"name","title":"Name","type":"string","default":"","input":"field"}]"""))) }
        // A list row field takes it the same way.
        val rows = PluginManifest(manifest().put("settings", org.json.JSONArray("""[
          {"key":"alerts","title":"Alerts","type":"list","default":[],"fields":[{"key":"above","title":"Above","type":"number","min":0,"max":100000,"input":"field"}]}
        ]""")))
        assertEquals(listOf(mapOf("above" to 85000)), rows.config(JSONObject().put("alerts", org.json.JSONArray("""[{"above":85000}]""")))["alerts"])
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
