# Vision Match

Navigate to **Settings > Ground Control > Vision Match**.

Vision Match has three features:

- **Face Detection:** finds the faces looking at the kiosk, so a face can dismiss or postpone the screensaver.
- **Hand Gestures:** counts the fingers held up on a raised hand for **Show fingers** gestures.
- **Face Recognition:** names the person looking at the kiosk from the faces enrolled in Ground Control. Chosen people can then skip the kiosk PIN, turn Lockdown Mode off or be the only ones whose face dismisses the screensaver.

Vision Match runs on [Ground Control](ground-control.md), a Home Assistant app or a Docker container that does the vision work off the kiosk. The camera and motion detection stay on the device. Vision Match is off by default. Devices without a screen don't have a Vision Match page.

## Setup

1. Set up [Ground Control](ground-control.md) and turn on **Enable Ground Control**.
2. Turn on **Enable camera** under **Settings > Camera**.
3. Turn on **Enable Vision Match**. Face Detection, Face Recognition and Hand Gestures are on by default.
4. Enroll each person's face with **Enroll a face**. See [Enrolling a Face](#enrolling-a-face).

**Dismiss on face** and **Postpone on face** under **Settings > Screensaver > Face Detection** work as they do without Ground Control. So do **Show fingers** gestures under **Settings > Gestures**.

## Settings

| Setting | Default | What it does |
| --- | --- | --- |
| Enable Vision Match | off | Runs the features below on Ground Control. Needs the camera and Ground Control. |
| **Face Detection** | | |
| Enable Face Detection | on | Runs Face Detection on Ground Control. When it is off, Face Detection runs on the device. |
| Presence sensors | off | Adds the **Presence** and **Looking at the kiosk** binary sensors to Home Assistant. See [Presence Sensors](#presence-sensors). |
| **Face Recognition** | | |
| Enable Face Recognition | on | Shows the name of the person looking at the kiosk in the **Face** sensor. Needs Face Detection on Ground Control. |
| Confirm voices with faces | off | Accepts a voice that is close to a person's voiceprint but under the recognition threshold when that person's face is recognized at the kiosk. Needs Voice Match. See [Confirm Voices With Faces](#confirm-voices-with-faces). |
| Enroll a face | | Pick a person from Ground Control or a new one to start the guided capture. See [Enrolling a Face](#enrolling-a-face). |
| **Recognition cards** | | |
| Show arrivals | on | Shows a card with the person's picture and name when someone is recognized at the kiosk. See [Recognition Cards](#recognition-cards). |
| Show face actions | on | Shows a small card with the person's picture each time something on the kiosk changes because their face was recognized. |
| Card position | Bottom left | The corner where both cards show. |
| **Hand Gestures** | | |
| Enable Hand Gestures | on | Runs palm and finger gesture detection on Ground Control. When it is off, gesture detection runs on the device. |
| **Used in other settings** | | |
| Detect faces, Only chosen people dismiss it, Skip the PIN for, Disable Lockdown Mode for, Turn Lockdown Mode back on, Finger gestures for, Focus on who is at the kiosk | | The settings on other pages that use Face Recognition, with their values. Tap one to go to that setting. See [Settings That Work With Ground Control](ground-control.md#settings-that-work-with-ground-control). |

Choose the model for each feature in Ground Control under **Settings > Vision Match**. Each feature has a Light and an Accurate model. On an NVIDIA GPU every feature uses Accurate. On a CPU, Face Detection and Hand Gestures use Light. Face Recognition uses Accurate on an x86 CPU or an Apple M-series chip and Light on other ARM CPUs. See [Vision Models](https://github.com/jxlarrea/kiosk-satellite-ground-control/blob/main/docs/vision-match.md#vision-models).

## How It Works

- **Frames go to Ground Control one at a time and only when something moves in front of the camera.** Each frame is a 640x480 JPEG.
- **Looks are paced to what the machine running Ground Control can keep up with.** The kiosk looks at most 2 times a second for faces and 4 times a second for hands. With Face Recognition on, it looks up to 5 times a second for the first 2 seconds a face is in view without a name, since a name often takes a second look.
- **A feature on Ground Control also works on devices that can't run it on their own.** Examples are Android 7 devices for any feature and x86 devices for Hand Gestures.
- **When Ground Control doesn't answer,** looks for the features on Ground Control wait until it answers again. The log records this once. The models on the device run only for a feature that is turned off on this page.
- **Ground Control saves the results as vision sessions** on its **Sessions** page. Each session also lists what the kiosk did, such as when the screensaver was dismissed or postponed and each finger gesture with its action. While **Keep frames** is on in Ground Control's **Settings > Vision Match**, it keeps up to 8 frames of each session. Deleting a session also deletes its frames.

Ground Control's Kiosks page shows which Vision Match features each kiosk has on.

## Face Detection

A face looks at the kiosk when the head is turned 30 degrees or less from the camera. Only a face looking at the kiosk dismisses or postpones the screensaver. A face turned away no longer counts as a face looking at the screen. On kiosk frames from 1 to 3 m, a head turned away passed as a face looking at the screen in 10% of frames. With the models on the device it was 82%.

On an Echo Show 5, running Face Detection on Ground Control frees the CPU time the model used, which was about a tenth of a second for each face look.

## Presence Sensors

With **Presence sensors** on, the kiosk adds two binary sensors to Home Assistant:

| Sensor | What it shows |
| --- | --- |
| Presence | On while someone is in front of the kiosk. A face counts whether it looks at the screen or is turned away. A raised hand counts too while Show fingers gestures are set up. It turns off 30 seconds after the last look that found someone. |
| Looking at the kiosk | On while a face looks at the screen, the same faces that dismiss the screensaver. It turns off 3 seconds after the last one. |

With Presence, someone standing still is told apart from an empty room. The **Motion** sensor can't do that. A light changing or a pet walking by doesn't turn Presence on. Use it for lights or climate in the room. Looking at the kiosk is useful for automations that should only run when someone is actually looking, like showing a dashboard view.

- **Looks still start with motion.** Once a face is seen, looks keep coming while it stays in view, so someone standing still stays present. Someone who comes in without being seen by the camera, like behind it, doesn't count.
- **The camera stays on.** Faces are checked whenever something moves, even with the screen off and with no screensaver setting that uses faces. That adds looks to Ground Control. Presence sensors is off by default for this reason.
- **It needs Face Detection on Ground Control.** The sensors use Ground Control's looks only. A device that runs Face Detection on its own doesn't get them.

## Hand Gestures

The finger count is right more often, including in dim light and for hands a few meters away. On kiosk frames from 1 to 3 m, it was right in 91 to 96% of frames, compared to 28% with the models on the device. A finger reading counts once two hand looks in a row give the same count.

On an Echo Show 5, running Hand Gestures on Ground Control frees about half a second of CPU time for each hand look. **Hand sensitivity** in Ground Control under **Settings > Vision Match** sets the smallest hand counted, so a hand cut off at the edge of the frame doesn't trigger a gesture.

## Face Recognition

With **Enable Face Recognition** on, Ground Control compares the face looking at the kiosk with the faces enrolled in it. The kiosk's **Face** sensor in Home Assistant shows the name of the person it matches. The sensor is empty when nobody known is in view. It clears 3 seconds after the face leaves. Face Recognition uses Face Detection's looks. With Face Recognition on, those looks also run whenever the screen is on, but still only after something moves.

Ground Control recognizes up to three faces looking at the kiosk at once. The face with the highest score is the person at the kiosk. That is the name in the **Face** sensor and the person shown on the camera preview. Someone else becomes the person at the kiosk only after they score higher two checks in a row or when the person at the kiosk leaves. This keeps the sensor from flipping between two people standing side by side. The **People in view** sensor lists everyone recognized with the person at the kiosk first.

With Face Recognition on, these settings on other pages can act on who is at the kiosk:

| Setting | Page | What it does |
| --- | --- | --- |
| Detect faces | **Settings > Screensaver > Face Detection** | Only the chosen people dismiss or postpone the screensaver. See [Screensavers](screensavers.md#ground-control-vision-match). |
| Only chosen people dismiss it | **Settings > Screensaver > Face Detection** | Nothing at the kiosk but a chosen person's face dismisses the screensaver. Kiosk Satellite and Home Assistant still can. See [Only chosen people dismiss it](screensavers.md#only-chosen-people-dismiss-it). |
| Skip the PIN for | **Settings > Kiosk Mode** | The menu opens after the exit gesture without the PIN for the chosen people. See [Kiosk Mode](kiosk.md#ground-control-vision-match). |
| Finger gestures for | **Settings > Gestures** | Show fingers gestures run only while one of the chosen people is recognized. See [Show Fingers](gestures.md#show-fingers). |
| Focus on who is at the kiosk | **Settings > Calendar** | The calendar rings the chips of the people recognized, puts their lanes first in Day, shows Up next for the person at the kiosk and picks their calendar for new events. See [Calendar](calendar.md#ground-control-vision-match). |
| Disable Lockdown Mode for | The Lockdown Mode page | Lockdown Mode is turned off when one of the chosen people is recognized. **Turn Lockdown Mode back on** turns it back on once they leave. See [Lockdown Mode](kiosk.md#ground-control-vision-match-on-the-lockdown-mode-page). |

The kiosk also fires a [face event](events.md#face) in Home Assistant when someone recognized arrives at the kiosk and when they leave.

### Plugins and Pages

Plugins that declare the `face.recognition` capability can read who is at the kiosk, everyone recognized in view and when someone arrives or leaves. See [Who is at the kiosk](https://github.com/jxlarrea/kiosk-satellite-plugins/blob/main/docs/ks-api.md#who-is-at-the-kiosk). Pages on Home Assistant and custom pages get the same through the [JavaScript API](js-api.md#face-recognition). Any other site loaded in the kiosk doesn't.

### Enrolling a Face

Each person's face is enrolled once with a guided capture through a kiosk's camera. It takes about half a minute. To start it, choose **Enroll a face** on the Vision Match page and pick the person. You can also start it from the person's page in the Ground Control app. The kiosk shows its camera's view and the steps:

1. Look at the screen.
2. Turn your head a little to one side.
3. Now a little to the other side.
4. Take a step back.

Hints under the view show what to fix: no face in view, only one person in view, come closer, turn more or less, too dark. Any other face in view is left out of the capture. Tap **Stop** on the kiosk or on the person's page in the Ground Control app to end it early. The pictures from a finished first step are kept. Starting a capture while the screensaver is up dismisses the screensaver so the screen is at its normal brightness. The screensaver doesn't come back until the capture ends. Ground Control keeps only small pictures of the face. It never keeps the frames.

## Face Recognition Is Not Security

Face Recognition is a convenience for the people who live with the kiosk. It is not a lock.

- There is no check for a real person. A photo or a video of an enrolled person held up to the camera can be recognized as them.
- Twins, siblings and young children can be mistaken for each other.
- A guest who looks like an enrolled person can now and then be recognized as them, more so in poor light.

Use the settings that act on faces to skip steps for your family, like **Skip the PIN for** and **Disable Lockdown Mode for**. Don't rely on them to keep a determined person out. For the same reason, don't use the [face event](events.md#face) or the **Face** sensor in Home Assistant to unlock doors, open a garage or disarm an alarm.

Everything stays on your network. Camera frames go only to Ground Control, which keeps only small pictures of each enrolled face.

## Confirm Voices With Faces

With **Confirm voices with faces** on, Voice Match accepts a voice that is close to someone's voiceprint but under the recognition threshold if that same person's face is recognized at the kiosk. This helps most with short commands and answers to questions because they are too short to recognize by voice alone. The voice is only accepted for the person whose voiceprint is closest to it. The setting is off by default because a guest talking while an enrolled person stands at the kiosk can now and then be mistaken for that person. Ground Control's session page shows when a voice was accepted this way. See [Voice Match](voice-match.md).

## Recognition Cards

With Face Recognition on, cards on the kiosk screen show who was recognized and what happened because of it. They show over everything on screen including the screensaver, the voice overlay and the Lockdown Mode shield. Touches go through them to the dashboard.

| Setting | What it does |
| --- | --- |
| Show arrivals | On by default. Shows a card with the person's picture and name for 4 seconds when someone is recognized at the kiosk. It shows again for the same person only after they have been away for a minute. When several people are in view, the card is for the person with the highest score. |
| Show face actions | On by default. Shows a small card for 3 seconds with the person's picture and what happened: **PIN skipped**, **Lockdown Mode off**, **Voice confirmed** or **Calendar focused**. If the arrival card for the same person is up, the action shows on that card instead. |
| Card position | The corner where both cards show. Bottom left by default. |

The picture is the person's Home Assistant picture when they are linked to a Home Assistant person on Ground Control's People page. Otherwise the card shows the first letter of their name in their color. While the camera preview shows, the cards show next to it in the preview's corner instead and a ring in the person's color appears around the preview.
