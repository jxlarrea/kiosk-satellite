# Optimizations

The **Optimizations** group under Settings, then **Home Assistant
Configuration**, collects the switches that keep a dashboard fast and its
connection healthy on kiosk hardware. A wall tablet is not a laptop: it runs
one page forever, often on a slow chipset, and spends most of its life behind
a screensaver or with the screen off. Each optimization exists because one of
those realities hurts a stock browser setup.

All three appear in the same place in the on-device settings and in the
remote admin's Home Assistant tab.

| Setting | Default | What it does |
| --- | --- | --- |
| Keep connected in the background | On | Stops Home Assistant from suspending the connection while the page is hidden. |
| Pause dashboard during screensaver | Off | Stops rendering the dashboard while the screensaver covers it. |
| Filter dashboard updates | Off | Drops entity updates that the current view does not display. |

## Keep connected in the background

Home Assistant's frontend has a per-user "automatically close connection"
behavior: a few minutes after the page stops being visible, it closes its
websocket to save resources. On a phone in a pocket that is sensible. On a
kiosk it is exactly wrong: the screen being off is the normal state, and a
closed connection means the next wake word or screen-on greets a dashboard
that is still reconnecting.

With this on (the default), the app turns that preference off for the
kiosk's session on every page load, so the connection stays up however long
the page sits hidden. Turn it off only if you specifically want Home
Assistant's stock suspend behavior back.

## Pause dashboard during screensaver

**Experimental.** The screensaver is drawn by the app, in front of the
dashboard, and the browser engine underneath never learns it is covered: it
keeps rasterizing and compositing every animation, chart and camera refresh
at full rate, for a page nobody can see. On a busy dashboard that is real
heat and battery for nothing.

With this on, the app hides the dashboard's native view while the
screensaver is showing, which stops all of that drawing work, and restores
it just before the screensaver lifts, so waking always lands on the live
page. Only drawing stops. The page itself still believes it is visible, so
nothing is throttled or suspended: the websocket keeps flowing, entity
states stay current, and wake words, voice interactions, announcements and
timers from the Voice Satellite integration behave exactly as they do with
the setting off.

Measured on a Galaxy Tab S8 showing a busy dashboard (animated power flow,
camera cards, ~5000 subscribed entities) under a clock screensaver:

| | Screensaver up, setting off | Screensaver up, setting on |
| --- | --- | --- |
| App process CPU | 152% of one core | 57% |
| Browser renderer CPU | 130% of one core | 35% |
| GPU | 70% busy | 0% |

The gain scales with how busy the dashboard is. A mostly static dashboard,
or one already running the update filter below, has little rendering work to
save, and the numbers barely move; that is the expected result, not a fault.

Turning it on also turns on **Keep connected in the background**, since a
covered dashboard must not be one Home Assistant chooses to disconnect.

Off by default while it collects mileage across devices. It has been
verified on Snapdragon and MediaTek hardware from Android 11 up, but
WebView builds vary; if a dashboard ever comes back wrong after the
screensaver, turn it off and please report what the device and Android
version were.

## Filter dashboard updates

A dashboard subscribes to every entity in Home Assistant, and a large
installation can push thousands of state updates a minute at a page that
displays thirty of them. Older tablets spend so much main-thread time
processing that firehose that scrolling visibly stutters.

With this on, the app reads the current view, works out which entities it
actually shows, and drops every update for the rest before the page ever
sees it. On the view it was built for, an Echo Show 5 went from 33% browser
main-thread load to about 1%. While the filter runs, a live line under the
setting shows what it is watching and how much of the stream it is dropping,
and the watched-entities count opens the full list, so the effect is
inspectable rather than taken on faith.

Views change, and the filter follows navigation. Any view whose entities it
cannot fully work out (heavily templated cards, custom cards that reference
entities dynamically) is deliberately left unfiltered, so nothing ever
breaks; the telemetry line says when that is the case. It works best on a
locked, single-view kiosk, which is why it is off by default.
