# Screensavers

After a period of inactivity, Kiosk Satellite can transition to a clock, a photo frame, a camera wall, a web page, a Home Assistant dashboard view, or a black panel. The display returns to the live dashboard immediately when someone touches the screen, speaks the wake word, or approaches the kiosk.

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
| Brighten for touch interactions | 5 s | Restores full display brightness for this many seconds after a touch that does not dismiss the screensaver, such as a tap on a notification or a plugin card. 0 turns it off. Appears when Screensaver brightness is enabled. |
| Turn screen off after | 0 (never) | Powers off the physical display panel after the screensaver has been running for the specified duration. |
| Use a black screen instead | off | Appears when **Turn screen off after** is greater than 0. Shows a plain black screen at zero brightness without powering off the panel. Hides widgets, timers, notifications and Now Playing. |
| Wake to screensaver | Off | Picks what brings the screensaver back instead of the dashboard after the screen has turned off: motion, face, proximity, person, the power button and touch. The **Turn screen off after** countdown starts over. See [Turning the Screen Off](#turning-the-screen-off). |
| Pixel shift | off | Periodically shifts on screen elements every minute to prevent image retention on OLED displays. Not applicable to Black mode. |
| Show in the kiosk menu | on | Opens [Device > User Interface > Drawer menu items](drawer-menu.md), where the **Start Screensaver** entry is turned on or off. Turn it off to shorten the menu on a device that never starts the screensaver by hand. The idle timeout, gestures, the ESPHome switch and the API commands still start it. |
| Follow Android animation settings | off | Pauses Weather Mood and the Celestial twinkle on a still frame while Android's **Transition animation scale** is off in Developer options. Turn it on to save CPU on low-power devices where the animation scales are zeroed. |
| Screensaver mode | Black | Selects the active screensaver display mode. Options for the chosen mode appear directly below this selector. |

The **Widgets** configuration group sits directly beneath the mode settings, allowing small overlays to be anchored to display corners.

## The Modes

### Weather Mood

Choose **Weather Mood** and open its subpage to pick a Home Assistant `weather.*` entity. Animated skies follow all 15 Home Assistant weather conditions, including rain, snow, fog, hail, wind and thunderstorms. The scene changes between day, dawn/dusk and night using `sun.sun`. Soft peach tones fade in near the horizon while the upper sky stays blue. The warmth reaches full strength between -2 and +2 degrees and fades out at -6 and +6 degrees. If elevation is unavailable, local time supplies dawn/dusk from 5:30 to 6:30 AM and 5:30 to 6:30 PM. The sun state still controls day and night when available. Otherwise daytime runs from 6 AM to 6 PM.

Use **Scene blur** in the main group to soften the weather scene from 0 to 30 pixels. The clock, weather chips, widgets and At a Glance pills stay sharp.

Weather Mood starts with only the animated scene. Its **Clock** and **Weather information** groups add optional information directly to the scene. All widget types and At a Glance pills remain available. Outside preview mode, if no weather entity is selected for Weather Mood, a black screen asks you to select one in its settings. The clock, weather chips, widgets and At a Glance stay hidden until an entity is selected.

Turn on **Enable clock** to reveal **Font Family**, **Font weight**, **24-hour clock**, **Show AM/PM**, **Show seconds**, **Show date**, **Clock size**, **Clock color** and **Text drop shadow**. The clock uses the same digital face and defaults as the Clock screensaver, with a drop shadow enabled for readability. These settings belong to Weather Mood and do not change the Clock screensaver.

Weather information appears as chips over the scene. A chip at the bottom left shows the conditions icon, temperature and conditions. Each reading gets a matching chip at the bottom right with its icon and value. The chips default to white text with a drop shadow on frosted glass with a thin light rim, so they take on the colors of every sky. The glass blurs the scene behind it, except on 32-bit devices, where the blur would cost too many frames. Devices that do not use the Impeller renderer show tinted chips instead.

Turn on **Enable weather bar** to show the selected entity's temperature and conditions along the bottom, with today's high and low, humidity, wind speed and visibility when available. **High and low** needs a weather entity with a daily forecast. Set **Location name** to add a place name, enable **Feels like** or **Feels like only** for the apparent temperature and switch individual readings off as needed. **Text scale**, **Text color**, **Background opacity** and **Text drop shadow** control the chips. Background opacity sets how dark the glass is, down to text alone at 0%. The reading values match the size of the temperature. Turn on **Show titles** to name each reading above its value. On narrow screens the reading chips move above the main chip and wrap as needed. At a Glance pills and bottom corner widgets sit above the chips. Over Weather Mood the At a Glance pills wear the same glass, tinted by the same Background opacity, so both rows match. They also share the Text drop shadow, and a colored icon shows in its color on a clear disc. Preview scenes leave the readings tied to live weather. No readings appear until the entity reports valid weather.

The **Weather Preview** group on the device and in Remote Admin lets you try any scene. Turn on **Enable weather preview** to reveal **Weather type** and **Time of day**. The active Weather Mood screensaver changes immediately to your selection, including when no weather entity is configured. Turn preview off to follow Home Assistant again. Preview changes only the animated background, so weather widgets continue showing their own entity readings. Preview settings stay local to each kiosk.

**Let alarms take over** (on by default) makes a ringing [alarm](alarms.md) show over the scene: the date line becomes the alarm's label and the weather bar makes way for Snooze and Stop in its glass. Turn it off to ring on the alarm's own screen instead.

Turn off **Lightning flashes** to keep thunderstorm clouds and rain without the flashes. Rainy scenes add drops that land on the glass in front of the sky, rest and sometimes slide down leaving a wet trail. Heavier rain brings more of them. The renderer uses Flutter GPU shaders and canvas drawing from bundled assets. Clouds render a few rows at a time across several frames and fade from one cloud image to the next, so older devices keep a steady frame rate. Each cloud image slides along with the wind until the next one is ready, low clouds faster than high ones, so moving clouds glide instead of jumping. It pauses when the display turns off or the app goes into the background. Android's animation scale does not stop the scene unless **Follow Android animation settings** is on. If weather data becomes unavailable, the scene retains its last known condition. Before the first valid reading it shows a neutral cloudy sky.

Older devices use fewer cloud samples and a smaller cloud image that adjusts when frames remain slow. The renderer caches the sky at the display's resolution and renders a fresh cloud image about once a second, twice as often in full wind. Precipitation, twinkling stars and lightning animate separately at up to 20 frames per second. This reduces repeated GPU work while keeping the sun, moon and stars sharp. Weather Preview changes refresh the background immediately.

### Celestial

Celestial shows the sky above the kiosk as it is right now: the stars down to the faintest you can see by eye, the planets, the Moon in its current phase, the Sun, constellation figures and names, the Milky Way and the brightest galaxies and nebulae. Hills, mountains or plains run along the horizon, or nothing at all. Everything is computed on the kiosk from bundled data, so the screensaver needs no internet connection.

Celestial needs to know where the kiosk is. Pick where that comes from under **Location**:

* **GPS** reads the device's GPS receiver, whether or not **Report location** is on in ESPHome. Most tablets have no receiver. It needs the **Location** permission with precise location, shown under **Required system permissions** right below the Location group, on the device and in the remote admin. On Android 12 and later, approximate location is not enough, and **Grant** asks to change it to precise. Once Android stops asking, **Grant** opens the app's page in the Android settings.
* **Home Assistant home** (the default) uses the home zone set in Home Assistant.
* **Home Assistant entity** uses a person, device tracker or zone you pick.
* **Manual** takes a latitude and longitude you type, like `40.71, -74.01`.

With **GPS**, the sky follows the device's live position while the screensaver runs, so a kiosk that travels keeps the right sky. The kiosk remembers the last GPS fix, so the sky starts there while the receiver looks for a new one, indoors too. Until the very first fix, the screensaver says it is waiting for one.

A **Current location** row shows the coordinates the source found, or why it has none, such as a device without a GPS receiver or an entity without a location. If the chosen source has no position, the screensaver shows a black screen that asks you to choose another.

Turn on **Point at the sky** to make the kiosk a sky viewer on a device with a compass, which Android fuses with the tilt sensors into its rotation vector sensor. Hold the device up and the sky on screen turns with it, roll included, so whatever is in front of you is named on screen. It works with any location source. A pinch still zooms and a double tap still closes the screensaver. While it runs, motion, face, person and proximity detection do not close the screensaver, since moving the device around would trigger them. On a device without a compass, the view stays on touch. A compass that has not moved for a while can be far off, even facing the wrong way. While Android reports it as uncalibrated, a note asks you to move the device in a figure eight, and it goes away once the compass settles.

Drag to look around the sky and pinch to zoom in or out. A single tap does nothing but show a reminder, and a double tap closes the screensaver. The kiosk remembers where you left the view and starts there next time. Until you move it, the view faces the equator with the horizon near the bottom of the screen.

Any touch also brings up a quiet status bar along the bottom of the screen, dim enough for dark-adapted eyes, which goes away after 5 seconds without a touch. Widgets and the At a Glance row step aside while the controls are up. Each control has its own switch under **Controls**:

* **Position** shows the latitude and longitude the sky is seen from.
* **Azimuth** and **Altitude** show the compass direction the center of the screen faces and how high above the horizon it is.
* **Field of view** shows how much of the sky the screen spans, in degrees across its long side.
* **Time** shows the time of the sky. After a timelapse, **Now** returns the sky to the present.
* **Timelapse** speeds up time so you can watch the sky turn. Tap its button to step through 60×, 600× and 3600×, which is one minute, ten minutes and one hour of sky per second, then back to off. Turning it off keeps the sky at the time it reached.
* **Point at the sky switch** is a button that turns Point at the sky on and off. It shows only on devices with a compass.
* **Moon phase** shows the phase of the Moon and how much of it is lit.

| Setting | Default | What it does |
| --- | --- | --- |
| Location | Home Assistant home | Where the sky is seen from: **GPS**, **Home Assistant home**, **Home Assistant entity** or **Manual**. |
| Entity | empty | With **Home Assistant entity**, the person, device tracker or zone to follow. |
| Coordinates | empty | With **Manual**, the latitude and longitude of the kiosk. |
| Landscape | Hills | The ground along the horizon: **Hills**, **Mountains** or **Plains**. **None** leaves out the ground, so the whole screen shows the sky, stars below the horizon included. The air no longer dims stars near the horizon, and the Sun stays hidden while it is down. |
| Point at the sky | off | The view turns with the device's compass and tilt. Needs a compass sensor. |
| Daytime sky | on | Brightens the sky and fades the stars while the Sun is up. Turn it off to show the night sky all day, with the Sun drawn where it is. |
| Milky Way | on | The glow of our galaxy, from NASA's Deep Star Maps. |
| Planets | on | Mercury to Neptune, each shown only when it is bright enough to see. |
| Galaxies and nebulae | on | Soft glows for the Andromeda and Triangulum galaxies and the Orion, Lagoon and Carina nebulae, with names for them and a few star clusters. |
| Light pollution | 0% | Simulates the glow of city lights. Higher values hide the fainter stars, then the Milky Way, and warm the sky near the horizon. At 100% only stars brighter than about magnitude 2 remain, as in a city center. |
| Twinkling stars | on | The stars shimmer, most of all near the horizon. Turn it off to save power: the sky then redraws only every 10 seconds and when you move it. |
| Larger Moon | on | Draws the Moon at three times its real size and the Sun at twice. Off shows both at their true size. |
| Constellation lines | on | Connects the stars of each constellation. The lines are clearest in the middle of the screen and fade out toward its edges. |
| Constellation names | on | Names the constellations. More appear as you zoom in, and names fade out toward the edges of the screen like the lines. |
| Star and planet names | on | Names the Sun, the Moon, the planets, the brightest stars and the galaxies. More stars get names as you zoom in. |
| Compass points | on | Marks north, east, south and west on the horizon. |
| Label size | 100% | Scales the labels on the sky from 50 to 200 percent. |
| Controls | all on | The controls a touch brings up: **Position**, **Azimuth**, **Altitude**, **Field of view**, **Time**, **Timelapse**, **Point at the sky switch** and **Moon phase**. |
| Controls size | 100% | Scales the controls from 50 to 200 percent. |

Positions come from orbital elements and are accurate to a few arcminutes, about a pixel at the closest zoom. Each star is drawn from its apparent magnitude, so brightness and size follow what you would see. Stars dim and redden near the horizon the way the air dims them, and moonlight, twilight and light pollution wash out the fainter ones. The sky follows the clock in real time, unless a timelapse runs.

Constellation names follow the interface language in Spanish, German, French, Russian and Chinese and use the Latin names in the other languages. Star names are the official IAU names.

### Calendar

Shows the [calendar](calendar.md) as the screensaver, on today, with the calendars, colors and hidden chips set up for it. Selecting the mode reveals the **Calendar screensaver** group with one row, **Calendar view**, which picks Day, Week (the default), Month or Schedule. It is separate from the calendar's own **Default view**, so the kiosk menu can open the calendar on one view while the screensaver shows another.

The calendar stays usable while it is the screensaver: tap an event, switch views, move between days and hide calendars with their chips as usual. A tap does not dismiss it. Use the X button in the top corner instead. The calendar's **Close when idle** does not apply, and widgets and the At a Glance row stay off it. Motion, face, proximity and person detection, the wake word, the brightness settings, the schedule and **Turn screen off after** work as in the other modes. Like the open calendar, the screensaver keeps the calendars live from Home Assistant while it shows.

### Dim

Reduces the display backlight to the configured **Dim level** while keeping the live Home Assistant dashboard visible underneath. Because the dashboard remains visible, the **Pause dashboard during screensaver** optimization cannot be applied in this mode. As a result, the browser process continues to consume CPU, GPU, and battery power.

### Black

Displays a completely black screen while leaving the underlying application running. Enabling **Hide all extras** ensures true black output by suppressing widgets, the At a Glance row, and all other visual overlays. It also prevents the At a Glance Home Assistant connection from opening.

### Clock

Renders a full screen clock with four selectable styles via **Style**: **Digital Clock**, **Flip Clock** (split-flap cards), **Roller Clock** (rolling digits styled after the Lenovo Smart Clock 2) or **Hand Clock** (a dial with hands, ticks and numbers). Dates use the app language set under **Device > User Interface > Language**. If the app does not offer the Android language, such as Czech or Italian, dates use the Android language instead.

| Setting | Notes |
| --- | --- |
| Font Family | Available across all faces. Options include Rubik (default app font), Nunito (rounded style similar to Apple StandBy), Inter (clean grotesque style), Oswald (tall condensed digits, the wall clock look), Roboto Slab (a warm slab serif), system font families (System, Serif, Condensed, Monospace, Casual, Cursive), or LCD (segmented LED alarm clock font covering digits, date, and AM/PM). |
| Font weight | Available across all faces. Default matches the face's native style. Options include Light, Regular, Medium, Bold, or Black. The LCD font uses a single fixed weight. |
| 24-hour clock | Applies to every clock face except Hand Clock. |
| Show AM/PM | Digital face only. Appears when **24-hour clock** is off. Turn it off to show the time as 7:45 instead of 7:45 PM. |
| Show seconds | Digital face only. |
| Show date | Digital face only (enabled by default). |
| Clock size | Scales the display size from 50% to 300%. |
| Numbers | Hand Clock only. Shows numbers at 12, 3, 6 and 9 (default) or at every hour. |
| Show seconds hand | Hand Clock only (enabled by default). The seconds hand ticks once a second. |
| Clock color | Digital and Hand faces, each with its own color. On the Hand Clock it colors the hands, numbers and ticks. Flip and Roller styles utilize dedicated custom color controls for cards, digits, and backgrounds. |
| Background color | Digital and Hand faces, each with its own color. Sets the solid color behind the clock (black by default). Setting a white background with a black clock color creates a high-contrast inverted face ideal for e-ink panels. |
| Background photo | Displays a custom background image behind any clock face instead of a solid color. Accepts a path to an image on the device or an `http(s)://` image URL the device fetches itself. |
| Refresh URL background | Minutes between fetches of a URL background. 0 by default, which only fetches when the setting is written. |

When picking a **Background photo** on the device, the image file is copied into internal app storage. The **URL** button on the same row, the remote admin interface and the ESPHome **Clock background** text entity all take a device path or an image URL instead. A URL is fetched by the device, so it can point at anything the device can reach: a file under Home Assistant's `/local/` folder, an Immich shared link, a daily photo service or an image an automation renders. Background images use the **Smart** scaling mode with a dark scrim overlay to maintain clock legibility.

Changes apply live while the clock is running, and writing an empty value clears the photo. Every write reloads the image, even when the value did not change, so an automation can rewrite the entity to fetch a new image served under the same URL, or to pick up a file replaced under its old name. A file replaced in place is also picked up on its own within a minute. The value is limited to 255 characters, the most Home Assistant allows in a text entity, and a failed fetch keeps the current photo and tries again a minute later.

**Night mode** recolors on screen text when the room gets dark to reduce room illumination. It relies on a physical ambient light sensor and is automatically disabled on hardware lacking one.

| Setting | Notes |
| --- | --- |
| Night mode | Disabled by default. |
| Light level | Configurable from 1 to 100 lx (5 lx by default). The clock transitions to night mode at or below this ambient threshold and returns to normal slightly above it to prevent color flickering. |
| Night color | Sets the accent color for digits, dates, At a Glance elements, and corner widgets (muted red by default). |
| Night background | Sets the background display color in dark environments (pure black by default) to eliminate panel glow. |
| Hide background photo | Disabled by default. Hides the photo while Night mode is active so the clock uses the Night background color. Works with every clock face and restores the photo when the room brightens. Changes apply immediately. |
| Hide widgets and At a Glance | Disabled by default. Hides the corner widgets and the At a Glance row while Night mode is active, leaving only the clock. Both come back when the room brightens. Changes apply immediately. |
| Night card color | Flip Clock face only. Sets the card color in the dark (near-black by default). |
| Turn screen off at night after | Configurable from 0 to 60 minutes (0 by default, which keeps the screen on). Turns the screen off once Night mode has lasted the set time and back on when the room brightens. A warning comes up when it is first moved off 0, because some devices misbehave with the display off. Needs the Device Administrator permission, shown under **Required system permissions** at the end of the page. |
| Use a black screen instead | Disabled by default. Shows a black screen at zero brightness instead of powering off the display. No Device Administrator permission is needed. |

**Let alarms take over** (on by default) makes a ringing [alarm](alarms.md) show on the Clock screensaver in its own style: the date line becomes the alarm's label and Snooze and Stop come in under the clock in the clock's colors, Night mode included. Turn it off to ring on the alarm's own screen instead.

**Turn screen off at night after** only applies while the Clock screensaver is showing, including when a schedule picks it. A voice conversation, a ringing alarm, the Now Playing view or another app keeps the screen on and the countdown starts over afterwards. Every wake that leaves the screensaver up also starts the countdown over. The screen comes back on once the light rises past **Light level** by a quarter, or when the slider is set to 0 or Night mode is turned off. A screen turned off by hand or by **Turn screen off after** stays off.

Some light sensors stop reporting while the display is off. On those devices the screen cannot come back on by itself in the morning, so use **Use a black screen instead**. If the Device Administrator permission is missing, the screen stays on and no permission prompt appears at night.

### Home Assistant Media

Streams media served by Home Assistant's media browser, including single images, image folders, video files, or `camera.*` entities (which stream over WebRTC with an MJPEG fallback). **Media source** opens the picker. Selecting an image folder unlocks playlist controls (**Seconds per image**, **Video length**, **Shuffle**, **Include subfolders**, **Transition** and **Tap edges to change slides**). Photos and videos follow the [Slideshow behavior](#slideshow-behavior) rules, while camera streams keep their native aspect ratio.

**Show metadata** puts each photo's details in a corner, read from the photo's own EXIF. **Date taken** shows when it was taken and **Camera details** shows the camera model with the focal length, aperture and ISO. **Metadata position**, **Text drop shadow**, **Text scaling** and **Vignette strength** work as they do on Immich Media. Location is left out because turning GPS coordinates into a place name needs an online lookup service. The details come from JPEG photos. Videos and camera streams show none.

### Local Media

Displays an image slideshow loaded from a local folder on the device. Configuration options include **Local folder** (selected on device or typed into the remote admin), **Seconds per photo**, **Video length**, **Shuffle**, **Include subfolders**, **Transition**, **Fill the screen** and **Tap edges to change slides**.

**Show metadata** puts each photo's details in a corner, read from the photo's own EXIF. **Date taken** shows when it was taken and **Camera details** shows the camera model with the focal length, aperture and ISO. **Metadata position**, **Text drop shadow**, **Text scaling** and **Vignette strength** work as they do on Immich Media. Location is left out because turning GPS coordinates into a place name needs an online lookup service. The details come from JPEG photos. Videos show none.

### Photo Gallery

Operates similarly to Local Media, but selects files using the native system gallery picker. This avoids needing broad storage permissions. Selected images are stored locally to survive device reboots. Options include **Photos** selection, **Seconds per photo**, **Video length**, **Shuffle**, **Transition**, **Fill the screen** and **Tap edges to change slides**.

### Image URL

Shows photos from a single web address that returns an image. The device fetches the address again for every slide, so it suits an endpoint that returns a random photo, a camera snapshot or an image an automation renders. Options include **Image URL**, **Seconds per photo** (60 by default), **Transition**, **Fill the screen** and **Tap edges to change slides**.

The current photo stays on screen until the next one has loaded, so a slow server never fades the screen to black. If a fetch fails, the current photo stays and the device tries again 30 seconds later. If the first fetch fails, the screen says so until a photo loads. The device keeps the last four photos in memory. **Screensaver previous slide** and a tap on the left edge step back through them. A step forward shows those photos again before it fetches a new one. Changing the address fetches from the new one right away.

**Show metadata** works as it does on Local Media, reading the date and camera details from each photo's EXIF. The device fetches the address itself, so it can point at anything the device can reach, such as a file under Home Assistant's `/local/` folder or a photo server on your network.

### Immich Media

Turns the kiosk into an automated photo frame backed by an [Immich](https://immich.app/) server. Includes local image caching, optional metadata overlays, and intelligent photo pairing: portrait photos side by side on landscape screens, landscape photos stacked on portrait screens. Detailed documentation is available on the [Immich](immich.md) guide page.

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

### Home Assistant Dashboard

Shows a Home Assistant dashboard view as the screensaver. Selecting the mode reveals the **Home Assistant Dashboard screensaver** group. Pick the view by tapping the field on its **Dashboard view** row, which opens the dashboard picker the **Go to a dashboard view** gesture also uses. The mode needs a connected Home Assistant.

The view opens in the dashboard's own web view with the same in-page navigation view rotation uses, so Home Assistant does not reload and the Voice Satellite integration keeps running. When the screensaver ends, the dashboard goes back to the view it was on before. With **Return to home dashboard view** on it goes to the home view instead. If something in Home Assistant navigated the dashboard while the screensaver was up, it stays where that navigation left it.

The screensaver follows **HA kiosk mode** by default. Turn on **HA kiosk mode override** to pick what it hides with its own **Hide the header** and **Hide the sidebar** switches. They apply only while the screensaver is up, so the dashboard can keep its header and sidebar for moving between views and the screensaver can still fill the screen.

A tap anywhere dismisses the screensaver without pressing the card under the finger. Turn on **Double tap to dismiss** to use the dashboard while the screensaver is up. Single taps then press buttons, move sliders and open popups, and a double tap dismisses the screensaver. Motion, face, proximity and person detection, the brightness settings, the schedule, widgets and the At a Glance row work as in the other modes. When no view is picked the screensaver keeps whatever the dashboard shows. Like Dim, this mode keeps the dashboard rendering, so **Pause dashboard during screensaver** does not apply.

## Slideshow Behavior

Photo slideshow modes (Home Assistant Media, Local Media, Photo Gallery, Image URL, Immich Media) share unified image processing logic:

* **Transitions**: Offers None, Crossfade, Slide, Zoom, Ken Burns, or Random. Ken Burns applies exclusively to still images (videos crossfade), while Random selects a different transition effect for each slide change.
* **Fill the screen** (Smart by default): Dictates image cropping rules to fit the display panel:

  | Setting | Behavior |
  | --- | --- |
  | Off | Displays the full image frame centered between black bars. |
  | Smart | Crops up to roughly 25% along one axis to fill the display if the image aspect ratio is close to the panel's aspect ratio (covering standard 4:3 and 16:9 camera formats). Portrait and square photos retain their full frame over an enlarged, blurred, and dimmed copy of the image instead of black bars. |
  | Always | Scales the image to cover the display completely regardless of aspect ratio, cropping overflow. A 4:3 image on a 2:1 display loses approximately one-third of its vertical framing. |

* **Videos** play muted. **Video length** (Whole video by default) picks how long. Whole video plays each one to its end, and Same as photos stops it once the seconds per photo run out, or at its end if it is shorter. Videos follow **Fill the screen** too, but one that is not enlarged keeps black bars instead of the blurred backdrop. Unplayable video files are skipped automatically.
* The slideshow playlist builds upon screensaver activation. Newly added files appear during the next screensaver launch rather than mid-session. Image URL has no playlist and fetches a new photo for every slide.
* Images decode at the native panel resolution, and memory for previous slides is released immediately to prevent memory exhaustion on low-RAM devices.
* **Tap edges to change slides** (on by default): A tap on the left or right fifth of the screen shows the previous or next slide and resets its full display interval. Taps on the middle three fifths dismiss the screensaver as usual. Each slideshow mode has its own switch on its settings page, and turning it off makes every tap dismiss again. Home Assistant Media offers it for image folders only, since a single image, video, or camera stream has nothing to step.
* **Manual Stepping via Home Assistant**: Triggering **Screensaver next slide** or **Screensaver previous slide** on the [ESPHome](esphome.md) device advances the slideshow by one item and resets the full display interval. These controls also step Camera Streams rotations. Triggering these actions while other screensaver modes are active performs no operation.

## Widgets

Widgets are small status overlays anchored to display corners, configured within the **Widgets** section of screensaver settings. Each widget claims one of the four display corners (limited to one widget per corner) and includes individual customization options. Widgets overlay all compatible screensaver modes, but are suppressed in Black mode when **Hide all extras** is enabled. 

**Enable screensaver widgets**, on by default, shows or hides all widgets at once and keeps the list as it is. Each widget in the list also has its own switch beside the delete button. A widget that is off stays in the list and keeps its corner there, but it does not show on the screensaver and the photo metadata overlay can use that corner. Widgets stay hidden while **Enable screensaver widgets** is off, even under a [schedule](#schedule) entry that sets **Widgets** to on. Home Assistant can flip the same switch with the [ESPHome](esphome.md) **Screensaver widgets** entity.

Every widget has its own **Scale** slider (-50% to +50%) in its editor, which sizes that widget relative to the others. The **Global widget scaling** slider (50% to 200%) then scales all of them together for the display, keeping their relative sizes, and previews live while the screensaver is running. Widgets draw in Rubik unless the **Global font family** and **Global font weight** rows say otherwise, with the same choices as the Clock screensaver's Font Family and Font weight rows. Each widget's editor has its own **Font family** and **Font weight** pickers, Default following the global rows, so one widget can wear the clock's face while the rest stay in Rubik. When running over the Clock screensaver in Night mode, all active widgets inherit the clock's **Night color** to maintain low light levels. **Text drop shadow**, enabled by default, adds a defined shadow beneath widget text. Turn it off for text without a shadow. Changes preview live. Widgets render over a soft dark vignette to ensure text readability against bright background images. The **Vignette strength** slider (0% to 100%, 40% default) adjusts vignette opacity with live previewing. Setting this to 0% removes shading entirely for a clean frame look.

Widgets hold corner priority over the photo metadata overlay of Immich Media, Home Assistant Media, Local Media and Image URL. If a widget claims a corner, the overlay automatically moves to the next available corner. However, when Immich displays a side-by-side portrait pair, both bottom corners are reserved for photo details, temporarily hiding any widgets assigned to those corners until the next single slide displays. A stacked landscape pair only reserves the bottom corner on the overlay's side, since the top photo's details sit at the bottom of its own half, so the top corners stay free.

### Small Clock

Displays a corner clock over any screensaver mode except Clock, Calendar and Camera Streams:

| Setting | Default | Notes |
| --- | --- | --- |
| Corner | First free corner | Automatically shifts if another widget or overlay claims a corner. |
| Color | White | Sets the text color. |
| 24-hour clock | Off | Independent switch from the main Clock screensaver mode setting. |
| Show AM/PM | On | Appears when **24-hour clock** is off. Turn it off to drop AM or PM from the time. |
| Show date | Off | Displays a localized short date line directly below the time. |

Renders over a soft vignette for legibility and supports pixel shift adjustments. Legacy small clock configurations automatically migrate into standard clock widgets while retaining their original settings and corner assignments.

### Weather

Displays real-time weather data pulled from a Home Assistant `weather` entity over any mode except Calendar and Camera Streams. The widget layout displays top-to-bottom: location name, current temperature with units (e.g., "28°C") with an icon for the current conditions beside it, condition text with a matching icon, humidity, wind speed, and visibility. Units are provided directly by the Home Assistant entity, and the icons on the detail lines render in a monochrome style matching the widget color.

| Setting | Default | Notes |
| --- | --- | --- |
| Weather entity | None | Selected from Home Assistant. The widget remains hidden until an entity is assigned. |
| Location name | Empty | Custom text header displayed above the temperature. Because weather entities lack a city attribute, this must be typed manually. If left empty, the line is hidden. |
| Corner | First free corner | Displays in the first available corner. |
| Color | White | Applies to all text elements and icons. |
| Feels like | Off | Displays apparent temperature alongside actual temperature (e.g., "30°C / 33°C"). Requires entity support. If rounded values match, only a single temperature displays. |
| Feels like only | Off | Replaces the actual temperature reading with the apparent temperature. Takes priority over Feels like, and falls back to actual temperature if apparent data is missing. |
| Location, Forecast, Humidity, Wind speed, Visibility | On | Individual toggles for each data line. Lines automatically hide if the source entity lacks that specific data point. |
| Colored icons | On | Shows the conditions icon next to the temperature in its own colors. Turn it off to draw it in the widget color. While the Clock screensaver's Night mode is on, the icon always takes the night color. |

The conditions icon sits on the corner's outer edge like the detail line icons: left of the temperature in a left corner and right of it in a right corner. Once the sun sets, sunny and partly cloudy show the moon instead of the sun. The kiosk reads that from Home Assistant's `sun.sun` entity, or from the local time (6 PM to 6 AM) when that entity is missing.

Data updates automatically via a live Home Assistant subscription while the screensaver is active. The last received values persist through brief network drops. Forecast condition text utilizes Home Assistant's localized translations (e.g., a server set to Italian displays "Nebbia" instead of "Fog"). Translations are fetched once upon app launch.

### Weather forecast

Lists the coming days of a Home Assistant `weather` entity's daily forecast over any mode except Calendar and Camera Streams. Each row shows the day, an icon for the expected conditions, the high and the low, such as **Mon**, a sun icon, **68°** and **49°**. The columns line up down the list.

| Setting | Default | Notes |
| --- | --- | --- |
| Weather entity | None | Selected from Home Assistant. The widget remains hidden until an entity is assigned. |
| Corner | First free corner | Displays in the first available corner. |
| Color | White | Applies to the days and temperatures, and to the icons when **Colored icons** is off. |
| Days shown | 5 | How many days it lists: 3, 5 or 7. If the integration forecasts fewer days, the widget lists the days it has. |
| Include today | On | Starts the list with today. Turn it off to start with tomorrow, such as next to a **Weather** widget that already shows today. |
| Colored icons | On | Shows the weather icons in their own colors. Turn it off to draw them in the widget color. While the Clock screensaver's Night mode is on, the icons always take the night color. |

Once the sun sets, today's row shows the moon instead of the sun for sunny and partly cloudy, the same as the **Weather** widget. Later days keep their daytime icons. The forecast updates live while the screensaver runs. An entity whose integration has no daily forecast shows nothing, and the low column is left out when the integration only reports highs.

### Battery

Displays the device's physical battery status in a display corner over any mode except Calendar and Camera Streams. Renders an adaptive battery icon, a lightning bolt indicator during external charging, and the current charge percentage.

| Setting | Default | Notes |
| --- | --- | --- |
| Corner | First free corner | Displays in the first available corner. |
| Color | White | Applies to the icon and percentage text. |
| Show percentage | On | Disabling this displays the battery icon only. |
| Only when low | Off | Hides the widget until battery capacity drops to 20% or below. Remains hidden whenever external power is connected. |

Reads hardware battery state directly from Android rather than a Home Assistant entity, operating independently of network connectivity. State re-checks occur every minute, while power cable connection changes update instantly. Devices lacking battery hardware (such as mains-powered boxes) automatically suppress this widget.

### Next alarm

Shows the next [alarm](alarms.md) set on the kiosk when it rings within 24 hours, and the snooze while one runs, over any mode except Calendar and Camera Streams. The corner stays empty the rest of the time. A tap on the widget opens the alarm list. Times follow **Settings > Alarms > 24-hour clock**.

| Setting | Default | Notes |
| --- | --- | --- |
| Corner | First free corner | Displays in the first available corner. |
| Color | White | Applies to the icon and the time. |

### Up next

Shows what is still to come on the [calendar](calendar.md), over any mode except Calendar and Camera Streams: the picture of the person linked to each event's calendar, the start time and the title. A calendar with no person linked shows its initial on its color, and a shared event shows everyone on it. Calendars hidden with their chips are left out. The corner stays empty once nothing else is on in the days shown. A tap on the widget opens the calendar on the Schedule view. Times follow **Settings > Calendar > 24-hour clock**.

| Setting | Default | Notes |
| --- | --- | --- |
| Corner | First free corner | Displays in the first available corner. |
| Color | White | Applies to the times and titles. |
| Events shown | 3 | How many coming events it lists, 1 to 5. |
| Days shown | Today | How far ahead it looks: Today, Today and tomorrow or Next 7 days. |
| Show all-day events | On | Turn this off to list only events with a start time. |
| Colored dots | Off | Marks each event with a small dot in its calendar's color instead of the pictures. Night mode always uses the dots. |

### Entity

Displays a single Home Assistant entity in a display corner over any mode except Calendar and Camera Streams. Styled similarly to the widget family, the layout features the entity icon and value on a single line with the entity name centered underneath. Ideal for displaying specific metrics, such as a room temperature sensor over an Immich photo slideshow.

| Setting | Default | Notes |
| --- | --- | --- |
| Entity | None | Selected by entity name or ID via the picker. The widget remains hidden until assigned. |
| Name | Empty | Custom label displayed under the value. If left empty, the default Home Assistant entity name displays. |
| Displayed value | State | Selects whether to display the primary entity state or a specific attribute value. |
| Visible states | Empty | A comma separated list of values. The widget only shows when its value matches one of them, such as `Open` or `on`. The list matches the displayed value or the raw Home Assistant value and ignores case. Leave it empty to always show the widget. |
| Corner | First free corner | Displays in the first available corner. |
| Color | White | Applies to icon, value, and label text. |
| Show name | On | Disabling this hides the bottom label, displaying only the icon and value. |
| Show icon | On | Disabling this hides the icon, displaying only the value and its name. |

The widget hides completely, vignette included, while the value is blank. A text sensor that clears when an alert ends takes the widget with it and brings it back with the next alert. Unknown and Unavailable still display.

Entity formatting matches At a Glance rules: custom Home Assistant icons display when set (falling back to domain defaults), numeric states round to configured precision with units, and state strings convert to clean text. Values update in real time over a live Home Assistant subscription and persist through brief network drops.

## Brightness

**Screensaver brightness** applies a dedicated display panel brightness level when the screensaver launches, restoring the original brightness when it closes. Dim and Black modes ignore this setting as they use dedicated levels, and active [Schedule](#schedule) entries override it. Adjusting the brightness slider while a screensaver is on screen updates panel output immediately. Pre-screensaver brightness settings persist across app restarts to prevent low night brightness from overwriting default daytime settings.

When [Adaptive brightness](screen.md#adaptive-brightness) is enabled, the screensaver brightness setting defines the baseline output for a bright room. Ambient light dimming scales the screensaver brightness proportionally alongside the dashboard. A clock set to 20% during the day automatically scales down to a fraction of that level in a dark room without requiring slider adjustments.

**Brighten for notifications** (enabled by default) temporarily restores full pre-screensaver display brightness while a [notification](esphome.md#notifications) card is visible on screen. Once all notification cards are dismissed, display brightness returns to the configured screensaver level. Only the backlight level adjusts; clock faces, photos, or black overlays remain unchanged beneath the notification card. This brightening behavior also applies to Dim, Black, and scheduled brightness overrides. Disable this feature in bedroom environments to prevent night notifications from illuminating the room.

**Brighten for touch interactions** (5 seconds by default, up to 15) restores the same brightness after a touch that leaves the screensaver up, so you can see what you are tapping. That covers taps on cards drawn over the screensaver, such as notifications, the Voice Satellite bubble or a plugin overlay, Now Playing controls, a slideshow's edge zones and the first tap of a double tap. Each touch starts the countdown again, and the screensaver level comes back once it runs out. A touch that dismisses the screensaver, or wakes it from a black screen, does not count. Set it to 0 to keep the screensaver dimmed while you use it. Like notifications, it also applies to Dim, Black and scheduled brightness.

## Turning the Screen Off

The screensaver pauses when another application takes the foreground. The idle timeout clock stops counting when Kiosk Satellite moves to the background (such as launching an external app via the App Launcher, a gesture, or Home Assistant, or pressing Home on unmanaged devices). An active screensaver closes so the newly opened app receives standard display brightness, and the idle clock resets when Kiosk Satellite returns to the foreground. Turning off the physical display panel pauses Kiosk Satellite in the same manner, preserving screensaver state upon waking.

**Use a black screen instead** uses the same countdown, including schedule overrides, to cover the app with a plain black screen at zero brightness. It keeps the panel powered on and does not need Device admin permission. Widgets, timers, notifications and Now Playing stay hidden until the screen wakes. Touch restores the dashboard and its brightness. Detection follows the existing dismiss switches, including **Only when screen is off** and **Wake to screensaver**. A detection picked under **Wake to screensaver** restores the configured screensaver and starts a fresh countdown. With **Touch** picked, the first touch does the same and a second touch opens the dashboard.

The screensaver holds a CPU wake lock while active, preventing Android's system display timeout from turning off the screen. **Turn screen off after** powers off the display panel after the screensaver has been running for a set duration. Both the global setting and schedule overrides range from 1 to 60 minutes in 1-minute increments. Set the value to 0 to disable panel power off. Powering off the display panel requires the **Device admin** permission (**Settings > Device > Permissions Manager**). If this permission is missing, a warning is logged and the panel remains powered on.

Android automatically arms the lock screen when display admin power-off is called, regardless of whether a PIN is configured. Waking a panel to an active lock screen causes the display to turn off again seconds later while the kiosk remains paused underneath. To prevent this, Kiosk Satellite automatically clears unsecured lock screens (swipe-to-unlock screens without PINs, patterns, or passwords) upon waking. On Android 10 and newer, clearing lock screens requires the **Display over other apps** permission. Secured lock screens are left intact. The kiosk waits behind them until someone unlocks the device, unless **Show over lock screen** is on under **Screen & Audio > Screen**, which shows the dashboard on top of them. Fire OS 8 strictly blocks non-Amazon apps from clearing lock screens, requiring a specific ADB setting change and reboot (see [Amazon Fire tablets](fire.md)). Kiosks configured to turn off display panels operate best with lock screens disabled entirely.

The screensaver session remains active behind a dark panel, ensuring symmetrical wake behavior across all trigger sources. Supported wake triggers include [camera motion detection](microphone.md) (on supported hardware where background camera sessions survive screen off), wake word detection, toggling the ESPHome **Screensaver active** switch off, or calling `stopScreensaver` via Home Assistant automations. All wake triggers return the display directly to the live dashboard rather than the screensaver. Physical power button presses and double-tap-to-wake gestures act as touch interactions, returning to the dashboard and resetting the idle timeout clock. Under [Lockdown Mode](kiosk.md) or with **Power button** picked under **Wake to screensaver**, screensavers persist through these wake events as they do for motion. 

The single wake event that preserves screensaver state is toggling display power via the ESPHome **Screen** light entity. Turning the Screen light entity on in the morning restores the active screensaver with a fresh power-off countdown, allowing an automation to subsequently turn off **Screensaver active** when it is time to display the dashboard.

**Wake to screensaver** gives other wakes that same behavior. Its box opens a list to pick from: **Motion**, **Face**, **Proximity**, **Person**, **Power button** and **Touch**. A picked wake after the panel has powered off only turns the screen back on: the screensaver is still up, the **Turn screen off after** countdown starts over and a quiet room lets the panel go dark again. Anything not picked opens the dashboard as before. This is the photo frame pattern: someone walking into the room brings the photos back and nobody sees the dashboard until they ask for it. The setting does nothing while **Turn screen off after** is at 0.

* **Motion**, **Face**, **Proximity** and **Person** still need their own Dismiss switch (or a schedule override) to wake the panel at all. Detection on a lit screensaver keeps its normal rules, so pair it with **Only when screen is off** on each detection type you use if the visible slideshow should survive people moving about.
* **Power button** covers every wake Kiosk Satellite did not start itself, because Android does not tell apps what woke the screen. That includes the power button (on an Echo Show running LineageOS, that is the mute button on top), double-tap to wake and any other app turning the screen on.
* **Touch**: the first touch brings the screensaver back and a second touch opens the dashboard. A panel that **Turn screen off after** powered off takes no touches, so this applies when **Use a black screen instead** keeps the panel on. Until **Turn screen off after** is above 0 and **Use a black screen instead** is on, **Touch** is grayed out in the list. Waking a powered-off panel with double-tap to wake counts as **Power button**.

The wake word, the ESPHome **Screensaver active** switch and `stopScreensaver` always dismiss to the dashboard. Before **Wake to screensaver** became a list it was a switch. A kiosk that had it on picks everything except **Touch** after the update, and one that had it off picks nothing.

Example configuration workflow: Display photo slideshows during the day, transition to Black mode in the evening via the [schedule](#schedule), and set **Turn screen off after** to 10 minutes. The display turns off completely overnight after the room empties, and the first morning wake event (motion or wake word) restores the dashboard immediately. Pick **Motion** under **Wake to screensaver** and the morning motion brings the photos back instead, with the dashboard a touch away.

## Schedule

**Scheduled screensavers** allows switching between different screensaver modes at specific times of day. Entries configured under **Times** specify a start time, a screensaver mode, a dedicated **Screensaver brightness** toggle, a dedicated **Turn screen off after** toggle and feature overrides for motion, face, proximity, person, widgets, At a glance and Now Playing. Tap any schedule entry to edit its properties. Each scheduled entry remains active from its start time until the next scheduled entry, with the final entry of the day carrying over past midnight. Schedules apply uniformly every day without day-of-week parameters.

When a schedule entry's brightness toggle is disabled, it inherits global [Brightness](#brightness) settings (following [Adaptive brightness](screen.md#adaptive-brightness) curves if enabled). When enabled, the schedule entry's brightness slider sets a fixed display level for those hours (excluding Black mode).

The **Turn screen off after** toggle works the same way for the [screen off timer](#turning-the-screen-off). Disabled, the entry follows the global slider. Enabled, the entry's own slider sets the countdown for those hours, starting from the global slider's value, and 0 keeps the screen on even when the global slider is set. A day entry can keep a clock lit while a night entry powers the panel off a few minutes after the screensaver starts, which is darker than Black mode and saves battery. The countdown starts over when the schedule crosses into an entry with a different value, and the same warning and **Device admin** requirement apply.

A standard schedule uses two entries: a photo slideshow at normal brightness starting in the morning, and a dimmed Clock or Black mode starting in the evening. The motion override configures **Dismiss on motion** explicitly per schedule block, allowing night entries to disable the camera entirely or day entries to enable approach waking even if globally disabled. The face override configures **Dismiss on face** similarly. Combining these controls enables face detection during daylight hours and motion detection at night. Because face detection requires ambient room light, a daytime entry enables Face detection, while an evening entry switches to Motion detection (which takes priority and works in the dark). The **Dismiss on proximity** and **Dismiss on person** overrides work the same way for the [proximity sensor](#proximity-detection) and the [person sensor](#person-detection). Like their switches, the proximity override is disabled on a device without a proximity sensor and the person override appears only on a device with a person sensor. 

Widget and At a glance overrides control [widgets](#widgets) and the [At a Glance](#at-a-glance) row per schedule block. Setting an override to Default follows global configurations, while setting it to Off suppresses those overlays during that schedule window. Overrides cannot enable widgets that have not been configured globally. Schedule edits made while a screensaver is active take effect live.

**Show Now Playing next to the screensaver** controls the music display for each schedule entry. **Default** follows the global **Show alongside screensaver** setting. **On** requests the shared layout when Now Playing is enabled and has a track to show. **Off** hides Now Playing entirely during those hours and prevents playback from launching it automatically. Music keeps playing. This lets a nighttime screensaver keep its own brightness and dismissal rules even when **Override screensaver brightness** is enabled for shared layouts. The override updates live when you edit the schedule or cross a scheduled start time, including midnight.

## Motion Detection

When the [device camera](camera.md) is enabled, two Motion Detection settings control screensaver wake behavior:

* **Dismiss on motion**: Monitors the camera while the screensaver is active, waking the display when motion is detected. The camera runs strictly while the screensaver is on screen.
* **Only when screen is off**: Keeps the visible screensaver up when motion is detected. Once the display turns off, motion dismisses the screensaver and wakes the dashboard. Requires Dismiss on motion.
* **Postpone screensaver on motion**: Monitors the camera between screensaver sessions, continuously resetting the idle timeout clock whenever room movement is detected. This keeps the camera active continuously and requires Dismiss on motion to be enabled.

Motion analysis functions in total darkness, filters out whole-room light shifts (such as TV flashes or turning on a lamp), and suppresses detection for a few seconds during internal app brightness and slide transitions to prevent false wakes. Sensitivity, frame rates, and camera selection are configured in Camera settings (see [Device Camera](camera.md)). Under [Lockdown Mode](kiosk.md), motion events will neither dismiss nor postpone screensavers.

### External Motion Sensor

A Home Assistant sensor can detect motion in place of the camera, for a tablet whose camera does not work or a room that already has a motion sensor. Turn on **Use Home Assistant entity** under **Screensaver > Motion Detection > External Motion Sensor**, then pick the sensor in **Motion sensor entity**. The picker lists occupancy, motion and presence binary sensors. Once one is picked, the row shows whether it reads Detected or Clear.

With the switch on, the entity drives **Dismiss on motion**, **Only when screen is off** and **Postpone screensaver on motion** above it, and the camera no longer runs for them. Neither the Camera switch nor a camera on the device is needed. The sensor turning on dismisses the screensaver. While it stays on, it postpones the screensaver the way movement does, but it never dismisses a screensaver that started while it was already on. When it clears, the idle timeout runs out as usual and the screensaver can turn the screen off after its own delay. The **Motion** `binary_sensor`, face detection and the Show fingers gesture keep using the camera. Dismiss on motion still takes precedence over Dismiss on face.

## Face Detection

**Dismiss on face** (under Face Detection) wakes the display only when a person looks directly at the kiosk camera. Someone walking past the device leaves the screensaver active, while turning to face the screen wakes the dashboard. Face detection performs on-device visual analysis without identifying individuals, storing images, or transmitting data. The camera operates strictly during screensaver playback, matching Dismiss on motion behavior.

Enable **Only when screen is off** under Face Detection to keep the visible screensaver up when a face is detected. Once the display turns off, a face dismisses the screensaver and wakes the dashboard. This requires Dismiss on face. Camera Preview appears only when the face actually dismisses the screensaver.

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
* **Only when screen is off**: Keeps the visible screensaver up when something approaches. Once the display turns off, a new approach dismisses the screensaver and wakes the dashboard. Requires Dismiss on proximity.
* **Postpone screensaver on proximity**: Monitors the sensor between screensaver sessions, resetting the idle timeout clock while an object remains close. Requires Dismiss on proximity. Proximity sensing incurs virtually zero power overhead as it relies on hardware interrupt lines.

Proximity sensing requires no camera permissions and functions in complete darkness. However, hardware availability is limited: most kiosk-class tablets (such as Galaxy Tab devices, Fire tablets, and Echo Show hardware) lack physical proximity sensors. On unsupported devices, this setting appears disabled. While modern smartphones include proximity sensors, many use virtual "palm proximity" software sensors designed for phone calls that only trigger on direct screen contact. The settings page displays the reported sensor hardware name: physical infrared or time-of-flight sensors (such as STK3310, VCNL4040, or TMD2755) support hover detection at a few centimeters, whereas virtual "palm" or "touch" sensors do not. Some devices, such as the Sonoff NSPanel Pro and the Lenovo Smart Clock, report a raw reading that rises as something comes closer instead of a distance. Kiosk Satellite recognizes these and treats a clear rise over the resting reading as an approach, which on the NSPanel Pro reaches about 20 cm.

Objects resting on the sensor when monitoring begins do not trigger an approach event, preventing tablet cases or mounts from causing continuous wake loops. While an object remains near the sensor, presence checks repeat every few seconds to hold off screensaver activation when Postpone is enabled. Repeat checks do not trigger wake events; only initial approach events dismiss the screensaver. Under [Lockdown Mode](kiosk.md), proximity events will neither dismiss nor postpone screensavers.

## Person Detection

Person Detection utilizes native hardware person sensors on supported devices (such as the Meta Portal):

* **Dismiss on person**: Monitors the hardware sensor while the screensaver is active, waking the display when a person is detected in front of the device.
* **Only when screen is off**: Keeps the visible screensaver up when someone arrives. Once the display turns off, a new arrival dismisses the screensaver and wakes the dashboard. Requires Dismiss on person.
* **Postpone screensaver on person**: Monitors the sensor between screensaver sessions, continuously resetting the idle timeout clock while a person remains present. Requires Dismiss on person.

Dismiss triggers on person arrival events. If a person is already present when the screensaver launches, it remains active until they leave and return, or until a touch event occurs.

To use the sensor in Home Assistant without changing the screensaver, turn on **Enable person sensor** under **Camera > Person Sensor** instead. See [Meta Portal](portal.md#person-sensor).

On Meta Portal hardware, this feature utilizes the Smart Camera background tracking service, operating on an internal video feed that never illuminates the camera LED. It detects human bodies at any angle rather than requiring facing faces, and requires a one-time ADB permission grant. It operates independently alongside camera motion and face detection. Full setup details are available in the [Meta Portal](portal.md) guide.

## Starting and Dismissing

Each detection page has its own **Only when screen is off** toggle in the app and Remote Admin. These toggles default to off. Enable them for each detection type you use to enjoy a photo slideshow without nearby activity dismissing it. Set **Turn screen off after** to the desired viewing time. Detection during that time leaves the countdown alone and touch still dismisses the screensaver. Black mode and zero brightness alone do not count as screen-off. The display must power off or the screen-off countdown must reach the plain black screen with **Use a black screen instead** enabled.

The toggles restrict dismissal, so the camera and sensors keep monitoring while the screensaver is visible and after the display turns off. Postpone settings still control activity before the screensaver starts. Schedule detection overrides still decide whether a detection type is enabled and **Only when screen is off** also applies when a schedule enables it. Motion retains priority over face detection.

What a detection does once the display has turned off is decided by **Wake to screensaver** (see [Turning the Screen Off](#turning-the-screen-off)). A detection that is not picked there wakes the dashboard. A picked one only lights the panel and the screensaver carries on.

The standard method for launching the screensaver is the idle timeout clock. Manual launch options include selecting **Start Screensaver** in the kiosk menu, triggering a mapped [gesture](gestures.md), toggling the ESPHome **Screensaver active** switch, or sending the `startScreensaver` command via the [remote API](remote-api.md) or [JavaScript API](js-api.md).

Touch interactions instantly dismiss the screensaver and reset the idle clock. There are four exceptions. A tap on the left or right fifth of a photo slideshow with **Tap edges to change slides** on steps the slide instead (see [Slideshow behavior](#slideshow-behavior)). The [Celestial](#celestial) screensaver takes a double tap, since a drag there looks around the sky. The [Website](#website) and [Home Assistant Dashboard](#home-assistant-dashboard) screensavers take a double tap when their **Double tap to dismiss** is on. The [Calendar](#calendar) screensaver stays until its X button is pressed. Additional dismissal triggers include:

* **Wake Word**: Dismisses the screensaver immediately and pauses the idle clock for the entire voice turn so the display remains active during conversation.
* **Camera Motion**: Triggers wake when Dismiss on motion is active.
* **Face Detection**: Triggers wake when Dismiss on face is active.
* **Proximity Sensing**: Triggers wake when Dismiss on proximity is active.
* **Camera Views**: Opening a camera view dismisses the screensaver and pauses the idle timeout clock while the view remains open.
* **Home Assistant Navigation**: Navigating via the Dashboard view select or `haNavigate` dismisses the screensaver to display the target view.
* **DLNA Media**: Casting DLNA video or image media to the kiosk dismisses the screensaver and holds it off during playback. Background DLNA audio playback deliberately does not dismiss the screensaver.
* **Media Player**: Active music playback holds off the screensaver unless the player's **"Now Playing" instead of the screensaver** mode is enabled, which renders a full screen Now Playing view during playback (see [Media Player](sendspin.md)).
* **ESPHome Controls**: Toggling the **Screensaver** master switch off removes active screensavers. Toggling **Screensaver active** off or pressing **Postpone screensaver** dismisses active screensavers and re-arms the timeout clock.
* **Hold Mode**: Activating Hold Mode in Home Assistant settings pins the current view, preventing screensaver activation, pausing dashboard view rotation, and suspending home return timers. Activating Hold Mode dismisses active screensavers, except a Now Playing view you opened yourself, which stays on screen. Hold Mode can be toggled from app settings, drawer notices, gestures, optional kiosk menu items, or the Hold mode switch in Home Assistant, with optional auto-expiry timers available.

## Around the Dashboard

While a screensaver obscures the web page, the **Pause dashboard during screensaver** optimization (enabled by default) completely halts web view rendering. This produces the majority of screensaver power and thermal savings (see benchmark details in [Optimizations](optimizations.md)). Dim and Home Assistant Dashboard are the exceptions, as the dashboard remains visible.

Automated dashboard view rotation pauses while a screensaver is active, resuming from its current position when dismissed. Conversely, the **Return to home dashboard view** timer continues running quietly behind screensavers, ensuring the kiosk resets to the primary home dashboard view overnight without illuminating the display. If the start URL has a hash, such as a Bubble Card popup address, the return lands on that view with the popup open. Under the Home Assistant Dashboard screensaver that return happens when the screensaver ends. Now Playing can land somewhere else with its [After dismissing](sendspin.md#full-screen-now-playing) setting.

When using the Voice Satellite integration on the dashboard, the **Turn off the Voice Satellite screensaver** setting (enabled by default in Voice Satellite settings) automatically disables the web integration's internal screensaver to prevent software conflicts.

## At a Glance

The **At a glance** feature displays a live status row containing up to four Home Assistant entity states across all screensaver modes except Calendar and the Camera Streams grid. Data updates over an independent Home Assistant subscription while the screensaver is active. Full setup details are available in the [At a Glance](at-a-glance.md) guide.

## Home Assistant

When ESPHome **Expose kiosk entities** is enabled, the screensaver provides comprehensive remote entity controls:
* **Screensaver** master switch
* **Screensaver schedule** switch (turns scheduled screensavers on or off)
* **Screensaver active** switch (start/dismiss)
* **Postpone screensaver** button (resets idle clock from external automations)
* **Screensaver mode** and **Clock style** select dropdowns
* **Clock background** text entity
* **Screensaver brightness** switch and level slider
* **Screensaver motion detection** and **Screensaver face detection** switches
* **Screensaver proximity detection** switch (on supported hardware)
* **Screensaver next slide** and **Screensaver previous slide** buttons (steps active slideshows or camera rotation grids)

All entities surface natively on the kiosk's primary ESPHome device.

Automations can follow the screensaver through the `esphome.kiosk_satellite_screensaver` [event](events.md#screensaver). Apps on the kiosk itself, like Tasker or MacroDroid, can use [Android Broadcasts](android-broadcasts.md#screensaver).
