/* ---- System permissions ----
   What the app can ask Android for, what each grant is for, and whether a
   switched-on feature needs it right now. One list, read by the Device
   page's Permissions Manager (every row, three states) and by the
   Overview's Needs attention card (only what is needed and missing).
   `on(key)` answers whether a boolean setting is on. */
export function permissionSpecs(on) {
  const background = on('wake_word.enabled') && on('wake_word.background');
  return [
    { key: 'microphone', name: 'Microphone', ask: 'microphone',
      needed: on('wake_word.enabled'),
      held: 'Allows microphone usage for wake word detection and speech to text.',
      missing: 'Wake word detection is on and nothing is listening.',
      idle: 'Needed by wake word detection and by pages that ask for the microphone.' },
    // Always needed: the app holds the Home Assistant and MQTT
    // connections open while the screen is off, and Doze is what stops
    // them. Nothing has to be switched on for this one to matter.
    { key: 'batteryUnrestricted', name: 'Unrestricted battery', ask: 'batteryOptimizations',
      needed: true, requestable: 'batteryRequestable', adb: "This device has no settings screen for it. Grant it over adb: adb shell dumpsys deviceidle whitelist +me.jxl.kiosk_satellite",
      held: 'Allows the process to run in the background without being paused or killed.',
      missing: 'Android may pause the app when the screen is off, dropping the Home Assistant connection and the MQTT entities with it.',
      idle: '' },
    { key: 'camera', name: 'Camera', ask: 'camera',
      needed: on('camera.enabled'),
      held: 'Motion detection and snapshots can use the camera.',
      missing: 'The camera is switched on and cannot be opened.',
      idle: 'Needed by motion detection, camera snapshots and pages that ask for the camera.' },
    { key: 'bluetooth', name: 'Nearby devices',
      ask: ['bluetoothScan', 'bluetoothConnect'],
      needed: on('btproxy.enabled'),
      held: 'The Bluetooth proxy can scan for nearby devices.',
      // A function of the full payload: name the actual blocker, the
      // pair, the location grant, or the system-wide location switch
      // (issues #240, #246; location gates Bluetooth scanning on every
      // Android version). Same wording as the ESPHome tab's card.
      missing: (all) => all.bluetoothPair === false
        ? 'The Bluetooth proxy is switched on and cannot scan.'
        : all.location === false
          ? 'Bluetooth scanning needs the Location permission.'
          : 'Location is off in the device settings, so Bluetooth scanning finds nothing.',
      idle: 'Needed by the Bluetooth proxy to scan for devices.' },
    { key: 'notification', name: 'Notifications', ask: 'notifications',
      // The service's notification is part of every install's deal.
      needed: true,
      held: "Allows the Kiosk Satellite Service's ongoing notification, which says what it is keeping alive.",
      missing: "Needed to show the Kiosk Satellite Service's ongoing notification.",
      idle: '' },
    { key: 'displayOverOtherApps', name: 'Display over other apps', ask: 'overlay',
      requestable: 'overlayRequestable', adb: "This device has no settings screen for it. Grant it over adb: adb shell appops set me.jxl.kiosk_satellite SYSTEM_ALERT_WINDOW allow",
      needed: background || on('browser.auto_reload_on_error')
        || on('kiosk.start_on_boot') || on('kiosk.disable_status_bar'),
      held: 'Kiosk Satellite can bring itself back in the foreground.',
      missing: 'Without this the app cannot reopen itself after a crash, an update or a wake word heard behind another app.',
      idle: 'Lets the app bring itself back to the front, and the lockdown shield cover the whole screen.' },
    { key: 'writeSettings', name: 'Modify system settings', ask: 'writeSettings',
      needed: on('screen.set_brightness_on_launch') || on('screensaver.brightness_enabled'),
      held: "Brightness changes set the panel's real brightness.",
      missing: 'Brightness only dims the app window, so the panel and Home Assistant never see the change.',
      idle: "Needed to set the panel's real brightness rather than dimming the app window." },
    { key: 'uiGuard', name: 'System UI guard', guard: true,
      needed: on('kiosk.enabled') && on('kiosk.disable_status_bar'),
      held: 'The notification shade and recents close on their own while the screen is protected.',
      missing: 'The notification shade and recents stay reachable. Enable Kiosk Satellite under Accessibility.',
      idle: 'Closes the notification shade and recents while kiosk mode protects the screen.' },
    { key: 'deviceAdmin', name: 'Device admin', ask: 'deviceAdmin',
      needed: false,
      held: 'Allows the app to turn the screen off.',
      missing: '',
      idle: 'Lets Screen off power the panel down instead of only blacking it out.' },
    { key: 'allFiles', name: 'All files access', ask: 'allFiles',
      needed: false,
      held: 'The File Manager can browse the shared storage.',
      missing: '',
      idle: 'Lets the File Manager browse the shared storage instead of only the app folder.' },
    { key: 'usageAccess', name: 'Usage access', ask: 'usageAccess',
      needed: false,
      held: 'The Foreground app sensor can name whichever app is on screen.',
      missing: '',
      idle: 'Lets the Foreground app sensor name apps other than Kiosk Satellite.' },
    { key: 'location', name: 'Location', ask: 'location',
      needed: on('btproxy.enabled') || on('location.enabled'),
      held: 'Pages, Bluetooth scanning and the location sensors can use the device position.',
      missing: 'Android will not deliver Bluetooth scan results without Location, and the location sensors cannot read the GPS receiver.',
      idle: 'Used by pages that ask for your location, by Bluetooth scanning and by the ESPHome location sensors.' },
  ];
}
