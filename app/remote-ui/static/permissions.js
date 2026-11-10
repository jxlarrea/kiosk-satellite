import { isHeadless } from './headless.js';

/* ---- System permissions ----
   What the app can ask Android for, what each grant is for, and whether a
   switched-on feature needs it right now. One list, read by the Device
   page's Permissions Manager (every row, three states) and by the
   Overview's Needs attention card (only what is needed and missing).
   `on(key)` answers whether a boolean setting is on, `value(key)` reads
   any setting. */
export function permissionSpecs(on, value = () => undefined, headless = isHeadless()) {
  const specs = allPermissionSpecs(on, value);
  if (!headless) return specs;
  // No screen to accept a grant on: adb gives each one, and the grants for
  // display features are left out. The buttons are the device's own row.
  return [
    ...specs
      .filter((spec) => ['microphone', 'batteryUnrestricted', 'bluetooth', 'notification', 'location', 'allFiles'].includes(spec.key))
      .map((spec) => ({ ...spec, adb: HEADLESS_ADB[spec.key] || spec.adb })),
    { key: 'hardwareButtons', name: 'Hardware buttons',
      needed: true,
      // Switched on but not running: Android 7 starts a service enabled at
      // runtime only after a reboot, so the commands would not help again.
      adb: (all) => (all.hardwareButtonsOn ? HEADLESS_ADB.hardwareButtonsRestart : HEADLESS_ADB.hardwareButtons),
      held: 'The device buttons reach gestures and Voice Satellite.',
      missing: 'The device buttons do nothing until the button service is switched on.',
      idle: '' },
  ];
}

// The adb command for each grant a device without a screen needs, since
// Android cannot ask for it there.
export const HEADLESS_ADB = {
    microphone: 'This device has no screen. Grant it over adb: adb shell pm grant me.jxl.kiosk_satellite android.permission.RECORD_AUDIO',
    notification: 'This device has no screen. Grant it over adb: adb shell pm grant me.jxl.kiosk_satellite android.permission.POST_NOTIFICATIONS',
    location: 'This device has no screen. Grant it over adb: adb shell pm grant me.jxl.kiosk_satellite android.permission.ACCESS_FINE_LOCATION',
    bluetooth: 'This device has no screen. Grant it over adb: adb shell pm grant me.jxl.kiosk_satellite android.permission.BLUETOOTH_SCAN, then the same for BLUETOOTH_CONNECT',
    batteryUnrestricted: 'This device has no screen. Grant it over adb: adb shell dumpsys deviceidle whitelist +me.jxl.kiosk_satellite',
    allFiles: 'This device has no screen. Grant it over adb: adb shell pm grant me.jxl.kiosk_satellite android.permission.READ_EXTERNAL_STORAGE, then the same for WRITE_EXTERNAL_STORAGE',
    hardwareButtons: 'This device has no screen. Switch it on over adb: adb shell settings put secure enabled_accessibility_services me.jxl.kiosk_satellite/.HeadlessKeyService, then adb shell settings put secure accessibility_enabled 1',
    hardwareButtonsRestart: 'The button service is switched on but has not started. Restart the device to start it: adb reboot',
};

/** A row's adb line, which for some rows depends on what the status says. */
export function adbHint(spec, all = {}) {
  return typeof spec.adb === 'function' ? spec.adb(all) : spec.adb;
}

function allPermissionSpecs(on, value) {
  // Nothing listens for the wake word with the native satellite switched
  // off. A dashboard runtime starts the engine from the page instead.
  const listening = on('wake_word.enabled')
    && (value('voice.runtime') === 'dashboard' || on('voice.enabled'));
  const background = listening && on('wake_word.background');
  return [
    { key: 'microphone', name: 'Microphone', ask: 'microphone',
      needed: listening,
      held: 'Allows microphone usage for wake word detection, speech to text and intercom calls.',
      missing: 'Wake word detection is on and nothing is listening.',
      idle: 'Needed by wake word detection, the intercom and pages that ask for the microphone.' },
    // Always needed: the app holds the Home Assistant and ESPHome
    // connections open while the screen is off, and Doze is what stops
    // them. Nothing has to be switched on for this one to matter.
    { key: 'batteryUnrestricted', name: 'Unrestricted battery', ask: 'batteryOptimizations',
      needed: true, requestable: 'batteryRequestable', adb: "This device has no settings screen for it. Grant it over adb: adb shell dumpsys deviceidle whitelist +me.jxl.kiosk_satellite",
      held: 'Allows the process to run in the background without being paused or killed.',
      missing: 'Android may pause the app when the screen is off, dropping the Home Assistant connection and the ESPHome entities with it.',
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
    // The Local Media Session player reads other apps' sessions through
    // it, so it counts as missing only while it is picked.
    { key: 'notificationAccess', name: 'Notification access', ask: 'notificationAccess',
      needed: !value('sendspin.player_source') && value('sendspin.player') === 'session:*',
      held: 'Now Playing can follow the apps playing on this device.',
      missing: 'Without this Android lists no media sessions, so Now Playing cannot follow the apps playing on this device.',
      idle: 'Lets Now Playing follow the apps playing on this device.' },
    { key: 'location', name: 'Location', ask: 'location',
      needed: on('btproxy.enabled') || on('location.enabled') || on('web.geolocation')
        || (value('screensaver.mode') === 'celestial'
          && value('screensaver.celestial_location') === 'gps'),
      held: 'Pages, Bluetooth scanning and the location sensors can use the device position.',
      missing: 'Android will not deliver Bluetooth scan results without Location, and the location sensors cannot read the GPS receiver.',
      idle: 'Used by pages that ask for your location, by Bluetooth scanning and by the ESPHome location sensors.' },
  ];
}
