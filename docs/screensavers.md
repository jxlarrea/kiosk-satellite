# Screensavers

After a period of inactivity, Kiosk Satellite can transition to a clock, a photo frame, a camera wall, a web page, or a black panel. The display returns to the live dashboard immediately when someone touches the screen, speaks the wake word, or approaches the kiosk.

A core design principle applies to all modes: the screensaver never powers off the physical display. Even the Black mode sets the backlight to zero behind a black overlay while keeping the application fully active underneath. This ensures motion detection, wake word processing, the ESPHome server, and remote administration (including live view) remain fully functional 24/7. Controlling actual display panel power is handled separately using the Screen light entity via the [ESPHome integration](esphome.md).

## Setup

Navigate to **Settings > Screensaver** (available in the on device settings and the remote admin interface):

| Setting | Default | Notes |
| --- | --- | --- |
| Screensaver | off | The master toggle. Turning this off immediately dismisses any active screensaver. |
| Idle timeout (seconds) | 300 | The period of inactivity before the screensaver launches. |
| Screensaver brightness | off | Enables an independent display brightness level while the screensaver is active. |
| Brightness level | 20% | Defines the screensaver brightness level across all modes except Dim and Black. |
| Brighten for notifications | on | Automatically restores full display brightness while an incoming notification is visible. Appears when Screensaver brightness is enabled. |
| Turn screen off after | 0 (never) | Powers off the physical display panel after the screensaver has been running for the specified duration. |
| Pixel shift | off | Periodically shifts on screen elements every minute to prevent image retention on OLED displays. Not applicable to Black mode. |
| Screensaver mode | Black | Selects the active screensaver display mode. Options for the chosen mode appear directly below this selector. |

The **Widgets** configuration group sits directly beneath the mode settings, allowing small overlays to be anchored to display corners.

## The Modes

### Dim

Reduces the display backlight to the configured **Dim level** while keeping the live Home Assistant dashboard visible underneath. Because the dashboard remains visible, the **Pause dashboard during screensaver** optimization cannot be applied in this mode. As a result, the browser process continues to consume CPU, GPU, and battery power.

### Black

Displays a completely black screen while leaving the underlying application running. Enabling **Hide all extras** ensures true black output by suppressing widgets, the At a Glance row, and all other visual overlays. It also prevents the At a Glance Home Assistant connection from opening.

### Clock

Renders a full screen clock with three selectable styles via **Style**: **Digital Clock**, **Flip Clock** (split-flap cards), or **Roller Clock** (rolling digits styled after the Lenovo Smart Clock 2). Date formats adapt automatically to the device's system language.

| Setting | Notes |
| --- | --- |
| Font Family | Available across all faces. Options include Rubik (default app font), Nunito (rounded style similar to Apple StandBy), Inter (clean grotesque style), system font families (System, Serif, Condensed, Monospace, Casual, Cursive), or LCD (segmented LED alarm clock font covering digits, date, and AM/PM). |
| Font weight | Available across all faces. Default matches the face's native style. Options include Light, Regular, Medium, Bold, or Black. The LCD font uses a single fixed weight. |
| 24-hour clock | Applies to all clock faces. |
| Show seconds | Digital face only. |
| Show date | Digital face only (enabled by default). |
| Clock size | Scales the display size from 50% to 300%. |
| Clock color | Digital face only. Flip and Roller styles utilize dedicated custom color controls for cards, digits, and backgrounds. |
| Background color | Digital face only. Sets the solid color behind the clock (black by default). Setting a white background with a black clock color creates a high-contrast inverted face ideal for e-ink panels. |
| Background photo | Displays a custom background image behind any clock face instead of a solid color. |

When picking a **Background photo** on the device, the image file is copied into internal app storage. It can also be set remotely via the remote admin interface or by writing a file path to the ESPHome **Clock background** text entity. Remote path changes apply live while the clock is running, and writing an empty value clears the photo. Background images use the **Smart** scaling mode with a dark scrim overlay to maintain clock legibility.

**Night mode** recolors on screen text when the room gets dark to reduce room illumination. It relies on a physical ambient light sensor and is automatically disabled on hardware lacking one.

| Setting | Notes |
| --- | --- |
| Night mode | Disabled by default. |
| Light level | Configurable from 1 to 100 lx (5 lx by default). The clock transitions to night mode at or below this ambient threshold and returns to normal slightly above it to prevent color flickering. |
| Night color | Sets the accent color for digits, dates, At a Glance elements, and corner widgets (muted red by default). |
| Night background | Sets the background display color in dark environments (pure black by default) to eliminate panel glow. |
| Night card color | Flip Clock face only. Sets the card color in the dark (near-black by default). |

### Home Assistant Media

Streams media served by Home Assistant's media browser, including single images, image folders, video files, or `camera.*` entities (which stream over WebRTC with an MJPEG fallback). **Media source** opens the picker. Selecting an image folder unlocks playlist controls (**Seconds per image**, **Shuffle**, **Include subfolders**, **Transition**, and **Tap edges to change slides**). Video assets play through to completion. Photos follow standard [Slideshow behavior](#slideshow-behavior) scaling rules, whereas videos and camera streams preserve their native aspect ratio.

### Local Media

Displays an image slideshow loaded from a local folder on the device. Configuration options include **Local folder** (selected on device or typed into the remote admin), **Seconds per photo**, **Shuffle**, **Include subfolders**, **Transition**, **Fill the screen**, and **Tap edges to change slides**.

### Photo Gallery

Operates similarly to Local Media, but selects files using the native system gallery picker. This avoids needing broad storage permissions. Selected images are stored locally to survive device reboots. Options include **Photos** selection, **Seconds per photo**, **Shuffle**, **Transition**, **Fill the screen**, and **Tap edges to change slides**.

### Immich Media

Turns the kiosk into an automated photo frame backed by an [Immich](https://immich.app/) server. Includes local image caching, optional metadata overlays, and intelligent side-by-side portrait pairing. Detailed documentation is available on the [Immich](immich.md) guide page.

### Website

Displays any web URL in full screen mode. Pages load natively in their own top level view rather than inside an iframe, sharing the application's cookie jar. This enables access to private URLs reliant on session cookies (such as private DAKboard links). Tap-to-dismiss and pixel shift scripts are injected automatically. If a page fails to load or returns a server error, the app automatically retries every 10 seconds rather than displaying a persistent error screen.

The **Zoom level** setting scales the target page independently from the main dashboard browser zoom. Scaling below 1.0x fits desktop-oriented web pages onto smaller tablet displays, while scaling above 1.0x enlarges content for readability. Zoom adjustments apply live to active web screensavers.

Loading a page hosted on your local Home Assistant instance unlocks two integration features:
1. The page automatically authenticates using the active dashboard session, bypassing login prompts.
2. The page respects **HA kiosk mode**, displaying pure dashboard content without Home Assistant's header or sidebar. These features apply exclusively to your configured Home Assistant server; external URLs load as designed by their authors.

Voice Satellite features do not run on screensaver web views. Because Voice Satellite runs on any Home Assistant page that loads it, opening a second session would create a duplicate microphone capture stream. The main dashboard remains the primary voice satellite while the screensaver acts strictly as a display.

### Camera Streams

Displays one or more configured [camera views](cameras.md) as a rotating screensaver. Select the target views under **Camera views** and set the rotation interval using **Seconds per camera view**. Dwell time timing starts once video playback begins. If a single view is selected, the display remains on that grid without cycling. Transitioning between camera views completely tears down the active video grid before loading the next, creating a brief black frame and enforcing a minimum interval threshold of 5 seconds. If a view's camera streams fail to load, the rotation advances after the interval plus a 20-second timeout grace period. 

Rotation can be stepped manually in either direction using the **Screensaver next slide** and **Screensaver previous slide** buttons on the [ESPHome](esphome.md) device. Landing on a view manually resets its full dwell timer. The **Mute all views** toggle (enabled by default) forces all camera views to remain silent, overriding single-camera audio settings configured in [Cameras](cameras.md). Disabling this toggle restores audio playback for single-camera views. Camera grid screensavers act as background scenery; tapping the screen dismisses the screensaver rather than focusing an individual camera tile, and corner clocks are hidden to keep video feeds clear.

## Slideshow Behavior

Photo slideshow modes (Home Assistant Media, Local Media, Photo Gallery, Immich Media) share unified image processing logic:

* **Transitions**: Offers None, Crossfade, Slide, Zoom, Ken Burns, or Random. Ken Burns applies exclusively to still images (videos crossfade), while Random selects a different transition effect for each slide change.
* **Fill the screen** (Smart by default): Dictates image cropping rules to fit the display panel:

  | Setting | Behavior |
  | --- | --- |
  | Off | Displays the full image frame centered between black bars. |
  | Smart | Crops up to roughly 25% along one axis to fill the display if the image aspect ratio is close to the panel's aspect ratio (covering standard 4:3 and 16:9 camera formats). Portrait and square photos retain their full frame over an enlarged, blurred, and dimmed copy of the image instead of black bars. |
  | Always | Scales the image to cover the display completely regardless of aspect ratio, cropping overflow. A 4:3 image on a 2:1 display loses approximately one-third of its vertical framing. |

* **Videos** play muted to completion, overriding image interval timers. Unplayable video files are skipped automatically.
* The slideshow playlist builds upon screensaver activation. Newly added files appear during the next screensaver launch rather than mid-session.
* Images decode at the native panel resolution, and memory for previous slides is released immediately to prevent memory exhaustion on low-RAM devices.
* **Tap edges to change slides** (on by default): A tap on the left or right fifth of the screen shows the previous or next slide and resets its full display interval. Taps on the middle three fifths dismiss the screensaver as usual. Each slideshow mode has its own switch on its settings page, and turning it off makes every tap dismiss again. Home Assistant Media offers it for image folders only, since a single image, video, or camera stream has nothing to step.
* **Manual Stepping via Home Assistant**: Triggering **Screensaver next slide** or **Screensaver previous slide** on the [ESPHome](esphome.md) device advances the slideshow by one item and resets the full display interval. These controls also step Camera Streams rotations. Triggering these actions while other screensaver modes are active performs no operation.

## Widgets

Widgets are small status overlays anchored to display corners, configured within the **Widgets** section of screensaver settings. Each widget claims one of the four display corners (limited to one widget per corner) and includes individual customization options. Widgets overlay all compatible screensaver modes, but are suppressed in Black mode when **Hide all extras** is enabled. 

The **Widget scaling** slider (50% to 150%) adjusts widget size across the display, offering a live preview while the screensaver is running. When running over the Clock screensaver in Night mode, all active widgets inherit the clock's **Night color** to maintain low light levels. Widgets render over a soft dark vignette to ensure text readability against bright background images. The **Vignette strength** slider (0% to 100%, 80% default) adjusts vignette opacity with live previewing. Setting this to 0% removes shading entirely for a clean frame look. 

Widgets hold corner priority over the Immich metadata overlay; if a widget claims a corner, the Immich overlay automatically moves to the next available corner. However, when Immich displays a side-by-side portrait pair, both bottom corners are reserved for photo details, temporarily hiding any widgets assigned to those corners until the next single slide displays.

### Small Clock

Displays a corner clock over any screensaver mode except Clock and WebRTC Camera:

| Setting | Default | Notes |
| --- | --- | --- |
| Corner | First free corner | Automatically shifts if another widget or overlay claims a corner. |
| Color | White | Sets the text color. |
| 24-hour clock | Off | Independent switch from the main Clock screensaver mode setting. |
| Show date | Off | Displays a localized short date line directly below the time. |

Renders over a soft vignette for legibility and supports pixel shift adjustments. Legacy small clock configurations automatically migrate into standard clock widgets while retaining their original settings and corner assignments.

### Weather

Displays real-time weather data pulled from a Home Assistant `weather` entity over any mode except Camera Streams. The widget layout displays top-to-bottom: location name, current temperature with units (e.g., "28°C"), condition text with a matching icon, humidity, wind speed, and visibility. Units are provided directly by the Home Assistant entity, and icons render in a monochrome style matching the widget color.

| Setting | Default | Notes |
| --- | --- | --- |
| Weather entity | None | Selected from Home Assistant. The widget remains hidden until an entity is assigned. |
| Location name | Empty | Custom text header displayed above the temperature. Because weather entities lack a city attribute, this must be typed manually. If left empty, the line is hidden. |
| Corner | First free corner | Displays in the first available corner. |
| Color | White | Applies to all text elements and icons. |
| Feels like | Off | Displays apparent temperature alongside actual temperature (e.g., "30°C / 33°C"). Requires entity support. If rounded values match, only a single temperature displays. |
| Feels like only | Off | Replaces the actual temperature reading with the apparent temperature. Takes priority over Feels like, and falls back to actual temperature if apparent data is missing. |
| Location, Forecast, Humidity, Wind speed, Visibility | On | Individual toggles for each data line. Lines automatically hide if the source entity lacks that specific data point. |

Data updates automatically via a live Home Assistant subscription while the screensaver is active. The last received values persist through brief network drops. Forecast condition text utilizes Home Assistant's localized translations (e.g., a server set to Italian displays "Nebbia" instead of "Fog"). Translations are fetched once upon app launch.

### Battery

Displays the device's physical battery status in a display corner over any mode except Camera Streams. Renders an adaptive battery icon, a lightning bolt indicator during external charging, and the current charge percentage.

| Setting | Default | Notes |
| --- | --- | --- |
| Corner | First free corner | Displays in the first available corner. |
| Color | White | Applies to the icon and percentage text. |
| Show percentage | On | Disabling this displays the battery icon only. |
| Only when low | Off | Hides the widget until battery capacity drops to 20% or below. Remains hidden whenever external power is connected. |

Reads hardware battery state directly from Android rather than a Home Assistant entity, operating independently of network connectivity. State re-checks occur every minute, while power cable connection changes update instantly. Devices lacking battery hardware (such as mains-powered boxes) automatically suppress this widget.

### Entity

Displays a single Home Assistant entity in a display corner over any mode except Camera Streams. Styled similarly to the widget family, the layout features the entity icon and value on a single line with the entity name centered underneath. Ideal for displaying specific metrics, such as a room temperature sensor over an Immich photo slideshow.

| Setting | Default | Notes |
| --- | --- | --- |
| Entity | None | Selected by entity name or ID via the picker. The widget remains hidden until assigned. |
| Name | Empty | Custom label displayed under the value. If left empty, the default Home Assistant entity name displays. |
| Displayed value | State | Selects whether to display the primary entity state or a specific attribute value. |
| Corner | First free corner | Displays in the first available corner. |
| Color | White | Applies to icon, value, and label text. |
| Show name | On | Disabling this hides the bottom label, displaying only the icon and value. |

Entity formatting matches At a Glance rules: custom Home Assistant icons display when set (falling back to domain defaults), numeric states round to configured precision with units, and state strings convert to clean text. Values update in real time over a live Home Assistant subscription and persist through brief network drops.

## Brightness

**Screensaver brightness** applies a dedicated display panel brightness level when the screensaver launches, restoring the original brightness when it closes. Dim and Black modes ignore this setting as they use dedicated levels, and active [Schedule](#schedule) entries override it. Adjusting the brightness slider while a screensaver is on screen updates panel output immediately. Pre-screensaver brightness settings persist across app restarts to prevent low night brightness from overwriting default daytime settings.

When [Adaptive brightness](screen.md#adaptive-brightness) is enabled, the screensaver brightness setting defines the baseline output for a bright room. Ambient light dimming scales the screensaver brightness proportionally alongside the dashboard. A clock set to 20% during the day automatically scales down to a fraction of that level in a dark room without requiring slider adjustments.

**Brighten for notifications** (enabled by default) temporarily restores full pre-screensaver display brightness while a [notification](esphome.md#notifications) card is visible on screen. Once all notification cards are dismissed, display brightness returns to the configured screensaver level. Only the backlight level adjusts; clock faces, photos, or black overlays remain unchanged beneath the notification card. This brightening behavior also applies to Dim, Black, and scheduled brightness overrides. Disable this feature in bedroom environments to prevent night notifications from illuminating the room.

## Turning the Screen Off

The screensaver pauses when another application takes the foreground. The idle timeout clock stops counting when Kiosk Satellite moves to the background (such as launching an external app via the App Launcher, a gesture, or Home Assistant, or pressing Home on unmanaged devices). An active screensaver closes so the newly opened app receives standard display brightness, and the idle clock resets when Kiosk Satellite returns to the foreground. Turning off the physical display panel pauses Kiosk Satellite in the same manner, preserving screensaver state upon waking.

The screensaver holds a CPU wake lock while active, preventing Android's system display timeout from turning off the screen. **Turn screen off after** powers off the display panel after the screensaver has been running for a set duration. Both the global setting and schedule overrides range from 1 to 60 minutes in 1-minute increments. Set the value to 0 to disable panel power off. Powering off the display panel requires the **Device admin** permission (**Settings > Device > Permissions Manager**). If this permission is missing, a warning is logged and the panel remains powered on.

Android automatically arms the lock screen when display admin power-off is called, regardless of whether a PIN is configured. Waking a panel to an active lock screen causes the display to turn off again seconds later while the kiosk remains paused underneath. To prevent this, Kiosk Satellite automatically clears unsecured lock screens (swipe-to-unlock screens without PINs, patterns, or passwords) upon waking. On Android 10 and newer, clearing lock screens requires the **Display over other apps** permission. Secured lock screens are left intact, requiring manual user unlock while logging the status. Fire OS 8 strictly blocks non-Amazon apps from clearing lock screens, requiring a specific ADB setting change and reboot (see [Amazon Fire tablets](fire.md)). Kiosks configured to turn off display panels operate best with lock screens disabled entirely.

The screensaver session remains active behind a dark panel, ensuring symmetrical wake behavior across all trigger sources. Supported wake triggers include [camera motion detection](microphone.md) (on supported hardware where background camera sessions survive screen off), wake word detection, toggling the ESPHome **Screensaver active** switch off, or calling `stopScreensaver` via Home Assistant automations. All wake triggers return the display directly to the live dashboard rather than the screensaver. Physical power button presses and double-tap-to-wake gestures act as touch interactions, returning to the dashboard and resetting the idle timeout clock. Under [Lockdown Mode](kiosk.md), screensavers persist through wake events as they do for motion. 

The single wake event that preserves screensaver state is toggling display power via the ESPHome **Screen** light entity. Turning the Screen light entity on in the morning restores the active screensaver with a fresh power-off countdown, allowing an automation to subsequently turn off **Screensaver active** when it is time to display the dashboard.

Example configuration workflow: Display photo slideshows during the day, transition to Black mode in the evening via the [schedule](#schedule), and set **Turn screen off after** to 10 minutes. The display turns off completely overnight after the room empties, and the first morning wake event (motion or wake word) restores the dashboard immediately.

## Schedule

**Scheduled screensavers** allows switching between different screensaver modes at specific times of day. Entries configured under **Times** specify a start time, a screensaver mode, a dedicated **Screensaver brightness** toggle, a dedicated **Turn screen off after** toggle, and six feature overrides (motion, face, proximity, person, widgets, and At a glance). Tap any schedule entry to edit its properties. Each scheduled entry remains active from its start time until the next scheduled entry, with the final entry of the day carrying over past midnight. Schedules apply uniformly every day without day-of-week parameters.

When a schedule entry's brightness toggle is disabled, it inherits global [Brightness](#brightness) settings (following [Adaptive brightness](screen.md#adaptive-brightness) curves if enabled). When enabled, the schedule entry's brightness slider sets a fixed display level for those hours (excluding Black mode).

The **Turn screen off after** toggle works the same way for the [screen off timer](#turning-the-screen-off). Disabled, the entry follows the global slider. Enabled, the entry's own slider sets the countdown for those hours, starting from the global slider's value, and 0 keeps the screen on even when the global slider is set. A day entry can keep a clock lit while a night entry powers the panel off a few minutes after the screensaver starts, which is darker than Black mode and saves battery. The countdown starts over when the schedule crosses into an entry with a different value, and the same warning and **Device admin** requirement apply.

A standard schedule uses two entries: a photo slideshow at normal brightness starting in the morning, and a dimmed Clock or Black mode starting in the evening. The motion override configures **Dismiss on motion** explicitly per schedule block, allowing night entries to disable the camera entirely or day entries to enable approach waking even if globally disabled. The face override configures **Dismiss on face** similarly. Combining these controls enables face detection during daylight hours and motion detection at night. Because face detection requires ambient room light, a daytime entry enables Face detection, while an evening entry switches to Motion detection (which takes priority and works in the dark). The **Dismiss on proximity** and **Dismiss on person** overrides work the same way for the [proximity sensor](#proximity-detection) and the [person sensor](#person-detection). Like their switches, the proximity override is disabled on a device without a proximity sensor and the person override appears only on a device with a person sensor. 

Widget and At a glance overrides control [widgets](#widgets) and the [At a Glance](#at-a-glance) row per schedule block. Setting an override to Default follows global configurations, while setting it to Off suppresses those overlays during that schedule window. Overrides cannot enable widgets that have not been configured globally. Schedule edits made while a screensaver is active take effect live.

## Motion Detection

When the [device camera](camera.md) is enabled, two Motion Detection settings control screensaver wake behavior:

* **Dismiss on motion**: Monitors the camera while the screensaver is active, waking the display when motion is detected. The camera runs strictly while the screensaver is on screen.
* **Postpone screensaver on motion**: Monitors the camera between screensaver sessions, continuously resetting the idle timeout clock whenever room movement is detected. This keeps the camera active continuously and requires Dismiss on motion to be enabled.

Motion analysis functions in total darkness, filters out whole-room light shifts (such as TV flashes or turning on a lamp), and suppresses detection for a few seconds during internal app brightness and slide transitions to prevent false wakes. Sensitivity, frame rates, and camera selection are configured in Camera settings (see [Device Camera](camera.md)). Under [Lockdown Mode](kiosk.md), motion events will neither dismiss nor postpone screensavers.

## Face Detection

**Dismiss on face** (under Face Detection) wakes the display only when a person looks directly at the kiosk camera. Someone walking past the device leaves the screensaver active, while turning to face the screen wakes the dashboard. Face detection performs on-device visual analysis without identifying individuals, storing images, or transmitting data. The camera operates strictly during screensaver playback, matching Dismiss on motion behavior.

**Face sensitivity** adjusts the required distance for face detection, calibrated on a scale from 1 to 100:
* A setting of 1 requires a face positioned directly in front of the screen.
* A setting of 100 detects faces up to approximately two meters away using a standard front camera.
* The default setting of 50 triggers at roughly arm's length plus one step back. Frame rate, camera selection, and startup delays are shared with motion detection and tuned in Camera settings.

Core operational rules:
* **Voice interactions pause face detection.** Face and motion analysis pause from the moment a wake word triggers until Voice Satellite finishes listening, ensuring voice interactions do not accidentally dismiss screensavers and freeing CPU cores for audio processing.
* **Dismiss on motion takes priority.** When both motion and face detection are enabled, motion detection takes precedence and face detection remains idle. Disable Dismiss on motion to use face wake.
* **Face detection requires ambient light.** Motion detection works in total darkness, whereas face detection requires sufficient light to resolve facial features. Use the [schedule](#schedule) feature to run Face detection during the day and Motion detection at night.

**Postpone screensaver on face** mirrors Postpone screensaver on motion: the camera monitors for faces between screensaver sessions, resetting the idle timeout clock whenever someone looks at the dashboard to keep the screen awake while being read. This requires Dismiss on face to be enabled and runs the camera continuously. Dismiss on motion retains priority over face postpone settings.

To conserve system resources, the face detection model executes only when frame movement is detected. The lightweight motion grid evaluates frame changes first; if movement occurs or a face was recently detected, the face model runs at most twice per second on a single CPU core. On low-powered hardware, execution rates drop further so that face detection never exceeds roughly 20% of a single CPU core. An empty room incurs zero model inference overhead.

Under [Lockdown Mode](kiosk.md), face events will neither dismiss nor postpone screensavers.

### Camera Preview

**Show camera preview** (under Camera Preview) displays a temporary visual overlay showing what the camera detected upon a face wake event. It renders a small, circular live camera preview with a white border in a screen corner for a few seconds before fading out. This shows the exact frames analyzed by the detector, aiding in camera placement and sensitivity tuning. The preview renders live frames without saving or transmitting data, and touch events pass through the preview to the underlying dashboard.

| Setting | What it does |
| --- | --- |
| Preview duration | Controls preview display time from 3 to 10 seconds (5 seconds default). |
| Preview scaling | Scales preview size from 50% to 150% of default. |
| Preview position | Selects the display corner for the preview overlay (top-right default). |

The preview triggers exclusively when a face dismisses an active screensaver; it does not display for postpone events. The camera stream remains active during the preview window and releases immediately afterward unless Postpone screensaver on face is enabled. Enabling Camera Preview increases the analysis resolution from 320x240 to 640x480 to improve preview image clarity.

## Proximity Detection

Proximity Detection uses the device's physical proximity sensor instead of the camera:

* **Dismiss on proximity**: Monitors the proximity sensor while the screensaver is active, waking the display when an object approaches.
* **Postpone screensaver on proximity**: Monitors the sensor between screensaver sessions, resetting the idle timeout clock while an object remains close. Requires Dismiss on proximity. Proximity sensing incurs virtually zero power overhead as it relies on hardware interrupt lines.

Proximity sensing requires no camera permissions and functions in complete darkness. However, hardware availability is limited: most kiosk-class tablets (such as Galaxy Tab devices, Fire tablets, and Echo Show hardware) lack physical proximity sensors. On unsupported devices, this setting appears disabled. While modern smartphones include proximity sensors, many use virtual "palm proximity" software sensors designed for phone calls that only trigger on direct screen contact. The settings page displays the reported sensor hardware name: physical infrared or time-of-flight sensors (such as STK3310, VCNL4040, or TMD2755) support hover detection at a few centimeters, whereas virtual "palm" or "touch" sensors do not.

Objects resting on the sensor when monitoring begins do not trigger an approach event, preventing tablet cases or mounts from causing continuous wake loops. While an object remains near the sensor, presence checks repeat every few seconds to hold off screensaver activation when Postpone is enabled. Repeat checks do not trigger wake events; only initial approach events dismiss the screensaver. Under [Lockdown Mode](kiosk.md), proximity events will neither dismiss nor postpone screensavers.

## Person Detection

Person Detection utilizes native hardware person sensors on supported devices (such as the Meta Portal):

* **Dismiss on person**: Monitors the hardware sensor while the screensaver is active, waking the display when a person is detected in front of the device.
* **Postpone screensaver on person**: Monitors the sensor between screensaver sessions, continuously resetting the idle timeout clock while a person remains present. Requires Dismiss on person.

Dismiss triggers on person arrival events. If a person is already present when the screensaver launches, it remains active until they leave and return, or until a touch event occurs.

On Meta Portal hardware, this feature utilizes the Smart Camera background tracking service, operating on an internal video feed that never illuminates the camera LED. It detects human bodies at any angle rather than requiring facing faces, and requires a one-time ADB permission grant. It operates independently alongside camera motion and face detection. Full setup details are available in the [Meta Portal](portal.md) guide.

## Starting and Dismissing

The standard method for launching the screensaver is the idle timeout clock. Manual launch options include selecting **Start Screensaver** in the kiosk menu, triggering a mapped [gesture](gestures.md), toggling the ESPHome **Screensaver active** switch, or sending the `startScreensaver` command via the [remote API](remote-api.md) or [JavaScript API](js-api.md).

Touch interactions instantly dismiss the screensaver and reset the idle clock. The one exception is a tap on the left or right fifth of a photo slideshow with **Tap edges to change slides** on, which steps the slide instead (see [Slideshow behavior](#slideshow-behavior)). Additional dismissal triggers include:

* **Wake Word**: Dismisses the screensaver immediately and pauses the idle clock for the entire voice turn so the display remains active during conversation.
* **Camera Motion**: Triggers wake when Dismiss on motion is active.
* **Face Detection**: Triggers wake when Dismiss on face is active.
* **Proximity Sensing**: Triggers wake when Dismiss on proximity is active.
* **Camera Views**: Opening a camera view dismisses the screensaver and pauses the idle timeout clock while the view remains open.
* **Home Assistant Navigation**: Navigating via the Dashboard view select or `haNavigate` dismisses the screensaver to display the target view.
* **DLNA Media**: Casting DLNA video or image media to the kiosk dismisses the screensaver and holds it off during playback. Background DLNA audio playback deliberately does not dismiss the screensaver.
* **Media Player**: Active music playback holds off the screensaver unless the player's **"Now Playing" instead of the screensaver** mode is enabled, which renders a full screen Now Playing view during playback (see [Media Player](sendspin.md)).
* **ESPHome Controls**: Toggling the **Screensaver** master switch off removes active screensavers. Toggling **Screensaver active** off or pressing **Postpone screensaver** dismisses active screensavers and re-arms the timeout clock.
* **Hold Mode**: Activating Hold Mode in Home Assistant settings pins the current view, preventing screensaver activation, pausing dashboard view rotation, and suspending home return timers. Activating Hold Mode dismisses active screensavers. Hold Mode can be toggled from app settings, drawer notices, gestures, optional kiosk menu items, or the Hold mode switch in Home Assistant, with optional auto-expiry timers available.

## Around the Dashboard

While a screensaver obscures the web page, the **Pause dashboard during screensaver** optimization (enabled by default) completely halts web view rendering. This produces the majority of screensaver power and thermal savings (see benchmark details in [Optimizations](optimizations.md)). Dim mode is the single exception, as the dashboard remains visible.

Automated dashboard view rotation pauses while a screensaver is active, resuming from its current position when dismissed. Conversely, the **Return to home dashboard view** timer continues running quietly behind screensavers, ensuring the kiosk resets to the primary home dashboard view overnight without illuminating the display.

When using the Voice Satellite integration on the dashboard, the **Turn off the Voice Satellite screensaver** setting (enabled by default in Voice Satellite settings) automatically disables the web integration's internal screensaver to prevent software conflicts.

## At a Glance

The **At a glance** feature displays a live status row containing up to four Home Assistant entity states across all screensaver modes except the Camera Streams grid. Data updates over an independent Home Assistant subscription while the screensaver is active. Full setup details are available in the [At a Glance](at-a-glance.md) guide.

## Home Assistant

When ESPHome **Expose kiosk entities** is enabled, the screensaver provides comprehensive remote entity controls:
* **Screensaver** master switch
* **Screensaver active** switch (start/dismiss)
* **Postpone screensaver** button (resets idle clock from external automations)
* **Screensaver mode** and **Clock style** select dropdowns
* **Clock background** text entity
* **Screensaver brightness** switch and level slider
* **Screensaver motion detection** and **Screensaver face detection** switches
* **Screensaver proximity detection** switch (on supported hardware)
* **Screensaver next slide** and **Screensaver previous slide** buttons (steps active slideshows or camera rotation grids)

All entities surface natively on the kiosk's primary ESPHome device.