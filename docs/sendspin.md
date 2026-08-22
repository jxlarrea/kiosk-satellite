# Kiosk Satellite Sendspin Player

Kiosk Satellite can act as a [Sendspin](https://www.sendspin-audio.com/)
player: the synchronized multi-room audio protocol native to
[Music Assistant](https://www.music-assistant.io/). Enable it and the
tablet appears as a player in Music Assistant automatically, named after
the device name, playing in sample-accurate sync with every other
Sendspin speaker in the house. Through the Music Assistant integration it
also shows up in Home Assistant as a `media_player` entity with full
metadata, artwork and volume control.

Browsing and queueing happen in Music Assistant (or its dashboard card),
voice control through Voice Satellite. On screen, the kiosk provides a
floating now-playing card and an optional full-screen "Now Playing" view
that stands in for the screensaver while music plays.

## Setup

Settings → **Music Assistant** on the device, or the matching tab in the
remote admin. The page opens on the Music Assistant group described
further down; the **Sendspin player** group below it holds the settings in
this table.

| Setting | Default | Notes |
| --- | --- | --- |
| Enable Sendspin player | off | The master switch. |
| Server | | `host:port` of the Sendspin server (Music Assistant listens on port 8927). Leave empty to discover the server via mDNS; note that mDNS does not cross subnets, so set the address explicitly when the tablet and the server live on different networks. |
| Preferred audio codec | FLAC | FLAC (lossless), Opus (efficient) or PCM (uncompressed). The server makes the final choice from what the device offers. |
| Duck volume during voice interactions | 10% | While the voice assistant listens or speaks, music drops to this fraction of its volume. Capped at 25% so wake word and speech detection stay reliable. |
| Show the floating media player | on | The now-playing card described below. |
| Player size | Compact | Compact is display-only; Large adds previous, play/pause and next buttons sized for touch. |
| Hide the paused player after | 3 min | How long a paused card stays before hiding itself. |
| "Now Playing" instead of the screensaver | off | The full-screen view described below. |
| Dismiss "Now Playing" on motion | off | Off, only touch dismisses it, so someone walking past does not interrupt the music display. |

### Music Assistant

The Sendspin protocol carries the audio and the track's name, artist and
album, and nothing beyond that. Anything richer comes from Music Assistant's
own API, which is a separate address with its own token.

| Setting | Default | Notes |
| --- | --- | --- |
| Server address | | The Music Assistant server's address as its web interface shows it, usually https on port 8095. A self-signed certificate is accepted. |
| Auth token | | A long-lived token from Music Assistant, under Settings then Users. Read access is enough for lyrics; the shortcut below browses as whoever the token belongs to. |
| Validate connection | | Opens the API and authenticates, so a wrong port and a wrong token report differently. |
| Player to control | This device | Follow and control another Music Assistant player instead of this device's own, described below. |
| Show in the kiosk menu | on | The shortcut described below. |
| Close after inactivity | 0s | Seconds without a touch on the Music Assistant page before it closes itself and the dashboard returns. Zero leaves it open until someone closes it. |
| Hide the close button | off | Remove the floating close button from the Music Assistant page, for the corner it shares with the page's own controls. The back button and the inactivity timer still close it. |
| Show lyrics | off | Synced lyrics on the "Now Playing" screen, described below. |
| Lyrics timing | +0.3s | Shifts the lyrics against the music. Positive shows each line earlier. |

Music Assistant's Sendspin provider is built in and always enabled, and
players register themselves on connection: there is nothing to add on the
server side.

## Controlling another player

By default the floating card and the "Now Playing" screen belong to this
device's own player: what plays here is what they show. **Player to
control** points them at any other Music Assistant player instead — the
kitchen speakers, a Sonos, a whole sync group — for the wall tablet whose
job is to show and steer the music without making any of it. Pick a player
from the list (it is the server's own, fetched live) and the card, the
full-screen view and the transport buttons all follow that player: its
track, its artwork, its progress, its play and pause. The kiosk menu's
Music Assistant shortcut opens on that player too.

With a remote player picked the device is a remote control, not a player:
its own Sendspin player shuts down and shows as offline in Music
Assistant, so nobody queues music to a screen that was never meant to make
any. The settings follow suit — everything about the local player (the
enable switch, server, codec, sync offset, voice ducking, lyrics) leaves
the settings for the duration, while the card and Now Playing rows stay,
since they are what the mode is for. Pick **This device** and the player
comes back online with all of its rows.

One behavior carries over unchanged: flinging the card away stops the
remote player's music, exactly as it does locally, unless "Keep playing
when dismissed" says otherwise.

## The Music Assistant shortcut

With a server address set, a **Music Assistant** entry appears in the kiosk
menu and opens the server's own web interface over the dashboard: the full
library, search, queue, playlists and radio, exactly as they are on a phone
or a laptop. Close it (or press back) and the dashboard is still there,
loaded, with the voice session and the wake word untouched, because the page
never left.

The interface is Music Assistant's, not a copy of it, so browsing and
queueing stay whatever the server's current version makes them. Playback
itself needs nothing more than the Sendspin player above: queue to this
device and it plays here. The page opens with the right player already
selected — this device's own, or the controlled player when **Player to
control** points elsewhere.

**Close after inactivity** puts the dashboard back on its own, for the wall
tablet whose visitor queued a song and walked away: up to a minute without a
touch anywhere on the Music Assistant page and it closes itself. Scrolling
and tapping count, so reading a long album page keeps it up. At zero it
stays until someone closes it, which is what a desk or a kitchen counter
wants. Everything else that closes it works the same as ever: the close
button, the back button, and a wake word.

**Hide the close button** is for the corner the button shares with Music
Assistant's own controls: the full-screen "now playing" view puts its
three-dot menu exactly there, unreachable under the button. With the
button hidden, the back button, a wake word and the inactivity timer
still lead back to the dashboard.

**No second sign-in.** Music Assistant keeps its own session, so the shortcut
would land on its login screen every time storage is cleared. Instead the
token above is handed to the page as it loads, and the interface opens
already signed in, as the user that token belongs to. Give the token the
rights that user should have on the tablet: a read-only token browses but
cannot queue. Signing in by hand still works and is left alone when it
happens, and the token is only ever given to pages on the configured server.

Home Assistant's own login cannot stand in for it, even though the dashboard
is signed in: Home Assistant mints a separate token per application and asks
for the password each time one is granted.

The server address alone is enough to show the entry; without a token the
shortcut opens Music Assistant's login screen. Music Assistant's own
certificate is accepted the same way the dashboard's is, through **Ignore SSL
errors** in the Browser settings. In kiosk mode the entry follows **Allowed
Actions**, where it can be left out of the restricted quick-actions menu.

## The floating media player

![Compact player card](../assets/screenshots/sendspin-cards.png)

While music plays, a small now-playing card floats over the dashboard:
artwork, title and artist (long lines marquee), and a live progress bar.
Drag it anywhere; the position is remembered. It follows the app's
light/dark theme.

The Large size adds previous, play/pause and next buttons sized for
touch. They act on the whole playback group through the Sendspin
controller role, so skipping a track here skips it on every speaker in
the group.

Card behavior:

- **Paused** music keeps the card on screen with a play button, ready to
  resume, then hides it after the configured timeout.
- **A quick fling dismisses the card.** Flinging away active playback
  also stops the music. A slow drag repositions instead; the two are
  distinguished by release speed.
- The card hides during voice interactions (Voice Satellite owns the
  screen for the duration) and returns after.
- Track changes hold the previous card through the stream rebuild, so
  nothing flickers between songs.

## "Now Playing" full screen

With the setting enabled, the idle screensaver becomes a full-screen
now-playing view while music plays: the album art stretched and blurred
across the whole screen as a backdrop, the art again as a sharp centered
panel, and large title and artist text. Songs cross-fade into each other.

![Now Playing full screen](../assets/screenshots/sendspin-now-playing.png)

It behaves like a screensaver, deliberately without controls: touch
dismisses it, motion only if allowed by its setting. With nothing
playing, the regular screensaver appears as usual, and a pause swaps the
view back to the regular screensaver live.

### Lyrics

With **Show lyrics** on, the view splits: the cover and track to one side,
the song's lyrics to the other, the current line lit and the rest receding as
it scrolls itself in time with the music. The line follows Sendspin's own
synced position, the same one that keeps the audio aligned, so it tracks what
is coming out of the speaker.

Lyrics come from Music Assistant, so **Music Assistant needs a lyrics
provider of its own** — add one under its Settings, then Providers; LRCLIB is
free and needs no account. Kiosk Satellite asks Music Assistant for the
playing track and its lyrics; nothing is fetched from anywhere else.

**Lyrics timing** nudges the lines against the music, and defaults to
showing them 0.3 seconds early: an LRC timestamp marks where a line starts
being sung, so displaying it at exactly that moment leaves no time to read it
first. Sync quality also varies from track to track, so raise it if the lines
consistently arrive too late for comfort, or go negative if they run ahead.
Files that carry the format's own `[offset:]` correction are honoured on top
of this.

The layout follows the panel: side by side on a landscape screen, and on a
portrait one the cover and track sit at the top with the lyrics filling the
space below them. A panel too small for either keeps the ordinary centred
view rather than squeezing a couple of lines into a corner.

Only timed lyrics are shown. A track whose provider returns plain, untimed
words shows none, since there is no honest way to follow along with them, and
tracks with no lyrics at all simply keep the ordinary layout. Lyrics are
looked up once per track.

## Voice Satellite interplay

Music and the voice assistant share one speaker and one microphone, so
the player cooperates:

- Playback ducks to the configured fraction during every voice
  interaction (wake word turns, announcements, questions, timers) and
  restores instantly after. The duck is applied in the audio pipeline
  itself, so sync timing and the volume setting are untouched.
- The stop word stays armed during interruptible states, timers
  included: saying "stop" silences the alert or the music.
- While audio plays, the kiosk holds off its screensaver and dashboard
  view rotation the same way it does for any other media interaction
  (unless the "Now Playing" screensaver mode is on, where the
  screensaver is the music display).

## How it works

The player implements `player@v1`, `metadata@v1` and `controller@v1` of
the Sendspin protocol: a WebSocket carries JSON control messages and
timestamped binary audio chunks, a burst-based NTP-style time exchange
feeds a Kalman clock filter, and chunks are scheduled against the DAC's
own timestamps with sample-level insert/drop drift correction. Decoding
uses Android's MediaCodec (no bundled codec libraries). Volume commands
map to the device's media volume, and hardware volume changes are
reported back to the server.

The implementation is adapted from
[SendspinDroid](https://github.com/chrisuthe/SendspinDroid) (MIT), whose
license and attribution ship in the source tree.

## Troubleshooting

- **Player never appears in Music Assistant**: check the app log
  (Settings → Logs) for `sendspin` lines; `connected as
  kiosksatellite_<id>` means the handshake worked. If discovery finds
  nothing, set the server address explicitly (mDNS does not cross
  subnets or VLANs).
- **Audio is out of sync with other speakers**: give it a few seconds
  after connecting; the clock filter needs a moment to converge. A fixed
  per-device offset can be tuned from Music Assistant's player settings
  (sync adjustment), which the player applies as a static delay.
- **Dropouts on weak WiFi**: prefer the Opus codec; it needs a fraction
  of FLAC's bandwidth.
- **Metadata lags a track change by a few seconds**: Music Assistant
  sends its now-playing snapshots on its own schedule, after the audio
  boundary. The card keeps the previous song on screen and cross-fades
  when the update arrives.
