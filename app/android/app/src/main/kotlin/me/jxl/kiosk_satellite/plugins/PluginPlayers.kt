package me.jxl.kiosk_satellite.plugins

import me.jxl.kiosk.plugins.AudioOutput
import me.jxl.kiosk.plugins.PlayerLibrary
import me.jxl.kiosk.plugins.PlayerListener
import me.jxl.kiosk.plugins.PlayerQueue
import me.jxl.kiosk.plugins.PluginPlayer

/**
 * The players one plugin session publishes (SDK `player`). Each is offered under Media Player > Player as
 * `plugin:<plugin id>/<key>`. While the pick names one, the app activates it and it holds a [PlayerHandle], the
 * plugin's view of the pick: its state, its queue notice and its audio output.
 */
internal class PluginPlayers(private val clock: () -> Long = System::nanoTime) {
    class Entry(val key: String, var title: String, val listener: PlayerListener, val discover: Boolean, val search: Boolean) {
        val library: PlayerLibrary? = listener as? PlayerLibrary
        val queue: PlayerQueue? = listener as? PlayerQueue
        @Volatile var handle: PlayerHandle? = null
    }

    private val items = linkedMapOf<String, Entry>()
    private var closed = false
    private var window = clock()
    private var changes = 0

    private fun budget() {
        check(!closed) { "Plugin session has ended" }
        val now = clock()
        if (now - window >= 1_000_000_000L) { window = now; changes = 0 }
        check(changes < 4) { "At most four player changes per second are supported" }
        changes++
    }

    /** Publish or retitle. A new listener under a live key replaces the old one, which the caller deactivates. */
    @Synchronized fun publish(key: String, title: String, listener: PlayerListener): Entry? {
        require(key.matches(KEY)) { "Invalid player key" }
        require(title.isNotBlank() && title.length <= 80) { "Invalid player title" }
        require(items.containsKey(key) || items.size < 2) { "At most two players are supported" }
        budget()
        val old = items[key]
        if (old != null && old.listener === listener) {
            old.title = title.trim()
            return null
        }
        val library = listener as? PlayerLibrary
        items[key] = Entry(key, title.trim(), listener, library?.hasDiscover() == true, library?.hasSearch() == true)
        return old
    }

    @Synchronized fun remove(key: String): Entry? { budget(); return items.remove(key) }
    @Synchronized fun get(key: String): Entry? = if (closed) null else items[key]

    @Synchronized fun snapshot(): List<Map<String, Any>> = items.values.map {
        mapOf(
            "key" to it.key,
            "title" to it.title,
            "library" to (it.library != null),
            "discover" to it.discover,
            "search" to it.search,
            "queue" to (it.queue != null),
        )
    }

    /** End the session: every entry, so the caller can deactivate the active ones. */
    @Synchronized fun close(): List<Entry> { closed = true; return items.values.toList().also { items.clear() } }

    companion object {
        val KEY = Regex("[a-z][a-z0-9_]{0,39}")
        val ACTIONS = setOf("play", "pause", "stop", "next", "previous", "seek", "shuffle", "repeat")
        private val STATES = setOf("idle", "buffering", "playing", "paused")
        private val KINDS = setOf("artist", "album", "track", "playlist", "radio", "podcast", "episode", "audiobook", "genre", "folder", "other")
        private val MODES = setOf("replace", "now", "next", "add")
        const val MAX_ARTWORK = 1024 * 1024

        fun validMode(mode: String) = mode in MODES

        private fun text(value: Any?, limit: Int): String = (value as? String)?.trim()?.take(limit) ?: ""
        private fun millis(value: Any?): Long? = (value as? Number)?.toDouble()?.takeIf { it.isFinite() && it >= 0 }?.toLong()
        private fun url(value: Any?): String = text(value, 2048).takeIf { it.startsWith("https://") || it.startsWith("http://") } ?: ""

        private fun list(value: Any?): List<Any?> = when (value) {
            is Iterable<*> -> value.toList()
            is Array<*> -> value.toList()
            else -> emptyList()
        }

        /** A plugin's player state in the shape the app reads, checked and detached. Artwork bytes come back apart. */
        fun state(raw: Map<String, Any?>): Pair<Map<String, Any?>, ByteArray?> {
            val state = (raw["state"] as? String)?.takeIf { it in STATES } ?: "idle"
            val bytes = raw["artwork"] as? ByteArray
            require(bytes == null || bytes.size <= MAX_ARTWORK) { "Player artwork must be at most 1 MiB" }
            val actions = list(raw["actions"]).filterIsInstance<String>().filter { it in ACTIONS }.distinct()
            val value = linkedMapOf<String, Any?>(
                "state" to state,
                "title" to text(raw["title"], 512),
                "artist" to text(raw["artist"], 512),
                "album" to text(raw["album"], 512),
                "artworkUrl" to url(raw["artworkUrl"]),
                "positionMs" to (millis(raw["positionMs"]) ?: 0L),
                "shuffle" to (raw["shuffle"] == true),
                "repeat" to ((raw["repeat"] as? String)?.takeIf { it == "one" || it == "all" } ?: "off"),
                "actions" to actions,
            )
            millis(raw["durationMs"])?.takeIf { it > 0 }?.let { value["durationMs"] = it }
            return value to bytes?.takeIf { it.isNotEmpty() }
        }

        /** One library or queue item, the known keys only. Null without an id. */
        fun item(raw: Any?): Map<String, Any?>? {
            if (raw !is Map<*, *>) return null
            val id = text(raw["id"], 512).takeIf { it.isNotEmpty() } ?: return null
            val value = linkedMapOf<String, Any?>(
                "id" to id,
                "kind" to ((raw["kind"] as? String)?.takeIf { it in KINDS } ?: "other"),
                "title" to text(raw["title"], 512),
                "subtitle" to text(raw["subtitle"] ?: raw["artist"], 512),
                "artworkUrl" to url(raw["artworkUrl"]),
                "playable" to (raw["playable"] != false),
                "browsable" to (raw["browsable"] == true),
            )
            millis(raw["durationMs"])?.takeIf { it > 0 }?.let { value["durationMs"] = it }
            return value
        }

        private fun items(raw: Any?, limit: Int): List<Map<String, Any?>> = list(raw).asSequence().mapNotNull(::item).take(limit).toList()

        private fun shelves(raw: Any?): List<Map<String, Any?>> = list(raw).filterIsInstance<Map<*, *>>().take(20).map {
            mapOf("title" to text(it["title"], 120), "items" to items(it["items"], 100))
        }

        /** A library or queue answer in the shape the app reads, by [op]. */
        fun answer(op: String, data: Any?): Any? = when (op) {
            "discover", "search" -> shelves(data)
            "browse" -> (data as? Map<*, *>).let { mapOf("items" to items(it?.get("items"), 200), "more" to (it?.get("more") == true)) }
            "open" -> (data as? Map<*, *>).let { mapOf("item" to item(it?.get("item")), "items" to items(it?.get("items"), 500)) }
            "queue" -> (data as? Map<*, *>).let {
                val listed = items(it?.get("items"), 500)
                val current = (it?.get("current") as? Number)?.toInt() ?: -1
                mapOf("items" to listed, "current" to if (current in listed.indices) current else -1)
            }
            else -> null
        }
    }
}

/**
 * A plugin player while it is the pick: what the plugin holds between onActivate and onDeactivate. Updates and
 * queue notices go to the app through [changed] and [queueChanged]; after [deactivate] they are dropped.
 */
internal class PlayerHandle(
    val entry: PluginPlayers.Entry,
    private val changed: (PlayerHandle) -> Unit,
    private val queueChanged: (PlayerHandle) -> Unit,
    private val outputFactory: (Int, Int) -> PluginOutput = { rate, channels -> PluginAudioOutput(rate, channels) },
) : PluginPlayer {
    @Volatile private var active = true
    private var output: PluginOutput? = null

    @Volatile var state: Map<String, Any?> = emptyMap()
        private set
    @Volatile var artwork: ByteArray? = null
        private set
    /** Counts artwork changes, so the app asks for the new picture. */
    @Volatile var artworkId = 0
        private set

    override fun update(state: Map<String, Any>) {
        if (!active) return
        val (value, bytes) = PluginPlayers.state(state)
        synchronized(this) {
            val previous = artwork
            if (bytes == null) {
                artwork = null
            } else if (previous == null || !previous.contentEquals(bytes)) {
                artwork = bytes.copyOf()
                artworkId++
            }
            this.state = value
        }
        changed(this)
    }

    override fun queueChanged() { if (active) queueChanged(this) }

    override fun isActive() = active

    override fun openAudio(sampleRate: Int, channels: Int, encoding: Int): AudioOutput {
        check(active) { "The player is no longer the pick" }
        require(sampleRate in 8000..192000) { "Invalid sample rate" }
        require(channels == 1 || channels == 2) { "Only 1 or 2 channels are supported" }
        require(encoding == PluginPlayer.ENCODING_PCM_16) { "Only ENCODING_PCM_16 is supported" }
        synchronized(this) {
            check(active) { "The player is no longer the pick" }
            output?.close()
            return outputFactory(sampleRate, channels).also { output = it }
        }
    }

    /** What the actions list allows. */
    fun allows(command: String): Boolean {
        @Suppress("UNCHECKED_CAST")
        val actions = state["actions"] as? List<String> ?: return false
        return command in actions
    }

    fun deactivate() {
        synchronized(this) {
            active = false
            output?.close()
            output = null
            state = emptyMap()
            artwork = null
        }
    }
}

/** The audio output a [PlayerHandle] opens, apart from Android so the handle can be tested. */
internal interface PluginOutput : AudioOutput
