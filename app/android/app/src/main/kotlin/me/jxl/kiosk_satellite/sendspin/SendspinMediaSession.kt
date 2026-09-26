package me.jxl.kiosk_satellite.sendspin

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.drawable.Icon
import android.media.MediaMetadata
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import androidx.core.content.ContextCompat
import me.jxl.kiosk_satellite.HomeRole
import me.jxl.kiosk_satellite.MainActivity
import me.jxl.kiosk_satellite.NativeMessages
import me.jxl.kiosk_satellite.R
import me.jxl.kiosk_satellite.StatusBarIcon

/**
 * The Sendspin player as an Android media session with a MediaStyle
 * notification. The system media controls, the lock screen, Bluetooth and
 * remote media keys and anything else that reads the device's sessions see
 * what plays here and can steer it. Presses go back through [sendCommand],
 * the same controller path the Now Playing view uses.
 *
 * A track surfaces once it has played in the current connection, so a boot
 * never conjures a paused session out of stale metadata. It stays, paused,
 * until the connection or the player goes away. Every call may come from
 * any thread. All work runs on the main thread.
 */
class SendspinMediaSession(
    context: Context,
    private val sendCommand: (command: String, value: Long) -> Unit,
) {
    companion object {
        private const val TAG = "SendspinMedia"
        private const val CHANNEL_ID = "kiosk_satellite_media"
        private const val NOTIFICATION_ID = 0x4B54
        private const val ACTION_COMMAND = "me.jxl.kiosk_satellite.SENDSPIN_MEDIA"
        private const val EXTRA_COMMAND = "command"

        // A track change ends one stream before the next starts. Without
        // this hold every song boundary flashed the controls to paused.
        private const val PAUSE_GRACE_MS = 2_500L

        // The system extrapolates a playing position on its own; the
        // engine's pushes only correct it when it drifts this far.
        private const val POSITION_DRIFT_MS = 1_500L

        // Cover art is downsampled to fit this. The session keeps its own
        // copy, and the low-RAM devices cannot spare a full-size one.
        private const val ARTWORK_MAX_PX = 512

        /** PlaybackState actions for the server's supported commands. */
        internal fun actionsFor(commands: List<String>, durationMs: Long): Long {
            var actions = 0L
            val canPlay = "play" in commands
            val canPause = "pause" in commands
            if (canPlay) actions = actions or PlaybackState.ACTION_PLAY
            if (canPause) actions = actions or PlaybackState.ACTION_PAUSE
            if (canPlay && canPause) actions = actions or PlaybackState.ACTION_PLAY_PAUSE
            if ("next" in commands) actions = actions or PlaybackState.ACTION_SKIP_TO_NEXT
            if ("previous" in commands) actions = actions or PlaybackState.ACTION_SKIP_TO_PREVIOUS
            if ("stop" in commands) actions = actions or PlaybackState.ACTION_STOP
            if ("seek" in commands && durationMs > 0) actions = actions or PlaybackState.ACTION_SEEK_TO
            return actions
        }

        /**
         * The commands the controls offer. An empty list is a server that
         * never reported its controller state; the bridge lets anything
         * through for it, so the controls offer the transport basics.
         */
        internal fun effectiveCommands(reported: List<String>): List<String> =
            reported.ifEmpty { listOf("play", "pause", "next", "previous") }

        /** The notification's transport buttons, in order. */
        internal fun buttonsFor(commands: List<String>, playing: Boolean): List<String> = buildList {
            if ("previous" in commands) add("previous")
            val toggle = if (playing) "pause" else "play"
            if (toggle in commands) add(toggle)
            if ("next" in commands) add("next")
        }
    }

    private val context = context.applicationContext
    private val main = Handler(Looper.getMainLooper())

    // Main thread only.
    private var session: MediaSession? = null
    private var receiver: BroadcastReceiver? = null
    private var connected = false
    private var sawPlayback = false
    private var streamPlaying = false
    private var shownPlaying = false
    private var pauseRequested = false
    private var title = ""
    private var artist = ""
    private var album = ""
    private var artworkUrl = ""
    private var durationMs = -1L
    private var positionMs = 0L
    private var positionAt = 0L
    private var commands: List<String> = emptyList()
    private var artUrl = ""
    private var art: Bitmap? = null
    private var metadataKey = ""
    private var notificationKey = ""
    private var channelReady = false

    private val pauseGrace = Runnable {
        if (!streamPlaying) setShownPlaying(false)
    }

    fun onConnectionChanged(connected: Boolean) = main.post {
        this.connected = connected
        if (!connected) {
            sawPlayback = false
            streamPlaying = false
            main.removeCallbacks(pauseGrace)
            shownPlaying = false
        }
        refresh()
    }

    fun onPlayingChanged(playing: Boolean) = main.post {
        if (playing == streamPlaying) return@post
        streamPlaying = playing
        main.removeCallbacks(pauseGrace)
        if (playing) {
            sawPlayback = true
            pauseRequested = false
            setShownPlaying(true)
        } else if (pauseRequested || !shownPlaying) {
            pauseRequested = false
            setShownPlaying(false)
        } else {
            main.postDelayed(pauseGrace, PAUSE_GRACE_MS)
        }
    }

    fun onMetadata(
        title: String?,
        artist: String?,
        album: String?,
        artworkUrl: String?,
        positionMs: Long,
        durationMs: Long,
    ) = main.post {
        this.title = clean(title)
        this.artist = clean(artist)
        this.album = clean(album)
        this.artworkUrl = clean(artworkUrl)
        if (durationMs >= 0) this.durationMs = durationMs
        if (positionMs >= 0) setPosition(positionMs)
        refresh()
    }

    fun onPosition(positionMs: Long) = main.post {
        val drift = kotlin.math.abs(currentPosition() - positionMs)
        if (!shownPlaying || drift >= POSITION_DRIFT_MS) {
            setPosition(positionMs)
            refresh()
        }
    }

    fun onCommands(commands: List<String>) = main.post {
        this.commands = commands
        refresh()
    }

    /** Cover bytes for [url], fetched by Dart; null when there are none. */
    fun setArtwork(url: String, bytes: ByteArray?) {
        if (bytes == null || bytes.isEmpty()) {
            main.post { if (artUrl == url) { artUrl = ""; art = null; refresh() } }
            return
        }
        Thread {
            val bitmap = decode(bytes)
            main.post {
                artUrl = if (bitmap != null) url else ""
                art = bitmap
                refresh()
            }
        }.apply {
            name = "SendspinArtwork"
            isDaemon = true
        }.start()
    }

    /** The player stopped: drop the session and its notification. */
    fun release() = main.post {
        connected = false
        sawPlayback = false
        streamPlaying = false
        shownPlaying = false
        main.removeCallbacks(pauseGrace)
        hide()
        session?.release()
        session = null
        receiver?.let {
            try {
                context.unregisterReceiver(it)
            } catch (_: Exception) {
            }
        }
        receiver = null
    }

    // ------------------------------------------------------------------

    private fun clean(value: String?): String =
        value?.trim()?.takeIf { it.isNotEmpty() && it != "null" } ?: ""

    private fun setPosition(ms: Long) {
        positionMs = ms
        positionAt = SystemClock.elapsedRealtime()
    }

    private fun currentPosition(): Long {
        val elapsed = if (shownPlaying) SystemClock.elapsedRealtime() - positionAt else 0L
        val position = positionMs + elapsed
        return if (durationMs > 0) position.coerceIn(0L, durationMs) else position.coerceAtLeast(0L)
    }

    private fun setShownPlaying(playing: Boolean) {
        if (playing == shownPlaying) return
        // Freeze or restart the extrapolation at the moment of the flip.
        setPosition(currentPosition())
        shownPlaying = playing
        refresh()
    }

    private fun command(name: String, value: Long = 0L) {
        if (name == "pause") pauseRequested = true
        sendCommand(name, value)
    }

    private fun refresh() {
        if (!connected || !sawPlayback || title.isEmpty()) {
            hide()
            return
        }
        val session = session ?: create() ?: return
        val offered = effectiveCommands(commands)
        val metaKey = listOf(title, artist, album, durationMs, if (artUrl == artworkUrl) artUrl else "")
            .joinToString("\u0000")
        if (metaKey != metadataKey) {
            metadataKey = metaKey
            session.setMetadata(buildMetadata())
        }
        session.setPlaybackState(
            PlaybackState.Builder()
                .setActions(actionsFor(offered, durationMs))
                .setState(
                    if (shownPlaying) PlaybackState.STATE_PLAYING else PlaybackState.STATE_PAUSED,
                    currentPosition(),
                    if (shownPlaying) 1f else 0f,
                    SystemClock.elapsedRealtime(),
                )
                .build(),
        )
        if (!session.isActive) session.isActive = true
        val key = "$metaKey\u0000$shownPlaying\u0000${buttonsFor(offered, shownPlaying)}"
        if (key != notificationKey) {
            notificationKey = key
            notify(session, offered)
        }
    }

    private fun buildMetadata(): MediaMetadata {
        val builder = MediaMetadata.Builder()
            .putString(MediaMetadata.METADATA_KEY_TITLE, title)
            .putString(MediaMetadata.METADATA_KEY_ARTIST, artist)
            .putString(MediaMetadata.METADATA_KEY_ALBUM, album)
        if (durationMs > 0) builder.putLong(MediaMetadata.METADATA_KEY_DURATION, durationMs)
        val cover = art?.takeIf { artUrl == artworkUrl }
        if (cover != null) builder.putBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART, cover)
        return builder.build()
    }

    private fun create(): MediaSession? = try {
        MediaSession(context, TAG).also { created ->
            @Suppress("DEPRECATION")
            created.setFlags(
                MediaSession.FLAG_HANDLES_MEDIA_BUTTONS or MediaSession.FLAG_HANDLES_TRANSPORT_CONTROLS,
            )
            created.setCallback(
                object : MediaSession.Callback() {
                    override fun onPlay() = command("play")
                    override fun onPause() = command("pause")
                    override fun onSkipToNext() = command("next")
                    override fun onSkipToPrevious() = command("previous")
                    override fun onStop() = command("stop")
                    override fun onSeekTo(pos: Long) = command("seek", pos)
                },
                main,
            )
            created.setSessionActivity(openApp())
            session = created
            registerReceiver()
        }
    } catch (e: Exception) {
        Log.w(TAG, "media session unavailable: $e")
        null
    }

    private fun hide() {
        metadataKey = ""
        notificationKey = ""
        session?.let { if (it.isActive) it.isActive = false }
        try {
            manager()?.cancel(NOTIFICATION_ID)
        } catch (_: Exception) {
        }
    }

    private fun manager(): NotificationManager? =
        context.getSystemService(NotificationManager::class.java)

    private fun openApp(): PendingIntent = PendingIntent.getActivity(
        context,
        1,
        HomeRole.launchIntent(context)
            ?: Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            },
        PendingIntent.FLAG_IMMUTABLE,
    )

    /** The notification buttons land here; Android 13 and later steer the session directly. */
    private fun registerReceiver() {
        if (receiver != null) return
        val created = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                val name = intent.getStringExtra(EXTRA_COMMAND) ?: return
                command(name)
            }
        }
        try {
            ContextCompat.registerReceiver(
                context,
                created,
                IntentFilter(ACTION_COMMAND),
                ContextCompat.RECEIVER_NOT_EXPORTED,
            )
            receiver = created
        } catch (e: Exception) {
            Log.w(TAG, "media button receiver unavailable: $e")
        }
    }

    private fun commandIntent(name: String, code: Int): PendingIntent = PendingIntent.getBroadcast(
        context,
        code,
        Intent(ACTION_COMMAND).setPackage(context.packageName).putExtra(EXTRA_COMMAND, name),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    private fun notify(session: MediaSession, offered: List<String>) {
        val manager = manager() ?: return
        try {
            val localized = NativeMessages.forKiosk(context)
            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                ensureChannel(manager, localized)
                Notification.Builder(context, CHANNEL_ID)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(context).setPriority(Notification.PRIORITY_LOW)
            }
            val icon = StatusBarIcon.bitmap(context)
            if (icon != null) {
                builder.setSmallIcon(Icon.createWithBitmap(icon))
            } else {
                builder.setSmallIcon(R.drawable.ic_stat_service)
            }
            val buttons = buttonsFor(offered, shownPlaying)
            buttons.forEachIndexed { index, name ->
                builder.addAction(
                    Notification.Action.Builder(
                        Icon.createWithResource(context, buttonIcon(name)),
                        localized.getString(buttonLabel(name)),
                        commandIntent(name, index),
                    ).build(),
                )
            }
            builder
                .setContentTitle(title)
                .setContentText(artist.ifEmpty { album })
                .setContentIntent(openApp())
                .setShowWhen(false)
                .setOngoing(shownPlaying)
                .setVisibility(Notification.VISIBILITY_PUBLIC)
                .setCategory(Notification.CATEGORY_TRANSPORT)
                .setStyle(
                    Notification.MediaStyle()
                        .setMediaSession(session.sessionToken)
                        .setShowActionsInCompactView(*buttons.indices.toList().toIntArray()),
                )
            art?.takeIf { artUrl == artworkUrl }?.let { builder.setLargeIcon(it) }
            manager.notify(NOTIFICATION_ID, builder.build())
        } catch (e: Exception) {
            Log.w(TAG, "media notification failed: $e")
        }
    }

    private fun ensureChannel(manager: NotificationManager, localized: Context) {
        if (channelReady || Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            localized.getString(R.string.ks_media_channel),
            // LOW: no sound, no heads-up for a track change.
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            setShowBadge(false)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        manager.createNotificationChannel(channel)
        channelReady = true
    }

    private fun buttonIcon(name: String): Int = when (name) {
        "previous" -> android.R.drawable.ic_media_previous
        "next" -> android.R.drawable.ic_media_next
        "pause" -> android.R.drawable.ic_media_pause
        else -> android.R.drawable.ic_media_play
    }

    private fun buttonLabel(name: String): Int = when (name) {
        "previous" -> R.string.ks_media_previous
        "next" -> R.string.ks_media_next
        "pause" -> R.string.ks_media_pause
        else -> R.string.ks_media_play
    }

    private fun decode(bytes: ByteArray): Bitmap? = try {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
        var sample = 1
        while (bounds.outWidth / (sample * 2) >= ARTWORK_MAX_PX &&
            bounds.outHeight / (sample * 2) >= ARTWORK_MAX_PX
        ) {
            sample *= 2
        }
        BitmapFactory.decodeByteArray(
            bytes,
            0,
            bytes.size,
            BitmapFactory.Options().apply { inSampleSize = sample },
        )
    } catch (e: Throwable) {
        Log.w(TAG, "artwork not decodable: $e")
        null
    }
}
