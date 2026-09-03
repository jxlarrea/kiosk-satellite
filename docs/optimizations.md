# Optimizations

The **Optimizations** group under **Settings > Home Assistant Configuration** contains the settings that keep your dashboard running fast and your connection stable. A wall mounted device operates differently than a laptop: it runs a single web page indefinitely, often on lower end hardware, and spends most of its life behind a screensaver or with the display turned off. Each optimization exists to address a specific bottleneck present in stock browser behavior.

All three options are located in the same place in both the on device settings menu and the remote admin's Home Assistant tab.

| Setting | Default | What it does |
| --- | --- | --- |
| Keep connected in the background | On | Prevents Home Assistant from disconnecting the WebSocket when the page is hidden. |
| Pause dashboard during screensaver | On | Stops rendering the active dashboard while a screensaver covers the screen. |
| Filter dashboard updates | On | Ignores entity updates that are not displayed on the active view. |

## Keep Connected in the Background

Home Assistant's frontend includes a per user setting that automatically closes its connection a few minutes after the page becomes hidden to conserve server resources. While this makes sense for a smartphone in a pocket, it creates problems for a wall mounted kiosk where the screen is frequently off. A closed connection means that waking the device forces you to wait while the dashboard reconnects.

When enabled (the default setting), Kiosk Satellite automatically overrides this preference for the kiosk's session on every page load, ensuring the WebSocket connection remains active no matter how long the screen stays off or hidden. You should only disable this if you explicitly want Home Assistant's stock disconnection behavior.

## Pause Dashboard During Screensaver

Screensavers are rendered natively by the app directly in front of the web dashboard. Standard web engines have no way of knowing they are obscured, so they continue rasterizing and compositing every animation, live chart, and camera refresh at full speed behind the screensaver. On a complex dashboard, this generates unnecessary heat and drains power.

When enabled, Kiosk Satellite temporarily hides the web view while a screensaver is active, stopping all visual rendering. It instantly restores the view the moment the screensaver is dismissed, ensuring you always wake up to a live page. 

Only visual rendering is paused; the underlying page logic remains active. The WebSocket stays connected, entity states continue updating in real time, and all voice features (wake words, voice interactions, announcements, and timers) operate normally.

Here is a performance comparison measured on a Galaxy Tab S8 displaying a complex dashboard (featuring animated power flow cards, live camera feeds, and roughly 5,000 subscribed entities) under a clock screensaver:

| Metric | Screensaver active (Setting OFF) | Screensaver active (Setting ON) |
| --- | --- | --- |
| App process CPU | 152% of one core | 57% of one core |
| Browser renderer CPU | 130% of one core | 35% of one core |
| GPU utilization | 70% busy | 0% (Fully idle) |
| CPU temperature | 68°C | 41°C |

Eliminating that unnecessary rendering significantly lowers internal temperatures. On this test dashboard, the CPU ran over 20°C cooler with the setting enabled. For a tablet mounted flush against a wall running 24/7, this temperature drop is crucial for long term hardware health and battery safety.

The efficiency gains depend on the complexity of your setup. A simple, mostly static dashboard has very little rendering work to pause, so the reduction in CPU and GPU usage will be smaller.

Enabling this setting automatically turns on **Keep connected in the background**, ensuring Home Assistant does not disconnect the backgrounded web view while it is paused.

Note: The **Dim** screensaver is the single mode that cannot benefit from this setting. Because the Dim screensaver keeps the dashboard visible at a lower brightness, visual rendering cannot be paused. All other screensaver modes draw a complete overlay in front of the dashboard and gain the full performance benefit.

This feature is verified and enabled by default on Snapdragon and MediaTek devices running Android 11 and newer. If your specific WebView implementation exhibits rendering glitches after waking from a screensaver, turn this option off and report your device model and Android version.

The exact same rendering pause occurs automatically whenever another opaque surface completely covers the dashboard, including:
* The settings menu
* A full screen camera view
* Media cast over DLNA
* Blackout Lockdown mode
* Overlay pages (such as the Music Assistant shortcut, tapped dashboard links, or external pages during view rotation)

The only exception is a web page loaded on Home Assistant's own server address; because the app treats these as part of the dashboard itself, rendering continues.

## Filter Dashboard Updates

A Home Assistant dashboard subscribes to every entity in your setup. A large smart home installation can broadcast thousands of state changes per minute to a tablet that might only display twenty or thirty of them. Older tablets spend considerable processing power handling this constant stream of data, causing visible stuttering when scrolling.

When enabled, Kiosk Satellite inspects the active dashboard view, identifies which entities are visually present, and filters out state updates for everything else before the web engine processes them. In testing on an Echo Show 5, this reduced the main thread browser load from 33% down to approximately 1%. 

While filtering is active, a status line beneath the setting shows real time telemetry detailing which entities are being tracked and what percentage of updates are being dropped. Tapping the tracked entity count opens a full list of allowed entities for easy verification.

As you navigate between different dashboard views, the filter updates automatically. If the app encounters a view containing dynamic or complex custom cards whose entity dependencies cannot be reliably parsed (such as heavily templated cards), it safely bypasses the filter for that specific view to prevent breaking your layout. This fallback mechanism ensures that, at worst, the dashboard simply reverts to standard, unfiltered Home Assistant behavior. This feature works best on dedicated, single view kiosk setups.

## Measured Against Fully Kiosk

To demonstrate the impact of these optimizations, here is a direct comparison running the same production dashboard on the same hardware: once using a standard installation of Fully Kiosk Browser, and once using Kiosk Satellite with default optimization settings.

* **Test Hardware:** Galaxy Tab S8+ (Snapdragon 8 Gen 1, Android 16)
* **Dashboard Details:** Live camera card, animated graphs, and numerous updating sensor cards
* **Environment:** Both applications loaded the exact same dashboard URL from the same Home Assistant instance using the native system WebView.

Note on testing methodology: Kiosk Satellite maintained its built in microWakeWord engine (a live 16 kHz microphone capture stream) throughout the test. Fully Kiosk Browser does not offer an equivalent on device wake word feature.

While the dashboard is actively displayed on screen, CPU usage between the two apps is roughly equal (even with Kiosk Satellite running on device wake word processing). Kiosk Satellite shows slightly higher GPU utilization due to rendering through the Flutter compositor.

However, the key difference appears when the device is idle. Because a wall mounted kiosk spends most of its time sitting behind a screensaver, idle efficiency is what dictates long term device thermals. 

When idle, Fully Kiosk Browser continues rendering the web page at full speed beneath its screensaver, resulting in identical resource consumption whether active or idle. (Using Fully Kiosk's black screensaver does not alter this, as the web page continues rendering underneath the overlay). 

In contrast, Kiosk Satellite engages its **Pause dashboard during screensaver** optimization 30 seconds after the last touch:

| Metric (30 Seconds After Idle) | Fully Kiosk 1.60.1 | Kiosk Satellite |
| --- | --- | --- |
| Total App CPU Usage (All processes) | 21.7% | 8.6% |
| System CPU Usage | 34.0% | 16.2% |
| GPU Load | 52.3% | 0.0% (Idle) |
| SoC Temperature (Window Mean) | 52.7°C | 38.7°C |

Kiosk Satellite uses less than half the CPU processing power (while actively running local wake word detection), drops GPU utilization to zero, and lowers the System on Chip (SoC) temperature from 57°C down to 43°C within one minute of entering the screensaver. 

System memory (RAM) is the one area where Fully Kiosk holds an advantage: Kiosk Satellite uses a few hundred megabytes more RAM to run the Flutter framework, local wake word models, and internal caches on top of the web engine. On modern devices with ample memory this is an easy trade off, though it is worth considering if you are deploying to a device with severely constrained RAM.

**Testing Methodology:**
* Each application was tested independently with the opposing app force closed.
* Tests were conducted back to back on the same Wi-Fi network and Home Assistant instance.
* Each test session started from a cooled baseline temperature (below 46°C on the home screen).
* CPU metrics represent system jiffies across all app processes (including the WebView renderer) sampled over a two minute window against total 8 core capacity.
* RAM metrics represent Proportional Set Size (PSS) summed across all relevant processes.
* GPU load was captured directly from the Adreno driver's busy cycle counters over the test window.
* Temperatures represent the hottest CPU cluster thermal zone sampled at three second intervals.