// SPDX-License-Identifier: Apache-2.0
package me.jxl.kiosk.plugins;

import java.util.Map;

/**
 * SDK 1, player. Hears what KS asks of a player published with PluginHost.publishPlayer. Calls arrive on a thread of
 * KS and must return within three seconds, so start long work on a thread of your own.
 *
 * Implement PlayerLibrary on the same object to show a Music Library source, and PlayerQueue to show a queue.
 */
public interface PlayerListener {
    /**
     * The user picked this player under Media Player > Player. Start serving now: open the audio output, listen on
     * the network, advertise the player. Nothing of it should run before this call.
     */
    void onActivate(PluginPlayer player);

    /**
     * Another player was picked, the player was removed or KS is stopping the plugin. Stop playing and serving. KS
     * has already closed the audio output.
     */
    void onDeactivate();

    /**
     * A transport command from Now Playing, the floating player, a voice request or an action: "play", "pause",
     * "stop", "next", "previous", "seek" with {positionMs}, "shuffle" with {on} or "repeat" with {mode: "off", "one"
     * or "all"}. Only the actions the player's state lists are sent.
     */
    void onCommand(String command, Map<String, Object> arguments);
}
