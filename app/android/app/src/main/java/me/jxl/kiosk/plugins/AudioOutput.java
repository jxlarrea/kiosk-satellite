// SPDX-License-Identifier: Apache-2.0
package me.jxl.kiosk.plugins;

import java.nio.ByteBuffer;

/**
 * SDK 1, player. PCM output from PluginPlayer.openAudio. Write from a thread of your own. A plugin that keeps time
 * with other speakers uses getTimestamp to learn when written frames are heard, the way AAudio and ALSA report it.
 */
public interface AudioOutput {
    /**
     * Queue up to frames frames from pcm, starting at its position, and advance the position past what was taken.
     * Blocks while the output is full, at most timeoutMs (1 to 2000). Returns the frames taken, or -1 once the output
     * is closed.
     */
    int write(ByteBuffer pcm, int frames, int timeoutMs);

    /**
     * Where playback is: out[0] is a frame position and out[1] the System.nanoTime() at which that frame was heard,
     * on the same clock the echo canceller uses. Positions count from the last flush. Returns false until the first
     * frames are heard.
     */
    boolean getTimestamp(long[] out);

    /** Frames written since the last flush. Frames written but not yet heard are framesWritten() minus the position. */
    long framesWritten();

    /** Drop what is queued and start a new count from zero, for a pause, a seek or a new track. */
    void flush();

    /** Stop and release the output. Writes return -1 afterwards. */
    void close();
}
