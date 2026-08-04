# Changelog

All notable changes to Kiosk Satellite are documented here. Full release notes for each version are available on the [releases page](https://github.com/jxlarrea/kiosk-satellite/releases).

## v0.33.3-beta - 2026-08-03

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
