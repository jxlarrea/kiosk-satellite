// SPDX-License-Identifier: Apache-2.0
package me.jxl.kiosk.plugins;

import java.util.Map;

/** Versioned host API. Access is scoped to the plugin and revoked when it stops. */
public interface PluginHost {
    /** SDK 1. Detached JSON-compatible data, or null. Errors have ok=false. */
    interface CommandCallback {
        void onResult(boolean ok, Object data, String error);
    }

    /** SDK 1, host.read or host.control. Asynchronous documented KS commands. */
    default void executeCommand(String command, Map<String, Object> arguments, CommandCallback callback) { throw new UnsupportedOperationException("SDK 1 required"); }
    /** SDK 1, host.read. Events arrive through onEvent("ks." + event, payload). */
    default void subscribe(String event) { throw new UnsupportedOperationException("SDK 1 required"); }
    /** SDK 1. Stop observing an event. All subscriptions end with the session. */
    default void unsubscribe(String event) { throw new UnsupportedOperationException("SDK 1 required"); }
    /** Publish a bounded chart snapshot. SDK 1. */
    default void publishSeries(String key, Map<String, Object> chart) { throw new UnsupportedOperationException("Charts are unavailable"); }
    /** Remove this session's chart with the given key. */
    default void removeSeries(String key) { throw new UnsupportedOperationException("Charts are unavailable"); }
    /** Show or update this plugin's one floating window. Text is plain text. */
    void showWindow(String title, String message, String buttonLabel);
    void hideWindow();
    void log(String message);
    /** SDK 1. Absolute path to a verified library private to this session. */
    default String nativeLibraryPath(String name) { throw new UnsupportedOperationException("SDK 1 required"); }
    /** SDK 1. Verified DEX container, for a plugin-owned helper process. */
    default String packagePath() { throw new UnsupportedOperationException("SDK 1 required"); }
    /** SDK 1. Display a runtime status in the plugin subpage. */
    default void status(String message, boolean error) { throw new UnsupportedOperationException("SDK 1 required"); }
    /** SDK 1. Persist settings changed by plugin actions or Home Assistant. */
    default void saveSettings(Map<String, Object> values) { throw new UnsupportedOperationException("SDK 1 required"); }
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
    /** SDK 1, entities. Changes arrive as select.KEY with {option: string}. Publish the applied option to confirm it. */
    default void publishSelect(String key, String name, String[] options, String state) { throw new UnsupportedOperationException("SDK 1 required"); }
    default void removeSelect(String key) { throw new UnsupportedOperationException("SDK 1 required"); }
}
