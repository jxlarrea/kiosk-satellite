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
| Pause dashboard during screensaver | On | Stops rendering the dashboard while the screensaver covers it. |
| Filter dashboard updates | On | Drops entity updates that the current view does not display. |

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

The screensaver is drawn by the app, in front of the
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
| CPU temperature | 68°C | 41°C |

All of that saved work is heat: on the same busy dashboard the CPU ran more
than 20°C cooler with the setting on. For a tablet mounted
flat against a wall, running warm around the clock, that is the difference
that matters for comfort and hardware longevity.

The gain scales with how busy the dashboard is. A mostly static dashboard,
or one already running the update filter below, has little rendering work to
save, and the numbers barely move; that is the expected result, not a fault.

Turning it on also turns on **Keep connected in the background**, since a
covered dashboard must not be one Home Assistant chooses to disconnect.

The one screensaver it cannot help is **Dim**: that mode keeps the dashboard
itself on screen, just darker, so there is nothing to stop drawing. The pause
simply does not engage there, and the dashboard keeps its normal CPU, GPU and
battery use. Every other mode puts its own overlay in front and benefits in
full.

On by default, verified on Snapdragon and MediaTek hardware from Android 11
up. WebView builds vary; if a dashboard ever comes back wrong after the
screensaver, turn it off and please report what the device and Android
version were.

The same pause, with no setting of its own, runs whenever anything else
covers the dashboard completely: the settings screen, a camera view, media
pushed over DLNA, blackout lockdown, and a page shown over the dashboard
(the Music Assistant shortcut, a tapped dashboard link, the view rotation's
external pages). Those surfaces are always opaque, so there is nothing to
decide. A page shown on Home Assistant's own address is the exception: the
two are indistinguishable underneath, so the dashboard keeps drawing.

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
breaks; the telemetry line says when that is the case. That safe fallback is
why it is on by default: the worst a view can get is the stock, unfiltered
behavior. It works best on a locked, single-view kiosk.

## Measured against Fully Kiosk

To put the optimizations in context, here is the same dashboard on the same
device, once under a stock install of Fully Kiosk Browser and once under
Kiosk Satellite with the optimizations at their defaults. The device is a
Galaxy Tab S8+ (Snapdragon 8 Gen 1, Android 16), and the page is a real
production tablet dashboard: live camera card, animated graphs, and a wall
of updating sensors. Both apps loaded the identical dashboard URL from the
same instance, and both render through the same system WebView, so the
engine is not the variable; what the app does around the engine is.

The comparison is asymmetric in one honest way: Kiosk Satellite ran its
built-in microWakeWord engine through every window (a live 16 kHz
microphone stream, verified in dumpsys), because on-device wake word is
part of what it is. Fully Kiosk has nothing comparable to run.

With the dashboard on screen the two are comparable: CPU is a dead heat
with the wake word engine included, with Kiosk Satellite a little heavier
on the GPU because the page's animations render through the app's
compositor. The state that matters is idle, because a kiosk on a
30-second screensaver timeout spends nearly its whole life there. Fully
Kiosk has nothing to stand down to: with no touches, the dashboard simply
keeps rendering, and its idle measurement is identical to its active one.
(Its optional black screensaver does not change that; measured
separately, the overlay draws over a page that keeps rendering
underneath.) Kiosk Satellite drops into its clock screensaver with
**Pause dashboard during screensaver** stopping the page:

| Idle, 30 s after the last touch | Fully Kiosk 1.60.1 | Kiosk Satellite |
| --- | --- | --- |
| App CPU (all processes, of total 8-core capacity) | 21.7% | 8.6% |
| System CPU total | 34.0% | 16.2% |
| GPU load | 52.3% | 0.0% |
| SoC temperature (window mean) | 52.7°C | 38.7°C |

Less than half the CPU with wake word inference still listening, a GPU
that goes fully idle instead of staying half-busy forever, and an SoC that
fell from 57°C to 43°C within a minute of the screensaver engaging. RAM is
the one metric that goes the other way: Kiosk Satellite holds a few
hundred MB more, its Flutter UI, wake word model and caches on top of the
same WebView, which is a fair trade on a tablet with memory to spare and
worth knowing about on one without.

Methodology, for anyone reproducing it: each app was measured alone with
the other force-stopped, back to back on the same network and Home
Assistant instance, each dashboard session started from the same cooled
baseline (under 46°C on the launcher), and every state was verified by
screenshot around its window. CPU is jiffies attributed to every process
of the app including its WebView renderer, sampled over two minutes and
reported against the full 8-core capacity. RAM is PSS summed over the same
processes. GPU load is the Adreno driver's busy-cycle counters over the
same window, cross-checked against its busy-percentage node (they agreed
within half a point). Temperature is the hottest CPU cluster thermal zone,
sampled every three seconds.
