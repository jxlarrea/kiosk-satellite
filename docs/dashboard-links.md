# Dashboard Links

A dashboard button can open the kiosk's own features or another Android app by pointing its tap action at a link with one of two schemes Kiosk Satellite claims. The link never leaves the dashboard: the app intercepts it, runs what it names and the page stays put. Anything on a dashboard that takes a URL works, so a button card's `url` tap action, a picture elements icon, a tile card or a link in a markdown card all do the same thing.

```yaml
type: button
name: Apps
icon: mdi:apps
tap_action:
  action: url
  url_path: ks://apps
```

Only these two schemes are claimed. Chromium's `intent://` links are refused on purpose, since they can carry any component and extras.

## Kiosk features: `ks://`

A `ks://` link runs the same action a [gesture](gestures.md) can, with the same rules. The app launcher refuses when it is off or has no apps picked, the intercom refuses when it is off, and the outcome shows in a toast when the link cannot do what it names. The Allowed Actions of a restricted kiosk menu are not consulted: a link is one way to keep a feature reachable while its menu row is hidden.

| Link | What it does |
| --- | --- |
| `ks://apps` | Opens the [app launcher](kiosk.md) overlay. `ks://launcher` is the same thing. |
| `ks://now-playing` | Opens the full-screen Now Playing view for the selected media player. Requires Now Playing to be enabled and a track to be loaded. |
| `ks://player` | Shows the floating [media player](sendspin.md) card. |
| `ks://music-assistant` | Opens Music Assistant's web interface for the kiosk's player. Requires a Music Assistant server address. |
| `ks://camera` | Shows the default [camera view](cameras.md). |
| `ks://camera/<view name or id>` | Shows that camera view. The name ignores case, and a dash or underscore can stand in for a space, so `ks://camera/front-door` shows Front Door. The ID is under View ID when you edit the view in Camera streams and keeps working if the view is renamed. |
| `ks://camera/close` | Closes whatever camera view is showing. |
| `ks://intercom` | Opens the [intercom's](intercom.md) Call a kiosk sheet. |
| `ks://intercom/<kiosk id>` | Calls that kiosk straight away. The id is the one under Intercom, Kiosks. |
| `ks://intercom/<kiosk id>/video` | Calls that kiosk with this kiosk's camera on, like the video button on the roster. It runs only when someone taps the link on this kiosk's screen, never from a page script or Home Assistant. If either kiosk cannot take video, the call is voice only. |
| `ks://screensaver` | Starts the screensaver. |
| `ks://screensaver/stop` | Stops it. |
| `ks://alarms` | Opens the full screen [alarm](alarms.md) list. |
| `ks://alarms/next` | Opens the alarm that rings next, snoozed alarms included, on its details page. Opens the list when no alarm is set. |
| `ks://timers` | Opens the full screen [timers](timers.md) view. |
| `ks://calendar` | Opens the [calendar](calendar.md) on its default view. |
| `ks://calendar/<view>` | Opens the calendar on `day`, `week`, `month` or `schedule`. |
| `ks://music-library` | Opens the [Music Library](music-library.md). It does nothing until a source is set up. |
| `ks://voice` | Starts a voice command, as if the wake word fired. Requires [Voice Satellite](voice-satellite.md) to be on. |
| `ks://voice/stop` | Dismisses a ringing timer, or ends the voice command in progress. |
| `ks://voice/mute` | Mutes the wake word, or unmutes it when it is muted. The same mute as the Voice Satellite **Mute** switch in Home Assistant. |
| `ks://plugin/<plugin id>/<action id>` | Runs that [plugin](plugins.md) action, the same as its entry in the kiosk menu. Open the action on the plugin's page to copy the link from **Dashboard link**. Anything after the action ID goes to the plugin, such as a camera name in `ks://plugin/<plugin id>/<action id>/front-door`. The plugin's documentation says what it accepts. |
| `ks://hold` | Toggles hold mode, which pins the current view. |
| `ks://ha-kiosk` | Toggles HA kiosk mode, the Home Assistant header and sidebar. |
| `ks://android-settings` | Opens the Android Settings app with the kiosk running behind it. |

Exit, restart and the settings pages are deliberately not offered. The first two the kiosk menu confirms with a dialog and the third sits behind the exit gesture and PIN, and a dashboard tap should not get around either.

## Other apps: `app://`

`app://<package name>` opens another installed app, keeping the kiosk running in the background so its Home Assistant entities and the wake word stay alive. The clock app to set an alarm, a music app, a browser, whatever is installed. Use the app's package name, for example `app://com.android.deskclock`. The [app launcher's](kiosk.md) return feature brings the kiosk back after the app goes untouched, when it is enabled.

A link that names an app which is not installed shows a toast saying so.
