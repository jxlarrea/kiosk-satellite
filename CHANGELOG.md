# Changelog

All notable changes to Kiosk Satellite are documented here. Full release notes for each version are available on the [releases page](https://github.com/jxlarrea/kiosk-satellite/releases).

## v2026.8.74 - 2026-08-23

### Changed
- The Home Assistant settings page is no longer one long scroll. Its groups now live on pages of their own, the way One UI does it, each reached by a row that names the page and lists what is inside: User Interface (kiosk mode, dashboard carousel, haptics, tap sounds), Theme, Dashboard View Rotation, Return to home dashboard view, Hold mode and Optimizations. What is left on the page itself is the connection, the dashboard picker and those six rows, so finding a setting is a short read instead of a long one. Opening a row gives its settings a page titled after it, with a back arrow beside the title; the back arrow, the system back gesture and, in the remote admin, the browser's own Back all come back to where you were on the page above rather than the top of it. The Voice Satellite page gets the same treatment: Wake Word (the engine, the wake words, sensitivity, the noise gate, the stop word, cached models and the app's own detection settings) and Appearance (skin, theme mode, activity bar and text scale) are each a page now, leaving General and the required permissions on the page itself. On Screen & Audio the Microphone settings group (capture mode, channel, gain and the live level meter) moves the same way, leaving Screen, Audio Volume and Audio Devices where they were. The Screensaver page, the longest of the lot, sends Widgets, At a Glance, Motion Detection and Scheduled Screensavers to pages of their own, along with the settings for four of the screensaver modes: Clock, Local Media, Photo Gallery and Immich Media. Every mode's settings are now named after the mode and the word screensaver, so the group under the mode picker reads "Dim screensaver" or "Website screensaver" and the rows that open a page read "Clock screensaver" or "Immich Media screensaver" - no more guessing which of them the picker above just chose. Those four still appear only while that mode is the one selected, exactly as their groups used to, so picking Clock now adds one row that opens the clock's settings instead of a dozen rows to scroll past; the shorter modes keep their settings on the page. The Device page keeps its Permissions Manager last, below Configuration, and sends Remote Administration to a page of its own carrying the Access card with it; in the remote admin its Hardware, Home Assistant and WebView reports each get a page too, so four rows sit together just above the grants. On ESPHome the Bluetooth proxy is one page: its own settings plus the Nearby devices group and the live list of what the kiosk is hearing, leaving the entity server's settings and the Bluetooth grants on the page above. Kiosk Mode sends its Allowed Actions group, the quick actions the kiosk menu offers, to a page of its own, keeping the protections and the grants on the page above. Nothing about the settings themselves changed, and the search still finds each one by name and opens the page it now lives on. Second-level pages are addressable in the remote admin, so they can be bookmarked and survive a reload.

### Added
- A Bluetooth devices connected sensor, in the ESPHome and MQTT integrations, next to the nearby-devices count. It reports how many Bluetooth devices this kiosk is linked to right now, with their names in attributes, so a dashboard can tell whether the room's speaker or keyboard is still on the panel without walking over to it. It counts every link the adapter holds, the ones the Bluetooth proxy has open for Home Assistant included, which is what a connection count means from the device's side. The proxy's own connection budget sits beside it as a plain number, renamed Bluetooth max connections: it used to be a Bluetooth connections sensor reading "1 of 3", a string no dashboard or template could do arithmetic on, and the live half of it is what the new sensor now reports properly. Both it and the connected count now follow links as they come and go rather than waiting for the minute poll, so a device Home Assistant connects to for a few seconds (a lock taking a command through the proxy) is visible for as long as the link lasts instead of falling between two polls. The sensor comes and goes with the Bluetooth Proxy switch, and devices whose Android will not report their links at all (no adapter, or the Nearby devices permission not granted on Android 12 and newer) get no sensor rather than one stuck on unknown.
- A notification arriving over a dimmed screensaver now brings the panel back to its ordinary brightness while it is on screen, and lets it dim again when the last one is dismissed. Kiosks routinely run their screensaver at a few percent, which is exactly dark enough that a message arriving on it cannot be read; the session borrows back the brightness it saved when it started, and only the backlight moves, so the clock, the photo or the black overlay stays where it was with the card lit on top of it. Dim and Black lift too, as does a schedule entry's own brightness. A new "Brighten for notifications" switch in the Screensaver settings turns it off, for a bedroom where a notification lighting the room at 3am is worse than missing it until morning.
- Notifications can carry any Material Design Icon. The `icon` argument takes an icon named the way Home Assistant names them, `mdi:washing-machine`, and draws it in place of the one the notification's type picks, in the type's own color. The whole icon set ships with the app, so anything valid in a dashboard works on the kiosk, including the older names Material Design Icons has since renamed. At a Glance now draws its icons from the same set: an entity whose icon you set in Home Assistant appears on the screensaver row exactly as it does on your dashboard, where before the name was matched against a short list of Material lookalikes (about eighty of them) and anything else fell through to a generic per-domain icon. Entities you have not given an icon still get the app's own per-domain guess, since Home Assistant computes those in its frontend and never sends them.
- Notifications can be drawn larger. The `scale` argument on the notification action (and on `showNotification`) takes 1, the ordinary card, up to 4, with decimals like 2.5 in between: type, icon, padding and width all grow together, so a wall panel can push an alert that reads from the far side of a room without a full-screen takeover, and an ordinary informational note can stay small. Each notification carries its own scale, so a big one can sit above small ones in the stack.
- Switching "Remote management" off from the remote admin now asks first. It is the one switch there that takes away the page you are using, and nothing on that page can undo it, so the confirmation warns that you will no longer be able to access the page and names the two places that can switch it back on: the device, or the Remote management switch this kiosk exposes in Home Assistant.

### Fixed
- Kiosk mode arms fully again on Android 7 tablets. The shield that guards the top edge of the screen (the "Disable status bar" protection) was created with a kind of window Android only introduced in version 8, so older devices refused it outright even with the draw over apps permission granted, and every refusal aborted the rest of the kiosk push behind it: the home button protection, the bar watcher, the System UI guard and Lockdown Mode's own screen shield were all left unarmed, while the log filled with a window permission error a couple of times a minute. Both overlays now ask for the window kind their Android version accepts, so the shields work on Android 7 as they do everywhere else, and a shield the system still refuses is logged as a warning without taking any of the other protections down with it.
- Losing remote access is now diagnosable. Warnings and errors reach the Android log as well as the app's own, which the remote admin is the only reader of, so a device whose remote server is down can still be inspected over adb; and switching "Remote management" off is written to that log, since it is the one change that removes the means of investigating it.
- The remote admin server no longer stays down without saying why. It needs an admin password as well as the "Remote management" switch, and when the password is missing it simply did not start: no log line, no notice, and a switch still reading "on", which looks exactly like a working setup. The switch now carries the reason underneath it ("Set an admin password below to start the server", or the port it could not listen on), and the reason is written to the log on every start, stop and restart. Turning remote management off also releases the server before closing it, so a close that stalls on a connection cannot leave the switch on with nothing listening.
- The Scheduled Screensavers group is named for what it does, and its master switch reads "Enable scheduled screensavers" so the page and the toggle no longer share a name.
- The remote admin no longer keeps the previous page's scroll position when you pick a different section from the navigation. Switching from a Home Assistant page scrolled halfway down to Voice Satellite used to open it halfway down as well, at whatever row happened to be there.
- "Keep listening in the background" no longer disappears from the remote admin's Voice Satellite page. The row is borrowed from the wake word settings to sit with the other important ones, and whenever the page refreshed its live controls (which it does whenever something changes them elsewhere) the row was dropped instead of put back, leaving the setting unreachable until the page was reloaded.

## v2026.8.73 - 2026-08-22

### Added
- A Battery widget for the screensaver, in the Widgets group beside the small clock and the weather widget. It puts this device's own charge in a corner of any screensaver except WebRTC Camera: an icon that follows the level, a bolt while the tablet is on external power, and the percentage beside it, so walking past the hallway tablet tells you where it stands without opening Home Assistant. Its own toggles pick the corner and the color, drop the percentage for the icon alone, or keep the widget hidden until the charge falls to 20 percent. The reading comes from the device itself, so it needs no entity and keeps working while Home Assistant is away.
- Toggles for each line of the Immich screensaver's metadata overlay: Album name, Date taken, Camera details and Location, all on, under Show metadata on the device and in the remote admin. A screensaver pointed at one album repeats its name on every photo, and now that line (or any other) can simply be turned off. With the album line off the extra lookup it needs is never made, and with every line off the overlay stands down entirely, vignette included. Camera details now also names the camera the photo was taken with, on its own line above the focal length, aperture and ISO.
- Notifications: Home Assistant can now push a message at the kiosk and have it appear over whatever is on screen, the screensaver included, as a large card at the top of the display with a chime. It is meant for the things a wall tablet is there to say ("Washing machine finished", "Front door opened", "Leak detected") without a dashboard card, a browser popup, or the screensaver being torn down: the photos or the clock keep running underneath and the notification slides away by itself. Home Assistant sends one with the new `esphome.<device>_notification` action, which carries the message, an optional title, how long it stays (0 keeps it up until it is tapped, the default is 30 seconds), which of the four kinds it is (informational, success, warning or error, picking the icon and its color) and whether to chime, and an ESPHome device can call the same action directly with no automation in between. Notifications stack, newest on top, up to four at a time, each with its own countdown, so a second one arriving does not take the first off the screen, and a fifth pushes the oldest out. The same thing is a `showNotification` command on the remote API for setups driving the kiosk over REST, with a `dismissNotification` beside it that takes down one card by id or clears the screen, and a tap anywhere on a card takes that card down.
- A Node name row in the ESPHome settings, on the device and in the remote admin. The node name is what Home Assistant discovers the kiosk by and, now that it registers actions for this device, what those actions are named after: a kiosk called "Kitchen Tablet" gets `esphome.kitchen_tablet_notification` instead of the generated `esphome.kiosk_satellite_a1b2c3_notification`. Newly set up kiosks name themselves after their device name; kiosks that Home Assistant already discovered keep the generated name they were found under, and the row now shows it and lets it be changed. Anything typed is reduced to what a network name allows (lower case, digits and single hyphens), and it must be unique among the kiosks on the network. Renaming keeps every entity, its history and its entity id, since Home Assistant keys those on the hardware address, but automations calling an action under the old name need updating, and Home Assistant only picks the new name up once the kiosk's ESPHome entry is reloaded.
- An update download can now be cancelled. The downloading dialog on the device has a Cancel button, and the remote admin shows one beside the progress while a download runs. Cancelling keeps the update notice up, so the download can simply be started again, which is the escape hatch for a download that stalls on flaky Wi-Fi and used to block every retry until the app was restarted. A download that stops delivering data now also gives up on its own after 60 seconds and reports the stall instead of pretending to run forever.

### Changed
- The weather widget's forecast line now reads in Home Assistant's language: the condition is written with Home Assistant's own translation of it, so a server set to Italian shows "Nebbia" where it used to show "Fog". Nothing to configure, and nothing changes on an English server. Its lines also sit on the same line height as the Immich metadata panel, so the two corner blocks read as one family.
- The remote admin attaches to an update download that is already running (one started on the device, or after a page reload mid-download) instead of failing with "a download is already running", it keeps riding through brief Wi-Fi blips on the tablet, and it now reports how the download actually ended: a cancelled or failed download re-offers the Install button (with the failure message), a silent install says so, and only an install genuinely waiting on the device screen asks to be confirmed there.

### Fixed
- Brightness set by the app now lands where it was asked for on panels that do not use Android's usual 0 to 255 brightness scale. The range is a per-device constant, and OEM tablets routinely use 0 to 1023 or 0 to 2047 instead, where the app's fixed 0 to 255 write asked for roughly a tenth of the level requested: the remote admin slider, the brightness applied at launch and the level restored when a screensaver ends all left the panel looking black, while every reading above a tenth reported back as 100%. The app now reads the panel's own range and scales every level to it, grows the range if the panel ever reports a value beyond it, and notes the scale it found in the log at startup.
- Downloading an update no longer floods the device with status traffic. Every whole percent of progress fanned out to the Home Assistant integrations and wrote log lines, several times a second on a fast connection, which showed up as heavy CPU load and a log full of getUpdateStatus entries on weaker tablets; mid-download updates are now capped to one per second, progress notifications advance in whole percents instead of per network chunk, and the download buffers at most a few megabytes ahead of what the storage has written.

## v2026.8.72 - 2026-08-22

### Changed
- In-app notifications now use the app's own toast instead of the stock Android-style snackbar: a compact rounded card that follows the app's light or dark theme, with a title, a message and a colored icon that says what kind of note it is (informational, success, warning or error). Toasts sit centered near the bottom at a comfortable width instead of stretching across the screen, and taps pass straight through the informational ones to the dashboard beneath. Finished downloads keep their Open button.

## v2026.8.71 - 2026-08-21

### Added
- The Now Playing card can follow another Music Assistant player. A new "Player to control" picker in the Music Assistant settings (on the device and in the remote admin) points the floating card, the full-screen Now Playing view and the transport buttons at any player the server offers (a Sonos, the kitchen speakers, a sync group) instead of this device's own, for the wall tablet whose job is to show and steer music that plays elsewhere. The card follows the chosen player live over Music Assistant's API (track, artwork, progress, play and pause), and the kiosk menu's Music Assistant shortcut now opens with the right player already selected, whether that is the controlled player or this device's own. While a remote player is picked the device is a remote control, not a player: its own Sendspin player shuts down and shows as offline in Music Assistant, and every setting about the local player (the enable switch, server, codec, sync offset, voice ducking, lyrics) leaves the settings for the duration, while the card and Now Playing rows stay. Lyrics stay off in this mode, since a remote player's position is reported too coarsely to sing along with. Picking "This device" brings the player back online with all of its rows.
- Hold mode: pin whatever is on screen until you say otherwise, made for keeping a recipe or a video up while you cook along. While it is on, the screensaver will not start (a showing one is dismissed the moment hold engages), dashboard view rotation freezes in place, the "return to home dashboard view" timer stands down, and the display stays awake. The toggle lives in a new Hold mode group in the Home Assistant settings, on the device and in the remote admin, together with an optional auto release slider (15-minute steps up to 6 hours, 0 holds forever) that ends a forgotten hold by itself. The same live state is everywhere it is useful: a "Hold mode" switch on the kiosk's Home Assistant device over both ESPHome and MQTT, a "Toggle hold mode" gesture action (claps included, for flour-covered hands), a notice in the kiosk menu that shows while a hold is active and releases it on a tap, and an on-screen note each time hold mode turns on or off. An opt-in "Show in the kiosk menu" toggle adds a "Turn On/Off Hold Mode" entry to the kiosk menu, with a matching Hold Mode allowed action in the Kiosk Mode settings deciding whether it appears in the restricted quick actions menu.
- An opt-in "Hide the close button" toggle in the Music Assistant settings, under "Close after inactivity". Music Assistant's full-screen Now Playing view puts its three-dot menu in the very corner the floating close button occupies, leaving the menu unreachable; hiding the button hands that corner back to the page. The back button, a wake word and the inactivity timer still close the page, and every other overlay keeps its close button.

## v2026.8.70 - 2026-08-21

### Added
- A show/hide entry for the floating Sendspin player in the kiosk menu. Enabled with a new opt-in "Show in the kiosk menu" toggle in the Sendspin player settings, it reads "Show Sendspin Player" or "Hide Sendspin Player" to match what is on screen: showing brings back a card that was flung away, timed out paused, or belongs to a paused queue the app has not seen since it restarted, and works even while "Show the floating media player" is off, without changing that setting; hiding tucks the card away without stopping the music. In Kiosk Mode a new "Sendspin Player" allowed action decides whether the entry appears in the quick actions menu.

### Changed
- The "Show the Sendspin player" gesture no longer switches the "Show the floating media player" setting on permanently; like the new menu entry, it now reveals the card for the current playback session only.

### Fixed
- A locked kiosk whose only allowed quick actions were Music Assistant, the Sendspin player or Apps never offered the edge swipe; the availability check now counts every allowed action that would actually show.
- Dropdowns, dialogs and three-dot menus land where they belong under a zoom level other than 1x, instead of drifting off toward the screen edge. The zoom level used to be applied as a CSS zoom on the page, and Home Assistant's floating menus position themselves by measuring their anchor and writing the result back in pixels; under CSS zoom those pixels get scaled a second time, pushing every overlay past its anchor by the zoom factor, often clean off an 8-inch screen at 1.35x. The setting now zooms the way a desktop browser does, by scaling the viewport itself, which keeps every measurement and the layout in one consistent coordinate space. Pinch to zoom, the display cutout behavior and returning to 1x all carry over unchanged.

## v2026.8.69 - 2026-08-21

### Added
- A "Show Music Assistant" button on the kiosk's Home Assistant device, over both the ESPHome and MQTT integrations. Pressing it wakes the screen, brings the kiosk forward and opens the Music Assistant web interface over the dashboard, the same page the kiosk menu entry opens. The button exists only while a Music Assistant server address is configured, appearing and retiring on its own as the address is set or cleared.
- A "Debug logging" switch in the Voice Satellite settings' General group, on the device and in the remote admin. It flips the same browser-console logging the Voice Satellite sidebar panel offers, so wake word scores and pipeline events can be turned on without leaving the kiosk's settings. Shown once the installed Voice Satellite version supports controlling it externally.
- The dashboard signs itself in. A new "Log in automatically" toggle in the Home Assistant settings (on by default) hands the page a session built from the long-lived access token the app already holds, so a freshly set up kiosk lands on its dashboard instead of the Home Assistant login form. A login someone did by hand, or a session the page already has, is never overwritten, and turning the toggle off stops future sign-ins without logging anything out.

### Changed
- The Voice Satellite status group is gone from the settings, on the device and in the remote admin: everything it reported is already told by the Wake Word settings themselves. Its "Cached models" clear button lives on, moved into the Wake Word group.
- The setup wizard's first step now calls out, on its own highlighted row, that setup can be continued from a web browser at the device's address whether remote administration is kept on or not. The satellite step now reminds that a new device needs its own satellite entity, with the Home Assistant menu path to create one, since two devices cannot share the same entity; the reminder appears in the on-device and the remote wizard alike.

## v2026.8.68 - 2026-08-20

### Fixed
- An open remote admin page no longer freezes the kiosk's reactive bar mid-turn and delays the done chime. The admin page refreshes its Voice Satellite panel on every wake-word state change, and those fire at the start and end of every voice turn; each refresh made the kiosk download and parse its Home Assistant instance's full entity registry twice plus the complete state table, megabytes of JSON on the same thread that animates the page, right while it was speaking. The registry half is now cached for five minutes and only the dozen entities the panel shows are read fresh, and the admin page itself no longer refreshes from a background tab, catching up when it next becomes visible instead.
- The done chime follows the end of speech immediately instead of a second or two later, and the reactive bar no longer freezes in that gap. When a natively played sound finished, the player's teardown ran on the interface thread before the finished signal was sent, and on devices with slow media decoders that teardown stalled the thread for most of a second; the chime's own start then queued behind the same stall. The finished signal now goes out first and the teardown is capped so it can never hold the interface thread.
- Voice interactions that speak through a remote media player now end when the speaker stops instead of thirty seconds later. The kiosk trims the Home Assistant websocket to the entities a view actually uses, and it already made an exception for the Voice Satellite device so its own controls never go stale. The speaker chosen as the satellite's TTS output is not part of that device, though, so its updates were dropped: the page kept reading it as unavailable, Voice Satellite never saw the playback finish, and only its safety timeout closed the turn, firing the done chime half a minute after the speech ended. Any entity the satellite's own entities point at now rides along on the allowlist, and switching the TTS output to a different speaker rebuilds it right away.
- The remote setup wizard no longer leaves the full settings interface sitting one scroll below it. Logging in, wizard and settings are three full-page views of the same page, and the code that revealed one never hid the others, so they stacked. On top of that, the decision to continue into the wizard after logging in was made once when the page loaded: any sign-out and second login during setup, including the automatic one when a stale session expires, then opened the settings of a kiosk that had never been set up. Each login now asks the kiosk whether setup is still pending, and switching views always replaces the one on screen.

## v2026.8.67 - 2026-08-20

### Added
- Home Assistant cameras that cannot stream at all play over MJPEG. Every camera entity serves Home Assistant's camera proxy stream, so stills-only cameras such as UniFi package cameras now show a live picture instead of failing, and MJPEG is the automatic last resort for every other Home Assistant camera whose WebRTC and HLS paths fail on a device. The import now accepts every camera entity, a hand-added Home Assistant camera asks Home Assistant what the entity really offers instead of assuming WebRTC and HLS (its formats label now tells the truth), and a transport the server itself refuses is skipped immediately rather than retried three times before moving on.

### Fixed
- Cards that make room for the Home Assistant sidebar (navbar-card among them) now sit flush to the screen edge when kiosk mode hides the sidebar. The frontend publishes the sidebar's width under two names across generations, and kiosk mode only zeroed the older one, so cards reading the newer variable kept dodging a sidebar that was no longer there. Verified live on an Echo Show 8: the navbar moved from 272px in to its intended 16px inset.
- Opening a camera view no longer flashes white as it slides up. Two causes stacked: hls.js was parsed in the page's critical path, delaying the first black paint (it now loads deferred, and the HLS player waits for it), and Android composites a fresh WebView's default white background for a frame or two before any page paints at all (the view now keeps a black cover over the WebView until the page reports its first frame, and the WebView background is transparent over the black surface behind it). Verified frame by frame on an Echo Show 8 screen recording.
- The bundled hls.js is now the light build, the same file the Voice Satellite integration ships: a third smaller and quicker to parse, dropping only subtitle, alternate-audio and DRM support that a camera stream never carries.

## v2026.8.66 - 2026-08-20

### Added
- A "Use real Wi-Fi MAC address" switch on the ESPHome page. The kiosk normally identifies itself with a generated hardware address (Android hides the real one from apps), which keeps its ESPHome device separate from the entries router and network integrations register for the same hardware. With the switch on, and where the address can be read at all (Android 9 and older, or any version with the app as device owner), the kiosk reports its real Wi-Fi MAC and Home Assistant merges those entries into one device; the MQTT integration's device block carries the same address, so it lands in the merged device too. The first address read is stored for good, keeping the identity stable across OS upgrades that close the door it came through, and where Android will not reveal the address the switch says so right below itself instead of silently changing nothing. Off by default, since adopting the new identity makes Home Assistant treat the kiosk as a new ESPHome device.

## v2026.8.65 - 2026-08-20

### Added
- Home Assistant cameras without a WebRTC path stream over HLS, so any camera the Home Assistant frontend can play now works in camera views. The Home Assistant import accepts every streamable camera entity instead of only WebRTC-capable ones and remembers which transports each offers; a camera that does both tries WebRTC first for its near-realtime latency and falls back to HLS on its own when WebRTC does not work out on the device, joining the existing WebRTC-to-MSE ladder. HLS playback runs through the app's loopback relay (the page cannot fetch from Home Assistant directly) and hls.js, vendored into the app like every other asset. A "Prefer HLS over WebRTC" toggle (Camera Streams, Playback) flips the order for devices whose WebRTC cannot play these streams, the counterpart of the MSE toggle, and each row in the Cameras list now names the formats that camera can play with.

### Fixed
- A camera view shown again while it was still sliding out no longer comes back invisible. The re-show landed in the closing player without replaying its entrance, so the exit finished underneath it: a black panel with every stream still connected and decoding behind it, which no later close could reach, and stale cameras on every later open of that view. Re-showing now plays the view back in mid-exit, or mounts a fresh player when the old one was already torn down. Found and verified live on an Echo Show 8 by toggling a view closed and open in under a second, the timing an MQTT automation or a doubled gesture produces.

## v2026.8.64 - 2026-08-20

### Added
- The Bluetooth proxy heals a wedged scanner by itself where Android allows it (#246 follow-up). A stack whose scan-client table is stuck (seen live on an Echo Show after app updates killed it mid-scan) refuses every scan registration until the adapter restarts, which Home Assistant's "power cycle the device" banner asks the user to do by hand; on Android 12L and older, exactly the device generation that wedges, the proxy now restarts the adapter itself after repeated registration failures and resumes scanning when it returns. Scan failures in the log also carry their name now ("registration failed", "internal error") instead of a bare code.

## v2026.8.63 - 2026-08-20

### Fixed
- Phones and beacons are no longer invisible to the Bluetooth proxy on Android 12 and newer (#246). The proxy scanned with Android's neverForLocation flag, and Android honors that flag by silently stripping every location-inferable beacon frame, iBeacon and Eddystone alike, from scan results: exactly the traffic a Bermuda or iBeacon presence setup needs relayed. Phones were invisible to every modern proxy device while ESP32 proxies and Android 11 devices heard them fine. The scan now runs with location attached, which makes Android require the Location permission and location services on every version; existing proxies on Android 12+ must grant Location once after updating (the ESPHome page's permission rows say so and walk through it), and the app still never reads the device's position. Verified end to end live: a phone invisible to a Tab S9 for days appeared within seconds of the change and Bermuda now tracks it through that kiosk.
- The ESPHome page's Required system permissions group now shows two rows, Nearby devices and Location, each reading its own half of the gate and naming what is blocking scanning, with one Grant flow that walks through the pair dialog, the location dialog and the location settings screen in order.

## v2026.8.62 - 2026-08-20

### Added
- The ESPHome proxy log now shows whether Home Assistant is actually taking the Bluetooth advertisements (#246). Each session's advertisement subscribe and unsubscribe is logged, a relay watchdog writes one line when the device keeps hearing advertisements but none have been forwarded to Home Assistant for two minutes (with the received and forwarded counters) and another when forwarding resumes, and the scanner logs a recovery line when advertisements start flowing again after a failure streak, naming whether the minimal-settings fallback is in effect. Together these split the case a full Nearby list and an empty Home Assistant side could not distinguish before: scanning trouble, a missing subscription, or a wedged relay.

### Fixed
- The app launcher works while "Disable home button" holds. Launching an app from a pinned kiosk only produced Android's "to unpin, swipe up and hold" toast, and manually unpinning to get around it left the kiosk unpinned until the setting was toggled. The kiosk now unpins itself for the launch and re-checks the pin every time it returns to the foreground, so the pin comes back on its own after the launched app, and after a manual unpin too. On devices without device ownership the re-pin shows Android's pinning confirmation again, the ceiling Android sets for screen pinning; the Apps row under Allowed Actions now says the launch drops the pin.

## v2026.8.61 - 2026-08-19

### Added
- A "Double tap to dismiss" switch in the Website screensaver settings. With it on, single taps interact with the page instead of waking the kiosk, so an interactive site shown as the screensaver (Immich Kiosk's navigation and rating buttons, a dashboard's controls) stays usable, and two quick taps anywhere bring the kiosk back. Off by default, and only offered for the Website mode, whose page is the only thing a single tap could talk to.

### Fixed
- HA Kiosk Mode reclaims the hidden header's space again. The fix that removed the black bar under panel views also began padding the dashboard by the display's safe-area inset, and because the rule landed on two nested view elements the inset counted twice, so on any device that reports one (a camera cutout, or an Android 15 status bar even while hidden) the dashboard kept a band of empty space where the header used to be. The padding is now simply zero: hiding the header gives the whole screen to the dashboard, and the panel-view sizing fix stays as it was.

## v2026.8.60 - 2026-08-19

### Fixed
- YAML-mode dashboards now appear in the Dashboard view select. When the option list was learned before the dashboard page was up (an app start, a reconnect), the fallback crawl kept only storage-mode dashboards, so an instance whose dashboards live in configuration.yaml offered nothing but the default dashboard's views plus Map, no matter how many dashboards the sidebar showed. The same crawl also duplicated the default dashboard's views whenever a dashboard is registered on the default url path, and gave up on the entire list when any single dashboard's config could not be read, freezing the select on whatever it knew last; now an unreadable dashboard (a YAML file that will not parse, an admin-only dashboard the token cannot open) is offered by its bare path like a strategy dashboard, and only a dead connection preserves the last known list.

## v2026.8.59 - 2026-08-19

### Added
- The Voice Satellite settings page can now change the integration's settings, not just read them, on both the device and the remote admin. A General card carries the assigned satellite (now a picker that rebinds the kiosk and reloads the dashboard, with a Disabled choice that clears the binding so the kiosk stops identifying as a satellite), Auto start, Mute, both Assist pipelines and Finished speaking detection; a Wake Word card carries the wake word engine, both wake words, the wake word sensitivity, the noise gate and Stop word interruption; an Appearance card carries the skin, theme mode, reactive activity bar, its update rate (as frames per second instead of milliseconds) and the text scale. The Home Assistant half writes through the satellite's own select entities, so the change lands exactly where the Voice Satellite panel would put it; the browser half goes through a new page hook that persists to the panel profile in Home Assistant and applies live, so a skin change repaints without a reload and survives one. Needs a Voice Satellite version that ships the hook for the browser-side rows; the entity rows work with any version.
- An Engine row on the Voice Satellite page starts or stops the voice assistant in the dashboard page, through the same path as the Voice Satellite panel's own Start and Stop buttons, with the running state shown next to it. The General card also reports the installed Voice Satellite integration version.
- A Last interaction timestamp sensor on both the ESPHome and MQTT integrations, stamped when someone touches the screen or speaks to the device, so automations can tell an idle kiosk from one in use and pick their own idle threshold, for example only showing a camera view after five quiet minutes. Motion, announcements, timers and media playback deliberately do not count, and a stream of touches collapses to at most one publish a minute with the final touch always landing accurately.

### Changed
- The "Wake word detection" master switch is gone: with Voice Satellite installed the app always takes detection over, and the Wake word engine select in Home Assistant is the real off switch. The setting is forced on, and a device that had it off is migrated once at startup so nothing is stranded silent. "Keep listening in the background" moved up into the General card, below Auto start, where an important switch belongs.
- The Voice Satellite screensaver is now always off inside the kiosk, and the "Turn off the Voice Satellite screensaver" toggle is gone. The app owns the screen and runs its own screensaver management, so two screensavers negotiating over one panel was never a real choice; the page is told to stand down unconditionally, and the Voice Satellite panel now renders its screensaver toggle off and disabled with a note pointing at the app's own screensaver settings.

## v2026.8.58 - 2026-08-18

### Fixed
- A trailing slash in the Home Assistant base URL no longer breaks the voice pipeline socket. The URL field accepted "http://ha:8123/" but stored it verbatim, so the native pipeline dialled "http://ha:8123//api/websocket" and every wake word died with a WebSocket upgrade error while the rest of the app, which normalized the URL on read, kept working. The setting is now canonicalized to its origin (scheme, host, port) on every write, and a value stored with a trailing slash by an older version is rewritten once at startup.
- The ESPHome Screen light is dimmable again. The entity described its brightness support only through the protocol's legacy field, which modern Home Assistant ignores in favor of the color-mode list, so the light that carried a working brightness slider on MQTT came over as bare on/off. The entity now declares the brightness color mode in both its description and its state; existing devices pick it up on the next reconnect, no re-adding needed.

## v2026.8.57 - 2026-08-18

### Added
- The Bluetooth scanner falls back to minimal scan settings when a device's stack keeps refusing the rich ones. A Meta Portal answered every scan start with an internal error, forever; after three straight refusals the proxy now retries with the plainest scan Android knows (dropping the aggressive match mode and PHY refinements) and says so in the log, since a degraded scanner beats a dead one. The fallback is sticky until the proxy restarts, so a stack that objects to the refinements is not re-broken on every recovery.

## v2026.8.56 - 2026-08-18

### Fixed
- The "Nearby devices" permission row tells the truth on Android 11 and older. Those versions grant the Bluetooth permissions at install but gate scan results on location: without the Location permission and location services on, the scanner runs and hears nothing, which the row nevertheless reported as Granted, leaving a Fire tablet scanning "actively" with a permanently empty Nearby list and nothing for Bermuda. On old devices the row now reads the location gate instead, its Grant button asks for the Location permission, and when the system-wide location switch is the blocker it opens the OS location settings screen, the only place that can flip it.
- On those same old Android versions the Nearby devices rows also say which half of the location gate is blocking scanning, on the device page, the ESPHome page and both remote admin views: "Location is off in the device settings" when the system-wide switch is the problem (the actual resolution, a setting nobody thinks to connect to Bluetooth), or that this Android version needs the Location permission when the grant is what is missing.

### Added
- A hand-edited encryption key is validated before the server starts. The ESPHome protocol's key must be the base64 form of 32 random bytes; a typed-in word used to kill the server silently, taking discovery down with it and leaving Home Assistant's generic "unable to connect" as the only symptom. An invalid key now surfaces as a clear failure reason on the settings pages, with the recovery spelled out: clear the field and a fresh key is generated.
- Bluetooth scanner failures now land in the proxy log that btProxyStatus and the remote admin show, named with their reason, instead of only Android's internal logcat. A scanner killed by a permission error or a stack failure used to look exactly like a healthy one from every surface a user could reach.
- The proxy log now states the server's bind scope and the IP address announced to Home Assistant over mDNS (logged whenever it changes). When discovery shows a device that then refuses to connect, which address Home Assistant was told to dial is the first question, and on multi-interface devices it was previously unanswerable.

## v2026.8.55 - 2026-08-18

### Added
- The dashboard carousel can now win swipes from cards that handle gestures themselves. A fullscreen camera card is a fullscreen video under the finger, and the carousel deliberately never claimed swipes starting on media elements or swipe-handling cards, which left a panel-view camera dashboard with nowhere left to swipe. "Capture swipe gestures over cards", off by default under the carousel toggle, claims those swipes for view navigation and silences the card's own gesture handling for the duration of the drag, so the card cannot react to the same swipe it just lost. Sliders, dialogs, maps, form fields and cards that scroll sideways natively keep their gestures either way.

### Fixed
- Slow Bluetooth advertisers are no longer invisible on some BLE 5 devices, which kept marking a Yale lock unavailable in Home Assistant between its brief battery-saving connections. Two independent causes, found live with two tablets sitting next to a lock that only a legacy-only device across the house could hear: scanning across every supported PHY made the controller time-slice its scan windows between the 1M and Coded bands (the proxy now scans 1M only, where extended advertisers overwhelmingly live), and some scan stacks report each static advertiser roughly once per scan session and then suppress its duplicates whatever the scan settings request, so quiet devices faded out minutes into every session while chatty ones kept flowing. The proxy now rotates its scan session every two minutes, comfortably inside Home Assistant's staleness window, so every advertiser re-reports before its availability can expire; verified with the previously flapping lock heard continuously across a half-hour soak.

### Added
- The ESPHome settings page says when the server is down and why. A server that failed to start, a port conflict on one of two identical tablets being the live case, used to render a page indistinguishable from a working one: toggles on, no error anywhere. Both the device page and the remote admin now show the failure reason right under the master switch, and the btProxyStatus command carries it for remote diagnosis.

## v2026.8.54 - 2026-08-18

### Fixed
- Exit application really exits now. The ESPHome server's foreground service, which runs whenever ESPHome is enabled, was missing from the shutdown sequence of a deliberate quit: Android revived the sticky service moments after the process ended, the revival read as a crash, and the crash recovery relaunched the app the user had just closed.
- The encryption key appears the moment it is generated. Enabling ESPHome generates the key a moment after the toggle flips, which was after the settings page had already redrawn, so the key row kept showing its placeholder until the next unrelated tap and the page read as if enabling had done nothing. Both the device page and the remote admin now refresh the row as soon as the key lands.

### Changed
- The foreground notification says what is actually running: "ESPHome active", with "Serving Home Assistant" or "Serving Home Assistant and relaying Bluetooth devices" depending on whether the Bluetooth proxy is on, instead of always claiming to be a Bluetooth proxy. The notification channel is renamed to ESPHome accordingly.

## v2026.8.53 - 2026-08-18

### Added
- The Bluetooth device-connection budget is visible before it surprises anyone: a "Bluetooth connections" diagnostic sensor on the ESPHome device shows "1 of 3" style usage, and a hint under "Allow device connections" on the settings pages states this kiosk's limit (two simultaneous connections on Android 11 and older, three on newer versions - a hard Android stack limit per proxy; Home Assistant routes further devices through other proxies). ESPHome, the Bluetooth proxy and device connections all now ship off by default, each an explicit opt-in, and entities are their own opt-in: "Expose kiosk entities" under ESPHome is off by default, so a household with MQTT enabled can turn on ESPHome just for the Bluetooth proxy without waking up to a duplicate entity set, and flips the switch when ready to migrate.
- The full MQTT entity catalog is now served natively over ESPHome: the Screen light with brightness, the Screensaver active switch, Volume plus Assistant, Media and Screensaver brightness sliders, every action button (postpone, reload, go to dashboard, clear cache, restart, bring to front, open launcher, close camera view, take snapshot, take screenshot), the Camera view and Dashboard view selects with their live option lists, the settings switches (Kiosk, Lockdown, HA kiosk, Keep screen on, Remote management, Screensaver and its brightness and motion detection, Camera enabled), the Screensaver mode and Clock style selects, the Clock background text, the Update entity with install-from-HA, a real camera entity streaming JPEG frames over the ESPHome image protocol, and the whole diagnostic set (battery, charging, CPU usage and temperature, RAM, current page, foreground app, nearby Bluetooth count, device, IPv4/IPv6, uptimes, ambient light, motion, next alarm, remote admin URL). Names mirror the MQTT entities so a migrating automation only swaps the device half of the id, and the per-view "Show ..." camera buttons, the Connectivity and Last seen sensors and the timestamp-style uptime sensors carry over too. One deliberate difference: the ESPHome camera protocol allows exactly one camera per device, so the kiosk serves its device camera when present and enabled, else the screenshot camera; a disconnected kiosk shows Connectivity as unavailable rather than off, since a lost connection takes every entity with it.
- The kiosk is now a native ESPHome device, the integration path going forward and the first step in sunsetting the MQTT broker requirement: one "Enable ESPHome" switch serves the kiosk's sensors and controls to Home Assistant as native entities over the automatically discovered ESPHome device, no broker, no custom integration, one pasted key. The starter set covers a Screensaver switch, a Screen brightness slider, a Reload dashboard button, and Battery, Charging, Uptime and IP address diagnostics; commands run through the exact same handlers the MQTT entities use, and states echo back from the device's real events rather than optimistic assumptions, so Home Assistant always shows what actually happened. The rest of the MQTT catalog ships in this same release; until MQTT is switched off the entities exist twice, once per integration, with Home Assistant suffixing whichever registered second, so automations can move over at their own pace. The settings page is reorganized to match: the Bluetooth Proxy page is now the ESPHome page, wearing the ESPHome mark, opening with the general settings (Enable, Encryption key, API port) followed by a Bluetooth Proxy section carrying the proxy toggles, its permissions and the Nearby devices list; the Bluetooth proxy is now a subsystem of the ESPHome device, existing proxy setups migrate to the new master switch automatically, and a Bluetooth-off adapter now grays only the Bluetooth section of the page while the entity server keeps running.

### Fixed
- Chimes and TTS now survive a broken hardware audio decoder. On a device whose vendor codec service has crashed, every hardware MP3 decode dies the moment it starts, which left the assistant answering visually in total silence. A sound that fails this way is now retried once on the device's software decoders, which run inside the app and keep working when the vendor service is down, and a chime whose first decode hits the broken codec is no longer blacklisted from the fast clip path for the rest of the session.

### Added
- Camera views can now play sound. "Play sound for a single camera", off by default under Camera Streams, then Playback, plays a camera's audio whenever it is the only one on screen: a view with a single camera, the camera focused with a tap in a larger view, or the camera screensaver showing a one-camera view, which is the baby-monitor setup the feature was asked for. Grids with several cameras always stay silent, and the audio track is only negotiated at all while the setting is on, so nothing changes for existing views. Works over both WebRTC and MSE; the camera needs to publish an audio codec the device can play, AAC and Opus being the safe choices.

### Fixed
- Picking a large photo set for the Photo Gallery screensaver no longer fails silently. Hundreds of photos, cloud-backed Google Photos items among them, take the picker a long while to hand over after DONE, and a single item that failed to copy aborted the whole batch without a word, after the previous selection had already been deleted. The wait is now covered by a progress dialog, the new set only replaces the old one once every photo has been copied so a failure keeps the previous selection intact, and an error shows a message instead of nothing happening.
- HA Kiosk Mode no longer leaves a black bar at the bottom of panel views. Cards that fill a panel view, the advanced camera card among them, size themselves against the header height Home Assistant publishes, honoring the zero override the kiosk-mode plugin used to declare when it hid the header; the built-in kiosk mode now declares the same override, so a full-screen camera panel really fills the screen. The hidden header's slot also keeps the display cutout inset it used to absorb, so on a notched screen the dashboard is not pushed under the cutout.

### Added
- The Bluetooth proxy settings now carry a "Minimum signal for connections" floor: with several proxies in the house, a kiosk refuses connection requests for devices it last heard below the chosen signal level, so Home Assistant immediately fails over to a closer proxy instead of a distant kiosk winning a link it cannot hold while its occupied slot blocks the proxy that could. Devices the kiosk has never heard always pass, so pairing flows keep working. The Bluetooth Proxy settings page and remote admin tab also now gray themselves out under a notice whenever the device's Bluetooth adapter is off, and clear the moment it returns.

### Fixed
- Bluetooth proxy GATT reconnections with a warm Home Assistant services cache no longer fail forever. A cached reconnect skipped service discovery entirely, leaving the connection's operation routing empty, so every read, write and subscribe on it failed instantly; since Home Assistant caches a device's services after the first session, the first reconnect after any drop entered a connect-fail loop that never converged. Discovery now always runs, cache or no cache. A connection torn down mid-handshake could also leak the scan pause that connect windows hold, leaving the scanner permanently stopped (still proxying its active connections, silent for everything else) until an app restart; the pause is now owned by the connection and released exactly once however the connection ends. Turning Bluetooth off mid-flight is also handled deterministically now: the proxy immediately closes every held GATT link and tells Home Assistant, instead of leaving the outcome to whichever callbacks the OEM stack feels like delivering, and scanning plus connections resume on their own when the adapter returns, with no app restart needed.

### Added
- The Bluetooth proxy now carries active GATT connections, not just advertisements: Home Assistant can connect to locks, buttons, curtain motors and anything else it controls over Bluetooth through the kiosk, including pairing, unpairing and device cache management, exactly as it would through an ESP32 proxy. "Allow device connections" under Bluetooth Proxy can be switched off to return the proxy to advertisement-only, with Home Assistant told either way. The connection budget is honest (two concurrent links on Android 11 and older, three on newer devices) and advertised to Home Assistant so it routes extra devices through another proxy; connecting pauses scanning for the handshake since both fight over the same radio, the one routine Android connect failure is retried once, a device that keeps failing goes on a doubling cooldown instead of being hammered, every disconnect is watchdogged so a connection slot can never leak, a connection only reports ready after its services are freshly discovered so Home Assistant never caches an empty service table, and the remote admin's btProxyStatus command lists the active connections.

### Fixed
- The Bluetooth proxy's scan retry backoff now escalates properly through repeated failures. Android reports a scan as started and only fails it a moment later, so the failure counter was being reset before the failure arrived and every retry ran at the shortest delay; the counter now resets on the first delivered scan result instead, the only real proof a scan is running. Found live on an Echo Show 8 whose adapter was mid-startup.

### Added
- The Bluetooth Proxy settings page now lists the devices the kiosk has heard in the last ten minutes, identified as far as the radio allows: the name a device broadcasts where there is one, otherwise its class read from the advertisement itself (a BTHome sensor, an Apple Find My device, a Windows PC, a Govee light), otherwise its manufacturer. Devices hiding behind rotating private addresses are marked as such rather than pretending to be trackable. The same list reaches Home Assistant as a per-kiosk "Bluetooth devices nearby" diagnostic sensor, the count as its state and the identified list as attributes, so a dashboard can show what each room hears. An optional "Look up device manufacturers online" toggle, off by default, names the remaining unknowns by their hardware address prefix via api.macvendors.com; only the 3-byte manufacturer prefix is sent, once per manufacturer ever, cached on the device from then on, and the advertisement relay to Home Assistant carries exactly what was received either way. The list sorts by last seen, name, MAC address or signal strength, each row's signal strength wears a green, yellow or red tag (same room, adjacent room, edge of range), devices Home Assistant is actively connected to through this kiosk are pinned to the top with a Connected tag and never expire from the list while the link lasts, and right under the master switch the page carries the same "Required system permissions" group the other features use, with the Nearby devices grant a tap away; the grant also has its row in the Device page's Permissions Manager.
- The kiosk can now act as a Bluetooth proxy for Home Assistant, relaying BLE advertisements from nearby devices (BTHome sensors, thermometers, iBeacons, plant sensors and anything else Home Assistant's Bluetooth integration understands) exactly like an ESPHome Bluetooth proxy, with no ESP32 and no custom integration: Home Assistant discovers the kiosk through its own ESPHome integration and asks for the encryption key the kiosk shows in its settings. Every kiosk becomes a Bluetooth coverage point in its room, and several of them form a mesh on their own, since Home Assistant merges its Bluetooth sources and listens through whichever proxy hears a device best. The proxy is advertisement-only by design and says so to Home Assistant, so no lock or switch ever gets an active connection routed through a path that cannot carry one. Scanning is built to survive what Android does to long-running scans: a watchdog restarts a silently stalled scanner, a Bluetooth toggle or stack crash suspends the proxy and it resumes the moment the adapter returns, restarts are budgeted under Android's own scan-start throttle, the screen turning off does not stop it, and a half-open connection left by a Home Assistant restart is noticed and cleaned up within seconds. On a device whose Bluetooth hardware is genuinely broken the scanner reports itself failed to Home Assistant instead of pretending, and the new `btProxyStatus` remote command shows the proxy's state, counters and recent log end to end.

## v2026.8.52 - 2026-08-16

### Added
- The Immich screensaver can now show two portrait photos side by side, filling a landscape screen with photos instead of leaving most of it to the blurred backdrop behind a single portrait shot. "Pair portrait photos" is on by default: each portrait photo reaches ahead for the next portrait photo in the playlist, wherever it sits, and the two share the screen half each and hold together as one slide, so portrait shots scattered between landscape ones are paired rather than left to whatever happens to follow them. Nothing is shown twice or skipped, only reordered, and turning the setting off gives every photo the screen to itself as before. Square photos and videos never pair, and a portrait screen does not either, since two halves of it would be slivers. With the metadata overlay on, a pair carries the left photo's details in the bottom-left corner and the right photo's in the bottom-right, and any corner widget in those two spots hides for as long as the pair is on screen so nothing sits on top of them. Metadata in a right-hand corner now also puts its icons on the right of the text, as the weather widget does, instead of hanging them off the inner edge.

### Fixed
- The photo screensavers now judge a photo's shape by how it will actually appear. A phone photographing in portrait usually stores a landscape frame plus an orientation tag, and only the frame was being measured, so those photos were treated as landscape: "Fill the screen" cropped them as though they matched the panel, and the new portrait pairing passed them over. The orientation tag is now read as well, on the device and from the Immich server's own metadata.

## v2026.8.51 - 2026-08-16

### Fixed
- The dashboard no longer stops loading with "ERR_RESPONSE_HEADERS_TOO_BIG" after the app has been running for a while, on an installation using the secure context proxy. Every response the proxy passed back to the page left a copy of two of Home Assistant's headers behind in the proxy's own defaults, so each page load carried a slightly larger header block than the one before it, and once it passed the browser's quarter megabyte limit nothing on that Home Assistant would load until the app was restarted. Responses now carry exactly the headers Home Assistant sent, and nothing accumulates.
- The secure context proxy no longer sends a body with a response that cannot have one. Home Assistant answers an unchanged dashboard file with an empty "not modified" reply, which the proxy forwarded with an empty body attached to it; the browser, knowing the reply has no body, left those few bytes in the connection and read them as the start of the next reply on it, which is a page load that fails for no visible reason.

## v2026.8.50 - 2026-08-16

### Fixed
- The dashboard now keeps running while the app is behind another app. Chromium suspends a page whose window is not on screen, which on a tablet took about a minute: with the page stopped, nothing answered Home Assistant's connection heartbeat, the server dropped the connection, and everything riding it went unavailable until someone brought the kiosk back to the front. Voice Satellite's entities were the visible half of that, going unavailable a minute after the app was sent to the background and returning when it came forward. The dashboard's window is now reported as on screen for as long as the app is alive, so the connection, the timers and anything playing carry on. Pausing the dashboard under the screensaver is unaffected and still stops it drawing.

## v2026.8.49 - 2026-08-16

### Changed
- HA kiosk mode now hides the Home Assistant header and sidebar entirely on its own, and no longer has anything to do with the kiosk-mode custom resource. Handing the job to that resource carried a cost that only showed up on a wall tablet: it receives every entity change in your instance to decide what its own options apply to, and Home Assistant disconnects a client that falls behind reading a stream that size, which on a tablet left alone reads as a dashboard that quietly stopped updating. So the setting is now a plain switch, the Off, Auto, Plugin and CSS choice is gone, and a device that had any of the three on comes back with kiosk mode on. The "HA kiosk method" dropdown in Home Assistant disappears with it, while the "HA kiosk mode" switch stays. Hiding the header and hiding the sidebar remain separate choices, both applying the moment they are flipped, with no page reload.
- HA kiosk mode now also applies to Home Assistant pages shown outside the dashboard: a page opened from a dashboard link, a page in the dashboard rotation, and a Home Assistant page set as the website screensaver. A wall clock dashboard put on the screensaver used to arrive with the header and sidebar over it, and there was no way to hide them. It follows the same switch and the same two hide choices the dashboard uses, applies the moment they are flipped, and never touches a page that is not from your own Home Assistant.
- Voice Satellite no longer starts on Home Assistant pages shown outside the dashboard. It runs per page rather than per card, so a Home Assistant page set as the website screensaver, opened from a link, or shown by the dashboard rotation brought up its own microphone and registered as the same satellite the dashboard was already answering as, with a stray mic button over the page as the visible half of it. The dashboard stays the satellite; those pages are displays. A Voice Satellite card placed on such a page by hand still works, since that is a card somebody put there on purpose.
- A Home Assistant page set as the website screensaver no longer shows as a black screen while "Pause dashboard rendering" is on. Pausing hides the dashboard's view by its address, and a screensaver page from that same Home Assistant looks like the dashboard from there, so both were hidden and nothing was left to see. The dashboard is left rendering in that one case, which is also what happens when a page from the same Home Assistant is opened over it.
- A hidden Home Assistant sidebar now stays hidden. The edge swipe and the menu button both opened it back up, which on a wall panel is a stray thumb away from leaving the sidebar sitting over the dashboard.
- The WebSocket filter's telemetry now says when something else on the page is receiving every entity change on its own, in the settings and in the remote admin alike. Some cards subscribe to the whole entity stream separately and sort it out in the browser, which the filter cannot see or reduce, and that stream is heavy enough that Home Assistant will disconnect a tablet that falls behind reading it. Knowing a page does this is the difference between a filter that looks broken and one that is doing all it can.
- Refreshing the page after the filter is lifted, which happens when you leave a dashboard for a page whose entities cannot be determined, now goes out in batches instead of one piece. On a large instance that was a single burst of every entity in the system, and for as long as the browser spent rebuilding from it the page stopped reading its connection, which is one of the ways a tablet falls behind far enough for Home Assistant to drop it.

### Fixed
- A dashboard that lost its connection to Home Assistant is now brought back on its own, instead of sitting on Home Assistant's "Connection lost. Reconnecting..." screen until someone walks up to the tablet. Every recovery the app had was triggered by something happening: the network coming back, the app returning from the background, a wake word about to need the connection. A wall panel that is never backgrounded, on a network that never drops, produces none of those, so a connection that died for its own reasons had nothing at all coming for it, and the fault stayed hidden behind the screensaver for as long as the tablet was left alone. Home Assistant does not always retry on its own either: it holds off reconnecting for as long as it believes the page is in the background, so a connection that drops at the wrong moment is never retried at all. The dashboard's connection is now checked every minute, and one that has been down for three checks in a row is released and reconnected, with a reload as the last resort if that does not take. The app also hears the connection close as it happens, so a dashboard that is not allowed to reconnect is released about ten seconds later rather than at the next check. The reload follows the "Auto-reload on error" setting and happens at most once every fifteen minutes, so a tablet left running while Home Assistant is down does not reload all night.
- Pausing the dashboard under the screensaver no longer tells the page it went to the background. Pausing works by hiding the dashboard's view, and the browser reports that to the page exactly as it reports the app being sent behind another app, so web apps tore their session down over an optimization they could not see: Voice Satellite released the microphone and rebuilt its wake word every time the screensaver came up, and Home Assistant's own background throttling applied under it. The page now keeps being told it is visible for as long as the pause is the app's own doing, and hears nothing when the screensaver comes and goes. Being genuinely in the background, behind another app, still reaches the page as before.

## v2026.8.48 - 2026-08-15

### Added
- Each entry of a scheduled screensaver now carries "Widgets" and "At a glance" overrides alongside the brightness and motion ones, so the corner widgets and the glance row can show by day and stay off overnight without unconfiguring them twice a day. Default leaves their own settings in charge, On shows them and Off withholds them for that entry's hours, and a boundary between two entries applies live under a showing screensaver. An entry set to On loads the glance row's entities even when the row's own switch is off, so a day entry can carry it while the rest of the day does not.
- An "Inject JavaScript on external pages" field under Browser runs your JavaScript after every load of a page that is not the dashboard: a site opened by a dashboard link or a tap action, a dashboard rotation page, and the website screensaver. These pages live in their own WebView, which the existing injection field never reached, so a site that renders too small on a wall tablet had no way to be adjusted; setting `document.documentElement.style.zoom` from here is the way to zoom one. The Music Assistant page is deliberately left out, since it is the app's own shortcut rather than a site you brought in.

### Changed
- Scheduled screensaver times are now edited in a dialog instead of inline. Each entry shows as one row naming its time, its screensaver and only the overrides it actually sets, and opens on a tap; the six controls an entry now carries never fit on one line, on a phone or in the remote admin.
- The Kiosk Satellite mark in the remote admin now goes back to Overview when clicked, in the side rail and in the phone top bar alike.
- The existing "Inject JavaScript" field is now called "Inject JavaScript on the HA dashboard", naming the one page it has always run on. Nothing about its behavior changed and whatever is in it stays there.
- Home Assistant pages opened outside the dashboard now sign in with the session the dashboard already holds, instead of showing the login form. This is what a Home Assistant page set as the website screensaver used to do, where the form could not even be answered because the first touch dismisses the screensaver, and it also affected links and rotation pages whenever their address did not match the dashboard's origin exactly, which is always the case with the secure context proxy on. The session is only ever handed to your own Home Assistant, matched against the configured base URL and the dashboard's own origin, and it never replaces a session the page already has.

## v2026.8.47 - 2026-08-15

### Improvements
- The default tap sound volume is now 50%, which by ear matches the loudness of the app's own interface clicks on every device tried. A slider that was already moved keeps its value.

### Fixed
- The tap sound now plays the same click the device's own interface makes on every brand of firmware. Which audio file the standard tap sound is belongs to the manufacturer, so on devices that customize it the dashboard clicked differently from the rest of the device. The tap now goes through the same system sound call the rest of the interface uses, which honors the manufacturer's mapping and any active sound theme with no file names involved, still at the volume the slider sets and unaffected by the system's own "touch sounds" toggle. Firmware that keeps its interface sounds where the system player cannot find them, where that call would play nothing, keeps the previous behavior of loading the sound file directly.

## v2026.8.46 - 2026-08-15

### Added
- A "Tap sound volume" slider under Home Assistant Configuration > Haptics sets how loud the tap sound plays, defaulting to 25%. Android never plays its own touch sounds at full sample volume; it attenuates them by a per-device amount, so the initial full-scale playback landed much louder than the clicks of the app's own interface. The slider is read per tap, so a change applies to the very next touch, and slider-step ticks keep their fixed fraction of whatever it says.

## v2026.8.45 - 2026-08-15

### Added
- A "Play tap sounds" toggle under Home Assistant Configuration > Haptics, on by default, plays the standard Android tap sound when a button, switch, chip, card or slider is used on the dashboard, matching the click the app's own interface already makes. Button taps get the full click and slider steps a quieter one, riding the same in-page tap detection as the vibration feedback. The sample is the platform's own touch-sound click played through the app's own audio path at the system sound volume, so the system's separate "touch sounds" setting cannot silently veto it, and it works alongside or independently of the vibration toggle.

### Fixed
- Haptics and tap sounds now fire for tile cards, chips, scene buttons and every other card activated through a tap action on a touch screen. Home Assistant runs tap actions from the touch gesture itself and suppresses the click event that would normally follow, so the feedback only triggered for plain buttons and controls; the detector now also listens for the activation event the frontend emits for the whole tap_action family, and the existing throttle keeps mouse input from producing doubled feedback.

## v2026.8.44 - 2026-08-15

### Fixed
- The Immich screensaver's "Validate connection" now also fetches one preview, so an API key missing Immich's `asset.view` permission fails at the button naming the missing scope instead of passing validation and then failing every image at night. Immich separates viewing previews (`asset.view`) from downloading originals (`asset.download`), and validation previously only exercised album listing and asset search. The screensaver's error message now distinguishes an answering-but-refusing server from an unreachable one: a 401/403 reads as a rejected or under-permissioned API key while "Could not reach the Immich server" is reserved for genuine transport failures, and every failing Immich call is logged with its endpoint and HTTP status so the cause is visible from the app's own logs. The docs now name the three permissions a restricted key needs.
- The remote API's raw settings import no longer clones the source device's identity when asked not to. `POST /api/settings/import` used to apply a settings dump verbatim, so provisioning a second device from another's export carried the Sendspin player id along and the two devices kicked each other off Music Assistant in an endless reconnect loop, bypassing the identity handling the config import flow gained earlier. The endpoint now takes the same `adoptIdentity` query parameter as `/api/config/import`: pass `0` when cloning a device and it keeps its own device name, MQTT device id, Sendspin player id and Voice Satellite selection, shedding any of them it had already inherited from an earlier verbatim import so the ids regenerate cleanly.

## v2026.8.43 - 2026-08-14

### Added
- A Connectivity binary sensor per device: on while the device holds its broker session, off the moment the broker's last will fires after a hard death or the app disconnects gracefully. It is the existing availability signal reread as a state, so it adds no MQTT traffic at all, stays readable (and off) while the device is gone instead of going unavailable, and gives automations a stable "device went offline" trigger plus a plottable online/offline history timeline.

### Improvements
- The App uptime, Network uptime and Last seen sensors no longer write a recorder row every minute. The uptime pair now publishes the moment the app or the network came up as a timestamp entity, which Home Assistant renders as a live "n hours ago" on its own, so the state only changes when a restart or reconnect actually happens; upgraded devices re-register the two entities automatically. Last seen is now stamped once per broker connect and once more on a graceful disconnect instead of every minute; after a hard death the moment of the drop is the availability transition Home Assistant already records on every entity.

### Fixed
- Changing the Home Assistant base URL now updates the stored dashboard start URL along with it. The dashboard picker stores an absolute URL built from the base URL at pick time, so a device first set up over an IP address kept loading the dashboard from that IP forever after the base URL moved to a domain, and every URL the page derives from its own address (wake word model downloads, TTS playback) kept the old host too. When the base URL changes, a start URL sitting on the old origin now follows it to the new one and the dashboard reloads there; a start URL pointing at some other site is left alone.

## v2026.8.42 - 2026-08-14

### Fixed
- The "Ignore SSL errors" setting is now honored by the app's own network requests, not just the browser. Wake word model downloads, native TTS and sound playback, and other in-app requests used to fail with a certificate error when the URL pointed at a host other than the configured Home Assistant base URL, such as the server's IP address while the certificate only matches its domain. With the setting enabled those requests now accept the certificate exactly like the dashboard browser does.

## v2026.8.41 - 2026-08-14

### Added
- The At a Glance row can now join the full-screen Now Playing view. A new "Show on Now Playing" toggle in the At a Glance group, off by default, pins the configured entities to the bottom of the screen while music plays, with the album art panel shrinking slightly and riding a little higher so both fit even on short screens like the Echo Show. The row stays hidden while lyrics are showing, since those layouts already use every free pixel, and entity states stay live for the whole session over the same lightweight subscription the screensaver row uses.
- Five new diagnostic MQTT sensors expose the rest of the remote admin's Device > Hardware data to Home Assistant. A Device sensor carries the device model as its state with the Android version and OEM build in attributes. IPv4 address and IPv6 address sensors report the primary address as the state, every other address in an `other_addresses` attribute, and all of them keyed by network interface in an `interfaces` attribute, so a script can tell a wired connection from a wireless one; addresses are re-checked once a minute and moments after any network change. App uptime and Network uptime sensors publish seconds since the app started and since the device's network came up, so a dashboard can highlight a kiosk that recently restarted or dropped offline; network uptime is read from the kernel's own timestamp on the interface's IP address, so it survives app restarts and only resets when the device actually reconnects or gets a new address (with a clock anchored at app start as the fallback on ROMs that refuse the read), and it reads unknown while the device is offline.

### Fixed
- The Dashboard view select entity no longer loses its view options after a Home Assistant restart or network flap. If the periodic option refresh happened to run while the app's Home Assistant websocket was down, every dashboard's view list read failed and the select's options collapsed to bare dashboard paths, which was then persisted and republished to MQTT discovery, leaving the device's retained "dashboard/view" state invalid in Home Assistant ("Invalid option for select"). A failed view list read now keeps the last known option list instead of downgrading it.
- Commanding the Dashboard view select no longer reports the requested view as current when the page never actually moved (a non Home Assistant page on screen, or a navigation failure). The app log now also says why the page did not move instead of staying silent.

## v2026.8.40 - 2026-08-14

### Added
- A new Haptics group under Home Assistant Configuration with an "Enable haptics" toggle, on by default: the vibration motor gives a short native click whenever a tap lands on a button, switch, chip or tap-action card in the dashboard, and a softer tick for every step crossed while dragging a slider or the thermostat card's temperature wheel, so a wall panel answers like a physical switch and a brightness drag feels like a detented knob. Custom card sliders (Mushroom included) tick too, even though their events never leave the card. A "Vibration strength" selector (Light, Medium, Strong) appears alongside while the toggle is on, with slider ticks always sitting one level softer than button clicks. The detection runs entirely on tap and value events inside the page (no polling, no observers, no layout reads), the buzz is the platform's own tuned click effect driven directly through the vibrator so the system's separate touch-vibration setting cannot silently veto it, and devices without a vibration motor simply ignore the toggle. Every change applies immediately, no reload needed.

### Fixed
- The updater can no longer reinstall the release the device already runs when two consecutive release APKs happen to be byte-identical in size. The downloaded APK was cached under one fixed name and recognized by size alone, so with 2026.8.38 and 2026.8.39 coming out at exactly the same byte count, a device holding the older cached file "updated" by reinstalling it and came back up on the same version every time. The cache file now carries the release version in its name and anything else in the cache is swept before the check, so a leftover from an earlier release can never impersonate the new download.

## v2026.8.39 - 2026-08-14

### Improvements
- The Immich Media screensaver's metadata panel no longer blinks at each slide change. The whole panel (corner vignette and text) was torn down and rebuilt with every photo; the vignette now holds steady from photo to photo while the text fades out with the old slide and back in with the new one.
- Slideshow screensavers no longer fade through black between photos. The next image was downloaded ahead of time but only decoded once the crossfade had already started, so on slower tablets the outgoing photo faded into the black backdrop and the new one popped in late. The image is now fully decoded before the hand-off begins, holding the current photo a moment longer instead, so the transition blends directly from one photo to the next. Applies to the Immich Media, Photo Gallery and Local Folder screensavers and every transition style.

## v2026.8.38 - 2026-08-13

### Added
- Wake word detection now prefers quantized int8 vsWakeWord models when Voice Satellite serves them, falling back to the original fp32 files automatically on servers without an int8 build. Inference drops from 8.6ms to 5.9ms per window on an Echo Show 8, cutting listening CPU by 10-30% depending on how busy the device is; the manifest, thresholds and detection gates are unchanged, and the quantization was validated against the standard wake-word benchmark suite on three wake words with recall identical on every positive set and false-positive deltas within a single borderline clip. A new "Prefer fp32 vsWakeWord models" toggle opts back into full precision, and both settings UIs gained a Model precision row in the Wake word panel stating which variant is actually loaded.

## v2026.8.37 - 2026-08-13

### Added
- The crash record now also covers deliberate process restarts. The frame watchdog's recovery restart (and a restart asked for from the kiosk menu, the remote admin or MQTT) kills the process without any exception, so it left no trace: after the restart it was indistinguishable from a crash, with an empty record where the answer should be. Such restarts now write their reason into the same record the crash trace uses, so the Logs screen says plainly whether the last abnormal end was a crash with a stack or the watchdog reacting to a wedged screen, and what wedged it.

### Improvements
- The Charging entity now updates the moment the cable changes. It rode the once-a-minute MQTT stats poll, so a plug or unplug could take up to a minute to reach Home Assistant; the app now listens for the system's battery broadcasts, re-reads the plugged flag on each, and pushes the flip immediately. The minute poll stays as the backstop.

## v2026.8.36 - 2026-08-13

### Fixed
- MQTT no longer amplifies a dropped connection into repeated ones when the device camera is enabled. Three hardenings: a camera frame larger than the packet size the broker advertised (MQTT 5) is now skipped with a log line instead of sent, since brokers answer an oversize publish by dropping the whole connection; the fresh camera frame taken at connect time is throttled to once per five minutes across reconnects, so a snapshot publish that kills the link can no longer re-kill every reconnect; and a connect attempt that fails or times out is now fully disarmed, where before it could complete in the background as a ghost session that fights the replacement link over the client id, with the broker kicking whichever connected last, forever.
- The camera exposure-hunt fallback now refuses to restart into a faster frame rate than the one it is escaping (fourth round). The fallback prefers the lowest pinned frame rate the sensor offers, but on sensors whose only pinned rate is the full one, "falling back" meant restarting into the full-rate camera pipeline, the very cost the affected hardware cannot pay; the reporter's tablet stayed cheap for a minute and then jumped to 100% CPU at exactly that restart. A pinned rate is now used only when its ceiling is no higher than the slow range's; otherwise the slow range stays and the fallback only stops watching for hunts.
- The Charging entity no longer sticks at "Charging" on devices whose kernel misreports the battery status (a Fire 7 on LineageOS). Charging (MQTT, the remote admin header and `/api/health` alike) is now read from the charger's own plugged flag rather than the battery status, with the status kept only as a fallback; the meaning stays "external power connected", so a docked kiosk holding at 100% still reads as charging.

### Added
- At a Glance entities can be renamed. Each chosen entity in the picker (device settings and remote admin alike) now has an Edit action opening one dialog with the entity's name and its displayed value; a custom name replaces the Home Assistant name on the screensaver row, and clearing the field goes back to following Home Assistant. Handy where the registry name is a mouthful ("Garage Door Left Side") and the row only needs "Garage".

## v2026.8.35 - 2026-08-13

### Improvements
- Clap detection now requires sequences to look deliberate: claps must come out of a calm moment, keep an even rhythm, and stay at one loudness (prompted by false triggers from a child playing with toys near the device). Ordinary clatter shares a clap's impulse shape but rarely its regularity. A new **Clap detection** setting on the Gestures page (both UIs) adds a Strict mode that tightens all three checks and wants louder claps, for homes where the standard checks still misfire.
- The rotation fade is smoother (reporter feedback). The dissolve that blended the outgoing and incoming views could not hide its mechanics on real dashboards: transparent card regions, the final view swap and mid-fade re-renders all read as steps. Rotation now fades the screen out to the theme's background color, switches views while covered, and fades back in once the new view has rendered, on longer and gentler legs; first visits simply build behind the cover, needing none of the previous pre-building. The toggle is now called **Fade between views**; its stored setting carries over.

### Added
- Crashes are now remembered across the restart that follows them. Android's own crash log rotates within minutes on a busy device, so by the time anyone copies logs after the app has come back, the actual crash trace is usually gone; every crash report so far has started with that dance. The app now writes the full trace to its own storage at the moment of the crash, and the next start surfaces it at the top of the app log, marked "a previous run crashed", where the Logs screen and the remote admin already look. The record keeps until the next crash replaces it, so a report filed days later still carries the trace.

### Fixed
- The remote admin no longer lets grant buttons overlap their status text on narrow screens. On phone-width viewports every control in a settings row was placed into the same layout slot, so rows carrying both a status ("Not granted") and a button ("Grant on device") painted them on top of each other; controls now sit side by side and wrap below the row's name when there is no room. The same fix covers the brightness slider's value and the permission notice rows, which overlapped the same way.

## v2026.8.34 - 2026-08-12

### Changed
- The **Default brightness** slider in Screen & Audio now goes down to 0% instead of 5%.

## v2026.8.33 - 2026-08-12

### Added
- Voice turns now run their transport natively. Until now the app streamed every microphone chunk into the dashboard page, which decoded it and re-sent it to Home Assistant over its own connection; on weak tablets that round trip competes with the page's rendering for the same main thread, so speech delivery stuttered exactly when the page did. The app now subscribes the assist pipeline run on its own authenticated websocket and uploads the audio directly, so during a voice turn no audio touches the page at all and speech recognition stays steady however busy the dashboard is. The overlay, chimes, wake behavior and every Voice Satellite setting work exactly as before, the reactive bar included (it animates to levels the app computes with the same speech weighting the page used). Like the wake-word handoff, this negotiates itself: a Voice Satellite release that knows the new transport uses it, an older one keeps working exactly as before, and any failure falls back to the page path mid-flight. Nothing to configure; a read-only **Native voice pipeline** row in the Wake word group (device settings and remote admin alike) shows Supported or Not supported, so it is easy to tell whether the installed Voice Satellite version takes advantage of it.

## v2026.8.32 - 2026-08-12

### Added
- A **Foreground app** sensor joins the MQTT device's diagnostics: which app is on the device's screen, the app's package name as the state (stable across languages and renames, so automations match on it safely) and its human-readable name in a `label` attribute, so an automation can notice the kiosk left behind another app and, say, bring it back after a couple of minutes. It updates within a few seconds of an app opening over the kiosk or the kiosk returning, and once a minute otherwise. Identifying other apps needs Android's **Usage access** grant, which gets its own row in the Permissions Manager in the device settings and the remote admin alike; without it the sensor still reports the kiosk's own package while the kiosk is frontmost, and unknown when it is not.

### Fixed
- The rotation crossfade no longer lets the outgoing view linger behind transparent parts of the incoming one. Card gaps and cards with transparent backgrounds showed the old view at full opacity through the fade, and that leftover content blinked out the moment the views swapped; the outgoing view now fades down beneath the incoming one on a slight stagger, so those regions dissolve to the dashboard background instead.
- Devices without any camera hardware no longer burn CPU retrying a camera service that does not exist. The camera library the app moved to in v2026.8.20 keeps a persistent watch on the platform's camera service once it initializes, and on hardware whose ROM ships no camera service at all (e-ink tablets, some LineageOS ports) that watch makes Android retry the missing service every second, forever, spamming the log and pegging a weak processor. The camera features now ask the lower-level camera API first, and on a device that enumerates no cameras the camera library is simply never started: the camera settings surfaces say plainly that no camera is available, and nothing retries anything.

## v2026.8.31 - 2026-08-12

### Added
- The Screensaver settings gain a Widgets group: small corner overlays added by picking a corner and a widget type, each widget carrying its own settings. The small clock is the first type (color, 24-hour format, date, one widget per corner, up to four), an already configured small clock migrates into a clock widget automatically with its corner and settings intact, and the group is edited the same way in the on-device settings and the remote admin. A Widget scaling slider (50 to 150 percent) sizes every widget for the screen, previewing live while the screensaver shows. The corner vignettes behind the overlays are darker, so widgets stay readable on bright daylight photos, and the Immich metadata overlay steps to the first free corner when a widget claims its spot instead of stacking onto it.
- Dashboard view rotation can now crossfade between views. An opt-in Crossfade between views toggle in the Dashboard View Rotation settings, in the device settings and the remote admin alike, makes each rotation step dissolve the current view into the next instead of cutting. The dissolve happens inside the page, riding the same view cache the dashboard carousel uses, so a view fades in fully rendered with fresh entity states; a view the rotation has never shown is built invisibly over the current view first and given a moment to render, so even the first pass through the ring dissolves. Moving to a different dashboard or an external page still switches instantly, since nothing of the two pages ever coexists to fade between.
- A Weather widget joins the Widgets group: pick a Home Assistant weather entity and a corner, and the screensaver (every mode including Clock, except WebRTC Camera) shows the location, a large temperature with its unit, the forecast with a matching icon, and optional humidity, wind speed and visibility lines. Every line except the temperature has its own toggle, lines the entity does not carry are left out automatically, the icons are monochrome and take the widget's color, and the readings stay live over a Home Assistant subscription while the screensaver shows. The location is named by hand (weather entities carry no city attribute); left empty, the line stays off.

### Fixed
- Rotation ticks landing right after an app start no longer mislabel ordinary dashboard views as hard loads. The rotation's strategy-dashboard discovery reads "no view rendered shortly after navigating" as "this path needs a full page load", but during the frontend's own boot no view is rendered for any path yet; a tick in that window taught the rotation to fully reload perfectly soft-navigable views on every pass for the rest of the session. The check now stands down for the first 15 seconds after a page load; a genuine strategy dashboard is still learned on its next pass.

## v2026.8.30 - 2026-08-12

### Fixed
- The camera exposure-hunt fallback no longer trades 9% CPU for 100% (third round). When a camera's auto exposure keeps hunting under the slow frame-rate request, the previous release restarted the camera with default exposure, and the reporter's Galaxy Tab S6 Lite revealed the flaw: on that hardware the camera pipeline at its full delivery rate is itself the 100% CPU, so the fallback re-created the very problem it was escaping (the hunt itself had been running at 9%). The fallback now steps down gently instead: a detected hunt restarts the camera at the lowest fixed frame rate the sensor offers, which stays as cheap as the slow range while removing the rate freedom the hunt oscillated in, and if even that hunts, the camera keeps the pinned rate and simply stops watching for hunts; default full-rate exposure never comes back.

## v2026.8.29 - 2026-08-12

### Fixed
- Voice Satellite no longer goes unavailable in Home Assistant while the screen is off. The screensaver's rendering freeze makes the dashboard page report itself hidden, and a hidden page inside an app with no screen turns out to be the combination that makes Android's WebView suspend the page's JavaScript timers and task queues outright, measured as a 50 millisecond timer that simply never fires. With its event loop stopped, the page's Home Assistant websocket could not answer keepalives or finish reconnects, so it died within a couple of minutes of the panel powering off and took Voice Satellite's availability with it; wake words kept working only because the wake path repairs the connection on its way in. The freeze now follows the panel: it lifts when the screen powers off, which costs nothing since a dark panel composites no frames, and returns the moment the screen does. Verified on an Echo Show 8: the assist satellite entity now stays available through dark spells that previously killed it inside three minutes.

### Changed
- The MQTT integration now speaks **MQTT 5**, and uses its will delay to end availability flapping for good. The keepalive tuning and Wi-Fi hold of v2026.8.28 help most devices, but some hardware (the Lenovo M10 Plus among them) cuts the connection outright on every screen-off radio nap, and no client-side tuning survives that: every cut fired the will and flapped the device's entities unavailable. Under MQTT 5 the broker now sits on the will for 90 seconds, so a device that reconnects within that window never shows offline at all, while one that stays gone is still marked offline honestly. Brokers that only speak MQTT 3.1.1 are detected automatically and served exactly as before; every current mosquitto, EMQX and the Home Assistant add-on speak MQTT 5.
- Enabling **Turn screen off after** now explains what it may cost first. Once the display truly powers off the manufacturer's power management takes over, and depending on the model that means Wi-Fi naps, unavailable entities, a revoked camera or the app being killed outright; the warning says so, in the device settings and the remote admin alike, and points at the Black screensaver as the reliable alternative that keeps the app in control with the panel just as dark.

## v2026.8.28 - 2026-08-11

### Fixed
- The Wi-Fi radio is now held awake while the screen is off. Minutes into a dark spell, OEM Wi-Fi power saving degrades the connection, and how that lands depends on the hardware: a Galaxy Tab S9 dropped it outright every ten to thirty minutes, while a Lenovo M10 Plus kept it up but delayed traffic long enough that the MQTT keepalive missed its answer every cycle, flapping the device's Home Assistant entities unavailable about once a minute, around the clock. Either way everything that makes a dark kiosk reachable suffered together: MQTT, the dashboard's websocket, remote sessions. The system's keep-Wi-Fi-on lock is now held by the keep-alive service for as long as it runs AND by the MQTT client while it is connected, so a device without background listening is covered too; in a 45-minute screen-off test that previously produced three drops, the connection did not blink once.
- The MQTT keepalive now tolerates one late answer before declaring the session dead. A single reply delayed past 30 seconds by a napping radio used to force a disconnect whose last-will flipped the device's entities unavailable, only for the automatic reconnect to bring them right back; the check now allows two ping cycles, so a slow radio no longer reads as a dead broker while a genuinely dead socket is still caught one cycle later.
- A network blip while the screen is off no longer queues up a dashboard reload that fires at the next wake. The network-return repair judged a long-hidden page by a liveness check the page could not pass: a hidden page's timers are heavily throttled, so its Home Assistant frontend cannot finish reconnecting inside the repair's window no matter how healthy the network is, and the resulting "dead" verdict reloaded a page nobody was looking at — the reload then sat pending under the paused view and committed the moment the screen came on. The repair now nudges the socket and defers the verdict until the page is visible and unthrottled again, where a genuinely broken page still gets its reload exactly as before.
- Waking the panel no longer rebuilds the dashboard. Every resume from the screensaver's screen-off (and any other background spell) force-reconnected the Home Assistant websocket as insurance against the half-open socket a long freeze can leave behind; the frontend answered with a connection-lost flash and every camera card tearing down and renegotiating its stream, which read as the page reloading itself moments after the screen came on. The insurance now checks before it acts: a ping goes through the frontend's connection first, and a socket that answers is provably alive and left untouched. Only a socket that stays silent (the half-open case the reconnect exists for) still gets cycled, so the recovery is exactly as reliable as before, it just stops paying its cost on healthy wakes.

## v2026.8.27 - 2026-08-11

### Fixed
- The **Show the Sendspin player** gesture now works after an app restart too. The Sendspin server announces nothing on connect about a queue that is not playing, so a Music Assistant queue paused before a restart was invisible to the app and the gesture had nothing to reveal, even though the queue sat there ready to resume. When the gesture fires with nothing to show, the app now asks Music Assistant directly for the player's active queue and brings it back as a paused card, with the artwork, track and position it left off at; play on that card resumes exactly where the queue stood. A queue that is already playing, or a server with no queue for this player, behaves as before.
- Camera motion detection now withdraws its long-exposure request when a camera's auto exposure cannot live with it (second round). Motion detection asks the camera for its slowest frame rate so dark rooms get longer exposures, but some vendor exposure loops never converge under that request; the Galaxy Tab S6 Lite's front camera oscillates exposure forever, and the endless hunt is what was pinning a core in the camera HAL even after the camera library rollback. The analyzer already sees the hunt plainly, as an unbroken run of global same-signed change with no local structure, so after about ten seconds of it the camera is restarted once with default exposure for the rest of the session. Healthy cameras, including every device the dark-room tuning was built on, keep the long exposures exactly as before.

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
- The Digital clock screensaver has a **Background color** setting. It was the one face with a hardcoded black backdrop; Flip and Roller already followed their card and background colors. A white background with a black clock color gives the inverted face e-ink panels read best. The At a Glance row now wears the clock's color on the Digital face too (it already followed the Flip and Roller digit colors), so the row stays readable instead of staying grey-on-white over a light backdrop.

### Fixed
- The File Manager's shared storage root now works before Android 11. "All files access" does not exist on those versions, and the app both reported the root as available when the OS would refuse to list it and offered no way to ask for the storage permission that actually gates it there. The root now reports its real state, the grant buttons ask with the normal Android storage dialog, and writing (delete, upload) works on Android 10 and earlier.
- The Permissions Manager (Settings > Device) now lists **All files access**, the settings-screen grant behind the File Manager's shared storage root. It was the one grant the app can use that the group did not show. Like Device admin it is never marked missing, because without it the File Manager still works on the app's own folder; the row appears in both the device settings and the remote admin, and granting opens the Android screen on the device like the rest.
- MSE camera tiles no longer grow a gray Cast button in their corner (seen on the Echo Show 8). Chromium overlays that button on any video playing from a media source once a castable device is visible on the network; a camera tile is not a castable movie, and now says so. WebRTC tiles never had it, which is why the icon only appeared on MSE streams.

## v2026.8.22 - 2026-08-10

### Fixed
- Camera motion detection now survives the screen turning truly off. Android revokes the camera from any app within seconds of the panel powering off (visibility, not process state, is what gates camera access), and until now the revocation was silent: the motion sensor looked alive in Home Assistant but saw nothing until the app was restarted. The camera session now reports the revocation and rebinds the moment the screen comes back on, and the same recovery covers the camera being taken by another app. The docs now also spell out the platform rule: no app can watch the camera while the panel is truly off; the Black screensaver (backlight at zero, everything running) is the screen-off that keeps motion detection alive.
- Updates now install on a pinned kiosk. Lock task pinning blocks Android's install confirmation screen outright, so pressing Install appeared to do nothing; the kiosk now stands down (unpins and drops its shields) right before an install that needs confirming, leaves the confirmation alone instead of reclaiming the foreground over it, and re-arms when the install is declined or fails. A confirmation nobody answers re-arms the protections on its own after ten minutes. A successful install re-arms on the relaunch as always.
- A declined or never-shown install no longer costs a second download: the downloaded APK is kept, recognized by the byte size GitHub reports for the release, and handed straight to the installer on the next attempt.

### Added
- Go2RTC cameras now **fall back to MSE when WebRTC cannot play them**. WebRTC stays first for its near-realtime latency, but a stream that connects and decodes nothing, a WebView with no WebRTC at all (Fire tablets), or repeated failed connections now switch the tile to MSE automatically instead of leaving it blank, with the switch recorded in the App Logs. A new **Prefer MSE over WebRTC** toggle (Camera settings, Playback; off by default) flips the order for devices known to lack WebRTC and doubles as the way to force MSE for testing; WebRTC then becomes the fallback. MSE sessions go through the app, so servers with a login or a self-signed certificate work the same as they do for WebRTC. WHEP and Home Assistant cameras are WebRTC by definition and are unaffected.
- A **Screenshot camera entity and a Take screenshot button** in Home Assistant, over MQTT like the rest of the device entities. Press the button and the entity shows what the device's display is showing at that moment: dashboard, screensaver, kiosk menu, whatever is actually on screen. Made for checking on a panel that is not in the same building without exposing the remote admin beyond Home Assistant. A **Last screenshot** timestamp sensor reports the frame's freshness, the frame is retained on the broker so it survives a Home Assistant restart, and captures are scaled to at most 1080p so a high-resolution panel never parks a multi-megabyte payload on the broker. Works on every device; no camera hardware involved.

## v2026.8.21 - 2026-08-10

### Fixed
- **Keep screen on** now takes effect after a device reboot. When the app starts at boot it comes up before its screen exists, the keep-awake flag cannot be set yet, and until now the failure was only logged, leaving the screen to time out until the setting was toggled by hand. The flag is now reapplied the moment the app reaches the foreground, which also restores it when the screen is rebuilt after a crash recovery.

## v2026.8.20 - 2026-08-10

### Fixed
- Camera motion detection no longer drives the CPU to 100% on some devices whose camera reports the LIMITED hardware level, the Galaxy Tab S6 Lite among them. The QR scanner added to the setup wizard in v2026.8.10 silently pulled the whole app onto a newer camera library whose rewritten backend misbehaves on such hardware; the app is now pinned back to the proven backend the motion feature was built and tuned on, for every camera user in the app including the QR scanner.

### Changed
- The update notice now shows **everything that changed since the version the device is running**, not just the newest release's notes. A device that skipped releases gets each missed release's notes stacked newest first under its own Version heading, in the app's update dialog, the remote admin's and the Home Assistant update entity's summary alike. The check still costs the same single request it always did; a device more than thirty releases behind gets the newest thirty and a pointer to the release history.
- The Sendspin player has been **rebuilt on the Sendspin reference engine**, sendspin-cpp, the same implementation behind ESPHome speakers, with Kiosk Satellite providing the Android audio output around it. The change matters most on devices whose audio hardware misreports its own playback clock (the Meta Portal): the old player measured sync against that clock and restarted the stream when the numbers looked wrong, which on such hardware looped forever, while the new engine paces itself by playback feedback that a broken clock can only slow down, never poison, and corrects drift with single-frame adjustments that cannot be heard. In a grouped four-device test spanning three hardware generations, the new engine played ten minutes with pause, resume and stream restarts without a single audible correction, where the old player logged hundreds of buffer underruns and an audible re-anchor on one device. Everything around the player is unchanged: same server and codec settings, floating player, lyrics, ducking, volume and MQTT surfaces. The device's write-to-speaker latency is now measured from the platform rather than assumed, so speakers of different hardware generations land on the same beat without hand tuning; the Sync offset setting remains for trimming Bluetooth outputs.

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
- Installing an update now asks GitHub for the latest release first, so what installs is the newest version at the moment Install is pressed rather than the one the notice named when it appeared. The release check runs twice a day and the notice then sits there until someone acts on it, so a version published in between used to install the older build and leave a second update waiting right behind it. This applies wherever the update starts: the kiosk menu, the Remote Administration UI and Home Assistant's Updates page. If GitHub cannot be reached at that moment the known release installs exactly as before, and in the rare case where the offered release is gone and the device is already on the latest, nothing downloads and the notice clears itself.

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
- Cameras that stream H.265 no longer show as a permanently blank tile. Android WebViews advertise H.265 support in the stream request whether or not anything on the device can decode it, so the server hands over H.265, the connection succeeds, video data arrives, and not one frame is ever decoded. Kiosk Satellite now leaves H.265 out of the request unless the new toggle turns it back on, which lets a Go2RTC server with ffmpeg transcode the camera to H.264 by itself, and makes a server that cannot transcode answer with a real error rather than silence.

## v2026.8.13 - 2026-08-08

### Added
- A Permissions Manager group in the Device settings, on the device and in the Remote Administration UI alike, listing every Android grant the app can use in one place, with an explanation as its first row: microphone, unrestricted battery, camera, notifications, display over other apps, modify system settings, system UI guard, device admin and location. Each row says what the grant is for and carries a button that starts it, and reads Granted, Missing when something currently switched on needs it, or Not granted when nothing needs it yet and it can still be given ahead of time. Until now permissions only appeared inside the feature groups that use them, so a grant no enabled feature happened to ask for could not be found at all: the battery exemption, which is what keeps the Home Assistant connection and the MQTT entities alive while the screen is off, was only listed under background wake word listening.

### Changed
- Setup now asks for the unrestricted battery permission on every device, instead of only when Voice Satellite background listening was turned on. It is what keeps the Home Assistant connection and the MQTT entities alive while the screen is off, so a kiosk without voice needed it just as much and was never asked. This covers the setup wizard on the device, the same wizard in the Remote Administration UI, and a device provisioned by importing a configuration.
- Permission rows describe what the grant allows rather than what it does for one feature, everywhere they appear: the microphone, unrestricted battery, display over other apps and device admin rows read the same in the Voice Satellite, Kiosk Mode and Lockdown Mode groups as in the new Permissions Manager group.
- The Remote Administration UI's Device tab no longer repeats itself: the read-only Permissions and Remote administration summaries at the bottom are gone, since the settings above list the same grants with a button to give them, and the same port and admin address.

## v2026.8.12 - 2026-08-08

### Added
- A Startup delay slider in the Camera settings' Motion Detection group, 0 to 15 seconds and 0 by default: motion is ignored for that long after the camera stream starts. Made for devices whose camera physically moves as it opens, such as a phone with a pop-up module, where the lens sweeping through the scene on its motor reads as motion and dismisses the screensaver that just started the camera. The delay counts from the first frame and covers every path that starts the camera, not just a screensaver, and the frames are still tracked as the baseline so the movement never desensitizes detection afterwards.

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
- Camera enabled and Screensaver motion detection switches over MQTT, on devices with a usable camera: the camera master toggle and the screensaver's Dismiss on motion, controllable from Home Assistant. Made for staged wake-ups where camera use should not run around the clock: a room-wide motion sensor turns the camera on when someone is nearby, the camera's approach detection then wakes the screen for whoever walks up, and the automation turns the camera, and its roughly 10% CPU cost, back off when the room empties. Turning the camera off retracts its entities as always; the switches themselves stay.

## v2026.8.8 - 2026-08-07

### Added
- A Keep audio in the background toggle for the DLNA renderer, off by default: with it on, audio pushed to the renderer, such as TTS announcements or music, plays without taking over the screen, so the dashboard or a running screensaver stays exactly as it was. Images, video and camera streams still show as before, and playback control from Home Assistant keeps working while the audio stays invisible.
- A Screensaver active switch over MQTT, carrying what the old Screensaver switch did: it is on while a screensaver is on screen, turning it on starts the screensaver right away, and turning it off dismisses it until the idle timeout runs out again.

### Changed
- Scrolling content now fades out gracefully at the edges instead of being cut off: the settings lists, search results, log boxes and scrolling dialog bodies on the device, and the settings pages, modals, nav rail and consoles in the Remote Administration UI, all show a soft gradient at an edge that still hides content, sliding away once the list reaches its end.

### Fixed
- The Screensaver switch in Home Assistant now controls the master screensaver enable/disable, the same toggle the Screensaver settings page has, instead of only dismissing the screensaver for one timeout period: turning it off keeps the screensaver away until the switch is turned back on, so automations no longer need a loop pressing Postpone screensaver to keep the screen alive. The switch moved to the device's Configuration area in Home Assistant accordingly, and turning it off while a screensaver is showing dismisses it immediately, from Home Assistant and the Remote Administration UI alike.
- The Remote Administration UI's File Manager no longer breaks on narrow viewports (phones): the Location tabs and the Upload file button no longer overlap, the tabs sit on their own toolbar without a card or label, and the per-file Download and Delete buttons became compact icon buttons that share a row with the file name. File and folder rows now use the same list style as the Gestures and Camera pages.
- The note under the gesture list in the Remote Administration UI now renders in the same quiet style as the other card notes, instead of full-size text.

## v2026.8.7 - 2026-08-07

### Added
- The Clock screensaver's background photo can be set from Home Assistant: a new Clock background text entity over MQTT holds the image's file path on the device, so automations can rotate the picture behind the clock, push an alert image, or clear it back to the solid color with an empty value. Writing a path overwrites the photo picked on the device, a path that does not exist yet simply shows no background until the file appears, and changes apply live while the clock is on screen. The Remote Administration UI's Background photo row edits the same path as a text field now, where it used to just say a photo was selected on the device. Getting the images onto the device is out of scope; the remote admin's File Manager can upload them.
- A Hide all extras toggle for the Black screensaver: with it on, Black shows nothing at all, hiding the small clock, the At a Glance entities and any other overlay, so a kiosk that schedules Black overnight looks fully off without unconfiguring those extras for the night. The toggle appears in a Black group under the screensaver mode picker whenever the mode is Black, on the device and in the Remote Administration UI alike, and it is off by default.

### Changed
- The Clock screensaver's background photo now fills the screen the way the photo screensavers do: a photo shaped close enough to the panel covers it edge to edge, and one that keeps its full frame sits over itself blurred and dimmed instead of being cropped, so a portrait photo behind a landscape clock no longer loses its top and bottom. A background changed while the clock is on screen also applies immediately now, instead of waiting for the next minute tick.

## v2026.8.6 - 2026-08-07

### Fixed
- A black screen at startup on some devices, stuck in a restart loop every 30 seconds: on slower hardware the dashboard's browser view could be created a moment before the app's screen was ready to host it, the creation failed silently and was never retried, and the built-in recovery restarted the app into the same failure. The browser view now waits for the screen to be ready before it is created, and the recovery watchdog additionally rebuilds the view in place, well before resorting to an app restart.

### Added
- Settings search, in the on-device settings and the Remote Administration UI alike: a search field sits under the Settings title (under the Kiosk Satellite logo in the remote UI), typing swaps the content for results grouped by page with the match highlighted, and tapping a result opens its page, scrolls to the setting and blinks it. Results cover every setting, the pages themselves and the hand-built rows such as Validate connection or the permissions groups; a setting currently hidden behind a switch that is off still appears, and tapping it lands on the switch that turns it on.

## v2026.8.5 - 2026-08-07

### Added
- Lockdown Mode: one switch that disables screen interactions until turned off either from Home Assistant or with the exit gesture. The dashboard stays visible and live but nothing on it can be tapped, and touching the locked screen shows a brief "Screen is locked" notice. Its setup lives only in the Remote Administration UI, with no page in the on-device settings, and the mode can also be toggled from Home Assistant through the Lockdown mode switch every device gets over MQTT. It arms every Kiosk Mode protection at runtime without changing the stored kiosk settings and mutes wake word detection while it holds; the shield covers the entire display at the system level, not just the app window, so it stays up no matter what comes forward. It has its own exit gesture (fast taps anywhere, behind the kiosk PIN when one is set), an optional Blackout that paints the locked screen solid black and pauses the dashboard's rendering underneath to save power, and an optional Allow screensaver that lets the screensaver keep running while locked, with Dismiss on motion staying deactivated until the lock lifts.
- System UI guard: an optional accessibility service that closes the notification shade the moment it opens and bounces the recents screen right back, while Lockdown Mode holds or the matching Kiosk Mode protections are on. Android only allows enabling it at the device, under Accessibility settings; the new permissions rows say when it is missing.
- The Kiosk Mode and Lockdown Mode settings now end with a Required system permissions group like Voice Satellite's, showing the Display over other apps grant and the System UI guard, each with a button that starts the grant on the device, including from the remote admin.

### Changed
- Kiosk Mode's protections no longer hinge on Android's "App is pinned" consent dialog. Under Lockdown Mode the dialog never appears at all, and with Disable home button on, if pinning was declined or ever lost, the app now pulls itself back to the front about a second after losing the foreground. Closing the app from the recents screen relaunches it immediately, and apps opened through the App Launcher are still left alone.

## v2026.8.4 - 2026-08-06

### Added
- Camera views are fully controllable over MQTT: a new Camera view select entity in Home Assistant lists every configured view, picking one shows it on the device and picking Closed dismisses it, and the entity always reflects what is on screen no matter how the view was opened or closed. The per-view Show buttons remain for automations that just press. The idle option is named Closed rather than None because Home Assistant reserves the None payload on MQTT entities and would blank the select.

### Changed
- Camera views grew from four cameras to twelve, laid out exactly like UniFi Protect lays out each grid size: mixes of large and small tiles such as four large beside a column of four small for eight, or two large over eight small for ten. The view editor on the device and in the remote admin gained a UniFi-style Grid dropdown with layout icons, preselected from the camera count and adjustable upward, with a numbered miniature of the chosen layout below it. Cameras always fill the largest tiles first, slots without a camera stay empty on screen, and portrait devices render the same layouts turned sideways.
- Scrolling in the on-device settings is much smoother: the dashboard keeps rendering behind the settings screen even though it is fully covered, and on a busy dashboard that background work caused visible stutters. The dashboard's rendering now pauses while settings are open, the same optimization the screensaver uses, and resumes the instant settings begin to close. The Home Assistant connection stays live throughout.
- The same rendering pause now applies under every surface that fully covers the dashboard: streaming camera views, where it matters most since the dashboard no longer competes with the video decoders, and media pushed over DLNA. The dashboard is drawing again the moment the covering surface closes.
- The settings categories are reordered into clearer groups in both the on-device settings and the remote admin: connection first, then the screen, browsing and screensaver, then the camera and media features, then kiosk behavior, with device, about and logs at the end.

### Fixed
- The Disable status bar shield no longer swallows taps on the top edge of the dashboard. Home Assistant's view-tab bar sits exactly where the shield used to cover, making the page switcher dead while the protection was on; the shield now covers only the thin strip at the very display edge where the status bar pull-down actually has to begin, so the pull-down stays blocked and everything on the page is tappable. On some devices a determined user can still surface the shade with two precise swipes by dragging the transient bar the system itself reveals; that was equally possible with the old full-height shield, and the hard guarantee remains Disable home button, whose screen pinning makes Android disable the shade entirely.
- Devices that cannot read any thermal sensor no longer show a permanently unknown CPU temperature entity. Some vendors' security policies deny apps the thermal sensors entirely (seen on a Lenovo TB336FU, where Android logs an SELinux denial for the read); the entity now only exists when a temperature can actually be read, it comes back on its own if a reading appears later, and the app stops retrying the blocked read, which was flooding logcat with denial lines on every stats poll.

## v2026.8.3 - 2026-08-06

### Added
- Motion is now available as its own Home Assistant sensor over MQTT: a new Motion Detection group in the Camera settings has a Motion sensor switch and a Clear after delay, and the resulting binary sensor turns on with movement and clears itself after the configured quiet time. Unlike the screensaver's motion features, the camera keeps watching even while the screen is off, so an automation can turn the panel on when someone walks into the room. The usual camera cost warning applies: the camera runs permanently while the sensor is on.

### Changed
- Motion detection's tuning lives with the camera now: Motion frame rate and Motion sensitivity moved from the Screensaver section into the Camera settings' Motion Detection group, since they tune every motion feature, not just the screensaver's. Dismiss on motion and Postpone stay in the Screensaver section, with a hint pointing at the new home; the remote admin mirrors the move, and its Latest snapshot preview moved to its own group at the end of the Camera page so the Motion Detection settings are not buried under the image.
- Motion-triggered camera snapshots publish once per motion arrival instead of every ten seconds for as long as movement continues: someone staying in front of the device updates the retained MQTT snapshot once, and the next update comes after the sensor has cleared and motion returns.

### Fixed
- Restoring a backup as a new device no longer copies the Sendspin player identity. Both devices ended up connecting to Music Assistant as one player and kicked each other off in an endless connect/disconnect loop, with neither ever syncing; a new-device restore now keeps the restoring device's own identity, while a replacement-device restore still adopts the backup's so Music Assistant sees the same player it always had.
- Camera motion detection no longer mistakes the device's own light for movement. The screensaver going dark could reflect off the room, read as motion and dismiss the screensaver the instant it started, an infinite loop on dark clock faces, and slideshow photo swaps could do the same mid-session. Detection now discounts uniform lighting shifts, including the camera auto-exposure resettle that follows them, and additionally stands down for a couple of seconds around the app's own screen transitions: screensaver start and stop, screen power, brightness changes and slide changes.
- The Filter dashboard updates optimization now catches entities referenced inside card templates, such as a custom button-card's name, label and style templates: any entity id written in a template is included in the filter's allowlist, so those cards keep updating. Only entity ids computed dynamically inside a template remain invisible to it.
- CPU temperature now reports on devices whose thermal sensors do not name the CPU, by also accepting the SoC sensor spellings MediaTek, Exynos and Qualcomm devices use. When no readable sensor exists at all, the app logs which sensors the device exposes, so a bug report's app logs carry the answer.

## v2026.8.2 - 2026-08-05

### Added
- The setup wizard can scan the QR code Home Assistant shows next to a newly created long-lived access token, so the token never has to be typed on the device. A scan button appears in the token field on devices with a camera; the remote admin's wizard keeps paste, where a clipboard exists.
- At a Glance entities can display an attribute instead of the state: each chosen entity in the picker has a gear button that lists the entity's attributes with their current readings, on the device and in the remote admin, so a weather entity can show its actual temperature rather than "Sunny".
- The Clock screensaver can have a background photo: a new Background photo setting in the Clock section picks one from the device's local media, and the clock draws over it with a subtle dark scrim so the time and the At a Glance row stay readable on any photo and any clock face.

### Changed
- Dropdowns are real controls now: every dropdown in the app sits on the same bordered box the remote admin's selects use, instead of rendering as bare text that read like another row title.

### Fixed
- Settings, the Automations editor, the Voice Satellite panel and other non-dashboard pages no longer show stale states while the "Filter dashboard updates" optimization is on. The filter now recognizes non-dashboard panels directly, and whenever it stands down it replays every entity's current state from the shadow copy it already keeps, so pages arrive seeing the truth instead of whatever they had when filtering started; previously only a full app restart caught them up. Update entities are also always forwarded now, so the sidebar's update badges stay current even while a dashboard view is filtered.
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
- Fill the screen for the Local Media and Photo Gallery screensavers: the same treatment the Immich screensaver already had. Photos shaped close enough to the screen are enlarged to cover it fully, and photos that keep their full frame, such as portrait shots on a landscape display, now show over a blurred, dimmed backdrop of the photo itself instead of black bars. On by default, with a Fill the screen switch in each mode's settings on the device and in the remote admin for anyone who prefers the plain letterboxed look.

### Changed
- The Web Browsing menu subtitle no longer mentions Start URL, which is not an option on that page (the dashboard is picked under Home Assistant Configuration); it now reads "Cache, SSL, Zoom level" on the device and in the remote admin.

## v0.35.0-beta - 2026-08-04

### Added
- Postpone screensaver button entity over MQTT: pressing it resets the screensaver's idle timer as if someone had touched the screen, dismissing the screensaver first when one is showing. Any Home Assistant automation can now keep the display awake from an external sensor, such as a door contact or a motion sensor elsewhere in the room, complementing the device-camera-based Postpone on motion. The same action is available to the remote REST API as the postponeScreensaver command.

### Changed
- The settings menu is shorter: Screen and Audio are now one Screen & Audio page, which also picked up the microphone and speaker selection and the Microphone settings group from Voice Satellite, and Remote Administration now lives on the Device page. Every setting kept its stored key, so nothing resets, and the remote admin mirrors the new layout; old remote admin bookmarks to the Screen, Audio or Remote Administration tabs land on the right page.
- The app log and the web console now share one Logs page in both UIs (on the device it opens the docked console over the live page), WebRTC Cameras is now called Camera Streams (it has streamed Home Assistant cameras without Go2RTC since the import arrived), and the menu subtitles now match between the device and the remote admin.

## v0.34.0-beta - 2026-08-04

### Fixed
- Devices whose GPU drivers crash under Flutter's Impeller renderer no longer crash at every launch (seen on a Galaxy Tab Pro 8.4 whose 2016 Adreno driver dies the moment Impeller draws). The renderer is now chosen per device when the engine starts: a new Legacy renderer switch in the Device settings forces the older Skia renderer, and the app also protects itself, so that two consecutive launches that die before showing a frame flip the switch automatically. Together with the crash self-heal an affected device converges to a working renderer on its own, and modern hardware keeps Impeller.

### Added
- Import WebRTC cameras from Home Assistant: a new Home Assistant group at the top of the WebRTC Cameras settings imports every camera entity the connected Home Assistant can stream over WebRTC (Home Assistant 2024.11 or newer), no Go2RTC URL or WHEP setup involved. Imported cameras stream through Home Assistant's own WebRTC signaling on the existing connection, including its ICE server configuration, so cloud setups work too. Re-importing merges new entities and marks removed ones as missing, exactly like the Go2RTC import, and a Home Assistant camera entity can also be added manually in the camera editor.
- Postpone screensaver on motion, a new opt-in switch in the screensaver's Motion Detection section: the camera also watches between screensavers, and movement nearby keeps resetting the idle timeout, so the screensaver stays away while people are actually around. An extension of Dismiss on motion, so it appears and acts only with that switch on. Off by default because this direction is the expensive one: the camera runs permanently while the screen is in use, which adds CPU load and heat. The camera still stands down whenever the screen is off.

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
- Two new Kiosk exit gesture options, 5 fast taps holding the last and 7 fast taps holding the last. With one of these selected the menu only opens when the final tap is held down for a second, so rapidly tapping a dashboard button, like a TV remote's volume control, can no longer trigger the exit gesture. The hold shape does not collide with anything on the Gestures screen: a corner hold needs a corner and a finger hold needs two or three fingers, while the exit hold is one finger anywhere after the tap chain. Existing installs keep their current setting.

## v0.33.1-beta - 2026-08-03

### Added
- The Microphone gain slider now goes down to -24 dB to attenuate overly sensitive microphones, like the Meta Portal's. Negative gain quiets the capture before the wake word engine or Home Assistant hears it. Note that attenuation happens after capture, so a microphone that clips at the hardware stage stays distorted; it helps the common case of a mic that is loud but clean.

### Fixed
- Dismiss on motion now works in the dark. The detector compared frames against one fixed change threshold that dim scenes never reached, so the screensaver only woke in a lit room. Each analysis cell now learns its own sensor noise and flags change just above it, and the camera is asked for the longest exposures it offers, gathering several times more light per frame at no extra CPU cost. Because a detector this sensitive would otherwise wake on light alone, a change that pushes the scene in one direction, like a TV or monitor lighting the room differently, a lamp toggling, or the camera's exposure settling, is recognized as illumination and ignored; a moving person brightens some cells while darkening others and still triggers.

## v0.33.0-beta - 2026-08-03

### Added
- App Launcher: a minimal app selector for kiosks that double as media players or alarm clocks. A new App Launcher settings page holds the enable toggle (off by default), the app whitelist picked from the device's installed apps (from the device settings or the remote admin), a grid or list layout choice and an icons toggle. The launcher opens from the kiosk menu, the quick actions panel (with its own Allowed Actions entry), a new Open app launcher MQTT button, and the showAppLauncher remote command. An optional Return automatically setting brings the kiosk back to the front after a configurable time in the other app; the existing Bring to front MQTT button works too. While the launcher is disabled it is gone everywhere: no menu entry, the commands refuse, and the MQTT button is retracted from Home Assistant.

### Fixed
- The small screensaver clock has its own 24-hour toggle. Its format silently followed the Clock mode's 24-hour switch, which is only visible while the screensaver mode is Clock, so on Immich and every other mode there was no way to see or change it. Devices that had the Clock mode set to 24 hours keep their 24-hour small clock after the update.
- The Website screensaver loads the URL as a top-level page instead of an iframe. Sites gated by a session cookie, like DAKboard private URLs, served their login page to the iframe because browsers withhold SameSite cookies from cross-site frames; top-level the site is first-party, shares the app's cookie jar, and renders like it does in the dashboard WebView. Tap-to-dismiss and pixel shift carry over unchanged.

## v0.32.2-beta - 2026-08-03

### Added
- Keep playing when dismissed toggle in the Sendspin settings (off by default): flinging the floating player away hides it without stopping the music.
- Go to dashboard button in the MQTT device, and a matching loadStartUrl remote command: navigates back to the configured Start URL, the device's own dashboard. Unlike Reload page it leaves whatever page is currently shown, so it is the quick way home after temporarily sending the device to another dashboard.
- The Immich screensaver's album picker now lists albums shared with the user, not just their own.

### Fixed
- Sendspin resilience on devices with unreliable audio hardware: a frozen playback position report from the audio HAL could silently starve the player, leaving the track "playing" with no sound until a manual pause and resume. The player now detects the stall within seconds and recovers on its own, stops trusting timestamps that do not advance, and escapes a start alignment that stops converging. Reconnection is faster and sturdier too: the client retries the moment the network returns instead of waiting out a parked backoff, a connection stuck waiting for the server's handshake times out, and a race that double-counted reconnect attempts is gone.
- Synced lyrics now actually follow the music. They ran several seconds ahead of the singer on every track (the position anchored to the server's read-ahead cursor during stream startup) and could break entirely after a pause and resume, a track change or a rejoin. The position now anchors to what the speaker is playing, survives every stream rebuild, and ignores the garbage progress value the server sends while pausing.
- Adjusting the Show lyrics toggle, the Lyrics offset or the new dismiss toggle no longer restarts the Sendspin player mid song; they apply live.
- Dates on the clock screensaver and in the Immich photo details follow the device language instead of always being in English: a Dutch device now shows "zondag 1 augustus" where it used to show "Sunday, August 1".

## v0.32.1-beta - 2026-08-02

### Fixed
- The last piece of the Lenovo fullscreen gap: some ROMs, notably Lenovo's ZUI, keep reporting the status bar as occupying space even while it is hidden, and the dashboard page dutifully padded itself by one bar height through its safe-area insets. Those insets are now withheld from the page on every Display cutout setting, since the bars are permanently hidden anyway. No effect on ROMs that report the insets correctly.
- The remote admin login now says "Too many attempts. Wait 5 minutes and try again." when the brute-force throttle is active, instead of reporting the password as invalid. The throttle rejects even the correct password, so the old message sent anyone with a typo behind them into a loop of retries that looked like a broken password on every device.

## v0.32.0-beta - 2026-08-02

### Added
- Display cutout setting in the new User Interface group under Web Browsing, next to the Zoom level which moved there. By default the dashboard uses the screen area around a punch-hole camera or notch; dashboards with buttons at the very top can pick Avoid the cutout to keep the page below the camera instead, with Short edges only and System default also available.

### Fixed
- On Lenovo tablets (and other ROMs that reserve the status bar row even after the bar is hidden), the dashboard no longer shows a permanent gap at the top of the screen: the app now lays its window out edge to edge through the modern Android inset pipeline instead of relying on the legacy fullscreen flags those ROMs ignore. Devices with a punch-hole camera also get the cutout row back.

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
- Crash recovery on Fire OS and Android 12+ is now graceful: a crashed kiosk comes back in about a second with its watchdog re-armed, and an explicit restart command always works instead of being throttled after repeated recoveries.

## v0.31.0-beta - 2026-08-01

### Added
- Gestures: map touch gestures (2 to 4 corner taps, corner holds, 2 or 3 finger taps and holds, or an ordered corner knock code) to Kiosk Satellite, Android, and Home Assistant actions. Configured in the new Gestures settings section on the device and in the remote admin. Gestures are observed rather than intercepted, so the dashboard keeps behaving as before; a Disable Gestures switch in Kiosk Mode settings opts a locked-down tablet out. See [docs/gestures.md](docs/gestures.md).

## v0.30.0-beta - 2026-07-31

### Fixed
- Streamed assistant audio (TTS responses and chimes) now plays through the app's own ExoPlayer-based pipeline, so it lands on the speaker selected in settings even on devices whose built-in media player ignores app routing. The route is watched while a sound plays and pinned back if the system tries to move it.

## v0.29.1-beta - 2026-07-31

### Fixed
- Crash self-heal is now armed whenever the kiosk is on screen, not only when background listening is enabled: a lightweight guard service relaunches the dashboard within seconds of a whole-process crash, backed by a heartbeat for devices slow to restart services such as Fire tablets. Requires the "Display over other apps" permission on Android 10 and newer.

## v0.29.0-beta - 2026-07-30

### Added
- Return to home dashboard view: an option under Home Assistant Configuration sends the kiosk back to the configured dashboard after a period of inactivity, quietly behind the screensaver if one is showing.
- Sync Home Assistant themes with Kiosk Satellite: a toggle keeps the dashboard theme in step with the app theme, including the device's own dark mode when the App theme is System.
- Screensaver schedule entries can override motion detection per time window.
- Login tokens for automations: pass ttl_days to /api/login for a long-lived token (up to 10 years), with a ready-made rest_command recipe in the docs.
- New Bring to front button entity over MQTT brings Kiosk Satellite back in front of whatever app covers it.

### Fixed
- Now Playing lyrics are driven by what the speaker is actually playing instead of the server's read-ahead position, multi-artist tracks no longer fail the lookup, unmatched tracks fall back to LRCLIB directly, slow lyrics providers get more time, and reopening the app mid-song picks lyrics up where the music is.
- Sendspin: fixed a buffer negotiation bug that garbled compressed codecs a few seconds into songs (worst on Opus), fixed the sync engine going blind for minutes after a pause or track restart, and stream starts are now lossless.
- External links now open fullscreen in their own layer with the dashboard alive underneath instead of replacing the Home Assistant page and killing the Voice Satellite session.
- Fixed the Dim screensaver showing a black screen instead of the dimmed dashboard after the pause optimization became a default in 0.28.0.
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
- Device health monitoring: a token-free health endpoint (GET /api/health) returning device identity, IPs, battery, screen state, RAM, storage, CPU usage and temperature, and uptimes; app and network uptime rows in the remote admin's Device Info page; and a Last seen MQTT timestamp sensor that stays readable after the device drops off the broker.

### Fixed
- At a Glance entity states now round to the entity's Display precision setting from Home Assistant.

## v0.26.0-beta - 2026-07-29

### Added
- Camera integration: the device's own camera is exposed to Home Assistant over MQTT with auto-discovered Camera, Take camera snapshot button, and Last camera snapshot sensor entities. New Camera settings section with master switch, camera picker, snapshot resolution, and optional continuous snapshot interval, all off by default. The camera is never held open; each still opens it, takes one frame, and releases it, and motion detection snapshots ride the existing camera session. The remote admin shows a live snapshot preview, and devices without a usable camera say so up front.

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
- Assistant volume: voice assistant responses and chimes have their own volume, independent of media volume, with a slider in Voice Satellite settings, in the remote admin, and as an MQTT number entity.

### Fixed
- Fixed the Roller Clock's digits clipping in mid-air during the roll animation.

## v0.22.0-beta - 2026-07-28

### Added
- Quick actions in kiosk mode: "Allow menu with quick actions" opens an edge-swipe menu limited to selected harmless actions (Dashboard, Default Camera View, Start Screensaver, theme picker) without the exit gesture or PIN. Off by default.
- Start Screensaver menu action, also available as a kiosk quick action.
- A kiosk protection that ignores the pull-to-refresh gesture while kiosk mode is on. Off by default.

## v0.21.2-beta - 2026-07-28

### Added
- Software volume for Chromebooks and other fixed-volume devices, detected automatically and applied across SendSpin playback, Voice Assistant responses and chimes, and DLNA media. Software volume can only lower output below the device's hardware level.

## v0.21.1-beta - 2026-07-27

### Fixed
- Fixed a crash in the microWakeWord engine where loud audio that clipped to full scale could kill the detection worker until the device went deaf to wake words.

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
- Wake word detection recovers from a crashed detector: the worker is brought back automatically seconds after it dies, and if it keeps crashing the app reports itself unavailable so Voice Satellite resumes browser detection instead of trusting a device that hears nothing. Crashes record their stack trace in the app log.
- Screen off on devices with an always-on display: kiosk mode's power button watch no longer undoes the app's own screen-off, and on ROMs whose always-on display relights the lock screen the Home Assistant screen entity goes unavailable with an explanatory notice instead of lying.

## v0.19.0-beta - 2026-07-26

### Added
- Microphone settings under Voice Satellite: capture mode (which Android microphone path to record from), automatic gain control, and microphone gain (0 to 24 dB applied before the wake word engine, stop word, and speech). Changes reopen the microphone on the spot. See [docs/microphone.md](docs/microphone.md).

### Fixed
- The DLNA renderer now steps to the next free port instead of failing with "Address already in use" on plain http instances where the secure context proxy holds port 2325, and a new Server port field shows (and can change) the port it took.

## v0.18.0-beta - 2026-07-25

### Added
- Synced lyrics on the Now Playing screen, sourced from Music Assistant, with a Validate connection check, an adjustable timing offset, and layouts for portrait and landscape.
- Open other Android apps from the dashboard via app:// tap actions, and a matching launchApp remote API command.
- Next alarm MQTT timestamp sensor exposing the tablet's next alarm clock, following alarms from any clock app.

### Fixed
- At a Glance entities now lay out two per row on portrait screens instead of wrapping into a single column.

## v0.17.0-beta - 2026-07-25

### Added
- At a Glance entities in screensavers: an optional row of up to four Home Assistant entity states on the Black and Clock screensavers, with a searchable picker and reordering, on the device and in the remote admin. See [docs/at-a-glance.md](docs/at-a-glance.md).

### Fixed
- The Screen entity in Home Assistant now follows the real display state however it changes (power button, idle timeout, another app, lock screen), including a screen that is already off at app start.

## v0.16.1-beta - 2026-07-25

### Fixed
- The remote administration page was completely broken in v0.16.0-beta by a duplicated script block causing a const redeclaration error; the login button did nothing. The device itself was unaffected.

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
- Cloning a configuration no longer makes two devices fight over one Home Assistant device; importing as new sheds a colliding MQTT identity.
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
- Ready-made Home Assistant entities over MQTT discovery, no YAML: Screen light, Screensaver switch, Kiosk mode, HA kiosk mode, Keep screen on and Remote management switches, Reload page and Clear cache buttons, Battery, Charging, CPU, RAM, and Current page sensors, with live availability. Configured in the new MQTT Settings page.
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
- Filter dashboard updates: filters Home Assistant's state-change stream down to the entities on the visible dashboard view. On an Echo Show 5 with ~4,700 entities, the main thread went from blocked a third of the time to essentially never. Fails safe on views it cannot resolve. Off by default.
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
