// SPDX-License-Identifier: Apache-2.0
package me.jxl.kiosk.plugins;

import java.util.Map;

/** SDK 1. Callbacks run serially on a worker thread and must return promptly. */
public interface KioskPlugin {
    void start(PluginHost host, Map<String, Object> settings) throws Exception;
    void configure(Map<String, Object> settings) throws Exception;
    void execute(String command, Map<String, Object> arguments) throws Exception;
    void onEvent(String event, Map<String, Object> payload) throws Exception;
    void stop() throws Exception;
}
