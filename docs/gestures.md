# Gestures

Touch, clap and hand gestures that trigger actions, for the kiosk that should stay clean.
The dashboard shows nothing extra, guests see nothing to press, and the
person who set the tablet up can still jump to an admin view, run a script
or trigger an automation with a touch shape nobody performs by accident.

Gestures generalize the kiosk exit gesture: where that one is fixed (fast
taps anywhere, then the PIN, then the menu), these are configurable on both
ends. The exit gesture itself is unchanged and keeps working alongside them.

Two gestures are not touch at all. **Claps**: two, three or four claps
heard through the microphone trigger an action from across the room, the
way the classic Clapper turned on a lamp. Clap detection works with or
without Voice Satellite; see [its section](#claps) below. **Show
fingers**: a hand showing a number of fingers to the camera, the gesture
for hands that are wet, floury or otherwise not touching a screen; see
[its section](#show-fingers).

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
| Show fingers | A hand showing 1 to 4 fingers, or an open hand, to the camera. |

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
| Open the app launcher | The overlay with the apps picked under App Launcher; its close button or a tap outside closes it. Needs the App Launcher enabled with at least one app picked, and works whether or not the Apps entry is allowed in the kiosk menu, so the menu entry can be switched off under Kiosk Mode, Allowed Actions, and the launcher kept reachable through a gesture only you know. |
| Start the screensaver | Whatever mode is configured. |
| Stop the screensaver | Redundant for touch (any tap dismisses), made for claps: the screen comes back from across the room. |
| Toggle hold mode | Pins the current view (screensaver, dashboard rotation and the return to home timer pause); the same gesture again releases it. Works well as a clap mapping while cooking from a recipe. |
| Open another app | By package name, kiosk still running behind it. |
| Open a deep link | Any URI another app claims, `myapp://path`. |
| Open Android Settings | |
| Call a service | Domain, service, optional entity and data. |
| Run a script | A `script.*` entity, run through `script.turn_on`. |
| Trigger an automation | An `automation.*` entity, run through `automation.trigger`. |
| Fire an event | An event type and optional data for automations to listen to. |

The four Home Assistant actions change nothing on the screen by themselves,
so each shows a toast when it completes, titled for what it is (Home
Assistant Service, Script, Automation or Event) with what ran underneath
(Called light.turn_on, Ran script.morning, Triggered automation.lights_off,
Fired event kiosk_gesture) or, in red, why it could not (Home Assistant not
configured, the connection down, the call rejected). The other actions are
their own confirmation.

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

## Show fingers

A hand showing one to four fingers, or an open hand, each its own
trigger, so five actions can live on one hand. The camera watches, finds a hand, tracks it from frame
to frame and reads its 21 joints on the device, from which the raised
fingers are counted: a finger is up when its tip
is farther from the wrist than its middle knuckle. The thumb is not
counted, so the counts are the four fingers and an open hand is all
four; a thumb resting out beside two raised fingers changes nothing. It runs on the frames the motion analyzer already
samples, only while something in the frame changed or a hand is in
view. Detection is not recognition: nothing is identified,
stored or compared, and no frame leaves the device.

The camera side:

- The gesture needs the camera enabled under Camera settings; the first
  hand mapping prompts for the Camera permission if it was never
  granted. While at least one hand mapping exists the camera runs
  whenever the screen is on, screensaver or not, so it costs what
  [Postpone screensaver on motion](camera.md#motion-detection) costs; a
  panel that is off releases it.
- Like claps, a hand shown during a voice interaction fires nothing: the
  camera's analysis is idled from the wake word until Voice Satellite is
  listening for it again, and a hand that was up when the turn started
  has to come up again afterwards.
- The reach is a few steps, and the hand has to be in the picture: a
  front camera set at chest height sees a hand at shoulder height or
  above, not one shown at the waist. The detector looks at a square of
  the frame around wherever the picture just changed (the hand coming
  up), which is what lets it see a hand that spans a fifteenth of a
  wide-angle frame. Across the room it does not reach; claps are the
  across-the-room gesture.
- The hand is read in any orientation and is confirmed by the landmark
  model, which turns a wall, a lamp or a hand-shaped shadow down; the
  count is what fires, so a hand at rest on a keyboard shows zero
  fingers and matches nothing. A fist held up counts too: the
  detector finds palms in any pose, and the hold is what makes the
  gesture deliberate.
- A hand is looked at within a quarter second of the picture changing
  with it coming up, and the first look that reads the configured count
  fires the action, about half a second after the hand is up on a slow
  tablet. A hand busy with something else (a vape or a cup at the
  mouth) can read as a count for a look and fire; speed was chosen over
  a second confirming look. The count then has to change (or the hand
  go) before the same mapping fires again, so switching from two
  fingers to an open hand fires both in turn. A second hand resting in
  view does not block it.
- Once fired, the count must change (or the hand go) before the same
  mapping fires again. Keeping the hand up does not repeat the action.
- Lockdown Mode and kiosk mode's Disable Gestures silence the hand
  gesture exactly as they silence touch gestures, and the camera is not
  even bound for it then.
- While a hand mapping exists the camera's exposure is steered by the
  frames themselves: a front camera meters the whole room and leaves a
  person in front of it dark, so a dark frame asks the camera for a
  stop more, a bright one gives it back, a step every couple of
  seconds; the motion analyzer and any snapshot taken meanwhile see the
  same frames. Hands need some light even so, though less than faces: a
  palm held up under a night light is still seen, at the price of a beat
  more hesitation than in daylight. In the dark the gestures do not
  work.

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
