# Kiosk Satellite Media Player

Kiosk Satellite displays and controls music on screen through a floating now-playing card overlaid on the dashboard and an optional full screen "Now Playing" view that replaces the screensaver during active playback. The interface displays artwork, transport controls, lyrics, and queues. It can manage playback originating locally from the device itself or remotely from a secondary media player.

The device's native local player is [Sendspin](https://www.sendspin-audio.com/), a synchronized multi room audio protocol native to [Music Assistant](https://www.music-assistant.io/). Enabling Sendspin registers the kiosk automatically as a player in Music Assistant named after the device, allowing sample-accurate synchronized playback across all Sendspin speakers in the household. Through the Music Assistant integration, the kiosk also exposes a `media_player` entity to Home Assistant with complete metadata, artwork, and volume controls.

Alternatively, the on screen interface can mirror a player located elsewhere: any Music Assistant player, any Home Assistant media player, or a Sonos speaker directly. This accommodates wall mounted displays intended to monitor and steer external speakers without generating local audio output.

Media browsing and queue management occur in Music Assistant (or via its dashboard card), while voice control operates through Voice Satellite.

## Setup

Navigate to **Settings > Media Player** on the device or the matching tab in the remote admin. The page features settings across several categories: Player selection, Sendspin Player, Music Assistant, Sonos, Floating Player, and Now Playing.

A core rule applies to all media sources: both the floating player card and the full screen "Now Playing" view appear only when the selected player has an active track playing or a queue loaded. When nothing is playing or queued, neither interface element is displayed.

### Player

| Setting | Default | Notes |
| --- | --- | --- |
| Player source | This device | Selects what the floating player and Now Playing view display and control: the native Sendspin player, or an external player from Home Assistant, Music Assistant, or a Sonos household. Selecting an external source takes the local Sendspin player offline. |
| Player | Sendspin Player | When "This device" is selected, it defaults to the native Sendspin player. For external sources, this dropdown populates with players available from that specific provider. |
| Show speaker selection pill | on | The chip in the Now Playing view's top left corner that names the player and opens the speaker group menu. Off, the view shows neither. |

### Sendspin Player

Configures the kiosk as a synchronized Music Assistant audio player. These settings are hidden when the kiosk is configured to follow an external player.

| Setting | Default | Notes |
| --- | --- | --- |
| Enable Sendspin player | off | The master toggle for local audio playback. |
| Server | empty | The `host:port` address of the Sendspin server (Music Assistant listens on port 8927). Leave empty for automatic mDNS discovery. Specify the address manually if the kiosk and server reside on different subnets, as mDNS does not cross subnet boundaries. |
| Preferred audio codec | FLAC | Selects between FLAC (lossless), Opus (efficient), or PCM (uncompressed). The server selects the final format based on device capabilities. |
| Audio sync offset | 0 ms | Adjusts audio timing in milliseconds. Use negative values if local output lags behind other speakers in a group (e.g., when outputting to Bluetooth). Applies live. |
| Duck volume during voice interactions | 10% | Reduces music volume to this percentage when the voice assistant listens or speaks. Capped at a maximum of 25% to ensure reliable wake word and speech detection. |

Music Assistant includes native Sendspin support enabled by default, and players register automatically upon connection without requiring server side setup.

### Music Assistant

The Sendspin protocol transmits audio data along with basic track name, artist, and album metadata. Extended information—including synchronized lyrics, queue management, player lists, and kiosk menu shortcuts—is fetched separately from Music Assistant's REST API.

| Setting | Default | Notes |
| --- | --- | --- |
| Server address | empty | The web interface address of the Music Assistant server (typically HTTPS on port 8095). Self-signed SSL certificates are accepted. |
| Auth token | empty | A long-lived access token generated in Music Assistant under **Settings > Users**. Read-only permissions suffice for lyrics, while menu shortcuts browse using the privileges of the token owner. |
| Validate connection | button | Authenticates against the server API to verify credentials and port settings. |
| Show in the kiosk menu | on | Toggles the Music Assistant web shortcut in the kiosk drawer menu. |
| Close after inactivity | 0s | Inactivity timer (in seconds) before the opened Music Assistant web overlay automatically closes and returns to the dashboard. Setting this to `0s` keeps the view open until closed manually. |
| Hide the close button | off | Removes the floating close button from the Music Assistant web overlay, avoiding visual overlap with the page's native controls. The physical back button and inactivity timer still close the view. |

### Sonos

Configures direct integration with local Sonos hardware.

| Setting | Default | Notes |
| --- | --- | --- |
| Adjust the group volume | on | Controls whether the Now Playing volume slider adjusts the entire Sonos group volume or only the local room volume. |
| Speakers | list | Displays discovered Sonos rooms, each with its address and its id (the serial an automation can follow the room by), and a **Forget** option to clear household pairings. **Search** discovers speakers on the local subnet via SSDP. **Add by address** allows manually targeting a speaker IP on a different VLAN. |

### Floating Player

| Setting | Default | Notes |
| --- | --- | --- |
| Show the floating player | on | Toggles the small now-playing card overlay on the dashboard. |
| Player size | Compact | **Compact** provides a display-only card; **Large** adds touch-friendly previous, play/pause, and next transport controls. |
| Hide the paused player after | 3 min | Timeout duration before a paused card and Now Playing view automatically hide from the screen. |
| Keep playing when dismissed | off | When disabled, swiping the floating card away stops audio playback. When enabled, swiping hides the card while audio continues playing in the background. |
| Show in the kiosk menu | off | Adds a toggle entry to the kiosk menu to manually show or hide the floating card. The menu entry remains hidden if nothing is playing or queued. |

### Now Playing

| Setting | Default | Notes |
| --- | --- | --- |
| "Now Playing" instead of the screensaver | off | Enables the full screen media view as an idle screensaver replacement during active playback. |
| Show media controls | on | Displays transport buttons and a progress bar over the background artwork. When enabled, a top-right close button appears and paused tracks remain on screen until the paused timeout expires. |
| Double tap to dismiss | off | Allows a double tap anywhere on the full screen view to dismiss it, removing the explicit close button. Taps on controls or queue rows do not trigger dismissal. |
| Launch Now Playing when music starts playing | on | Instantly launches the full screen view when playback starts rather than waiting for the idle screensaver timeout. |
| Dismiss "Now Playing" on motion | off | When disabled, motion events will not dismiss the full screen music display. |
| Show in the kiosk menu | off | Adds a menu shortcut to open the full screen view directly. Remains hidden if no media is playing or queued. |

### Lyrics

Synchronized lyrics for every player source, on a page of their own.

| Setting | Default | Notes |
| --- | --- | --- |
| Enable lyrics | on | The master switch. Off, the Now Playing view has no lyrics button and nothing is looked up. |
| Lyrics source | LRCLIB | Where the words come from. **LRCLIB** asks the public database directly, with the track's title, artist and duration. **Music Assistant** asks its providers, the user's own .lrc files among them, and needs the server address and token on the Music Assistant page. |
| Fallback to Music Assistant | on | Shown with LRCLIB as the source. If LRCLIB is unreachable, Music Assistant is asked instead, when a connection is configured. Useful for devices that have no internet access: the lyrics then come from Music Assistant on the local network. A track LRCLIB has no lyrics for is not retried there. |
| Lyrics timing | +0.3s | Adjusts lyric line synchronization relative to audio. Positive values display lyric lines earlier. |

## Following Another Player

By default, the floating player card and Now Playing view control the kiosk's native Sendspin output. Setting **Player source** to an external source redirects the interface to track and control another player on the network. The **Player** dropdown populates based on the chosen source:

* **This device**: The native Sendspin player.
* **Music Assistant**: Selects from players listed directly by the Music Assistant server API. Offline players are flagged in the list.
* **Home Assistant**: Selects from any `media_player` entity exposed over the active Home Assistant WebSocket connection. Native Sendspin entities and Music Assistant entities are filtered out of this list to avoid duplicates.
* **Sonos**: Selects Sonos rooms directly over the local network via UPnP. Groups playing together appear as single consolidated entries.

When following an external player, track details, album art, progress, play/pause states, seeking, and lyrics reflect the target player's state. The full screen view displays a badge naming the targeted player.

Capabilities vary slightly by player source:

| Source | Track, Art, Transport | Lyrics | Queue Panel |
| --- | --- | --- | --- |
| This device | Supported | Supported | Supported |
| Music Assistant player | Supported | Supported | Supported |
| Home Assistant media player | Supported | Supported | Not supported |
| Sonos (Direct UPnP) | Supported | Supported | Supported |

Unsupported controls are hidden automatically. For example, if a Home Assistant player does not report position seeking, the progress bar thumb is removed.

Direct Sonos tracking polls the speaker over port 1400 once per second while active, maintaining precise lyric timing, queue jumping, and group volume controls. Regrouping speakers in the official Sonos app automatically updates the target tracking. Album artwork for Spotify or Deezer tracks on Sonos is resolved using public API image lookups to prevent loading failures on isolated VLANs.

When configured to follow an external player, the kiosk acts purely as a remote control: its internal Sendspin player shuts down and reports as offline in Music Assistant. Selecting "This device" brings the local Sendspin player back online. Swiping away the floating card will stop the external player's music unless "Keep playing when dismissed" is explicitly enabled.

## The Music Assistant Shortcut

When a server address is configured, a **Music Assistant** entry appears in the kiosk drawer menu. Clicking this opens Music Assistant's web interface directly over the dashboard inside an overlay. Users can browse libraries, search, manage queues, and trigger playback without unloading the underlying dashboard or interrupting Voice Satellite background listening.

The web interface automatically pre-selects the active player assigned in app settings.

* **Close after inactivity**: Automatically closes the web overlay after a set period of touch inactivity, returning the display to the dashboard. Scrolling and tapping reset the timer.
* **Hide the close button**: Removes the overlay's top-right close button to prevent visual interference with Music Assistant's native interface elements.
* **Automatic Authentication**: The long-lived access token configured in settings is passed to the web interface as it loads, bypassing login screens.

In Kiosk Mode, access to this shortcut is controlled via the **Allowed Actions** menu permissions.

## The Floating Player

The floating card displays album artwork, track title, artist name (with scrolling text for long titles), and a live progress line. The card can be dragged anywhere on screen, and its position is saved across sessions.

The Large card format adds touch-friendly previous, play/pause, and next controls that operate across the entire playback group.

Card behavior:
* **Paused State**: Remains on screen with a play button until the configured pause timeout expires.
* **Dismissal**: A fast swipe gesture dismisses the card and stops audio playback (unless configured to keep playing). A slow drag repositions the card on screen.
* **Voice Interactions**: The card hides automatically during active voice interactions and reappears when the interaction ends.
* **Track Transitions**: Retains the previous track artwork briefly during stream buffering to eliminate visual flickering.

In Kiosk Mode, visibility controls for the card follow the **Floating Player** setting under Allowed Actions.

## Full Screen Now Playing

When enabled, the full screen "Now Playing" view activates during active playback as an idle screensaver replacement. It features blurred, full screen album artwork in the background, sharp centered artwork, and prominent title and artist typography. Track changes cross-fade smoothly.

When **Launch Now Playing when music starts playing** is enabled, the view opens immediately upon track start rather than waiting for the idle timeout. Pausing playback returns the display to the standard screensaver once the pause timeout expires.

### Media Controls

When **Show media controls** is enabled, transport buttons, a progress bar, and secondary toggles appear over the artwork:

* **Transport & Progress**: Displays previous, play/pause, and next buttons alongside elapsed and total track time. On supported players, dragging the progress bar thumb seeks within the track.
* **Left Toggles**: Controls volume and shuffle. Toggling volume replaces the progress bar with a volume slider and a mute button. On Sonos devices, adjusting volume updates the entire group volume when group volume adjustment is enabled.
* **Right Toggles**: Controls synchronized lyrics and queue panels. Side-by-side or stacked layouts adapt dynamically based on screen orientation. The queue panel displays past tracks, the current track, and upcoming items, allowing direct track jumping by tapping any row.
* **Dismissal**: When media controls are enabled, tapping the background does not dismiss the view; users must tap the top-right close button, use a double tap gesture (if **Double tap to dismiss** is on), or press the physical back button.

### Speaker groups

The chip in the top left corner names the player the view shows. Where the source can group players, the chip carries a caret and a tap opens the group menu, the same from every member of a group: the player the music streams from is its title, then the players already in the group, then every player that could join, alphabetical within each, a checkbox on every row. Checking a row puts that player in the group, unchecking takes it out, and the row spins until the source reports the group back. When the shown player follows another, the title names that leader with **Leads the group** under it, and the shown player is a row of its own, tagged **This device** for this device's own player; unchecking it leaves the group.

| Source | Who can join |
| --- | --- |
| This device | Other players Music Assistant can sync with it, over the Music Assistant connection, so the Music Assistant page's server address and token are needed. |
| Music Assistant player | Whatever Music Assistant lets that player sync with. |
| Sonos, direct | Every other room of the household, over the speakers' own interface. |
| Home Assistant media player | No menu: grouping stays with the integration behind the entity. |

### Lyrics

Enabling the lyrics toggle splits the screen to display synchronized lyric lines alongside album artwork. The active line highlights and auto-scrolls in sync with audio playback. For the local Sendspin player, timing relies on Sendspin position timestamps. For external players, timing relies on progress data reported by Music Assistant or Home Assistant.

The words come from the **Lyrics source** on the Lyrics page: LRCLIB's public database by default, or Music Assistant's providers. With LRCLIB as the source and **Fallback to Music Assistant** on, a device that cannot reach LRCLIB asks Music Assistant instead.

The **Lyrics timing** setting applies a global offset (defaulting to +0.3 seconds early) to ensure lyrics display slightly ahead of vocal execution for better readability. Embedded `[offset:]` file tags are applied on top of this setting. Plain, un-timed text lyrics are suppressed.

## Voice Assistant Interplay

Local audio playback interacts directly with the voice assistant:

* **Audio Ducking**: Media volume automatically attenuates to the configured percentage during voice turns (wake word listening, announcements, questions, and timers) and restores instantly upon completion. Ducking occurs directly within the audio pipeline without altering system master volume settings.
* **Stop Command**: Saying the wake word followed by "stop" silences active music or alerts.
* **Screensaver Management**: Active audio playback suppresses standard screensavers. Dashboard view rotation and home return timers continue operating in the background unless Hold Mode is engaged.

## Technical Architecture

The native Sendspin player implements the `player@v1`, `metadata@v1`, and `controller@v1` protocols over a WebSocket connection carrying JSON control frames and binary audio chunks. Time synchronization uses an NTP-style burst exchange feeding a Kalman clock filter, with drift correction applied directly at the DAC level. Audio decoding is handled by Android's native `MediaCodec` framework.

External player tracking uses dedicated connections:
* **Music Assistant**: Monitored via a persistent WebSocket connection receiving active queue state and event pushes.
* **Home Assistant**: Monitored via a `subscribe_entities` WebSocket subscription, routing commands via `media_player` service calls.
* **Sonos**: Polled directly via local UPnP services on port 1400.

The Sendspin client implementation is adapted from [SendspinDroid](https://github.com/chrisuthe/SendspinDroid) (MIT License).

## Troubleshooting

* **Player does not appear in Music Assistant**: Inspect the app logs under **Settings > Logs** for `sendspin` entries. A message reading `connected as kiosksatellite_<id>` confirms a successful handshake. If auto-discovery fails across subnets or VLANs, enter the server IP address manually.
* **Audio is out of sync with other speakers**: Allow a few seconds after connection for the Kalman filter to converge. Static speaker delays can be adjusted using the **Audio sync offset** setting in app settings or Music Assistant.
* **Audio dropouts on Wi-Fi**: Switch the **Preferred audio codec** to Opus to reduce network bandwidth consumption.
* **Sonos speakers not discovered**: Automatic discovery uses local network multicast. If speakers reside on a separate VLAN, add them manually by IP address using **Add by address**.
* **Home Assistant player shows no metadata**: The target `media_player` entity must publish a valid `media_title` attribute. Inputs lacking title metadata (such as line-in or TV sources) will display an empty card until media with metadata is played.