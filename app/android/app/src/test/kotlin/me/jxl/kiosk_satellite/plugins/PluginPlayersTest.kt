package me.jxl.kiosk_satellite.plugins

import java.nio.ByteBuffer
import me.jxl.kiosk.plugins.PlayerLibrary
import me.jxl.kiosk.plugins.PlayerListener
import me.jxl.kiosk.plugins.PlayerQueue
import me.jxl.kiosk.plugins.PluginHost
import me.jxl.kiosk.plugins.PluginPlayer
import org.junit.Assert.*
import org.junit.Test

class PluginPlayersTest {
    private open class Listener : PlayerListener {
        override fun onActivate(player: PluginPlayer) {}
        override fun onDeactivate() {}
        override fun onCommand(command: String, arguments: Map<String, Any>) {}
    }

    private class Full : Listener(), PlayerLibrary, PlayerQueue {
        override fun hasSearch() = true
        override fun browse(folderId: String?, offset: Int, callback: PluginHost.CommandCallback) {}
        override fun open(itemId: String, callback: PluginHost.CommandCallback) {}
        override fun play(itemId: String, mode: String, withinId: String?, callback: PluginHost.CommandCallback) {}
        override fun queue(callback: PluginHost.CommandCallback) {}
        override fun playItem(id: String) {}
        override fun moveItem(id: String, toIndex: Int) {}
        override fun removeItem(id: String) {}
        override fun clear() {}
    }

    private class FakeOutput : PluginOutput {
        var closed = false
        override fun write(pcm: ByteBuffer, frames: Int, timeoutMs: Int) = if (closed) -1 else frames
        override fun getTimestamp(out: LongArray) = false
        override fun framesWritten() = 0L
        override fun flush() {}
        override fun close() { closed = true }
    }

    private fun rejects(action: () -> Unit) {
        try { action(); fail("Expected rejection") } catch (_: IllegalArgumentException) {} catch (_: IllegalStateException) {}
    }

    @Test fun publishesWhatTheListenerOffers() {
        var now = 0L
        val players = PluginPlayers { now }
        players.publish("plain", "Plain", Listener())
        now += 2_000_000_000L
        players.publish("full", "Full", Full())
        assertEquals(listOf(
            mapOf("key" to "plain", "title" to "Plain", "library" to false, "discover" to false, "search" to false, "queue" to false),
            mapOf("key" to "full", "title" to "Full", "library" to true, "discover" to false, "search" to true, "queue" to true),
        ), players.snapshot())
    }

    @Test fun validatesKeysTitlesAndCount() {
        var now = 0L
        val players = PluginPlayers { now }
        rejects { players.publish("Bad", "Title", Listener()) }
        rejects { players.publish("good", " ", Listener()) }
        players.publish("one", "One", Listener())
        players.publish("two", "Two", Listener())
        now += 2_000_000_000L
        rejects { players.publish("three", "Three", Listener()) }
    }

    @Test fun samePublisherRetitlesAndANewOneReplaces() {
        var now = 0L
        val players = PluginPlayers { now }
        val first = Listener()
        assertNull(players.publish("radio", "Radio", first))
        assertNull(players.publish("radio", "Radio 2", first))
        assertEquals("Radio 2", players.get("radio")!!.title)
        now += 2_000_000_000L
        val old = players.publish("radio", "Radio", Listener())
        assertSame(first, old!!.listener)
    }

    @Test fun stateKeepsKnownKeysWithinBounds() {
        val (state, art) = PluginPlayers.state(mapOf(
            "state" to "playing",
            "title" to "a".repeat(600),
            "artworkUrl" to "file:///sdcard/x.jpg",
            "durationMs" to 1000,
            "positionMs" to -5,
            "repeat" to "sideways",
            "actions" to arrayOf("play", "dance", "play", "seek"),
            "artwork" to byteArrayOf(1, 2, 3),
            "other" to "dropped",
        ))
        assertEquals("playing", state["state"])
        assertEquals(512, (state["title"] as String).length)
        assertEquals("", state["artworkUrl"])
        assertEquals(1000L, state["durationMs"])
        assertEquals(0L, state["positionMs"])
        assertEquals("off", state["repeat"])
        assertEquals(listOf("play", "seek"), state["actions"])
        assertFalse(state.containsKey("other"))
        assertArrayEquals(byteArrayOf(1, 2, 3), art)
        assertEquals("idle", PluginPlayers.state(mapOf("state" to "lost")).first["state"])
        rejects { PluginPlayers.state(mapOf("artwork" to ByteArray(PluginPlayers.MAX_ARTWORK + 1))) }
    }

    @Test fun answersAreShapedByRequest() {
        val page = PluginPlayers.answer("browse", mapOf("items" to listOf(mapOf("id" to "a", "kind" to "album", "browsable" to true), mapOf("title" to "no id")), "more" to true)) as Map<*, *>
        assertEquals(true, page["more"])
        val item = (page["items"] as List<*>).single() as Map<*, *>
        assertEquals("album", item["kind"])
        assertEquals(true, item["browsable"])
        assertEquals(true, item["playable"])
        val queue = PluginPlayers.answer("queue", mapOf("items" to listOf(mapOf("id" to "x", "artist" to "Band")), "current" to 4)) as Map<*, *>
        assertEquals(-1, queue["current"])
        assertEquals("Band", ((queue["items"] as List<*>).single() as Map<*, *>)["subtitle"])
        val shelves = PluginPlayers.answer("search", listOf(mapOf("title" to "Albums", "items" to listOf(mapOf("id" to "y"))))) as List<*>
        assertEquals("Albums", (shelves.single() as Map<*, *>)["title"])
    }

    @Test fun artworkNumbersAreNotReusedByALaterHandle() {
        val entry = PluginPlayers.Entry("radio", "Radio", Listener(), discover = false, search = false)
        val earlier = PlayerHandle(entry, changed = {}, queueChanged = {})
        earlier.update(mapOf("state" to "playing", "artwork" to byteArrayOf(1)))
        val old = earlier.artworkId
        earlier.update(mapOf("state" to "playing", "artwork" to byteArrayOf(2)))
        val last = earlier.artworkId
        // The picture a number named is gone once the plugin sends another.
        assertNull(earlier.artworkFor(old))
        earlier.deactivate()
        val later = PlayerHandle(entry, changed = {}, queueChanged = {})
        later.update(mapOf("state" to "playing", "artwork" to byteArrayOf(3)))
        assertTrue(later.artworkId > last)
        assertNull(later.artworkFor(old))
        assertTrue(later.artworkFor(later.artworkId)!!.contentEquals(byteArrayOf(3)))
        later.deactivate()
    }

    @Test fun handleSendsUpdatesUntilDeactivatedAndOwnsOneOutput() {
        val entry = PluginPlayers.Entry("radio", "Radio", Listener(), discover = false, search = false)
        var changes = 0
        val outputs = mutableListOf<FakeOutput>()
        val handle = PlayerHandle(entry, changed = { changes++ }, queueChanged = {}, outputFactory = { _, _ -> FakeOutput().also { outputs += it } })
        handle.update(mapOf("state" to "playing", "actions" to listOf("pause"), "artwork" to byteArrayOf(9)))
        assertEquals(1, changes)
        val first = handle.artworkId
        assertTrue(first > 0)
        handle.update(mapOf("state" to "playing", "actions" to listOf("pause"), "artwork" to byteArrayOf(9)))
        assertEquals(first, handle.artworkId)
        assertTrue(handle.artworkFor(first)!!.contentEquals(byteArrayOf(9)))
        assertTrue(handle.allows("pause"))
        assertFalse(handle.allows("next"))
        handle.openAudio(48000, 2, PluginPlayer.ENCODING_PCM_16)
        handle.openAudio(44100, 2, PluginPlayer.ENCODING_PCM_16)
        assertTrue(outputs[0].closed)
        rejects { handle.openAudio(44100, 6, PluginPlayer.ENCODING_PCM_16) }
        rejects { handle.openAudio(44100, 2, 8) }
        handle.deactivate()
        assertTrue(outputs[1].closed)
        assertFalse(handle.isActive)
        handle.update(mapOf("state" to "playing"))
        assertEquals(2, changes)
        assertTrue(handle.state.isEmpty())
        rejects { handle.openAudio(48000, 2, PluginPlayer.ENCODING_PCM_16) }
    }
}
