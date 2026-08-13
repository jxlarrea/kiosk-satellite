# Gestures

Touch and clap gestures that trigger actions, for the kiosk that should stay clean.
The dashboard shows nothing extra, guests see nothing to press, and the
person who set the tablet up can still jump to an admin view, run a script
or trigger an automation with a touch shape nobody performs by accident.

Gestures generalize the kiosk exit gesture: where that one is fixed (fast
taps anywhere, then the PIN, then the menu), these are configurable on both
ends. The exit gesture itself is unchanged and keeps working alongside them.

One gesture is not touch at all: **Claps**. Two, three or four claps heard
through the microphone trigger an action from across the room, the way the
classic Clapper turned on a lamp. Clap detection works with or without
Voice Satellite; see [its section](#claps) below.

## Setup

Settings, then **Gestures**: the list of gestures and the actions they
trigger. The same page is in the remote admin. Anything configured there
works whenever the app is running, kiosk mode or not.

Kiosk Mode has one related switch, **Disable Gestures**, for the locked
tablet that should ignore them: while kiosk mode is on with that switch
set, the gestures stay dormant, and they arm again the moment lockdown
ends.

Each entry is one gesture bound to one action. Adding one asks for the
gesture's shape, then the action, and each action type asks only for what
it needs: a URL, a dashboard view, a service call. The Home Assistant
dialogs carry a **Validate** button that checks the domain, service and
entity against the connected instance before anything is saved.

## The gestures

| Gesture | Notes |
| --- | --- |
| Taps in a corner | 2 to 4 quick taps inside one corner of the screen. |
| Hold a corner | Press and hold a corner, 0.5 to 3 seconds. |
| Multi-finger tap | 2 or 3 fingers, single or double tap, anywhere. |
| Multi-finger hold | 2 or 3 fingers held down, anywhere. |
| Corner sequence | An ordered sequence of corner taps, like a knock code. |
| Claps | 2 to 4 claps, heard through the microphone. |

The corners are boxes about a centimeter and a half on a side. Two mappings
can share a corner with different tap counts; the shorter one waits a beat
to be sure the longer one is not still coming.

Gestures are observed, never intercepted: every touch still reaches the
dashboard underneath. That is why the shapes are corners, extra fingers and
long holds. None of them double as something a card would react to, where a
plain tap or swipe would. A corner sequence is the most hidden of the set
and works well as the one that opens something sensitive.

## The actions

The chooser groups them: Kiosk Satellite, Android, Home Assistant.

| Action | Notes |
| --- | --- |
| Go to a dashboard view | Picked from a list of the instance's dashboards and views. |
| Open a web page | An external URL, in the same overlay a dashboard link opens, with its close button. |
| Show a camera view | Any configured camera view. The show action toggles: the same gesture performed again closes the view it opened. A separate close action exists for closing whatever view is up. |
| Show the Sendspin player | The floating player card; a fling on the card is how it hides. |
| Start the screensaver | Whatever mode is configured. |
| Stop the screensaver | Redundant for touch (any tap dismisses), made for claps: the screen comes back from across the room. |
| Open another app | By package name, kiosk still running behind it. |
| Open a deep link | Any URI another app claims, `myapp://path`. |
| Open Android Settings | |
| Call a service | Domain, service, optional entity and data. |
| Run a script | A `script.*` entity, run through `script.turn_on`. |
| Trigger an automation | An `automation.*` entity, run through `automation.trigger`. |
| Fire an event | An event type and optional data for automations to listen to. |

## Claps

A clap is detected as what it is acoustically: a sharp, broadband burst
that jumps far above the room's noise level and dies away within a fraction
of a second. Detection is plain arithmetic on the audio stream, no models
and no cloud, and it is light enough to run on the weakest supported
devices without competing with wake word detection.

Claps in a sequence land roughly a half second apart or faster; a pause of
about three quarters of a second ends the sequence. Two mappings can use
different counts; a smaller count waits out that pause when a larger one is
configured, to be sure more claps are not coming.

The microphone side:

- With Voice Satellite wake word detection running, clap detection shares
  the capture that is already open and costs nothing extra. Without it, the
  app opens the microphone itself while at least one claps mapping exists,
  so the Clapper works on a device that has never seen Voice Satellite. The
  first claps mapping prompts for the Microphone permission if it was never
  granted.
- Claps are ignored while a voice interaction is running: talking at the
  satellite must not fire an action.
- Muting the satellite in Voice Satellite closes the microphone, claps
  included. A muted device is not listening, full stop.
- Lockdown Mode and kiosk mode's Disable Gestures silence claps exactly as
  they silence touch gestures.
- Thresholds adapt to the room: steady loudness (music, a running TV)
  raises the bar claps must clear rather than firing through it. Detection
  keeps working over background music, though very percussive tracks at
  high volume can occasionally read as claps; pick 3 or 4 claps for
  anything that should never misfire.
- Claps must look deliberate: they come out of a calm moment, land on an
  even beat, and stay at one loudness. Ordinary clatter shares a clap's
  impulse shape but rarely all three. If it still false-triggers (a child
  playing with toys can be surprisingly clap-like), set **Clap detection**
  on the Gestures page to Strict, which tightens those checks and wants
  louder claps, and prefer 3 or 4 claps over 2.
- On Android 12 and later the system microphone indicator shows while clap
  detection is listening, as it does for wake word detection.

## Timing

Taps chain when they land within about half a second of each other; a pause
or a tap outside the corner starts over. A hold fires while the finger is
still down, at the configured duration. Corner sequences allow a slower
rhythm, about a second and a half between taps.

## Notes

- Gestures pause the dashboard rotation and reset the screensaver idle
  timer, exactly as any touch does.
- The first tap on an active screensaver dismisses it and still counts, so
  a corner double tap performed on a sleeping screen wakes it and fires.
- Long holds inside the dashboard can also select text or open a context
  menu unless **Disable context menus** (Kiosk Mode) is on.
- The exit gesture's fast-tap counter is position blind and unchanged: five
  or seven fast taps anywhere still open the menu, whatever is configured
  here. Its hold variants (the last tap held down for a second) do not
  collide with these gestures either: a corner hold needs a corner box and
  a finger hold needs two or three fingers, while the exit hold is one
  finger anywhere after a chain of fast taps.
