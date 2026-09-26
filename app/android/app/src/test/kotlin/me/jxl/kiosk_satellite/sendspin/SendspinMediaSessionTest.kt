package me.jxl.kiosk_satellite.sendspin

import android.media.session.PlaybackState
import org.junit.Assert.assertEquals
import org.junit.Test

class SendspinMediaSessionTest {
    private fun actions(commands: List<String>, durationMs: Long = 180_000) =
        SendspinMediaSession.actionsFor(commands, durationMs)

    @Test fun playAndPauseTogetherAlsoOfferTheToggle() {
        assertEquals(
            PlaybackState.ACTION_PLAY or PlaybackState.ACTION_PAUSE or PlaybackState.ACTION_PLAY_PAUSE,
            actions(listOf("play", "pause")),
        )
        assertEquals(PlaybackState.ACTION_PLAY, actions(listOf("play")))
    }

    @Test fun transportCommandsMapToTheirActions() {
        assertEquals(
            PlaybackState.ACTION_SKIP_TO_NEXT or PlaybackState.ACTION_SKIP_TO_PREVIOUS or
                PlaybackState.ACTION_STOP,
            actions(listOf("next", "previous", "stop", "shuffle", "repeat_all")),
        )
    }

    @Test fun seekNeedsAKnownDuration() {
        assertEquals(PlaybackState.ACTION_SEEK_TO, actions(listOf("seek")))
        assertEquals(0L, actions(listOf("seek"), durationMs = 0))
        assertEquals(0L, actions(listOf("seek"), durationMs = -1))
    }

    @Test fun aServerThatNeverReportedGetsTheTransportBasics() {
        assertEquals(
            listOf("play", "pause", "next", "previous"),
            SendspinMediaSession.effectiveCommands(emptyList()),
        )
        assertEquals(listOf("play"), SendspinMediaSession.effectiveCommands(listOf("play")))
    }

    @Test fun buttonsShowTheToggleForTheCurrentState() {
        val all = listOf("play", "pause", "next", "previous")
        assertEquals(listOf("previous", "pause", "next"), SendspinMediaSession.buttonsFor(all, playing = true))
        assertEquals(listOf("previous", "play", "next"), SendspinMediaSession.buttonsFor(all, playing = false))
        assertEquals(listOf("play"), SendspinMediaSession.buttonsFor(listOf("play"), playing = false))
        assertEquals(emptyList<String>(), SendspinMediaSession.buttonsFor(listOf("play"), playing = true))
    }
}
