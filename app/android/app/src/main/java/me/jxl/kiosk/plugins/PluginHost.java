// SPDX-License-Identifier: Apache-2.0
package me.jxl.kiosk.plugins;

import java.util.Map;

/** Versioned host API. Access is scoped to the plugin and revoked when it stops. */
public interface PluginHost {
    /** SDK 1. Detached JSON-compatible data, or null. Errors have ok=false. */
    interface CommandCallback {
        void onResult(boolean ok, Object data, String error);
    }

    /** SDK 1, camera. Frames from openCamera, delivered one at a time on a camera thread of the plugin's own. */
    interface CameraListener {
        /** A new frame. Frames that arrive while this call still runs are skipped. */
        void onFrame(CameraFrame frame);
        /**
         * The camera closed and no frames follow. reason is "closed", "timeout", "busy", "disabled", "permission",
         * "no_camera" or "camera_failed".
         */
        default void onClosed(String reason) {}
    }

    /** SDK 1, host.read, host.control or screensaver.mode. Asynchronous documented KS commands. */
    default void executeCommand(String command, Map<String, Object> arguments, CommandCallback callback) { throw new UnsupportedOperationException("SDK 1 required"); }
    /** SDK 1, host.read. Events arrive through onEvent("ks." + event, payload). */
    default void subscribe(String event) { throw new UnsupportedOperationException("SDK 1 required"); }
    /** SDK 1. Stop observing an event. All subscriptions end with the session. */
    default void unsubscribe(String event) { throw new UnsupportedOperationException("SDK 1 required"); }
    /**
     * SDK 1, ha. Send one Home Assistant websocket command without its id, such as {type: "call_service", domain,
     * service, service_data, target}. KS signs in with its own token and numbers the message. data is HA's result. On
     * failure, error reads "code: message" and data holds {code, message}. Credential commands are refused.
     */
    default void haCall(Map<String, Object> message, CommandCallback callback) { throw new UnsupportedOperationException("Home Assistant access is unavailable"); }
    /**
     * SDK 1, ha. Start a Home Assistant subscription, such as subscribe_trigger or render_template, under a key of the
     * plugin's choosing. The callback says whether HA accepted it. Events arrive through
     * onEvent("ks.ha.subscription." + key, payload) until haUnsubscribe or the end of the session. At most 16.
     */
    default void haSubscribe(String key, Map<String, Object> message, CommandCallback callback) { throw new UnsupportedOperationException("Home Assistant access is unavailable"); }
    /** SDK 1, ha. End a subscription. Unknown keys are ignored. */
    default void haUnsubscribe(String key) { throw new UnsupportedOperationException("Home Assistant access is unavailable"); }
    /**
     * SDK 1, ma. Run one Music Assistant API command, such as "player_queues/play_media" with {queue_id, media}, through
     * the kiosk's own Music Assistant connection and token. data is Music Assistant's result. On failure, error reads
     * "code: message" and data holds {code, message}. Players, queues, the library and metadata are open. Server
     * configuration, sign-in, users and tokens are refused.
     */
    default void maCall(String command, Map<String, Object> args, CommandCallback callback) { throw new UnsupportedOperationException("Music Assistant access is unavailable"); }
    /**
     * SDK 1, ma. Hear Music Assistant events under a key of the plugin's choosing. The filter is {events: [names],
     * objectId}, such as {events: ["queue_updated"], objectId: queueId}, with objectId optional. Events arrive through
     * onEvent("ks.ma.subscription." + key, payload) until maUnsubscribe or the end of the session. At most 16.
     */
    default void maSubscribe(String key, Map<String, Object> filter, CommandCallback callback) { throw new UnsupportedOperationException("Music Assistant access is unavailable"); }
    /** SDK 1, ma. End a subscription. Unknown keys are ignored. */
    default void maUnsubscribe(String key) { throw new UnsupportedOperationException("Music Assistant access is unavailable"); }
    /**
     * SDK 1, camera. Receive frames from the device camera, through the same session motion detection uses. Options:
     * size "320x240", "640x480" (default) or "1280x720", fps 1 to 15 (default 5), facing "default", "front" or
     * "back", format "luminance" (default) or "nv21" and timeoutSeconds 5 to 600 (default 60). The camera closes when
     * the time is up. Call it again to change the options or restart the time. One plugin holds the camera at a time.
     */
    default void openCamera(Map<String, Object> options, CameraListener listener) { throw new UnsupportedOperationException("Camera access is unavailable"); }
    /** SDK 1, camera. Stop the frames. The listener hears onClosed("closed"). */
    default void closeCamera() { throw new UnsupportedOperationException("Camera access is unavailable"); }
    /**
     * SDK 1, barcode. Show the KS scanner and answer with the first code it reads as {value, format}. Options: formats,
     * a list from "qr_code", "aztec", "data_matrix", "pdf417", "ean_13", "ean_8", "upc_a", "upc_e", "code_128",
     * "code_39", "code_93", "codabar" and "itf" (default all), facing "default", "front" or "back", timeoutSeconds
     * 5 to 120 (default 30), title up to 80 characters and message up to 200. On failure error and data.code are
     * "canceled", "timeout", "busy", "disabled", "permission", "no_camera", "camera_failed" or "unavailable".
     */
    default void scanBarcode(Map<String, Object> options, CommandCallback callback) { throw new UnsupportedOperationException("Barcode scanning is unavailable"); }
    /** SDK 1, barcode. Close this plugin's scanner. Its callback reports "canceled". */
    default void cancelBarcodeScan() { throw new UnsupportedOperationException("Barcode scanning is unavailable"); }
    /** SDK 1, shizuku. Current availability, permission, backend UID and version. Does not prompt. */
    default Map<String, Object> shizukuState() { throw new UnsupportedOperationException("Shizuku is unavailable"); }
    /** SDK 1, shizuku. Run an absolute executable with separate arguments after the user grants KS access. */
    default void executeShizuku(String[] command, int timeoutMs, CommandCallback callback) { throw new UnsupportedOperationException("Shizuku is unavailable"); }
    /** SDK 1, screensaver. Register self-contained HTML as a stock screensaver mode. Does not activate it. */
    default void publishScreensaver(String key, String title, String html) { throw new UnsupportedOperationException("Screensavers are unavailable"); }
    /** SDK 1, screensaver. Register an HTML path relative to assets/ with scalar JSON data. Assets load on demand. */
    default void publishScreensaverAsset(String key, String title, String entry, Map<String, Object> data) { throw new UnsupportedOperationException("Screensaver assets are unavailable"); }
    /**
     * SDK 1, screensaver. Register a native screensaver drawn by an Android view, under the same keys and limits as
     * the HTML renderers, replacing any renderer with this key. Does not activate it. While the screensaver shows it,
     * KS builds the view through the factory on the main thread to fill the screen, with the KS theme and UI scale.
     * Touches stay with KS. onDestroy means the screensaver is gone, so stop updating the view.
     */
    default void publishScreensaverView(String key, String title, OverlayFactory factory) { throw new UnsupportedOperationException("Native screensavers are unavailable"); }
    /**
     * SDK 1, screensaver. As above, but with touch true single taps reach the view and a double tap closes the
     * screensaver. Draw your own hint, such as "Double tap to close". Older KS releases throw.
     */
    default void publishScreensaverView(String key, String title, OverlayFactory factory, boolean touch) { throw new UnsupportedOperationException("Touch screensavers are unavailable"); }
    /** SDK 1, screensaver. Remove a renderer. KS retains the session with a black background. */
    default void removeScreensaver(String key) { throw new UnsupportedOperationException("Screensavers are unavailable"); }
    /**
     * SDK 1, player. Offer a player under Media Player > Player, listed under This device as the plugin's name and the
     * title, such as "Radio: Internet Archive". KS calls listener.onActivate once the user picks it and
     * onDeactivate when the pick moves on. Publishing again under the same key changes the title. key is 1 to 40
     * lowercase letters, digits and underscores, title up to 80 characters. At most two players per plugin.
     */
    default void publishPlayer(String key, String title, PlayerListener listener) { throw new UnsupportedOperationException("Players are unavailable"); }
    /** SDK 1, player. Withdraw a player. A pick that names it stays and shows the player as unavailable. */
    default void removePlayer(String key) { throw new UnsupportedOperationException("Players are unavailable"); }
    /** Publish a bounded chart snapshot. SDK 1. */
    default void publishSeries(String key, Map<String, Object> chart) { throw new UnsupportedOperationException("Charts are unavailable"); }
    /** Remove this session's chart with the given key. */
    default void removeSeries(String key) { throw new UnsupportedOperationException("Charts are unavailable"); }
    /** SDK 1. Publish or update a tile on the Remote Admin Overview Status panel. Level is "on", "warn", "off" or "". */
    default void publishStatusTile(String key, String title, String level, String text) { throw new UnsupportedOperationException("Status tiles are unavailable"); }
    /** Remove this session's status tile with the given key. */
    default void removeStatusTile(String key) { throw new UnsupportedOperationException("Status tiles are unavailable"); }
    /** SDK 1. Fire a trigger declared in the manifest. Gestures mapped to it run their actions. At most four per second, extras are dropped. */
    default void fireTrigger(String id) { throw new UnsupportedOperationException("Gesture triggers are unavailable"); }
    /**
     * SDK 1. Run the action the user chose in an "action" setting. The setting is its key, or for a list row field
     * the list key, the row index and the field key joined by dots, such as "items.2.action". The callback hears
     * ok=false with an error when nothing is chosen, Lockdown Mode is on or the action fails. At most four per
     * second. Plugins cannot change action settings, so only the user decides what runs.
     */
    default void runAction(String setting, CommandCallback callback) { throw new UnsupportedOperationException("Action settings are unavailable"); }
    /** SDK 1, overlay. Show a native overlay, or replace the one with this key. Never blocks: KS builds its view later on the main thread through the factory. At most four per plugin. */
    default void showOverlay(String key, OverlaySpec spec, OverlayFactory factory) { throw new UnsupportedOperationException("Native overlays are unavailable"); }
    /** SDK 1, overlay. Remove an overlay. Unknown keys are ignored. */
    default void hideOverlay(String key) { throw new UnsupportedOperationException("Native overlays are unavailable"); }
    /**
     * SDK 1, overlay. Keep the dashboard clear of a bar: Home Assistant pads its views, dialogs and toasts by these
     * distances from each edge, 0 to 4096 dp, so nothing hides under the bar. All zero clears it, and so does the end
     * of the session. With several plugins, each edge keeps the largest.
     */
    default void setContentInsets(int left, int top, int right, int bottom) { throw new UnsupportedOperationException("Content insets are unavailable"); }
    /** True on a device without a screen, where overlays, windows and screensavers are never shown. A plugin that declares "headless": true checks this and skips them. */
    default boolean isHeadless() { return false; }
    /** Show or update this plugin's one floating window. Text is plain text. */
    void showWindow(String title, String message, String buttonLabel);
    void hideWindow();
    void log(String message);
    /** SDK 1. Absolute path to a verified library private to this session. */
    default String nativeLibraryPath(String name) { throw new UnsupportedOperationException("SDK 1 required"); }
    /** SDK 1. Verified DEX container, for a plugin-owned helper process. */
    default String packagePath() { throw new UnsupportedOperationException("SDK 1 required"); }
    /** SDK 1. Absolute path to a verified, read-only file under the package's assets folder, such as a font for Typeface.createFromFile. */
    default String assetPath(String name) { throw new UnsupportedOperationException("Plugin assets are unavailable"); }
    /** SDK 1. Open a verified file under the package's assets folder for reading. The caller closes the stream. */
    default java.io.InputStream openAsset(String name) throws java.io.IOException { throw new UnsupportedOperationException("Plugin assets are unavailable"); }
    /** SDK 1. Display a runtime status in the plugin subpage. */
    default void status(String message, boolean error) { throw new UnsupportedOperationException("SDK 1 required"); }
    /** SDK 1. Persist settings changed by plugin actions or Home Assistant. */
    default void saveSettings(Map<String, Object> values) { throw new UnsupportedOperationException("SDK 1 required"); }
    /**
     * SDK 1. Save only the named settings. Every other saved value stays, secrets included. Use it to fill in
     * settings that depend on a choice. Like saveSettings, it does not call configure.
     */
    default void updateSettings(Map<String, Object> values) { throw new UnsupportedOperationException("Setup controls are unavailable"); }
    /**
     * SDK 1. Report on a run that a settings button or a choices refresh started: "running" with progress text,
     * then "success" or "error" with the outcome. Returns false once the run was canceled, replaced or timed out,
     * so stop its work. A run with nothing reported for 60 seconds fails.
     */
    default boolean setupResult(String run, String state, String message) { throw new UnsupportedOperationException("Setup controls are unavailable"); }
    /**
     * SDK 1. Ask the person who started a run to confirm a step, such as trusting a certificate fingerprint. The
     * answer arrives as onEvent("settings.confirm", {run, accepted}). One question per run at a time. Returns
     * false once the run is over.
     */
    default boolean confirmSetup(String run, String title, String message, String confirmLabel) { throw new UnsupportedOperationException("Setup controls are unavailable"); }
    /**
     * SDK 1. List the choices of a string setting or list row field declared with "choices": "plugin". The setting
     * stores the ID. labels may be null, and a null label shows its ID. At most 200, with labels up to 80
     * characters. key is the setting key or the dotted path of a list row field. KS keeps the latest list for each
     * key, also across restarts, until the plugin lists that key again.
     */
    default void setSettingChoices(String key, String[] ids, String[] labels) { throw new UnsupportedOperationException("Setup controls are unavailable"); }
    /**
     * SDK 1, setup controls. Lists the choices of a string setting or list row field declared with "choices":
     * "plugin". Each map holds id (required, 1 to 512 characters), label (up to 120, defaults to the id), group (up
     * to 120, choices with the same group show under one heading, in the order groups first appear) and detail (up
     * to 120, a secondary line), value (up to 40, shown on the right the way an entity shows its state), category (up to
     * 40, the chips above the list filter by it) and icon (an MDI name such as "mdi:thermometer"). At most 2000
     * choices. key is the setting key or the dotted
     * path of a list row field, such as "panels.tiles.sensor".
     */
    default void setSettingChoices(String key, java.util.List<java.util.Map<String, Object>> choices) { throw new UnsupportedOperationException("Rich setting choices are unavailable"); }

    /**
     * SDK 1, setup controls. Turns a choices setting or list row field off or back on, such as while the device its
     * choices come from cannot be reached. Off, its picker and its Refresh button do not open and the saved choice
     * still shows. Every choice starts on in a new session. key is the setting key or the dotted path of a list row
     * field, as for setSettingChoices.
     */
    default void setSettingChoicesEnabled(String key, boolean enabled) { throw new UnsupportedOperationException("Turning choices off is unavailable"); }
    /** SDK 1. Register or update an RGB light. Commands arrive as light.<key>. */
    default void publishLight(String key, String name, String[] effects, Map<String, Object> state) { throw new UnsupportedOperationException("SDK 1 required"); }
    default void removeLight(String key) { throw new UnsupportedOperationException("SDK 1 required"); }
    /** SDK 1, entities. Numeric state or null for unknown. Metadata: unit, deviceClass, stateClass, accuracyDecimals. */
    default void publishSensor(String key, String name, Map<String, Object> metadata, Double state) { throw new UnsupportedOperationException("SDK 1 required"); }
    default void removeSensor(String key) { throw new UnsupportedOperationException("SDK 1 required"); }
    /** SDK 1, entities. Text state (up to 512 characters) or null for unknown. */
    default void publishTextSensor(String key, String name, String state) { throw new UnsupportedOperationException("SDK 1 required"); }
    default void removeTextSensor(String key) { throw new UnsupportedOperationException("SDK 1 required"); }
    /** SDK 1, entities. Boolean state or null for unknown. Empty deviceClass means none. */
    default void publishBinarySensor(String key, String name, String deviceClass, Boolean state) { throw new UnsupportedOperationException("SDK 1 required"); }
    default void removeBinarySensor(String key) { throw new UnsupportedOperationException("SDK 1 required"); }
    /** SDK 1, entities. Confirmed boolean state. Commands arrive as switch.KEY with {on: boolean}. */
    default void publishSwitch(String key, String name, boolean state) { throw new UnsupportedOperationException("SDK 1 required"); }
    default void removeSwitch(String key) { throw new UnsupportedOperationException("SDK 1 required"); }
    /** SDK 1, entities. Changes arrive as select.KEY with {option: string}. Publish the applied option to confirm it. */
    default void publishSelect(String key, String name, String[] options, String state) { throw new UnsupportedOperationException("SDK 1 required"); }
    default void removeSelect(String key) { throw new UnsupportedOperationException("SDK 1 required"); }
}
