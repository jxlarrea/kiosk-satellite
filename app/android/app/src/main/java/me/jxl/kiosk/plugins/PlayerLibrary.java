// SPDX-License-Identifier: Apache-2.0
package me.jxl.kiosk.plugins;

/**
 * SDK 1, player. Implemented by a PlayerListener to show a Music Library source under the player's name. The library
 * lists it whenever the plugin runs, the same way as Music Assistant or Sonos, and plays on the plugin's own player:
 * while another player is picked, the library asks the user to pick this one first.
 *
 * Items are maps: id (required, up to 512 characters), kind ("artist", "album", "track", "playlist", "radio",
 * "podcast", "episode", "audiobook", "genre", "folder" or "other"), title, subtitle, artworkUrl (http or https),
 * durationMs, playable (default true) and browsable (default false, true opens it with open() or browse()). A shelf
 * is a map of title and items. Answer through the callback: ok with the data, or ok=false with an error to show.
 * Each call has 20 seconds.
 */
public interface PlayerLibrary {
    /** Whether the library opens on discover() shelves. */
    default boolean hasDiscover() { return false; }

    /** Whether the library offers search(). */
    default boolean hasSearch() { return false; }

    /** The first page's shelves, as a list of shelves. */
    default void discover(PluginHost.CommandCallback callback) { callback.onResult(false, null, "Discover is unavailable"); }

    /**
     * A folder's children as {items, more}, more true when another page follows from offset + items. folderId null
     * is the root.
     */
    void browse(String folderId, int offset, PluginHost.CommandCallback callback);

    /** Results for a query, as a list of shelves. */
    default void search(String query, PluginHost.CommandCallback callback) { callback.onResult(false, null, "Search is unavailable"); }

    /** An album, playlist or other browsable item, as {item, items}: its own item map and its tracks. */
    void open(String itemId, PluginHost.CommandCallback callback);

    /**
     * Play an item on this player. mode is "replace" (clear the queue and play), "now" (play now, keep the rest),
     * "next" (after the current track) or "add" (to the end). withinId is the album or playlist a track was tapped
     * in, or null, so the rest of it can follow.
     */
    void play(String itemId, String mode, String withinId, PluginHost.CommandCallback callback);
}
