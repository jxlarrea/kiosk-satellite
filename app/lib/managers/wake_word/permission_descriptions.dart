/// Permission names and explanations shared by Device settings pages.
const devicePermissionDescriptions = <String, ({String title, String description})>{
  'microphone': (
    title: 'Microphone',
    description:
        'Allows microphone usage for wake word detection and speech to text.',
  ),
  'batteryUnrestricted': (
    title: 'Unrestricted battery',
    description:
        'Allows the process to run in the background without being paused or killed.',
  ),
  'camera': (
    title: 'Camera',
    description: 'Motion detection and snapshots can use the camera.',
  ),
  'bluetooth': (
    title: 'Nearby devices',
    description: 'The Bluetooth proxy can scan for nearby devices.',
  ),
  'notification': (
    title: 'Notifications',
    description:
        "Allows the Kiosk Satellite Service's ongoing notification, which says what it is keeping alive.",
  ),
  'displayOverOtherApps': (
    title: 'Display over other apps',
    description: 'Kiosk Satellite can bring itself back in the foreground.',
  ),
  'writeSettings': (
    title: 'Modify system settings',
    description: "Brightness changes set the panel's real brightness.",
  ),
  'uiGuard': (
    title: 'System UI guard',
    description:
        'The notification shade and recents close on their own while the screen is protected.',
  ),
  'deviceAdmin': (
    title: 'Device admin',
    description: 'Allows the app to turn the screen off.',
  ),
  'allFiles': (
    title: 'All files access',
    description: 'The File Manager can browse the shared storage.',
  ),
  'usageAccess': (
    title: 'Usage access',
    description:
        'The Foreground app sensor can name whichever app is on screen.',
  ),
  'location': (
    title: 'Location',
    description:
        'Pages, Bluetooth scanning and the location sensors can use the device position.',
  ),
};
