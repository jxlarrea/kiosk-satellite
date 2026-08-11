# Changelog

All notable changes to Kiosk Satellite are documented here. Full release notes for each version are available on the [releases page](https://github.com/jxlarrea/kiosk-satellite/releases).

## v2026.8.26 - 2026-08-11

### Fixed
- The **Show the Sendspin player** gesture action actually brings the card back now. It only turned on a setting that is usually already on, while a card flung away (or hidden by the paused-for-a-while timeout) is dismissed by widget state that setting never reaches; the action now clears that dismissal too.

## v2026.8.25 - 2026-08-11

### Added
- A **Turn screen off after** slider in Screensaver, below Brightness level (0 to 60 minutes in 5-minute steps, default never): once the screensaver has run that long, the panel truly powers off instead of glowing all night. It needs the Device admin permission (the only way Android lets an app power a panel off), and the timer fails quietly without it. The screensaver session stays active behind the dark panel, so every dismiss source wakes the display and lands on the dashboard: motion, the wake word, the MQTT Dismiss screensaver button, or an automation. The power button and double-tap-to-wake count as activity like a touch and land on the dashboard too; only the MQTT Screen switch wakes back into the screensaver (an automation turning a photo frame on in the morning gets its photos back), with a fresh countdown. Pairs with camera motion detection surviving screen-off (below) for a display that sleeps when the room empties and comes back the moment someone walks in.
- A detected wake word now always lights a dark panel, before the voice turn's UI appears. This holds from the foreground, behind another app, and whatever turned the screen off.
- A Device admin status row under Turn screen off after, in the device settings and the remote admin alike: when the grant is missing it says so and offers the grant button right there, instead of leaving a timer that silently never fires. Hidden while the permission is held.
- The MQTT **Dismiss screensaver** button (and the `stopScreensaver` command) now wakes the display even when no screensaver is showing, so an automation can use it as a plain "bring the dashboard back".
- Screenshots taken while the screen is truly off (the remote admin overview, the MQTT Screenshot camera) now return a "Screen off" placeholder image instead of a broken or half-drawn capture. A dark panel composites no frames, so there is nothing real to photograph. A capture requested in the instant a dismiss wakes the panel used to race the first redraw and come back broken or all black; it now waits the wake transition out and delivers the dashboard.

### Fixed
- Camera motion detection keeps watching after the screen truly powers off. Newer Android revokes any non-visible app's camera within seconds of the panel going dark, which silently benched the motion sensor, Dismiss on motion and continuous snapshots until the screen came back. With background listening enabled and the camera permission granted, the background service now carries the camera foreground type Android reserves for exactly this, and the OS leaves the feed alone (verified on Android 11 and Android 16 hardware). Vendors that suspend apps entirely once the panel is off remain out of reach, and the Black screensaver stays the route that works everywhere.

## v2026.8.24 - 2026-08-11

### Added
- An **Auto-dismiss after** slider in Camera Streams, Playback (0 to 5 minutes, default off): an opened camera view closes on its own after the chosen time, so a view brought up in passing with a clap or a corner tap does not stream forever. Focusing a camera restarts the countdown, and the camera screensaver is unaffected.
- A **Stop the screensaver** gesture action. Every touch already dismisses the screensaver, but a clap works from across the room with full hands, which is exactly the Clapper's use case.
- The **Show a camera view** gesture action now toggles: performing the same gesture again closes the view it opened, so one clap sequence (or corner tap) is both the open and the close. The explicit close action stays for closing whatever view is up.
- **The Clapper**: clap sequences as a gesture. A new **Claps** trigger on the Gestures page maps 2, 3 or 4 claps to any existing gesture action, so a light scene, a camera view or the screensaver is two claps away from across the room. Detection is plain arithmetic on the microphone stream (no models, no cloud) with thresholds that adapt to the room's noise level, light enough for the weakest supported devices. With Voice Satellite wake word detection running it shares the already-open capture at no extra cost; without Voice Satellite the app opens the microphone itself, so the Clapper works standalone. Claps are ignored during a voice interaction, while the satellite is muted, in Lockdown Mode, and under kiosk mode's Disable Gestures. The Gestures menu entry now reads "Touch and clap gestures", and searching the settings for "clap" finds the page in both UIs.

## v2026.8.23 - 2026-08-11

### Added
- A new [Permissions](docs/permissions.md) doc: every Android grant the app uses, what each one is for, and the adb commands that grant them all at once for provisioning a panel from a computer.
- The Digital clock screensaver has a **Background color** setting (#173). It was the one face with a hardcoded black backdrop; Flip and Roller already followed their card and background colors. A white background with a black clock color gives the inverted face e-ink panels read best. The At a Glance row now wears the clock's color on the Digital face too (it already followed the Flip and Roller digit colors), so the row stays readable instead of staying grey-on-white over a light backdrop.

### Fixed
- The File Manager's shared storage root now works before Android 11 (#175). "All files access" does not exist on those versions, and the app both reported the root as available when the OS would refuse to list it and offered no way to ask for the storage permission that actually gates it there. The root now reports its real state, the grant buttons ask with the normal Android storage dialog, and writing (delete, upload) works on Android 10 and earlier.
- The Permissions Manager (Settings > Device) now lists **All files access**, the settings-screen grant behind the File Manager's shared storage root. It was the one grant the app can use that the group did not show. Like Device admin it is never marked missing, because without it the File Manager still works on the app's own folder; the row appears in both the device settings and the remote admin, and granting opens the Android screen on the device like the rest.
- MSE camera tiles no longer grow a gray Cast button in their corner (seen on the Echo Show 8). Chromium overlays that button on any video playing from a media source once a castable device is visible on the network; a camera tile is not a castable movie, and now says so. WebRTC tiles never had it, which is why the icon only appeared on MSE streams.

## v2026.8.22 - 2026-08-10

### Fixed
- Camera motion detection now survives the screen turning truly off. Android revokes the camera from any app within seconds of the panel powering off (visibility, not process state, is what gates camera access), and until now the revocation was silent: the motion sensor looked alive in Home Assistant but saw nothing until the app was restarted. The camera session now reports the revocation and rebinds the moment the screen comes back on, and the same recovery covers the camera being taken by another app. The docs now also spell out the platform rule: no app can watch the camera while the panel is truly off; the Black screensaver (backlight at zero, everything running) is the screen-off that keeps motion detection alive.
- Updates now install on a pinned kiosk (#170). Lock task pinning blocks Android's install confirmation screen outright, so pressing Install appeared to do nothing; the kiosk now stands down (unpins and drops its shields) right before an install that needs confirming, leaves the confirmation alone instead of reclaiming the foreground over it, and re-arms when the install is declined or fails. A confirmation nobody answers re-arms the protections on its own after ten minutes. A successful install re-arms on the relaunch as always.
- A declined or never-shown install no longer costs a second download: the downloaded APK is kept, recognized by the byte size GitHub reports for the release, and handed straight to the installer on the next attempt (#170).

### Added
- Go2RTC cameras now **fall back to MSE when WebRTC cannot play them** (#160). WebRTC stays first for its near-realtime latency, but a stream that connects and decodes nothing, a WebView with no WebRTC at all (Fire tablets), or repeated failed connections now switch the tile to MSE automatically instead of leaving it blank, with the switch recorded in the App Logs. A new **Prefer MSE over WebRTC** toggle (Camera settings, Playback; off by default) flips the order for devices known to lack WebRTC and doubles as the way to force MSE for testing; WebRTC then becomes the fallback. MSE sessions go through the app, so servers with a login or a self-signed certificate work the same as they do for WebRTC. WHEP and Home Assistant cameras are WebRTC by definition and are unaffected.
- A **Screenshot camera entity and a Take screenshot button** in Home Assistant, over MQTT like the rest of the device entities (#168). Press the button and the entity shows what the device's display is showing at that moment: dashboard, screensaver, kiosk menu, whatever is actually on screen. Made for checking on a panel that is not in the same building without exposing the remote admin beyond Home Assistant. A **Last screenshot** timestamp sensor reports the frame's freshness, the frame is retained on the broker so it survives a Home Assistant restart, and captures are scaled to at most 1080p so a high-resolution panel never parks a multi-megabyte payload on the broker. Works on every device; no camera hardware involved.

## v2026.8.21 - 2026-08-10

### Fixed
- **Keep screen on** now takes effect after a device reboot (#167). When the app starts at boot it comes up before its screen exists, the keep-awake flag cannot be set yet, and until now the failure was only logged, leaving the screen to time out until the setting was toggled by hand. The flag is now reapplied the moment the app reaches the foreground, which also restores it when the screen is rebuilt after a crash recovery.

## v2026.8.20 - 2026-08-10

### Fixed
- Camera motion detection no longer drives the CPU to 100% on some devices whose camera reports the LIMITED hardware level, the Galaxy Tab S6 Lite among them (#164). The QR scanner added to the setup wizard in v2026.8.10 silently pulled the whole app onto a newer camera library whose rewritten backend misbehaves on such hardware; the app is now pinned back to the proven backend the motion feature was built and tuned on, for every camera user in the app including the QR scanner.

### Changed
- The update notice now shows **everything that changed since the version the device is running**, not just the newest release's notes (#165). A device that skipped releases gets each missed release's notes stacked newest first under its own Version heading, in the app's update dialog, the remote admin's and the Home Assistant update entity's summary alike. The check still costs the same single request it always did; a device more than thirty releases behind gets the newest thirty and a pointer to the release history.
- The Sendspin player has been **rebuilt on the Sendspin reference engine**, sendspin-cpp, the same implementation behind ESPHome speakers, with Kiosk Satellite providing the Android audio output around it. The change matters most on devices whose audio hardware misreports its own playback clock (the Meta Portal of issue #163): the old player measured sync against that clock and restarted the stream when the numbers looked wrong, which on such hardware looped forever, while the new engine paces itself by playback feedback that a broken clock can only slow down, never poison, and corrects drift with single-frame adjustments that cannot be heard. In a grouped four-device test spanning three hardware generations, the new engine played ten minutes with pause, resume and stream restarts without a single audible correction, where the old player logged hundreds of buffer underruns and an audible re-anchor on one device. Everything around the player is unchanged: same server and codec settings, floating player, lyrics, ducking, volume and MQTT surfaces. The device's write-to-speaker latency is now measured from the platform rather than assumed, so speakers of different hardware generations land on the same beat without hand tuning; the Sync offset setting remains for trimming Bluetooth outputs.

## v2026.8.19 - 2026-08-10

### Added
- A **Microphone channel** setting under Microphone settings, shown only when the selected microphone reports more than one channel. Multichannel USB arrays often reserve a channel for recognition engines: on the reSpeaker XVF3800, channel 1 carries the call-tuned output (noise suppression, automatic gain control) while channel 2 carries the same voice with lighter processing, the one its maker recommends for wake word and speech recognition. Android's mono capture averages every channel together, mixing the processed channel into the clean one; picking a channel feeds it alone to wake word detection, the stop word and speech to text. Downmix stays the default, the remote admin carries the row in the same place, and a channel the microphone cannot deliver falls back to the downmix rather than going silent. For the XVF3800 the recommended setup is Channel 2 with Capture mode on Raw microphone (the array already does its own echo cancellation and noise handling on-silicon) and the gain re-tuned in the Wake Word Tester, with around -10 dB as a starting point.

## v2026.8.18 - 2026-08-09

### Added
- A **Network connection lost** notice at the bottom of the screen while the device has no network, and a brief **Network connection restored** one when it comes back. Until now an outage was completely silent: the dashboard sat there showing the last state it had rendered, and the first sign of trouble was a page that would not reload, hours later. The notice stays for as long as the outage does, takes no touch away from the dashboard underneath, and gives way to the screensaver, the camera view and anything else that owns the whole screen.
- A **No network connection** page in place of the browser engine's own error page, which is a dark screen with a fallen Android robot and a `net::` error string on it, and reads on a wall panel as a broken app. The Kiosk Satellite notice says whether the device has no network at all or the dashboard could not be reached, and offers a Retry button. It covers a failed load only: a dashboard that is merely stale keeps showing, since a page nobody can update is still worth reading.

### Changed
- Pages opened over the dashboard (a tapped link, the Music Assistant shortcut, a gesture's page) and the camera view now rise from the bottom edge and leave the same way, so what opens reads as something brought up over the dashboard rather than the dashboard being replaced between two frames. The camera grid keeps playing as it leaves, and its streams are shut down as before once it is off screen. Two are deliberately left as they were: the view rotation and the screensaver's camera grid change on a timer, and animating those would make the panel appear to move by itself.
- The kiosk menu's Music Assistant entry now wears the Music Assistant mark, the same one the settings page uses, instead of a generic music glyph.
- The dashboard now comes straight back when the network does, including from a failed load. A page that failed while the network was down could only be recovered by the blind retry timer, since there is no page there to diagnose; it is now re-requested as soon as the interface is up.
- Retries of a failed page load now back off (5 seconds, then 10, 20, 40 and 60), instead of hammering the same failing address every 5 seconds for as long as the outage lasts. Nothing waits on the ladder when the network returns, and it starts over at 5 seconds after the next successful load.
- A server error on the main page (the secure context proxy's 502 while Home Assistant is unreachable, a reverse proxy's 502 or 504) now shows the same notice instead of the empty page those answers render as.

## v2026.8.17 - 2026-08-09

### Changed
- Installing an update now asks GitHub for the latest release first, so what installs is the newest version at the moment Install is pressed rather than the one the notice named when it appeared (#162). The release check runs twice a day and the notice then sits there until someone acts on it, so a version published in between used to install the older build and leave a second update waiting right behind it. This applies wherever the update starts: the kiosk menu, the Remote Administration UI and Home Assistant's Updates page. If GitHub cannot be reached at that moment the known release installs exactly as before, and in the rare case where the offered release is gone and the device is already on the latest, nothing downloads and the notice clears itself.

## v2026.8.16 - 2026-08-09

### Changed
- The Sendspin Player settings page is now **Music Assistant**, wearing the server's own mark, and it opens on the Music Assistant group: the address, the token, the kiosk menu shortcut and lyrics. The player's own settings follow under a **Sendspin player** heading, unchanged. Home Assistant Configuration wears the Home Assistant mark for the same reason, since a page named after a product is easier to find by its logo than by a generic glyph.

### Fixed
- A page someone opened over the dashboard and walked away from now gives way to the screensaver, the way an abandoned app launcher already did, so what comes back when the screensaver lifts is the dashboard rather than a half-browsed Music Assistant page from hours ago. It also stops that page rendering behind the screensaver, which the dashboard's own pause could never do for it. Touching the page still counts as activity, so the screensaver never interrupts someone using it, and a view rotation's external page is left alone since the rotation moves it along itself.

## v2026.8.15 - 2026-08-09

### Added
- A **Music Assistant** entry in the kiosk menu, which opens the Music Assistant web interface over the dashboard: the full library, search, queue, playlists and radio, exactly as they are on a phone or a laptop. Closing it (or pressing back) reveals the dashboard still loaded underneath, with the voice session and the wake word untouched, because the page never left. It appears as soon as a server address is set under Sendspin, Music Assistant, and a new **Show in the kiosk menu** toggle there turns it off. In kiosk mode it is one of the Allowed Actions, so it can be offered in, or kept out of, the restricted quick-actions menu.
- A **Close after inactivity** slider under the shortcut, 0 to 60 seconds and off by default: with no touch anywhere on the Music Assistant page for that long, it closes itself and the dashboard comes back. Made for the wall tablet whose visitor queues a song and walks away. Scrolling and tapping count as activity, so reading a long album page keeps it up, and the close button, the back button and a wake word still work as before.
- The Music Assistant web interface opens already signed in, using the long-lived token configured for lyrics, so the shortcut is not a second login to get past every time. The token decides what the tablet can do there, so a read-only one browses but cannot queue. Signing in by hand still works and is left alone, and the token is only ever handed to pages on the configured server. Home Assistant's own login cannot stand in for it: Home Assistant mints a separate token per application and asks for the password each time one is granted, dashboard session or not.

### Changed
- A page shown over the dashboard (the Music Assistant shortcut, a tapped dashboard link, a view rotation's external page) now pauses the dashboard's rendering underneath it, the way the camera view, DLNA media and the settings screen already do, so the whole frame budget goes to the page on top instead of to a dashboard nobody can see. The dashboard keeps its Home Assistant connection, its timers and its scripts throughout, and is drawing again in the same frame the page is dismissed. A page on Home Assistant's own address is left out of this, since the two cannot be told apart underneath.

### Fixed
- Flipping a switch in the Remote Administration UI that reveals or hides other settings no longer rebuilds the whole page under it. The revealed rows now appear and disappear on their own, exactly where they belong, with nothing else on the page touched and no round trip to the device: until now every such switch re-read the entire configuration and redrew every tab, which re-ran the connection, permission and audio probes those tabs own and made the page jump. Switches that swap whole sections at once, such as the screensaver mode, still redraw as before, and so does anything that changes what the device reports back.
- Pages shown over the dashboard (a tapped dashboard link, a view rotation's external page, a gesture's page) no longer fail to load from a server with a self-signed certificate while the dashboard itself loads fine. They now follow the same **Ignore SSL errors** setting the dashboard does.

## v2026.8.14 - 2026-08-08

### Added
- An Allow H.265 streams toggle in the Camera Streams settings' new Playback group, on the device and in the Remote Administration UI alike, off by default. Leave it off and cameras are requested as H.264 (or VP8, VP9, AV1), which is what Android devices actually decode; turn it on for a device that genuinely plays H.265 and the stream is taken as it comes. A device that cannot decode H.265 shows a blank image instead, so the toggle is worth trying one camera at a time.
- A decode watchdog behind every camera tile: a stream that connects and receives video without ever decoding a frame now says so on the tile and writes a warning to the App Logs naming the codec, the packet count and the camera, instead of sitting black with nothing recorded anywhere. A stream that plays normally logs its codec and resolution once, so an issue report carries what the device actually negotiated.

### Changed
- Kiosk Satellite now identifies itself on the network as `KioskSatellite/<version> (Android <version>; +<project URL>)` instead of `Dart/3.9 (dart:io)`, on every request and websocket it opens: Home Assistant, Go2RTC and WHEP camera signaling, Music Assistant, Immich, DLNA, model and update downloads, and the native audio and Sendspin stacks alike. A Go2RTC or reverse proxy access log now names the app, its version and the Android release behind a request, which is what makes a stream problem traceable to a device. No device model is included, since the string reaches servers the user does not own. The browser keeps its normal browser user agent, since pages are browsed as a browser.
- A camera tile that fails to start now says which side failed instead of always reading Connection failed, which implied a network problem even when the camera server had answered: Stream not found on the camera server, The camera server rejected the login, The camera server could not start this stream, or Cannot reach the camera server, each still followed by the retry countdown. Connection failed is now reserved for a stream that negotiated and then dropped.

### Fixed
- Cameras that stream H.265 no longer show as a permanently blank tile (#160). Android WebViews advertise H.265 support in the stream request whether or not anything on the device can decode it, so the server hands over H.265, the connection succeeds, video data arrives, and not one frame is ever decoded. Kiosk Satellite now leaves H.265 out of the request unless the new toggle turns it back on, which lets a Go2RTC server with ffmpeg transcode the camera to H.264 by itself, and makes a server that cannot transcode answer with a real error rather than silence.

## v2026.8.13 - 2026-08-08

### Added
- A Permissions Manager group in the Device settings, on the device and in the Remote Administration UI alike (#156), listing every Android grant the app can use in one place, with an explanation as its first row: microphone, unrestricted battery, camera, notifications, display over other apps, modify system settings, system UI guard, device admin and location. Each row says what the grant is for and carries a button that starts it, and reads Granted, Missing when something currently switched on needs it, or Not granted when nothing needs it yet and it can still be given ahead of time. Until now permissions only appeared inside the feature groups that use them, so a grant no enabled feature happened to ask for could not be found at all: the battery exemption, which is what keeps the Home Assistant connection and the MQTT entities alive while the screen is off, was only listed under background wake word listening.

### Changed
- Setup now asks for the unrestricted battery permission on every device, instead of only when Voice Satellite background listening was turned on. It is what keeps the Home Assistant connection and the MQTT entities alive while the screen is off, so a kiosk without voice needed it just as much and was never asked. This covers the setup wizard on the device, the same wizard in the Remote Administration UI, and a device provisioned by importing a configuration.
- Permission rows describe what the grant allows rather than what it does for one feature, everywhere they appear: the microphone, unrestricted battery, display over other apps and device admin rows read the same in the Voice Satellite, Kiosk Mode and Lockdown Mode groups as in the new Permissions Manager group.
- The Remote Administration UI's Device tab no longer repeats itself: the read-only Permissions and Remote administration summaries at the bottom are gone, since the settings above list the same grants with a button to give them, and the same port and admin address.

## v2026.8.12 - 2026-08-08

### Added
- A Startup delay slider in the Camera settings' Motion Detection group (discussion #159), 0 to 15 seconds and 0 by default: motion is ignored for that long after the camera stream starts. Made for devices whose camera physically moves as it opens, such as a phone with a pop-up module, where the lens sweeping through the scene on its motor reads as motion and dismisses the screensaver that just started the camera. The delay counts from the first frame and covers every path that starts the camera, not just a screensaver, and the frames are still tracked as the baseline so the movement never desensitizes detection afterwards.

## v2026.8.11 - 2026-08-08

### Added
- Page indicator dots for the dashboard carousel: while swiping between views, a small pill at the bottom center shows the dashboard's views and where in the cycle you are, with the target dot lighting up as the swap starts and the whole indicator fading away once the gesture settles. It ignores touches and respects display cutouts.

### Fixed
- With the dashboard carousel enabled, scrolling a tall view vertically no longer flashes a horizontal scrollbar: the parked view previews kept a phantom horizontal scroll range alive, and Android wakes both bars on any scroll whenever a range exists. Previews now park where no range can form.
- Swiping to the previous view no longer nudges the whole page (and the page indicator with it) a few pixels along with the finger: Android's overscroll stretch effect counted the drag as edge overscroll and distorted the entire browser surface. The stretch is suspended for exactly the duration of a carousel drag and restored afterwards, so overscroll behavior everywhere else is unchanged.

## v2026.8.10 - 2026-08-08

### Added
- A dashboard carousel, off by default, under the Home Assistant settings' new User Interface group (which also gathers the HA kiosk mode rows): with it on, swiping left or right on the dashboard moves to the neighboring view of the current dashboard, wrapping at the ends. The view follows the finger while dragging, and once a view has been visited it appears live beside the current one during the drag, sliding in with the finger like a real carousel; letting go far enough (or flicking) carries the swap through seamlessly, while a hesitant drag springs back into place. Views not yet visited slide in right after the release instead. Made for small screens where the header tabs waste precious space: hide the header with HA kiosk mode and navigate by swipe instead. Swipes on sliders, maps, dialogs and horizontally scrolling cards are left to those elements, subviews and hidden views are skipped, and the toggle applies live without a reload.
- A Disable scrolling toggle in the Web Browsing settings: locks the page in place so it cannot be scrolled in either direction, for dashboards built to fit the screen where a stray drag should not move anything. Only the browser's own panning is taken away, so taps, pull to refresh, pinch to zoom and the app's gestures all keep working, and the toggle applies live without a reload.

### Changed
- The Web Browsing page's User Interface group is gone: Zoom level moved up into the page's main group, and Display cutout moved to the Screen & Audio page under Screen, where a choice about the device's window belongs. Stored values carry over unchanged.
- Setting titles in the Home Assistant Configuration pages now use consistent sentence casing: Sync Home Assistant themes with Kiosk Satellite, Return to home dashboard view, Home Assistant base URL, and Enable dashboard view rotation.
- Scrollbars stay hidden while a carousel swipe or its animation is in progress, and reappear for normal scrolling exactly as before.

### Fixed
- The Remote Administration UI's About page no longer takes seconds to appear on its first open after a page load. The update-status read was fetching the full device info, including a CPU load measurement that pays for a fresh half-second sample whenever it runs twice in quick succession, exactly what opening the page caused; it now reads the one value it needs directly, and the page fetches its two reads in parallel.

## v2026.8.9 - 2026-08-07

### Changed
- The Clear cache and Restart app buttons in Home Assistant moved from the device's Configuration area to Controls, where day-to-day actions belong. Existing devices migrate on their own, keeping entity ids and customizations.

### Added
- Camera enabled and Screensaver motion detection switches over MQTT (discussion #155), on devices with a usable camera: the camera master toggle and the screensaver's Dismiss on motion, controllable from Home Assistant. Made for staged wake-ups where camera use should not run around the clock: a room-wide motion sensor turns the camera on when someone is nearby, the camera's approach detection then wakes the screen for whoever walks up, and the automation turns the camera, and its roughly 10% CPU cost, back off when the room empties. Turning the camera off retracts its entities as always; the switches themselves stay.

## v2026.8.8 - 2026-08-07

### Added
- A Keep audio in the background toggle for the DLNA renderer (discussion #153), off by default: with it on, audio pushed to the renderer, such as TTS announcements or music, plays without taking over the screen, so the dashboard or a running screensaver stays exactly as it was. Images, video and camera streams still show as before, and playback control from Home Assistant keeps working while the audio stays invisible.
- A Screensaver active switch over MQTT, carrying what the old Screensaver switch did: it is on while a screensaver is on screen, turning it on starts the screensaver right away, and turning it off dismisses it until the idle timeout runs out again.

### Changed
- Scrolling content now fades out gracefully at the edges instead of being cut off: the settings lists, search results, log boxes and scrolling dialog bodies on the device, and the settings pages, modals, nav rail and consoles in the Remote Administration UI, all show a soft gradient at an edge that still hides content, sliding away once the list reaches its end.

### Fixed
- The Screensaver switch in Home Assistant now controls the master screensaver enable/disable, the same toggle the Screensaver settings page has, instead of only dismissing the screensaver for one timeout period (#152): turning it off keeps the screensaver away until the switch is turned back on, so automations no longer need a loop pressing Postpone screensaver to keep the screen alive. The switch moved to the device's Configuration area in Home Assistant accordingly, and turning it off while a screensaver is showing dismisses it immediately, from Home Assistant and the Remote Administration UI alike.
- The Remote Administration UI's File Manager no longer breaks on narrow viewports (phones): the Location tabs and the Upload file button no longer overlap, the tabs sit on their own toolbar without a card or label, and the per-file Download and Delete buttons became compact icon buttons that share a row with the file name. File and folder rows now use the same list style as the Gestures and Camera pages.
- The note under the gesture list in the Remote Administration UI now renders in the same quiet style as the other card notes, instead of full-size text.

## v2026.8.7 - 2026-08-07

### Added
- The Clock screensaver's background photo can be set from Home Assistant (#150): a new Clock background text entity over MQTT holds the image's file path on the device, so automations can rotate the picture behind the clock, push an alert image, or clear it back to the solid color with an empty value. Writing a path overwrites the photo picked on the device, a path that does not exist yet simply shows no background until the file appears, and changes apply live while the clock is on screen. The Remote Administration UI's Background photo row edits the same path as a text field now, where it used to just say a photo was selected on the device. Getting the images onto the device is out of scope; the remote admin's File Manager can upload them.
- A Hide all extras toggle for the Black screensaver (#151): with it on, Black shows nothing at all, hiding the small clock, the At a Glance entities and any other overlay, so a kiosk that schedules Black overnight looks fully off without unconfiguring those extras for the night. The toggle appears in a Black group under the screensaver mode picker whenever the mode is Black, on the device and in the Remote Administration UI alike, and it is off by default.

### Changed
- The Clock screensaver's background photo now fills the screen the way the photo screensavers do: a photo shaped close enough to the panel covers it edge to edge, and one that keeps its full frame sits over itself blurred and dimmed instead of being cropped, so a portrait photo behind a landscape clock no longer loses its top and bottom. A background changed while the clock is on screen also applies immediately now, instead of waiting for the next minute tick.

## v2026.8.6 - 2026-08-07

### Fixed
- A black screen at startup on some devices, stuck in a restart loop every 30 seconds (#145): on slower hardware the dashboard's browser view could be created a moment before the app's screen was ready to host it, the creation failed silently and was never retried, and the built-in recovery restarted the app into the same failure. The browser view now waits for the screen to be ready before it is created, and the recovery watchdog additionally rebuilds the view in place, well before resorting to an app restart.

### Added
- Settings search, in the on-device settings and the Remote Administration UI alike: a search field sits under the Settings title (under the Kiosk Satellite logo in the remote UI), typing swaps the content for results grouped by page with the match highlighted, and tapping a result opens its page, scrolls to the setting and blinks it. Results cover every setting, the pages themselves and the hand-built rows such as Validate connection or the permissions groups; a setting currently hidden behind a switch that is off still appears, and tapping it lands on the switch that turns it on.

## v2026.8.5 - 2026-08-07

### Added
- Lockdown Mode (#143): one switch that disables screen interactions until turned off either from Home Assistant or with the exit gesture. The dashboard stays visible and live but nothing on it can be tapped, and touching the locked screen shows a brief "Screen is locked" notice. Its setup lives only in the Remote Administration UI, with no page in the on-device settings, and the mode can also be toggled from Home Assistant through the Lockdown mode switch every device gets over MQTT. It arms every Kiosk Mode protection at runtime without changing the stored kiosk settings and mutes wake word detection while it holds; the shield covers the entire display at the system level, not just the app window, so it stays up no matter what comes forward. It has its own exit gesture (fast taps anywhere, behind the kiosk PIN when one is set), an optional Blackout that paints the locked screen solid black and pauses the dashboard's rendering underneath to save power, and an optional Allow screensaver that lets the screensaver keep running while locked, with Dismiss on motion staying deactivated until the lock lifts.
- System UI guard: an optional accessibility service that closes the notification shade the moment it opens and bounces the recents screen right back, while Lockdown Mode holds or the matching Kiosk Mode protections are on. Android only allows enabling it at the device, under Accessibility settings; the new permissions rows say when it is missing.
- The Kiosk Mode and Lockdown Mode settings now end with a Required system permissions group like Voice Satellite's, showing the Display over other apps grant and the System UI guard, each with a button that starts the grant on the device, including from the remote admin.

### Changed
- Kiosk Mode's protections no longer hinge on Android's "App is pinned" consent dialog. Under Lockdown Mode the dialog never appears at all, and with Disable home button on, if pinning was declined or ever lost, the app now pulls itself back to the front about a second after losing the foreground. Closing the app from the recents screen relaunches it immediately, and apps opened through the App Launcher are still left alone.

## v2026.8.4 - 2026-08-06

### Added
- Camera views are fully controllable over MQTT: a new Camera view select entity in Home Assistant lists every configured view, picking one shows it on the device and picking Closed dismisses it, and the entity always reflects what is on screen no matter how the view was opened or closed. The per-view Show buttons remain for automations that just press. The idle option is named Closed rather than None because Home Assistant reserves the None payload on MQTT entities and would blank the select.

### Changed
- Camera views grew from four cameras to twelve (#140), laid out exactly like UniFi Protect lays out each grid size: mixes of large and small tiles such as four large beside a column of four small for eight, or two large over eight small for ten. The view editor on the device and in the remote admin gained a UniFi-style Grid dropdown with layout icons, preselected from the camera count and adjustable upward, with a numbered miniature of the chosen layout below it. Cameras always fill the largest tiles first, slots without a camera stay empty on screen, and portrait devices render the same layouts turned sideways.
- Scrolling in the on-device settings is much smoother: the dashboard keeps rendering behind the settings screen even though it is fully covered, and on a busy dashboard that background work caused visible stutters. The dashboard's rendering now pauses while settings are open, the same optimization the screensaver uses, and resumes the instant settings begin to close. The Home Assistant connection stays live throughout.
- The same rendering pause now applies under every surface that fully covers the dashboard: streaming camera views, where it matters most since the dashboard no longer competes with the video decoders, and media pushed over DLNA. The dashboard is drawing again the moment the covering surface closes.
- The settings categories are reordered into clearer groups in both the on-device settings and the remote admin: connection first, then the screen, browsing and screensaver, then the camera and media features, then kiosk behavior, with device, about and logs at the end.

### Fixed
- The Disable status bar shield no longer swallows taps on the top edge of the dashboard (#142). Home Assistant's view-tab bar sits exactly where the shield used to cover, making the page switcher dead while the protection was on; the shield now covers only the thin strip at the very display edge where the status bar pull-down actually has to begin, so the pull-down stays blocked and everything on the page is tappable. On some devices a determined user can still surface the shade with two precise swipes by dragging the transient bar the system itself reveals; that was equally possible with the old full-height shield, and the hard guarantee remains Disable home button, whose screen pinning makes Android disable the shade entirely.
- Devices that cannot read any thermal sensor no longer show a permanently unknown CPU temperature entity (#138). Some vendors' security policies deny apps the thermal sensors entirely (seen on a Lenovo TB336FU, where Android logs an SELinux denial for the read); the entity now only exists when a temperature can actually be read, it comes back on its own if a reading appears later, and the app stops retrying the blocked read, which was flooding logcat with denial lines on every stats poll.

## v2026.8.3 - 2026-08-06

### Added
- Motion is now available as its own Home Assistant sensor over MQTT: a new Motion Detection group in the Camera settings has a Motion sensor switch and a Clear after delay, and the resulting binary sensor turns on with movement and clears itself after the configured quiet time. Unlike the screensaver's motion features, the camera keeps watching even while the screen is off, so an automation can turn the panel on when someone walks into the room. The usual camera cost warning applies: the camera runs permanently while the sensor is on.

### Changed
- Motion detection's tuning lives with the camera now: Motion frame rate and Motion sensitivity moved from the Screensaver section into the Camera settings' Motion Detection group, since they tune every motion feature, not just the screensaver's. Dismiss on motion and Postpone stay in the Screensaver section, with a hint pointing at the new home; the remote admin mirrors the move, and its Latest snapshot preview moved to its own group at the end of the Camera page so the Motion Detection settings are not buried under the image.
- Motion-triggered camera snapshots publish once per motion arrival instead of every ten seconds for as long as movement continues: someone staying in front of the device updates the retained MQTT snapshot once, and the next update comes after the sensor has cleared and motion returns.

### Fixed
- Restoring a backup as a new device no longer copies the Sendspin player identity (#136). Both devices ended up connecting to Music Assistant as one player and kicked each other off in an endless connect/disconnect loop, with neither ever syncing; a new-device restore now keeps the restoring device's own identity, while a replacement-device restore still adopts the backup's so Music Assistant sees the same player it always had.
- Camera motion detection no longer mistakes the device's own light for movement. The screensaver going dark could reflect off the room, read as motion and dismiss the screensaver the instant it started, an infinite loop on dark clock faces, and slideshow photo swaps could do the same mid-session. Detection now discounts uniform lighting shifts, including the camera auto-exposure resettle that follows them, and additionally stands down for a couple of seconds around the app's own screen transitions: screensaver start and stop, screen power, brightness changes and slide changes.
- The Filter dashboard updates optimization now catches entities referenced inside card templates (#139), such as a custom button-card's name, label and style templates: any entity id written in a template is included in the filter's allowlist, so those cards keep updating. Only entity ids computed dynamically inside a template remain invisible to it.
- CPU temperature now reports on devices whose thermal sensors do not name the CPU (#138), by also accepting the SoC sensor spellings MediaTek, Exynos and Qualcomm devices use. When no readable sensor exists at all, the app logs which sensors the device exposes, so a bug report's app logs carry the answer.

## v2026.8.2 - 2026-08-05

### Added
- The setup wizard can scan the QR code Home Assistant shows next to a newly created long-lived access token, so the token never has to be typed on the device. A scan button appears in the token field on devices with a camera; the remote admin's wizard keeps paste, where a clipboard exists.
- At a Glance entities can display an attribute instead of the state (#132): each chosen entity in the picker has a gear button that lists the entity's attributes with their current readings, on the device and in the remote admin, so a weather entity can show its actual temperature rather than "Sunny".
- The Clock screensaver can have a background photo (#132): a new Background photo setting in the Clock section picks one from the device's local media, and the clock draws over it with a subtle dark scrim so the time and the At a Glance row stay readable on any photo and any clock face.

### Changed
- Dropdowns are real controls now: every dropdown in the app sits on the same bordered box the remote admin's selects use, instead of rendering as bare text that read like another row title.

### Fixed
- Settings, the Automations editor, the Voice Satellite panel and other non-dashboard pages no longer show stale states while the "Filter dashboard updates" optimization is on (#131). The filter now recognizes non-dashboard panels directly, and whenever it stands down it replays every entity's current state from the shadow copy it already keeps, so pages arrive seeing the truth instead of whatever they had when filtering started; previously only a full app restart caught them up. Update entities are also always forwarded now, so the sidebar's update badges stay current even while a dashboard view is filtered.
- Settings rows with dropdowns no longer squeeze their text into a sliver on portrait phones: on narrow screens the row stacks as title, dropdown, description, with the dropdown across the full row width, while wide screens keep the dropdown in its usual trailing spot.
- On narrow screens, long page titles such as Home Assistant Configuration no longer get cut off at the screen edge, and the Made with footer line stays centered instead of clipping on the right.

## v2026.8.1 - 2026-08-05

### Changed
- Kiosk Satellite leaves beta. Versions now follow the same scheme as Home Assistant and Voice Satellite, year.month.release, so this release is 2026.8.1 and the -beta suffix is gone. Updating works exactly as before.
- The whole app now draws from one design system: a single spacing and corner-radius scale, one card and section-heading treatment on every settings page (Camera Streams, Gestures and the setup wizard included), and Rubik, the typeface the screensaver clocks already use, on page, dialog and drawer titles in both the device UI and the remote admin.
- Buttons are consistent everywhere: compact pills at one height and minimum width in both UIs, so Save and Cancel render as a matched pair, and secondary actions share one outlined style (the remote admin's Validate, Import, Export and Grant buttons no longer differ from Change view).
- Dialogs share one anatomy in both UIs: the title and the action row stay on screen and only the body scrolls, pickers use real radio rows with clearance next to the scrollbar, confirm buttons are short verbs, and stacked input fields in the camera editors got their missing spacing.
- Tab-like controls in the remote admin (the Logs source and the File Manager location) are now real segmented tabs, echoing the app's segmented buttons instead of looking like action buttons.
- Long setting descriptions were rewritten to one or two short sentences, so rows no longer wrap into walls of text on small screens; both UIs pick the new texts up.
- The drawer is tidier: Web Console left the menu (the console lives in Settings > Logs), Toggle HA Kiosk Mode is now HA Kiosk Mode, and Default Camera View is now Camera View, matching its renamed Allowed Actions switch.
- The remote admin's Dashboard tab is now Overview, its narrow-screen top bar shows the app icon and a proper menu button, and log severity colors are legible in the light theme.

### Fixed
- Loading the remote admin no longer logs two failed haListDashboardViews requests: dashboards without a stored view config (auto-generated and strategy dashboards) now report no views instead of an error, and every picker keeps falling back to the dashboard's default view.

## v0.35.1-beta - 2026-08-05

### Added
- Fill the screen for the Local Media and Photo Gallery screensavers (#130): the same treatment the Immich screensaver already had. Photos shaped close enough to the screen are enlarged to cover it fully, and photos that keep their full frame, such as portrait shots on a landscape display, now show over a blurred, dimmed backdrop of the photo itself instead of black bars. On by default, with a Fill the screen switch in each mode's settings on the device and in the remote admin for anyone who prefers the plain letterboxed look.

### Changed
- The Web Browsing menu subtitle no longer mentions Start URL, which is not an option on that page (the dashboard is picked under Home Assistant Configuration); it now reads "Cache, SSL, Zoom level" on the device and in the remote admin.

## v0.35.0-beta - 2026-08-04

### Added
- Postpone screensaver button entity over MQTT (#129): pressing it resets the screensaver's idle timer as if someone had touched the screen, dismissing the screensaver first when one is showing. Any Home Assistant automation can now keep the display awake from an external sensor, such as a door contact or a motion sensor elsewhere in the room, complementing the device-camera-based Postpone on motion. The same action is available to the remote REST API as the postponeScreensaver command.

### Changed
- The settings menu is shorter: Screen and Audio are now one Screen & Audio page, which also picked up the microphone and speaker selection and the Microphone settings group from Voice Satellite, and Remote Administration now lives on the Device page. Every setting kept its stored key, so nothing resets, and the remote admin mirrors the new layout; old remote admin bookmarks to the Screen, Audio or Remote Administration tabs land on the right page.
- The app log and the web console now share one Logs page in both UIs (on the device it opens the docked console over the live page), WebRTC Cameras is now called Camera Streams (it has streamed Home Assistant cameras without Go2RTC since the import arrived), and the menu subtitles now match between the device and the remote admin.

## v0.34.0-beta - 2026-08-04

### Fixed
- Devices whose GPU drivers crash under Flutter's Impeller renderer no longer crash at every launch (#127, seen on a Galaxy Tab Pro 8.4 whose 2016 Adreno driver dies the moment Impeller draws). The renderer is now chosen per device when the engine starts: a new Legacy renderer switch in the Device settings forces the older Skia renderer, and the app also protects itself, so that two consecutive launches that die before showing a frame flip the switch automatically. Together with the crash self-heal an affected device converges to a working renderer on its own, and modern hardware keeps Impeller.

### Added
- Import WebRTC cameras from Home Assistant (#124): a new Home Assistant group at the top of the WebRTC Cameras settings imports every camera entity the connected Home Assistant can stream over WebRTC (Home Assistant 2024.11 or newer), no Go2RTC URL or WHEP setup involved. Imported cameras stream through Home Assistant's own WebRTC signaling on the existing connection, including its ICE server configuration, so cloud setups work too. Re-importing merges new entities and marks removed ones as missing, exactly like the Go2RTC import, and a Home Assistant camera entity can also be added manually in the camera editor.
- Postpone screensaver on motion, a new opt-in switch in the screensaver's Motion Detection section (discussion #126): the camera also watches between screensavers, and movement nearby keeps resetting the idle timeout, so the screensaver stays away while people are actually around. An extension of Dismiss on motion, so it appears and acts only with that switch on. Off by default because this direction is the expensive one: the camera runs permanently while the screen is in use, which adds CPU load and heat. The camera still stands down whenever the screen is off.

## v0.33.4-beta - 2026-08-04

### Fixed
- The microphone level meter no longer disables wake word detection. The meter rides the wake word tester's telemetry feed, and telemetry mode suppressed real detections by design (a tester hit must not start a voice interaction), so simply having the Voice Satellite settings open with the meter visible, on the device or in the remote admin, made the device deaf, and a remote admin tab left open on that page kept it deaf indefinitely. Telemetry now distinguishes a tester from a meter: the meter only reads levels and detections keep firing while it is on screen.

## v0.33.3-beta - 2026-08-03

### Added
- Start the screensaver is a new gesture action, next to the other Kiosk Satellite actions in the gesture editor on the device and in the remote admin. Start only: any tap already dismisses a running screensaver, so a stop action would duplicate what every touch does.

### Fixed
- Momentary Wi-Fi drops no longer leave parts of the app dead until a restart. The app now watches Android's network state and repairs everything the moment connectivity returns: the dashboard reconnects a dead or half-open Home Assistant websocket, retries Home Assistant's "Unable to connect" screen immediately instead of waiting out its growing countdown, and re-navigates an error page back to the dashboard. MQTT recovers even when the app started before the network was up (previously a device that booted ahead of the router lost its Home Assistant entities until an app restart) and a stuck broker connection is now detected within a minute through ping timeouts. Sendspin, the At a Glance entity feed and the secure context proxy reconnect immediately as well.
- Server errors on the dashboard recover like network errors always did: a 502 or 504 from a reverse proxy (or the secure context proxy) during an outage used to sit on screen until an app restart, because auto reload only watched network-level failures. The page now retries every few seconds until Home Assistant answers again.
- The Website screensaver and rotation overlay pages retry failed loads instead of showing an error page for the rest of the session, and a crashed page renderer in the screensaver or camera view rebuilds its own WebView instead of Android killing the whole app, which matters most on low-RAM devices.
- Camera streams routed through the secure context proxy fail fast and reconnect when Home Assistant becomes unreachable mid stream, instead of hanging on a frozen frame.

### Changed
- Retained MQTT payloads on command topics are now ignored when the broker replays them at reconnect, so a stale retained press (a reload, a restart, a volume set) no longer refires on every network hiccup. If you deliberately published retained commands for offline devices to pick up on return, publish them unretained instead, as Home Assistant itself does.

## v0.33.2-beta - 2026-08-03

### Added
- Two new Kiosk exit gesture options, 5 fast taps holding the last and 7 fast taps holding the last (#120). With one of these selected the menu only opens when the final tap is held down for a second, so rapidly tapping a dashboard button, like a TV remote's volume control, can no longer trigger the exit gesture. The hold shape does not collide with anything on the Gestures screen: a corner hold needs a corner and a finger hold needs two or three fingers, while the exit hold is one finger anywhere after the tap chain. Existing installs keep their current setting.

## v0.33.1-beta - 2026-08-03

### Added
- The Microphone gain slider now goes down to -24 dB to attenuate overly sensitive microphones, like the Meta Portal's. Negative gain quiets the capture before the wake word engine or Home Assistant hears it. Note that attenuation happens after capture, so a microphone that clips at the hardware stage stays distorted; it helps the common case of a mic that is loud but clean.

### Fixed
- Dismiss on motion now works in the dark. The detector compared frames against one fixed change threshold that dim scenes never reached, so the screensaver only woke in a lit room. Each analysis cell now learns its own sensor noise and flags change just above it, and the camera is asked for the longest exposures it offers, gathering several times more light per frame at no extra CPU cost. Because a detector this sensitive would otherwise wake on light alone, a change that pushes the scene in one direction, like a TV or monitor lighting the room differently, a lamp toggling, or the camera's exposure settling, is recognized as illumination and ignored; a moving person brightens some cells while darkening others and still triggers.

## v0.33.0-beta - 2026-08-03

### Added
- App Launcher (#114): a minimal app selector for kiosks that double as media players or alarm clocks. A new App Launcher settings page holds the enable toggle (off by default), the app whitelist picked from the device's installed apps (from the device settings or the remote admin), a grid or list layout choice and an icons toggle. The launcher opens from the kiosk menu, the quick actions panel (with its own Allowed Actions entry), a new Open app launcher MQTT button, and the showAppLauncher remote command. An optional Return automatically setting brings the kiosk back to the front after a configurable time in the other app; the existing Bring to front MQTT button works too. While the launcher is disabled it is gone everywhere: no menu entry, the commands refuse, and the MQTT button is retracted from Home Assistant.

### Fixed
- The small screensaver clock has its own 24-hour toggle (#116). Its format silently followed the Clock mode's 24-hour switch, which is only visible while the screensaver mode is Clock, so on Immich and every other mode there was no way to see or change it. Devices that had the Clock mode set to 24 hours keep their 24-hour small clock after the update.
- The Website screensaver loads the URL as a top-level page instead of an iframe (#118). Sites gated by a session cookie, like DAKboard private URLs, served their login page to the iframe because browsers withhold SameSite cookies from cross-site frames; top-level the site is first-party, shares the app's cookie jar, and renders like it does in the dashboard WebView. Tap-to-dismiss and pixel shift carry over unchanged.

## v0.32.2-beta - 2026-08-03

### Added
- Keep playing when dismissed toggle in the Sendspin settings (off by default): flinging the floating player away hides it without stopping the music.
- Go to dashboard button in the MQTT device, and a matching loadStartUrl remote command: navigates back to the configured Start URL, the device's own dashboard. Unlike Reload page it leaves whatever page is currently shown, so it is the quick way home after temporarily sending the device to another dashboard. (#110)
- The Immich screensaver's album picker now lists albums shared with the user, not just their own. (#109)

### Fixed
- Sendspin resilience on devices with unreliable audio hardware (#106): a frozen playback position report from the audio HAL could silently starve the player, leaving the track "playing" with no sound until a manual pause and resume. The player now detects the stall within seconds and recovers on its own, stops trusting timestamps that do not advance, and escapes a start alignment that stops converging. Reconnection is faster and sturdier too: the client retries the moment the network returns instead of waiting out a parked backoff, a connection stuck waiting for the server's handshake times out, and a race that double-counted reconnect attempts is gone.
- Synced lyrics now actually follow the music. They ran several seconds ahead of the singer on every track (the position anchored to the server's read-ahead cursor during stream startup) and could break entirely after a pause and resume, a track change or a rejoin. The position now anchors to what the speaker is playing, survives every stream rebuild, and ignores the garbage progress value the server sends while pausing.
- Adjusting the Show lyrics toggle, the Lyrics offset or the new dismiss toggle no longer restarts the Sendspin player mid song; they apply live.
- Dates on the clock screensaver and in the Immich photo details follow the device language instead of always being in English: a Dutch device now shows "zondag 1 augustus" where it used to show "Sunday, August 1". (#108)

## v0.32.1-beta - 2026-08-02

### Fixed
- The last piece of the Lenovo fullscreen gap (#102): some ROMs, notably Lenovo's ZUI, keep reporting the status bar as occupying space even while it is hidden, and the dashboard page dutifully padded itself by one bar height through its safe-area insets. Those insets are now withheld from the page on every Display cutout setting, since the bars are permanently hidden anyway. No effect on ROMs that report the insets correctly.
- The remote admin login now says "Too many attempts. Wait 5 minutes and try again." when the brute-force throttle is active, instead of reporting the password as invalid. The throttle rejects even the correct password, so the old message sent anyone with a typo behind them into a loop of retries that looked like a broken password on every device.

## v0.32.0-beta - 2026-08-02

### Added
- Display cutout setting in the new User Interface group under Web Browsing, next to the Zoom level which moved there. By default the dashboard uses the screen area around a punch-hole camera or notch; dashboards with buttons at the very top can pick Avoid the cutout to keep the page below the camera instead, with Short edges only and System default also available.

### Fixed
- On Lenovo tablets (and other ROMs that reserve the status bar row even after the bar is hidden), the dashboard no longer shows a permanent gap at the top of the screen: the app now lays its window out edge to edge through the modern Android inset pipeline instead of relying on the legacy fullscreen flags those ROMs ignore. Devices with a punch-hole camera also get the cutout row back. (#102)

## v0.31.3-beta - 2026-08-02

### Added
- Live Microphone level meter in the Voice Satellite Microphone settings, on the device and in the remote admin: a segmented bar with an RMS and dBFS readout, so the microphone gain can be tuned by watching normal speech land at the top of the green. Useful on devices whose ROM captures audio far quieter than it should.

### Changed
- Playback level updates for the reactive bar skip near-duplicate values and no longer stream to remote admin clients, cutting bridge and WebSocket traffic during TTS and chimes.

### Fixed
- A microphone capture stuck delivering pure silence (a wedged recorder after an audio server crash, or a ROM whose direct 16 kHz record path is broken) is now detected within 2 seconds and reopened through a path that works, instead of leaving wake word detection silently deaf.

## v0.31.2-beta - 2026-08-01

### Changed
- The Zoom level in Web Browsing can now go below 1x, down to 0.5x, to fit more dashboard on a small screen.

## v0.31.1-beta - 2026-08-01

### Added
- Audio sync offset slider in the Sendspin settings (-1000 to +1000 ms) shifts this one device's playback against the group timeline, the cure for Bluetooth speakers whose buffering Android cannot measure. Changes apply live with no restart or rebuffer.

### Fixed
- Lyrics timing rebuilt around what the speaker is actually playing, paired against the server's reported position at the same instant: fixes lyrics pinning on their last line after replaying a finished queue, running ahead or behind after restarting the app mid-song, and inheriting the previous song's scroll position on a track change. Malformed metadata now heals itself within seconds.
- The LRCLIB lyrics fallback now requires the artist to appear in the credit when the artist is known, so a namesake song with the same title and length no longer wins the lookup.
- Crash recovery on Fire OS and Android 12+ is now graceful: a crashed kiosk comes back in about a second with its watchdog re-armed, and an explicit restart command always works instead of being throttled after repeated recoveries. (#94)

## v0.31.0-beta - 2026-08-01

### Added
- Gestures: map touch gestures (2 to 4 corner taps, corner holds, 2 or 3 finger taps and holds, or an ordered corner knock code) to Kiosk Satellite, Android, and Home Assistant actions. Configured in the new Gestures settings section on the device and in the remote admin. Gestures are observed rather than intercepted, so the dashboard keeps behaving as before; a Disable Gestures switch in Kiosk Mode settings opts a locked-down tablet out. See [docs/gestures.md](docs/gestures.md). (#99)

## v0.30.0-beta - 2026-07-31

### Fixed
- Streamed assistant audio (TTS responses and chimes) now plays through the app's own ExoPlayer-based pipeline, so it lands on the speaker selected in settings even on devices whose built-in media player ignores app routing. The route is watched while a sound plays and pinned back if the system tries to move it. (#93)

## v0.29.1-beta - 2026-07-31

### Fixed
- Crash self-heal is now armed whenever the kiosk is on screen, not only when background listening is enabled: a lightweight guard service relaunches the dashboard within seconds of a whole-process crash, backed by a heartbeat for devices slow to restart services such as Fire tablets. Requires the "Display over other apps" permission on Android 10 and newer. (#94)

## v0.29.0-beta - 2026-07-30

### Added
- Return to home dashboard view: an option under Home Assistant Configuration sends the kiosk back to the configured dashboard after a period of inactivity, quietly behind the screensaver if one is showing. (#83)
- Sync Home Assistant themes with Kiosk Satellite: a toggle keeps the dashboard theme in step with the app theme, including the device's own dark mode when the App theme is System. (#92)
- Screensaver schedule entries can override motion detection per time window. (#89)
- Login tokens for automations: pass ttl_days to /api/login for a long-lived token (up to 10 years), with a ready-made rest_command recipe in the docs. (#84)
- New Bring to front button entity over MQTT brings Kiosk Satellite back in front of whatever app covers it.

### Fixed
- Now Playing lyrics are driven by what the speaker is actually playing instead of the server's read-ahead position, multi-artist tracks no longer fail the lookup, unmatched tracks fall back to LRCLIB directly, slow lyrics providers get more time, and reopening the app mid-song picks lyrics up where the music is. (#90)
- Sendspin: fixed a buffer negotiation bug that garbled compressed codecs a few seconds into songs (worst on Opus), fixed the sync engine going blind for minutes after a pause or track restart, and stream starts are now lossless.
- External links now open fullscreen in their own layer with the dashboard alive underneath instead of replacing the Home Assistant page and killing the Voice Satellite session. (#86)
- Fixed the Dim screensaver showing a black screen instead of the dimmed dashboard after the pause optimization became a default in 0.28.0. (#82)
- Snapshots now work on single-camera devices whose ROM advertises cameras it does not have: startup no longer waits on a nonexistent camera, failed captures report a real error and self-heal, and the Front/Back picker becomes a label when there is only one camera.

## v0.28.0-beta - 2026-07-29

### Added
- New Audio settings page with mixer-style volume: Master volume (the device volume), plus independent Media volume and Assistant volume sliders, each exposed to Home Assistant as number entities. The Sendspin player volume in Music Assistant now controls the Media volume directly. Replaces the previous volume handling.

### Changed
- The dashboard optimizations (Keep connected in the background, Pause dashboard during screensaver, Filter dashboard updates) are now on by default and part of the setup wizard's recommended settings. Devices where a toggle was explicitly turned off keep that choice.
- Styled the remote admin scrollbars to match the theme.

## v0.27.1-beta - 2026-07-29

### Fixed
- CPU usage is now measured from actual idle time instead of clock speed, fixing the flat 100% reading on devices that pin their clocks (LineageOS Echo Shows, ThinkSmarts). Parked cores count as free capacity. Applies to the Home Assistant sensor, the Device Info tab, and the health endpoint.
- Dismissing the screensaver no longer flashes a scrollbar.

## v0.27.0-beta - 2026-07-29

### Added
- Device health monitoring: a token-free health endpoint (GET /api/health) returning device identity, IPs, battery, screen state, RAM, storage, CPU usage and temperature, and uptimes; app and network uptime rows in the remote admin's Device Info page; and a Last seen MQTT timestamp sensor that stays readable after the device drops off the broker. (#75)

### Fixed
- At a Glance entity states now round to the entity's Display precision setting from Home Assistant.

## v0.26.0-beta - 2026-07-29

### Added
- Camera integration: the device's own camera is exposed to Home Assistant over MQTT with auto-discovered Camera, Take camera snapshot button, and Last camera snapshot sensor entities. New Camera settings section with master switch, camera picker, snapshot resolution, and optional continuous snapshot interval, all off by default. The camera is never held open; each still opens it, takes one frame, and releases it, and motion detection snapshots ride the existing camera session. The remote admin shows a live snapshot preview, and devices without a usable camera say so up front. (#72)

## v0.25.1-beta - 2026-07-28

### Changed
- Remote admin quick controls are now tiles with icons matching the navigation rail, Go to view (a picker of dashboards and views) replaces Load URL, and the browser tab is named after the device.
- Short sounds like the wake and done chimes are now decoded once and played from memory, removing a dropped frame and a CPU burst per chime on weaker devices.

## v0.25.0-beta - 2026-07-28

### Added
- Pause dashboard during screensaver (experimental): an optimization toggle that stops the dashboard WebView from rendering while the screensaver covers it. The Home Assistant connection, entity updates, wake words, and voice interactions keep working. On a Galaxy Tab S8 with a busy dashboard: app CPU from 152% to 57% of one core, renderer from 130% to 35%, GPU from 70% to 0%, running over 20 C cooler.

## v0.24.0-beta - 2026-07-28

### Added
- Dashboard view MQTT select entity: automations can navigate the kiosk to any dashboard view. The dropdown lists every view by navigation path, follows dashboards being added or removed, and its state tracks what is actually on screen. Picking a view wakes the page and pauses rotation for the same grace window a touch gets.

### Changed
- The Current page sensor and the remote admin now track in-page navigation (view switches) instead of only full page loads.

## v0.23.0-beta - 2026-07-28

### Added
- Assistant volume: voice assistant responses and chimes have their own volume, independent of media volume, with a slider in Voice Satellite settings, in the remote admin, and as an MQTT number entity. (#69)

### Fixed
- Fixed the Roller Clock's digits clipping in mid-air during the roll animation. (#68)

## v0.22.0-beta - 2026-07-28

### Added
- Quick actions in kiosk mode: "Allow menu with quick actions" opens an edge-swipe menu limited to selected harmless actions (Dashboard, Default Camera View, Start Screensaver, theme picker) without the exit gesture or PIN. Off by default. (#64)
- Start Screensaver menu action, also available as a kiosk quick action.
- A kiosk protection that ignores the pull-to-refresh gesture while kiosk mode is on. Off by default.

## v0.21.2-beta - 2026-07-28

### Added
- Software volume for Chromebooks and other fixed-volume devices, detected automatically and applied across SendSpin playback, Voice Assistant responses and chimes, and DLNA media. Software volume can only lower output below the device's hardware level. (#62)

## v0.21.1-beta - 2026-07-27

### Fixed
- Fixed a crash in the microWakeWord engine where loud audio that clipped to full scale could kill the detection worker until the device went deaf to wake words. (#52)

## v0.21.0-beta - 2026-07-27

### Added
- New MQTT entities: Screensaver mode select, Clock style select, and HA kiosk method select (Off, Auto, Plugin, CSS).

## v0.20.0-beta - 2026-07-27

### Added
- Clock styles: the Clock screensaver gained Flip Clock (animated split-flap with configurable colors) and Roller Clock (gliding oversized digits) faces.
- Scheduled screensavers: switch to a different screensaver at set times of day, each with its own brightness override.

### Fixed
- Sendspin skipping and stuttering on slower devices: audio decoding runs on its own dedicated thread and late decoder output plays at its correct position instead of being dropped. The sendspinStatus command now reports detailed pipeline counters.

## v0.19.1-beta - 2026-07-27

### Fixed
- Wake word detection recovers from a crashed detector: the worker is brought back automatically seconds after it dies, and if it keeps crashing the app reports itself unavailable so Voice Satellite resumes browser detection instead of trusting a device that hears nothing. Crashes record their stack trace in the app log. (#52)
- Screen off on devices with an always-on display: kiosk mode's power button watch no longer undoes the app's own screen-off, and on ROMs whose always-on display relights the lock screen the Home Assistant screen entity goes unavailable with an explanatory notice instead of lying. (#51)

## v0.19.0-beta - 2026-07-26

### Added
- Microphone settings under Voice Satellite: capture mode (which Android microphone path to record from), automatic gain control, and microphone gain (0 to 24 dB applied before the wake word engine, stop word, and speech). Changes reopen the microphone on the spot. See [docs/microphone.md](docs/microphone.md).

### Fixed
- The DLNA renderer now steps to the next free port instead of failing with "Address already in use" on plain http instances where the secure context proxy holds port 2325, and a new Server port field shows (and can change) the port it took. (#49)

## v0.18.0-beta - 2026-07-25

### Added
- Synced lyrics on the Now Playing screen, sourced from Music Assistant, with a Validate connection check, an adjustable timing offset, and layouts for portrait and landscape. (#43)
- Open other Android apps from the dashboard via app:// tap actions, and a matching launchApp remote API command. (#44)
- Next alarm MQTT timestamp sensor exposing the tablet's next alarm clock, following alarms from any clock app. (#42)

### Fixed
- At a Glance entities now lay out two per row on portrait screens instead of wrapping into a single column.

## v0.17.0-beta - 2026-07-25

### Added
- At a Glance entities in screensavers: an optional row of up to four Home Assistant entity states on the Black and Clock screensavers, with a searchable picker and reordering, on the device and in the remote admin. See [docs/at-a-glance.md](docs/at-a-glance.md). (#37)

### Fixed
- The Screen entity in Home Assistant now follows the real display state however it changes (power button, idle timeout, another app, lock screen), including a screen that is already off at app start. (#41)

## v0.16.1-beta - 2026-07-25

### Fixed
- The remote administration page was completely broken in v0.16.0-beta by a duplicated script block causing a const redeclaration error; the login button did nothing. The device itself was unaffected. (#40)

## v0.16.0-beta - 2026-07-24

### Added
- WebRTC Camera screensaver: shows a chosen camera view after the idle timeout; any touch wakes the kiosk.
- A permanent default camera view: once it holds a camera, a Default Camera View entry appears in the kiosk menu.
- Drag and drop camera ordering in the view editor.
- Stop button next to Play on every camera view row in the remote admin, and a Dismiss camera view button on the remote dashboard.
- Validate connection row in MQTT Settings using a throwaway connection that reports what the broker actually said.

### Changed
- Exported configurations are named after the device and export time (ks-backup_device_date_time.json).

## v0.15.0-beta - 2026-07-24

### Added
- WebRTC/WHEP camera views: import streams from Go2RTC or add cameras manually, combine up to four into named views that arrange themselves for the display, with basic auth, self-signed certificates, missing-stream detection, and a separate high-resolution stream for fullscreen focus.
- Tap to focus a camera (the other streams disconnect), Back or double tap to return to the grid.
- MQTT camera controls: a button per camera view, a Close camera view button, and an Active camera view sensor, with stable IDs across renames.
- Full camera management on the device and in the remote admin.
- Camera views cooperate with voice interactions (temporarily closing for Voice Satellite and restoring after) and dismiss the screensaver while open.
- Optimized for low-memory tablets: the player exists only while visible, one WebView owns all peer connections, camera audio is never negotiated.

## v0.14.4-beta - 2026-07-24

### Fixed
- Completes the screen edge fix from 0.14.3-beta: the WebView itself could be sized one physical pixel short by a rounding error. The dashboard now covers the full screen on all display densities.

## v0.14.3-beta - 2026-07-24

### Fixed
- The dashboard no longer leaves a thin black line along the right and bottom screen edges on devices whose display density is not a whole multiple of 160dpi (such as the Echo Show 5).

## v0.14.2-beta - 2026-07-24

### Fixed
- Updates installed remotely could leave the app closed on Android 10+ without the "Display over other apps" permission. The gap is now surfaced in the update dialog, the remote admin's Updates card (with a Grant on device button), and the app log.

## v0.14.1-beta - 2026-07-24

### Fixed
- The Sendspin player now heals itself through anything the server does: reconnects after clean closes, retries through connection refusals, never stops trying, detects silently dead connections, and periodically recycles its mDNS discovery.
- Flipping settings in the remote admin's Home Assistant tab no longer re-fetches the dashboard list or loses the scroll position.

### Changed
- The remote admin URL is published to Home Assistant as a sensor, with a Visit button on each device page.
- Zoom level is adjustable from 1x to 4x in 0.05 steps.
- File Manager rows carry folder and file icons.

## v0.14.0-beta - 2026-07-23

### Added
- File Manager in the remote admin: browse, download, upload, and delete files in shared storage or the app's own folder, with server-side path validation.
- Dismiss screensaver and Restart app buttons on the remote dashboard.
- Restart App MQTT button for restarting Kiosk Satellite from Home Assistant.

## v0.13.1-beta - 2026-07-23

### Added
- Crash self-heal: when the app dies unexpectedly, the background listening service relaunches the kiosk automatically. Rides the Auto-reload on error toggle, only fires when the kiosk was on screen when it died, and throttles relaunch loops.

## v0.13.0-beta - 2026-07-23

### Added
- Separate screensaver brightness with a dedicated toggle and slider, applied to every mode except Dim and Black, restored on dismissal, and exposed to Home Assistant as a switch and slider.
- Ambient light sensor exposed as an illuminance entity (lux) over MQTT on devices with the hardware, with damped readings.
- Photos only toggle for Immich Media, skipping video assets in the slideshow.

## v0.12.0-beta - 2026-07-22

### Added
- Home Assistant update entity: each MQTT-enabled device appears in Home Assistant's Updates UI with installed and latest versions, release notes, and an Install button with live download progress.
- Silent updates on Android 12+ through a proper Android install session: after the first confirmed update, every later update installs with no interaction. Device-owner devices install silently on any Android version.
- Automatic relaunch after updates, so a wall tablet returns to its dashboard on its own.

## v0.11.1-beta - 2026-07-22

### Added
- Explicit import choices on every import path: device identity (set up as new vs replace) and whether to restore the WebView's local storage.

### Fixed
- Cloning a configuration no longer makes two devices fight over one Home Assistant device; importing as new sheds a colliding MQTT identity. (#25)
- The Ken Burns screensaver no longer burns a CPU core around the clock: the drift now steps at ~12fps, visually identical, cutting app CPU by more than half on an Echo Show 5.
- Importing over the remote admin no longer hangs at "Importing..." while permission prompts wait on the tablet; the browser now shows a "Finish on the device" step.
- A stale admin session after a wipe no longer strands the browser at an unusable login screen.
- Immich no longer needs a manual re-validate after a restore.
- The kiosk-mode bar guard no longer re-hides system bars that are already hidden.

## v0.11.0-beta - 2026-07-22

### Added
- Microphone and speaker selection for Voice Satellite: pin the wake word and voice turns to a specific microphone and choose where Voice Satellite sounds play, surviving reboots and following hotplug.
- Native sound playback for Voice Satellite: chimes, TTS, and announcements play through the app instead of the WebView, with no browser autoplay blocking, self-signed certificate support, streaming TTS, and reactive bar levels.
- Bluetooth aware routing across media and call routes, marking combinations Bluetooth physically cannot do.

### Fixed
- White dashboard after hours of uptime: an unresponsive renderer is detected and the WebView rebuilt automatically.
- Voice Satellite wake could break after a page reload with the WebSocket filter enabled; the filter now always passes updates for the Voice Satellite device.
- Steady memory growth that could crash low-RAM devices over hours: screensaver slides and camera frames release their decoded images, the engine image cache is capped, openWakeWord no longer leaks a native inference object per audio chunk, the remote admin and built-in proxy no longer buffer without bound, and SendSpin no longer allocates a silence buffer proportional to an outage.
- MQTT no longer hammers a broker that refused the connection.
- Local photo screensavers decode at panel resolution, avoiding 50MB+ allocation spikes.

### Changed
- Much lower idle CPU: backdrop blur renders once per slide, the rotation overlay pauses while hidden, SendSpin stops writing silence after streams end, the full-screen clock wakes once per minute when seconds are hidden, and wake word inference reuses buffers.

## v0.10.0-beta - 2026-07-21

### Added
- Immich Media screensaver: point at an Immich server, pick the whole library or an album, with edge-to-edge display, blurred backdrops for portrait photos, muted video playback, an optional metadata overlay (album, date, camera details, location), and a size-controlled local cache.
- A small corner clock for every screensaver mode, with corner, color, and optional short date, sitting on a soft vignette and respecting OLED pixel shift.

## v0.9.0-beta - 2026-07-21

### Added
- DLNA renderer: the kiosk appears in Home Assistant as a media player and anything cast shows full screen over the dashboard, including HA camera streams (HLS and MJPEG) and image entities, with play, pause, seek, stop, volume, and mute from Home Assistant.
- Restore a backup during setup, from the first screen of the onboarding wizard.
- Volume control over MQTT with a slider tracking changes from every side.
- Release notes shown before updating, with Cancel and Update buttons.
- Check for updates on demand by tapping the version number.

### Fixed
- Crash when dismissing the screensaver on devices where the camera fails to open.
- Stuck on the splash screen after an OS-driven process restart; a watchdog now restarts the app if the screen fails to come up.
- Duplicate MQTT devices after restoring a backup; the identity now always follows the restored configuration.
- App Logs viewer filters out the WebView frame-rate spam flooding logcat.
- Permission hints name and explain the notifications permission accurately.

## v0.8.1-beta - 2026-07-20

### Fixed
- The Now Playing view scales to small screens like the Echo Show 5 instead of cutting off artwork and text.
- The Now Playing view no longer inherits the dim or black screensaver's brightness reduction.

### Changed
- The large media player card is 20% wider.

## v0.8.0-beta - 2026-07-20

### Added
- Sendspin player for Music Assistant: the kiosk registers itself as a synchronized multi-room speaker playing in sample-accurate sync, with lossless FLAC, Opus, and PCM. Includes a draggable floating now-playing card, a full-screen Now Playing view that can stand in for the screensaver, voice assistant awareness (ducking, stop word, stepping aside for Voice Satellite), and a media_player entity in Home Assistant via Music Assistant.
- Browser zoom level slider (1x to 5x in 0.25 steps), applied live without a reload.

### Fixed
- Stop word during timer alerts: the fix lives in the Voice Satellite integration; update to Voice Satellite v2026.7.14.

## v0.7.0-beta - 2026-07-20

### Added
- Ready-made Home Assistant entities over MQTT discovery, no YAML: Screen light, Screensaver switch, Kiosk mode, HA kiosk mode, Keep screen on and Remote management switches, Reload page and Clear cache buttons, Battery, Charging, CPU, RAM, and Current page sensors, with live availability. Configured in the new MQTT Settings page. (#11)
- Real screen brightness control: brightness is read from and written to the actual system setting, with the one-time "Modify system settings" permission requested by the wizard and a graceful fallback to app dimming without it.

## v0.6.0-beta - 2026-07-20

### Added
- Working downloads with in-app feedback: files hand off to Android's download manager, with Downloading and Open notices shown in the app.
- Crash recovery on low-memory devices: when Android kills the WebView renderer under memory pressure, the WebView is rebuilt in place instead of taking the app down.
- Logcat viewer in App Logs with Errors, Warnings, and Info filters.
- Page interaction API: window.kioskSatellite.setInteractionActive(active, reason) holds off the screensaver and view rotation. Documented in docs/js-api.md.

### Changed
- Dashboard view rotation overhaul: starts from the first view, never rotates behind the screensaver or in the background, remembers views needing a full page load, navigates fully before revealing, and pauses for voice interactions.

### Fixed
- CPU temperature no longer reads a constant 105C from thermal trip-point pseudo-sensors.
- Remote UI screenshots from portrait devices are no longer cropped to a sliver.
- The battery indicator in the remote UI header is a proper flat icon.
- Added missing padding above the filter telemetry text in Optimizations.

## v0.5.0-beta - 2026-07-20

### Added
- Filter dashboard updates: filters Home Assistant's state-change stream down to the entities on the visible dashboard view. On an Echo Show 5 with ~4,700 entities, the main thread went from blocked a third of the time to essentially never. Fails safe on views it cannot resolve. Off by default. (#8)
- Optimizations settings group under Home Assistant Configuration, including Keep connected in the background (on by default) and the update filter with live telemetry.

### Fixed
- Flipping a switch in the remote UI's Home Assistant tab no longer reloads the whole tab.

## v0.4.2-beta - 2026-07-19

### Fixed
- Wake words after long backgrounding no longer come back broken: the connection is pinged while backgrounded, verified live before handing the wake to Voice Satellite, and Home Assistant's "Suspend background connections" setting is turned off automatically.

## v0.4.1-beta - 2026-07-19

### Added
- The dashboard picker now targets an individual view within a dashboard, everywhere the dashboard is chosen.

### Fixed
- Exit Application now fully stops the background service and ends the process instead of only closing the window.

## v0.4.0-beta - 2026-07-19

### Added
- Wake Word Tester: a live diagnostic with a real time chart of detection score against threshold, hit and near-miss counts, inference latency, decoded phonemes for vsWakeWord near misses, and a copyable log. Live detection is suppressed while the tester is open.
- External pages in dashboard rotation, loaded in an overlay so the Home Assistant session and wake word detection stay loaded, plus a "Pause rotation on interaction" setting.

## v0.3.1-beta - 2026-07-19

### Fixed
- TTS and announcement audio could play as silence with the secure context proxy on: Home Assistant's media URLs are now kept on the page's origin so the browser no longer mutes them as cross-origin.

## v0.3.0-beta - 2026-07-19

### Added
- Secure context proxy: routes the dashboard through a loopback proxy inside the app, making plain http Home Assistant instances a genuine secure context so the microphone and full voice pipeline work with no certificates. Enabled automatically by the wizard for http URLs.
- Real screen power controls: Screen on wakes a sleeping panel and Screen off truly powers the display down, with the one-time device admin permission requested by the wizard.
- The web admin's console accepts typed JavaScript with history, Copy buttons on Console and Logs tabs, and a new App Logs section in the device settings.

## v0.2.0-beta - 2026-07-18

### Added
- In-app updates: the app checks GitHub for new releases twice a day, with an update notice in the drawer, an Updates card in the web admin with live progress, and getUpdateStatus and installUpdate remote API commands.

### Fixed
- Pull to refresh stays fully disabled when the setting is off.

## v0.1.0-beta - 2026-07-18

First public release of Kiosk Satellite: a free Android kiosk browser built specifically for Home Assistant, and the official companion app for the [Voice Satellite](https://github.com/jxlarrea/voice-satellite-card-integration) integration.

### Highlights
- Two-minute setup with a five-step wizard, on the tablet or from a browser.
- Voice Satellite natively: wake word detection runs inside the app instead of the browser, 10x-30x cheaper, working with the screen off or another app in front, surviving reboots, with a microphone pre-roll so the first words are never clipped.
- Kiosk lockdown: exit gesture with PIN, blocked hardware buttons, status-bar shield, instant re-wake on the power button, and full lock-task support on device-owner tablets.
- HA kiosk mode: hide the Home Assistant header and/or sidebar, with or without the kiosk-mode HACS plugin.
- Dashboard view rotation through a chosen set of views.
- Screensavers: dim, black, clock, Home Assistant media, local folders, or a photo gallery, with transitions, motion wake, and scheduled themes.
- Remote administration: a web admin at http://device-ip:2324 mirroring every setting, with live screenshot, web console, logs, and full configuration export/import.
- Power-user extras: custom JavaScript injection, start on boot, default brightness, pull-to-refresh, and self-signed certificate support.
