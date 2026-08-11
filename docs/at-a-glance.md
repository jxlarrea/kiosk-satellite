# At a Glance

A row of Home Assistant entity states on the screensaver, for the things
people check in passing: is the garage still open, is the front door locked,
is the gate shut. It keeps the plain screensaver plain, so the answer is there
without waking the tablet and finding a dashboard.

## Setup

Settings, then **Screensaver**, then **At a Glance**:

| Setting | Notes |
| --- | --- |
| At a glance | Turns the row on. |
| Entities | Up to four entities, in the order they appear. |

**Entities** opens a picker that searches Home Assistant by name or entity id,
so nothing has to be typed from memory. The chosen entities sit at the top and
can be reordered; the same picker is in the remote admin's Screensaver tab.

The row needs a working Home Assistant connection (Settings, Home Assistant
Configuration).

## Where it appears

Only the **Black** and **Clock** screensaver modes:

- **Black**: the row is centred, and is the whole display.
- **Clock**: the row sits under the date, and the clock shrinks a little to
  make room for it.

The photo modes (Home Assistant Media, Local Media, Photo Gallery, Immich) and
the WebRTC Camera mode do not carry it. They already have something to look
at, and a status row over a photo is neither subtle nor readable.

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

Everything is drawn in one muted tone. State is never color coded: the row is
meant to be read across a dark room without competing with the clock. On the
Clock screensaver the tone is the face's own digit color (Clock color for
Digital, the digit colors for Flip and Roller), so the row stays readable on
whatever backdrop the clock was given.

States are shown the way they read in Home Assistant, capitalised (`Open`,
`Locked`, `Closed`), with the unit appended for numeric sensors.

## How it stays current

While the screensaver is showing, Kiosk Satellite subscribes to just these
entities over its own Home Assistant connection, and closes it again when the
screensaver goes away. Home Assistant's subscription takes an entity list, so
that connection carries these entities and nothing else, and it costs nothing
while the kiosk is in normal use.

It deliberately does not read the states off the dashboard the kiosk is
showing. **Filter dashboard updates** (Settings, Home Assistant Configuration,
Optimizations) exists to stop weak tablets processing entities they do not
display, and feeding the At a Glance entities back through the page would give
back the work that setting saves: a rapidly changing entity, a power meter
say, would cost the dashboard real work every second it updated. The row
therefore has no effect on that filter, and works the same whether it is on or
off.

It also means the row works on a kiosk pointed at something other than a Home
Assistant dashboard, and keeps working while the page is reloading.
