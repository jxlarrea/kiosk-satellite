# Gestures

Kiosk Satellite supports touch, clap, and hand gestures that trigger specific actions. This keeps your kiosk screen clean, as guests see no extra buttons on the dashboard. Meanwhile, the person who configured the device can use a deliberate, hidden gesture to jump to an admin view, run a script, or trigger an automation.

These custom gestures build upon the standard kiosk exit gesture. While the exit gesture is fixed (rapid taps anywhere, followed by a PIN, then the menu), these custom gestures allow you to fully configure both the input and the action. The standard exit gesture remains active and works alongside your custom ones.

Two of the available gestures do not require touching the screen at all. **Claps** allow you to trigger an action from across the room using the microphone, much like a classic Clapper switch. This works independently of Voice Satellite (see the [Claps](#claps) section below). The **Show fingers** gesture uses the camera to count the number of fingers you hold up. This is perfect for when your hands are wet, covered in flour, or otherwise unable to touch a screen (see the [Show fingers](#show-fingers) section below).

## Setup

Navigate to **Settings**, then **Gestures**. Here you will find the list of active gestures and the specific actions they trigger. This same page is also available in the remote admin interface. Any gesture configured here will function whenever the app is running, regardless of whether Kiosk Mode is enabled.

If you are using Kiosk Mode, you can use the **Disable Gestures** switch. When Kiosk Mode is active and this switch is turned on, all custom gestures become dormant. They will automatically rearm the moment lockdown ends.

Each entry on this page binds one specific gesture to one specific action. When adding a new entry, the app will first ask for the gesture's shape, and then the action. Each action type only requests the information it specifically requires (like a URL, a dashboard view, or a Home Assistant service call). The Home Assistant configuration dialogs include a **Validate** button, which actively checks the domain, service, and entity against your connected instance before saving anything.

## The Gestures

| Gesture | Notes |
| --- | --- |
| Taps in a corner | 2 to 4 quick taps located entirely inside one corner of the screen. |
| Hold a corner | Press and hold a specific corner for 0.5 to 3 seconds. |
| Multi-finger tap | 2 or 3 fingers, executing a single or double tap anywhere on the screen. |
| Multi-finger hold | 2 or 3 fingers held down simultaneously, anywhere on the screen. |
| Corner sequence | An ordered sequence of corner taps, functioning like a knock code. |
| Claps | 2 to 4 distinct claps, detected through the device microphone. |
| Show fingers | An open hand, or a hand showing 1 to 4 fingers, presented to the device camera. |

The corner hitboxes are approximately 1.5 centimeters square. You can map two different gestures to the exact same corner using different tap counts; the system will automatically wait a beat after the shorter sequence to ensure you aren't simply entering the longer one.

Crucially, touch gestures are only *observed*, never intercepted. Every touch still passes through to the dashboard underneath. This is exactly why the gesture shapes rely on corners, extra fingers, and long holds. None of these motions will accidentally trigger a standard dashboard card, which expects a simple tap or swipe. The corner sequence is the most discreet option available, making it perfect for protecting sensitive actions.

## The Actions

The action chooser groups options into three categories: Kiosk Satellite, Android, and Home Assistant.

| Action | Notes |
| --- | --- |
| Go to a dashboard view | Select from a dynamic list of your instance's dashboards and views. |
| Open a web page | Opens an external URL in an overlay (the same type used for dashboard links), complete with a close button. |
| Show a camera view | Displays any configured camera view. This action toggles: performing the exact same gesture again will close the view it just opened. A separate, dedicated close action exists if you simply want to close whatever view is currently visible. |
| Show the floating player | Displays the floating media player card. You can hide it by simply flinging the card away. |
| Show Now Playing | Opens the full-screen Now Playing view for the selected media player, including a paused track. Requires Now Playing to be enabled and a track to be loaded. |
| Open Music Assistant | Opens Music Assistant's web interface for the kiosk's player. Uses **Open directly to Now Playing** under Media Player > Music Assistant and works even when the menu shortcut is hidden. Requires a Music Assistant server address. |
| Open the app launcher | Opens the app launcher overlay displaying the specific apps you selected under App Launcher configuration. You can close it via its close button or by tapping outside the overlay. This requires the App Launcher to be enabled with at least one app selected. It works even if the Apps entry is hidden from the main kiosk menu (meaning you can hide the menu entry via Kiosk Mode, Allowed Actions, but keep the launcher accessible via a secret gesture). |
| Start the screensaver | Immediately launches whatever screensaver mode is currently configured. |
| Stop the screensaver | While redundant for touch gestures (since any screen tap dismisses a screensaver), this is highly useful for clap gestures, allowing you to wake the screen from across the room. |
| Toggle hold mode | Pins the current view, pausing the screensaver, dashboard rotation, and the return to home timer. Performing the same gesture again releases the hold. This pairs exceptionally well with a clap gesture when cooking from a recipe. |
| Toggle HA kiosk mode | Toggles the Home Assistant header and sidebar visibility. This controls the exact same setting as "HA kiosk mode" in the Home Assistant configuration and the "HA Kiosk Mode" menu option. It remains fully functional even when Kiosk Mode hides the menu item, allowing a hidden gesture to temporarily expose navigation controls without requiring a PIN. |
| Open another app | Opens a specific app by its package name, keeping the kiosk running safely in the background. |
| Open a deep link | Launches any custom URI claimed by another app (e.g., `myapp://path`). |
| Open Android Settings | Opens the core Android Settings app, keeping the kiosk running in the background. |
| Call a service | Executes a Home Assistant domain and service, with optional entity and data payload. |
| Run a script | Triggers a `script.*` entity using `script.turn_on`. |
| Trigger an automation | Triggers an `automation.*` entity using `automation.trigger`. |
| Fire an event | Fires a specific event type (with optional data) for Home Assistant automations to listen for. |

The four Home Assistant actions do not inherently change anything on the screen. Therefore, when they complete, Kiosk Satellite displays a toast notification titled by the action type (Home Assistant Service, Script, Automation, or Event). It will detail exactly what ran (e.g., "Called light.turn_on", "Ran script.morning"). If it fails, the toast will appear in red and explain why (e.g., Home Assistant not configured, connection down, call rejected). All other actions provide their own visual confirmation simply by executing.

## Claps

The app detects claps purely acoustically: it listens for a sharp, broadband burst of sound that significantly exceeds the room's ambient noise level and decays within a fraction of a second. This detection relies on simple arithmetic applied to the audio stream; it uses absolutely no machine learning models and relies on no cloud services. It is so lightweight that it runs comfortably on the weakest supported devices without ever competing with wake word detection resources.

For a sequence, claps must land roughly a half second apart or faster. A pause of roughly three quarters of a second definitively ends the sequence. You can map different actions to different clap counts; if you clap twice but have a three clap action configured, the system will wait out that brief pause to ensure a third clap isn't coming before firing the two clap action.

Microphone behavior for claps:
* If Voice Satellite wake word detection is running, clap detection simply piggybacks on the already open microphone capture, costing absolutely zero extra resources. If Voice Satellite is off, the app will open the microphone itself as long as at least one clap mapping exists. This means the clap feature works perfectly on a device that has never even installed Voice Satellite. When you create your first clap mapping, the app will prompt for the Microphone permission if it hasn't been granted yet.
* The app actively ignores claps while a voice interaction is taking place, ensuring that speaking to the satellite does not accidentally fire an action.
* If you mute the satellite via Voice Satellite, it closes the microphone entirely, which also disables clap detection. A muted device listens to nothing, full stop.
* Lockdown Mode and Kiosk Mode's Disable Gestures toggle will silence clap detection exactly as they silence touch gestures.
* The detection thresholds automatically adapt to the room's environment. Constant ambient noise (like background music or a running TV) will raise the acoustic bar a clap must clear to trigger, preventing false positives. While it works reliably over music, extremely percussive tracks played at high volumes can sometimes register as claps. For any critical action that must never misfire, configure it to require 3 or 4 claps.
* A clap must appear deliberate to the system: it must emerge from a relatively calm moment, land on an even beat, and maintain consistent loudness. While random room clatter might share a clap's acoustic shape, it rarely exhibits all three of these traits. If you still experience false triggers (children playing with toys can occasionally mimic clapping sounds), go to the Gestures page and set **Clap detection** to Strict. This forces the algorithm to tighten those checks and demand significantly louder claps. In these environments, prefer 3 or 4 claps over 2.
* On Android 12 and later, the standard system microphone indicator will remain visible while clap detection is active, just as it does for wake word detection.

## Show Fingers

You can trigger up to five distinct actions using a single hand by displaying one to four fingers, or a fully open hand. The device camera watches the scene, locates a hand, tracks it frame by frame, and analyzes its 21 physical joints locally to count the raised fingers. 

A finger is considered "up" when its tip is further from the wrist than its middle knuckle. The thumb is explicitly ignored in this count. Therefore, the available counts are 1, 2, 3, or 4 fingers, and an open hand registers as all four. A thumb resting to the side of two raised fingers will not alter the count. 

This detection runs on the exact same frames that the motion analyzer already samples, and it only activates when something in the frame moves or a hand is actively in view. Crucially, this is detection, not recognition: the system identifies nothing specific about the person, stores absolutely no data, compares nothing against a database, and ensures no frame ever leaves the device.

Camera behavior for Show Fingers:
* This gesture requires the camera to be enabled in the Camera settings. Creating your first hand mapping will prompt for the Camera permission if it is missing. As long as one hand mapping exists, the camera will run whenever the screen is on (whether displaying a screensaver or not). The resource cost is identical to running [Postpone screensaver on motion](camera.md#motion-detection). When the panel turns off, it releases the camera.
* This feature is physically unavailable on x86 devices (such as ChromeOS, FydeOS, and BlissOS containers) because the hand landmarker library only ships for ARM processors. The trigger will simply not be offered on those platforms.
* Just like claps, any hand shown during an active voice interaction will be ignored. The camera's analysis idles from the moment the wake word triggers until Voice Satellite returns to listening mode. If your hand was up when the voice turn started, you must lower it and raise it again afterward to trigger an action.
* The effective range is a few steps away from the device, and your hand must be visible within the frame. A front facing camera mounted at chest height will easily see a hand held at shoulder height, but it will miss a hand held at the waist. The detector focuses on a localized square of the frame wherever movement occurred (where the hand came up). This allows it to accurately read a hand that only occupies a fifteenth of a wide angle shot. It will not work from across the room; use claps for across the room gestures.
* The system can read a hand in any orientation. It uses a landmark model to confirm the shape, ensuring it rejects a wall, a lamp, or a hand shaped shadow. The action fires based strictly on the finger count, meaning a hand resting flat on a keyboard shows zero fingers and triggers nothing. A raised fist is also detected, as the system finds palms in any pose, but holding the pose is what confirms the gesture is deliberate.
* The system analyzes a hand within a quarter second of the picture changing as the hand raises. The very first frame that confidently reads a configured count will fire the action (typically half a second after raising your hand on a slow device). If a hand is busy doing something else (like holding a vape or a cup near the mouth), it might briefly resemble a configured count and fire. The system prioritizes speed over requiring a long, secondary confirming look. 
* Once an action fires, the finger count must physically change (or the hand must drop out of frame) before that specific mapping can fire again. Simply holding the hand up will not repeat the action. However, smoothly switching from two fingers to an open hand will fire both associated actions in sequence. A second hand resting in view will not block detection.
* Lockdown Mode and Kiosk Mode's Disable Gestures toggle will silence the hand gesture exactly as they do touch gestures. When silenced, the camera is not even bound for hand detection.
* As long as a hand mapping exists, the camera's exposure is dynamically steered by the video frames themselves. Because a front camera typically meters for the whole room (which often leaves a person standing in front of it in silhouette), the app will ask the camera to step up the exposure for dark frames and step it down for bright ones, adjusting every couple of seconds. The motion analyzer and any snapshots taken simultaneously will use these same adjusted frames. Hands still require some ambient light to be read, though less than faces. A palm held up near a dim night light will be detected, though it may take a beat longer than in daylight. The gesture will not function in complete darkness.

## Timing

Tap gestures chain together as long as they land within roughly half a second of each other. If you pause too long, or tap outside the designated corner, the sequence restarts. A hold gesture fires while your finger is actively pressed down, triggering exactly at the configured duration. Corner sequences are more forgiving, allowing a slower rhythm of about a second and a half between taps.

## Notes

* Gestures automatically pause dashboard rotation and reset the screensaver's idle timer, functioning exactly like a standard screen touch.
* If you tap an active screensaver, that first tap dismisses the screensaver but still counts toward your gesture. For example, performing a corner double tap on a sleeping screen will both wake the device and fire the mapped action.
* Long holds executed inside the dashboard area can still select text or open context menus, unless you have specifically enabled **Disable context menus** under Kiosk Mode settings.
* The primary exit gesture's fast tap counter remains completely position blind and unchanged. Tapping five or seven times rapidly anywhere on the screen will still open the menu, regardless of any custom gestures configured here. The hold variants of the exit gesture (where the final tap is held down for a second) will not conflict with custom gestures. A custom corner hold strictly requires the corner hitbox, and a custom finger hold requires two or three fingers, whereas the exit hold is a single finger anywhere on the screen following a chain of fast taps.
