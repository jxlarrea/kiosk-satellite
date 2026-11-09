// SPDX-License-Identifier: Apache-2.0
package me.jxl.kiosk.plugins;

import java.util.Map;

/** SDK 1, player. A published player while it is the pick. KS hands it to PlayerListener.onActivate. */
public interface PluginPlayer {
    /** 16-bit signed PCM, little endian, channels interleaved. */
    int ENCODING_PCM_16 = 16;

    /**
     * Show what plays. KS shows it in Now Playing, the floating player and the ESPHome media player, and moves the
     * position on while it plays. Send a new state whenever something in it changes, not on a timer. Keys:
     * <ul>
     * <li>state: "idle", "buffering", "playing" or "paused". Idle shows nothing.</li>
     * <li>title, artist and album: up to 512 characters each.</li>
     * <li>artworkUrl: an http or https image address, or artwork: the image itself as byte[], JPEG or PNG, at most
     * 1 MiB.</li>
     * <li>durationMs: the track's length. Leave it out for a stream with no end.</li>
     * <li>positionMs: where the track is right now.</li>
     * <li>shuffle: true or false. repeat: "off", "one" or "all".</li>
     * <li>actions: the commands the player takes, from "play", "pause", "stop", "next", "previous", "seek",
     * "shuffle" and "repeat". Only these show as buttons. Leave it empty for a player that only shows what plays.</li>
     * </ul>
     * Volume is not part of it: KS applies its own media volume and the assistant's duck level to the audio output.
     */
    void update(Map<String, Object> state);

    /** The queue changed. KS asks PlayerQueue.queue again if the queue is on screen. */
    void queueChanged();

    /** Whether this player is still the pick. False after onDeactivate. */
    boolean isActive();

    /**
     * Open the audio output, replacing one opened before. sampleRate is 8000 to 192000, channels 1 or 2 and encoding
     * ENCODING_PCM_16. The output plays through the same path as the Sendspin player: the echo canceller hears it, the
     * media volume and the assistant's duck apply to it and it follows the device's audio route. Throws once the
     * player is no longer the pick.
     */
    AudioOutput openAudio(int sampleRate, int channels, int encoding);
}
