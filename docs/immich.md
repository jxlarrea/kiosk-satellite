# Kiosk Satellite Immich Screensaver

Kiosk Satellite can use an [Immich](https://immich.app/) server as its
screensaver: point it at your library or a single album and the kiosk
becomes a photo frame, with slideshow transitions, full screen photos, an
optional metadata overlay, and a local cache so images appear instantly.
Videos in the selection play too, muted and in full.

## Setup

1. In Immich, create an API key under **Account Settings → API Keys**. A
   full-access key works; a restricted key needs the `album.read`,
   `asset.read` and `asset.view` permissions. Note that Immich separates
   viewing from downloading: `asset.view` covers the screen-sized previews
   the screensaver actually fetches, and `asset.download` (originals) is
   neither a substitute for it nor needed.
2. On the device, Settings → **Screensaver** → set the screensaver mode to
   **Immich Media** (or do the same from the Screensaver tab in the remote
   admin).
3. Enter the **Server address** (for example `http://immich.local:2283`)
   and the **API key**, then tap **Validate connection**. Validation
   checks the exact calls the screensaver needs, album listing, asset
   search and a preview fetch, so a key that is missing a permission
   fails here naming it instead of failing silently at night. The preview
   check tries up to five assets of the selected source and passes on the
   first one that answers, since an asset the server has not generated a
   preview for yet says nothing about the key. The rest of
   the settings unlock once validation succeeds, and changing the address
   or key asks for a new validation.

## Settings

| Setting | Default | Notes |
| --- | --- | --- |
| Media source | All media | The whole library, or a single album picked from a dropdown. Shared albums are listed too. |
| Photos only | off | Skip videos in the slideshow. |
| Seconds per image | 10 | Videos ignore this and play to their end. |
| Shuffle | off | Random order instead of the server's newest-first order. |
| Transition | Crossfade | The same set every slideshow mode offers: none, crossfade, slide, zoom, Ken Burns, or random. |
| Fill the screen | on | See below. |
| Pair portrait photos | on | See below. |
| Cache media locally | on | See below. |
| Cache size (items) | 500 | The oldest cached items are deleted once the cache is full. Live usage shows under the field. |
| Show metadata | off | See below. |
| Album name, Date taken, Camera details, Location | on | One toggle per metadata line. |

The playlist is fetched from the server each time the screensaver
activates, so new uploads and album changes are picked up on the next
activation, not in the middle of a running session.

## Fill the screen

Most people want photos edge to edge. With **Fill the screen** on, a
photo whose shape is close enough to the screen's (within about a 25
percent crop along one axis) is enlarged to cover the whole panel. This
admits the common 4:3 and 16:9 camera frames on a landscape tablet in
either orientation. Portrait and square photos, which such a crop would
ruin, keep their full frame and get the photo itself, enlarged, blurred
and dimmed, as the backdrop instead of black bars.

## Pair portrait photos

A photo taken in portrait uses about a third of a landscape screen and
leaves the rest to the blurred backdrop. **Pair portrait photos**, on by
default, shows two portrait photos in a row side by side instead, half
the screen each, so the panel is filled with photos rather than
backdrop. Turn it off to give every photo the screen to itself.
The pair counts as one slide: it holds for the usual interval and then
both are replaced together.

A portrait photo is not limited to the photo that happens to follow it.
When the playlist is read, each portrait photo reaches ahead for the next
portrait photo anywhere in the list and brings it back to its side, so a
library with portrait shots scattered between landscape ones still pairs
them all. Nothing is shown twice or skipped; the order is only
rearranged, and it happens after the shuffle so it follows the order the
slideshow actually runs in.

Pairing needs both photos taller than wide (square ones do not pair,
since half a screen each would show them small) and the screen itself
landscape; videos never pair. A photo left without a partner, the odd one
out of an odd number of portrait shots, shows on its own exactly as
before. Photos are measured by the shape Immich reports, including the
orientation tag phones set instead of rotating the pixels, so a portrait
photo stored as a landscape frame still counts as portrait.

With the metadata overlay on, a pair carries two sets of details: the
left photo's in the bottom-left corner and the right photo's in the
bottom-right, each under its own photo. For as long as the pair is on
screen, any [widget](screensavers.md#widgets) in those two corners is
hidden, so nothing sits on top of the details; it reappears with the
next single photo.

## Metadata overlay

**Show metadata** puts the photo's details in a corner of the screen
(pick which one), each line with its own icon and only when the asset
actually carries the information:

- Album name: the selected album, or, in All media mode, the first album
  the photo belongs to.
- Date taken.
- Camera details: the camera the photo was taken with, and its focal
  length, aperture and ISO, from EXIF. A line each, one toggle.
- Location: city, state and country from EXIF.

Each line has its own toggle, all on: pointing the screensaver at one
album makes its name the same on every photo, and the same goes for any
other line somebody would rather not read. With the album line off the
lookup it needs is never made either. Turn every line off and the
overlay stands down entirely, vignette included, exactly as if **Show
metadata** were off.

In a right-hand corner the lines are right-aligned with their icons on
the right, mirroring the layout of the corner widgets.

A pair of portrait photos overrides the chosen corner, using both bottom
corners so each photo's details sit under it.

## The local cache

With **Cache media locally** on, every image shown is kept on the device,
so later loops of the playlist load from disk instead of the network.
Images are fetched as Immich's screen-sized previews rather than
originals, so a cached item is a few hundred KB, not a 50 MB original.
When the cache exceeds the configured item cap, the least recently shown
items are deleted first; lowering the cap prunes immediately. Videos are
never cached, they stream from the server each time.

## Small clock

The screensaver's **Small clock** widget (added from the Widgets group
under the mode's settings) pairs well with this one: a corner
clock and date over the photos, with a soft vignette behind it so it
stays readable on bright pictures. Widgets own their corners: the
metadata overlay steps to the first free corner when a widget claims
its spot, so both are always readable at once.

## Troubleshooting

- **Validation fails with a permission message**: the API key is
  restricted too tightly. It needs `album.read`, `asset.read` and
  `asset.view`; the message names the one the failing call was denied.
- **"The API key is missing the asset.view permission"**: the key can
  search assets but not fetch their previews. Add `asset.view` to the key
  in Immich; the change applies immediately, no new key needed.
- **Validation passes but the log says a preview probe was skipped**:
  that asset has no preview on the server yet (still being processed,
  generation failed, an external library not scanned, or the file is
  offline). Validation moves on to the next asset, and the screensaver
  skips such photos when it meets them.
- **"Could not reach the Immich server"**: the address is wrong, the
  server is down, or the tablet cannot route to it. This message is
  reserved for genuine transport failures (DNS, refused connections,
  timeouts); a server that answers with an error shows the HTTP status or
  the missing permission instead. The screensaver keeps trying on its own,
  first after 15 seconds and then at up to a minute apart, and the
  slideshow resumes by itself once the server answers again, so a device
  that drops its Wi-Fi overnight shows photos again without a restart.
- **Diagnosing from the device**: every failing Immich call is logged
  with its endpoint and HTTP status in the app's log (the Logs tab of the
  remote admin, or `GET /api/logs`), so there is no need to instrument a
  reverse proxy to see what the server answered.
- **Self-signed HTTPS**: certificate errors are accepted automatically
  for the configured Immich host (and only that host). One caveat: videos
  play through the platform player, which does its own certificate
  checking, so on a self-signed server videos are skipped while images
  work. Plain `http://` servers, the common LAN setup, are unaffected.
- **A video does not play**: the device lacks the codec, or the
  self-signed case above applies. Failed items are logged and skipped;
  the slideshow keeps going.
- **New photos do not appear**: the playlist refreshes when the
  screensaver next activates, not during a running session. Dismiss it
  once.
