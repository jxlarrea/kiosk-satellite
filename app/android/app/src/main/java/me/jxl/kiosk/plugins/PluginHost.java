// SPDX-License-Identifier: Apache-2.0
package me.jxl.kiosk.plugins;

/** SDK 1. Calls are scoped to the owning plugin and ignored after it stops. */
public interface PluginHost {
    /** Show or update this plugin's one floating window. Text is plain text. */
    void showWindow(String title, String message, String buttonLabel);
    void hideWindow();
    void log(String message);
}
