// SPDX-License-Identifier: Apache-2.0
package me.jxl.kiosk.plugins;

/**
 * SDK 1, player. Implemented by a PlayerListener to show its queue in Now Playing and the Music Library, and to let
 * the user edit it there. Call PluginPlayer.queueChanged whenever it changes.
 */
public interface PlayerQueue {
    /**
     * The queue as {items, current}: items in play order, each a map of id, title, artist, artworkUrl and durationMs,
     * and current the index of the playing one, or -1. At most 500 items. 20 seconds to answer.
     */
    void queue(PluginHost.CommandCallback callback);

    /** Play the queue item with this id. */
    void playItem(String id);

    /** Move the queue item with this id to index toIndex of the queue as it is now. */
    void moveItem(String id, int toIndex);

    /** Take the queue item with this id out of the queue. */
    void removeItem(String id);

    /** Empty the queue and stop. */
    void clear();
}
