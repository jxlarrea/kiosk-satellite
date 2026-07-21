# Kiosk Satellite Immich Screensaver

Kiosk Satellite can use an [Immich](https://immich.app/) server as its
screensaver: point it at your library or a single album and the kiosk
becomes a photo frame, with slideshow transitions, full screen photos, an
optional metadata overlay, and a local cache so images appear instantly.
Videos in the selection play too, muted and in full.

## Setup

1. In Immich, create an API key under **Account Settings → API Keys**. A
   full-access key works; a restricted key needs to be able to read
   albums, search assets, and view and download assets.
2. On the device, Settings → **Screensaver** → set the screensaver mode to
   **Immich Media** (or do the same from the Screensaver tab in the remote
   admin).
3. Enter the **Server address** (for example `http://immich.local:2283`)
   and the **API key**, then tap **Validate connection**. Validation
   checks the exact calls the screensaver needs, so a key that is missing
   a permission fails here with the reason instead of failing silently at
   night. The rest of the settings unlock once validation succeeds, and
   changing the address or key asks for a new validation.

## Settings

| Setting | Default | Notes |
| --- | --- | --- |
| Media source | All media | The whole library, or a single album picked from a dropdown. |
| Seconds per image | 10 | Videos ignore this and play to their end. |
| Shuffle | off | Random order instead of the server's newest-first order. |
| Transition | Crossfade | The same set every slideshow mode offers: none, crossfade, slide, zoom, Ken Burns, or random. |
| Fill the screen | on | See below. |
| Cache media locally | on | See below. |
| Cache size (items) | 500 | The oldest cached items are deleted once the cache is full. Live usage shows under the field. |
| Show metadata | off | See below. |

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

## Metadata overlay

**Show metadata** puts the photo's details in a corner of the screen
(pick which one), each line with its own icon and only when the asset
actually carries the information:

- Album name: the selected album, or, in All media mode, the first album
  the photo belongs to.
- Date taken.
- Camera details: focal length, aperture and ISO from EXIF.
- Location: city, state and country from EXIF.

## The local cache

With **Cache media locally** on, every image shown is kept on the device,
so later loops of the playlist load from disk instead of the network.
Images are fetched as Immich's screen-sized previews rather than
originals, so a cached item is a few hundred KB, not a 50 MB original.
When the cache exceeds the configured item cap, the least recently shown
items are deleted first; lowering the cap prunes immediately. Videos are
never cached, they stream from the server each time.

## Small clock

The screensaver's **Small clock** option (above the screensaver mode
setting, available to every mode) pairs well with this one: a corner
clock and date over the photos, with a soft vignette behind it so it
stays readable on bright pictures. The metadata overlay defaults to the
opposite corner, so both can be on at once.

## Troubleshooting

- **Validation fails with a permission message**: the API key is
  restricted too tightly. Create one that can read albums, search assets,
  and view and download assets.
- **"Could not reach the Immich server"**: the address is wrong, the
  server is down, or the tablet cannot route to it. The screensaver tries
  again on its next activation.
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
