// SPDX-License-Identifier: Apache-2.0
package me.jxl.kiosk.plugins;

import java.util.Map;

/** SDK 1. Calls are scoped to the owning plugin and ignored after it stops. */
public interface PluginHost {
    /** Show or update this plugin's one floating window. Text is plain text. */
    void showWindow(String title, String message, String buttonLabel);
    void hideWindow();
    void log(String message);
    /** SDK 2. Absolute path to a verified library private to this session. */
    default String nativeLibraryPath(String name) { throw new UnsupportedOperationException("SDK 2 required"); }
    /** SDK 2. Verified DEX container, for a plugin-owned helper process. */
    default String packagePath() { throw new UnsupportedOperationException("SDK 2 required"); }
    /** SDK 2. Display a runtime status in the plugin subpage. */
    default void status(String message, boolean error) { throw new UnsupportedOperationException("SDK 2 required"); }
    /** SDK 2. Persist settings changed by plugin actions or Home Assistant. */
    default void saveSettings(Map<String, Object> values) { throw new UnsupportedOperationException("SDK 2 required"); }
    /** SDK 2. Register or update an RGB light. Commands arrive as light.<key>. */
    default void publishLight(String key, String name, String[] effects, Map<String, Object> state) { throw new UnsupportedOperationException("SDK 2 required"); }
    default void removeLight(String key) { throw new UnsupportedOperationException("SDK 2 required"); }
}
