# Fleet Management

One kiosk leads, the others follow. The leader pushes the settings categories a follower was given to it, holds off while the two run different versions and can bring the whole fleet to one release. Identity never travels: each kiosk keeps its name, its Home Assistant, Music Assistant and ESPHome selves and its hardware picks.

The page is **Settings, Fleet Management** on the kiosk and the **Fleet Management** tab in the remote admin, the same cards on both. It needs **Remote management** and **Find other kiosks** on (Settings, Device, Remote Administration): kiosks find each other through the remote admin and the fleet talks over it.

## Roles

| Role | How | Limits |
| --- | --- | --- |
| Leader | **Lead this fleet** on its Fleet Management page | Cannot follow anyone |
| Follower | Accepted a leader's invitation on its own screen | One leader, cannot lead |
| Standalone | The default | Neither |

A kiosk that should share settings with a different set of kiosks leads a fleet of its own. Two fleets on one network are fine.

## Adding a kiosk

1. On the leader, **Add a kiosk** lists the kiosks heard on the network that do not follow this one. A kiosk following another leader shows dimmed and has to leave that fleet first. A kiosk on another version can be added now and syncs once it updates.
2. Pick one, then the profile it gets. **Send invitation**.
3. The invitation appears on that kiosk's screen over whatever it shows and stays under its Settings, Fleet Management until answered. **Accept** there. The remote admin shows the invitation too but cannot answer it: the confirmation is always on the kiosk. No password is involved.
4. The leader's row reads **Waiting for its OK** until then and syncs at once after.

Accepting hands the leader a token good only for the fleet endpoints, honored only while the kiosk lists that leader. **Leave the fleet** forgets the leader, which revokes it.

## Profiles

A profile is a named list of what a follower gets. The built-in **Default** is always there and can be edited; the leader adds more under **Profiles** and hands each follower one, when adding it or later from the row's overflow, **Profile**. The row wears the profile's name as a tag when it is not the Default. Every profile has a page of its own, opened from its row: the name, then **Categories**, **Synced Credentials**, **Include the dashboard** and **Excluded settings**, each opening a dialog that saves on the spot, then the kiosks on it, **Duplicate** and **Delete**. Deleting a profile drops its kiosks back on the Default. Profile names are unique on a leader.

A profile holds:

| Part | What |
| --- | --- |
| Categories | One checkbox per category, in the sidebar's order, each saying what is not synced inside it |
| Credentials | One switch each, so a kiosk can keep its Home Assistant user and still share the Music Assistant and Immich ones |
| Dashboard | Whether the start page and default dashboard travel |
| Excluded settings | Settings left out whatever their category says, each with a way back in and a picker to add any other |

| Switch | Default | Off | On |
| --- | --- | --- | --- |
| Home Assistant token | Off | The kiosk keeps its own, so a kiosk running as another user stays that user | It travels |
| Music Assistant token | On | The kiosk keeps its own | It travels |
| Immich API key | On | The kiosk keeps its own | It travels |
| Include the dashboard | Off | The kiosk keeps the start page and default dashboard it shows | They travel |

The kiosk PIN is not a credential here: it goes with Kiosk Mode. The camera streams configuration goes with Camera Streams.

### Excluded by default

What scales the UI, drives the backlight or sets a volume depends on the panel and the speaker, files and picks only resolve on the device that made them and camera tuning belongs to the camera and its room, so every new profile leaves these out. Any of them can be brought back in the profile and any other setting added.

| Setting | Page |
| --- | --- |
| `browser.zoom` Zoom level | Web Browsing |
| `screensaver.website_zoom` Zoom level | Screensaver, Website mode |
| `screensaver.clock_scale` Clock size | Clock screensaver |
| `screensaver.widget_scale` Widget scaling | Widgets |
| `screensaver.glance_scale` Row scaling | At a Glance |
| `face.preview_scale` Preview scaling | Face Detection |
| `sendspin.player_size` Player size | Floating Player |
| `screen.default_brightness` Default brightness | Screen & Audio |
| `screen.adaptive_min_brightness`, `screen.adaptive_max_brightness`, `screen.adaptive_dark_lux`, `screen.adaptive_bright_lux` | Adaptive brightness |
| `screensaver.brightness_level`, `screensaver.dim_level` | Screensaver |
| `audio.media_volume` Media volume, `audio.assistant_volume` Assistant volume | Screen & Audio |
| `notifications.volume` Notification volume | Notifications |
| `ha.tap_sound_volume` Tap sound volume | Home Assistant Setup, User Interface |
| `screensaver.gallery_items` Photo Gallery selection | Photo Gallery screensaver |
| `screensaver.local_folder` Local media folder | Local Media screensaver |
| `screensaver.clock_background` Clock background photo | Clock screensaver |
| `notifications.chime_file` Notification sound | Notifications |
| `launcher.apps` Apps | App Launcher |
| `motion.sensitivity`, `motion.fps` | Camera |
| `face.sensitivity` | Face Detection |
| `camera.snapshot_resolution` | Camera |
| `browser.cutout_mode` Display cutout | Screen & Audio |

## How the sync runs

| | |
| --- | --- |
| When | A synced setting changes on the leader, a profile or an assignment changes, a follower comes back online, a follower reports a local change to a synced setting or **Sync now** |
| What | The full set of the follower's synced settings every time. The follower applies only what differs, so nothing restarts for a value it already holds |
| Versions | Only between kiosks on the same version name (the build number is ignored). The leader's row says which release a follower needs and sync resumes on its own once they match |
| Drift | A change made on the follower to a synced setting is replaced at the next sync. Its category pages wear a banner saying so |
| Cadence | Followers are polled every 30 seconds while a Fleet Management page is open, every 5 minutes otherwise and on every change |
| Offline | A follower not heard on the network reads **Offline** and is left alone until it is back |

## Updates

**Update the fleet** installs the release offered to each follower behind the leader, followers first and this kiosk last so the leader stays up to drive it. A kiosk with a pinned screen asks on its own screen, as it does for any update. **Keep followers on this version** does the same on its own whenever a follower falls behind and the release the leader runs is offered to it.

## Never synced

These stay per kiosk whatever the list says. The follower drops them itself, whatever a leader sends.

| Group | Keys |
| --- | --- |
| Identity | `device.name`, `esphome.node_name`, `esphome.mac_override`, `esphome.real_mac`, `btproxy.key`, `sendspin.client_id`, `sendspin.local_player_name`, `ha.satellite_entity` |
| Remote administration and the fleet | `remote.enabled`, `remote.port`, `remote.password`, `remote.fleet_discovery`, `fleet.*` |
| Hardware picks | `camera.device`, `motion.camera`, `audio.mic_device`, `audio.speaker_device`, `audio.mic_channel`, `audio.mic_source`, `audio.mic_gain_db`, `audio.mic_agc`, `render.disable_impeller`, `render.legacy_webview`, `ui.scale`, `screen.ambient_display` |
| The followed player | `sendspin.player`, `sendspin.player_source`, `sendspin.player_name` |
| State a kiosk keeps for itself | `screensaver.saved_brightness`, `screensaver.immich_validated`, `sendspin.player_active`, `sendspin.player_pos`, `sendspin.sonos_hosts` |

Files a setting points at do not travel, only their paths: a notification chime, the gallery's photos, the local media folder. A follower without the file falls back the way it would with a missing file of its own. The Voice Satellite selection lives in the page itself and stays with the kiosk as well.

## Remote API

| Endpoint | Method | Token | Description |
| --- | --- | --- | --- |
| `/api/fleet/identity` | GET | none | `{id, name, version, leader, follows}`: who this kiosk is to another kiosk |
| `/api/fleet/invite` | POST | none | `{invite, leader: {id, name, version, port}}`. Checked against the kiosk it came from, then shown on the screen. Rate limited |
| `/api/fleet/invite/<nonce>` | GET | none | `{status}`: `pending`, `accepted` (with `token`, once), `declined`, `unknown` |
| `/api/fleet/status` | GET | fleet | Version, the revision applied, whether a synced setting changed here since, the update state |
| `/api/fleet/apply` | POST | fleet | `{revision, version, settings}`. Held while the versions differ |
| `/api/fleet/leave` | POST | fleet | The leader removed this kiosk |

A fleet token also opens `getUpdateStatus`, `checkUpdateNow` and `installUpdate` under `/api/commands/`, nothing else. The commands both pages draw from: `fleetStatus`, `fleetCandidates`, `fleetInvite`, `fleetSetProfile`, `fleetDeleteProfile`, `fleetAssignProfile`, `fleetSyncable`, `fleetRemove`, `fleetSyncNow`, `fleetUpdate`, `fleetLeave`. `fleetAccept` and `fleetDecline` are refused over the remote API. The WebSocket carries a `fleetsync` event on every change.
