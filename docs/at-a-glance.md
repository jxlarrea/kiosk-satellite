# At a Glance

A row of Home Assistant entity states on the screensaver, for the things
people check in passing: is the garage still open, is the front door locked,
is the gate shut. The answer is there without waking the tablet and finding a
dashboard.

## Setup

Settings, then **Screensaver**, then **At a Glance**:

| Setting | Notes |
| --- | --- |
| At a glance | Turns the row on. |
| Entities | Up to four entities, in the order they appear. |
| Show on Now Playing | Adds the row to the full-screen Now Playing view. |

Under **Appearance**:

| Setting | Notes |
| --- | --- |
| Row scaling | Scales the whole row, like the widgets' Widget scaling. |
| Monochromatic icons | Keeps every icon in the neutral grey instead of its state color. |
| Floating text style | Floating text instead of chips, the row's original look. |

**Entities** opens a picker that searches Home Assistant by name or entity id,
so nothing has to be typed from memory. The chosen entities sit at the top and
can be reordered; the same picker is in the remote admin's Screensaver tab.

The row needs a working Home Assistant connection (Settings, Home Assistant
Configuration).

## Where it appears

Every screensaver mode except the Camera Streams grid, where a status row
would sit over a live feed:

- **Black**: the row is centred, and is the whole display.
- **Clock**: the row sits under the date, and the clock shrinks a little to
  make room for it.
- The photo and web modes (Home Assistant Media, Local Media, Photo Gallery,
  Immich, Website): the row is pinned near the bottom of the screen, over
  whatever the mode is showing.

On the Immich screensaver, when the [metadata
overlay](screensavers.md#immich-media) occupies a bottom corner (its own
panel, or the two panels under a portrait pair), the row narrows to two
columns and wraps, staying clear of the corners instead of spreading into
them.

A landscape screen shows the entities in one row. A portrait one takes two
side by side and wraps the rest onto further rows, since three across a narrow
panel leaves every name truncated to a stub. The entities keep equal-width
columns either way, and the type shrinks a little when the columns are tight
before any name is shortened.

## What it shows

Each entity shows its icon, its name and its current state. The icon is the
one set on the entity in Home Assistant; entities without one get the icon
Home Assistant itself would draw for that kind of entity, so a lock looks like
a lock and an open garage looks open.

By default each entity is a chip: a rounded pill in one translucent dark
tone, sized to its content, with the icon in its own circle on the left and
the name over the state beside it. The pill carries its own contrast, which
is what lets the row sit over photos: no photo is bright or dark enough to
take the text with it.

The icon's circle follows the entity's state, the way Home Assistant lights
up an active tile: a lit light glows amber, an unlocked lock warns red, an
open cover shows purple, and anything idle (and every plain sensor) stays
grey, so a colored circle always means something is going on.
**Monochromatic icons** keeps every circle in the neutral grey instead. The
text never takes a color in any case: the state is read from the words, the
color is only a hint.

**Floating text style** switches back to the row's original look: floating
text in one muted tone, no chip and no state color. On the Clock screensaver that tone
is the face's own digit color (Clock color for Digital, the digit colors for
Flip and Roller), so the text stays readable on whatever backdrop the clock
was given. Over photos the text-only style is at the photo's mercy, which is
exactly why the chips are the default.

States are shown the way they read in Home Assistant, capitalised (`Open`,
`Locked`, `Closed`), with the unit appended for numeric sensors.

## How it stays current

While the screensaver is showing, Kiosk Satellite subscribes to just these
entities over its own Home Assistant connection, and closes it again when the
screensaver goes away. Home Assistant's subscription takes an entity list, so
that connection carries these entities and nothing else, and it costs nothing
while the kiosk is in normal use.

It deliberately does not read the states off the dashboard the kiosk is
showing. **Filter dashboard updates** (Settings, Home Assistant Setup,
Optimizations) exists to stop weak tablets processing entities they do not
display, and feeding the At a Glance entities back through the page would give
back the work that setting saves: a rapidly changing entity, a power meter
say, would cost the dashboard real work every second it updated. The row
therefore has no effect on that filter, and works the same whether it is on or
off.

It also means the row works on a kiosk pointed at something other than a Home
Assistant dashboard, and keeps working while the page is reloading.
