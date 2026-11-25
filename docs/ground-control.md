# Ground Control

Navigate to **Settings > Ground Control**, under the **Kiosk Satellite** heading.

[Kiosk Satellite Ground Control](https://github.com/jxlarrea/kiosk-satellite-ground-control) is a companion service for Kiosk Satellite. It runs on a computer or server in your home and handles the voice and vision processing that kiosks don't have the computing power for. Install it as a Home Assistant app or run it in Docker on a CPU or an NVIDIA GPU.

Ground Control currently has two components. [Voice Match](voice-match.md) does speaker voice recognition, trimming and isolation. [Vision Match](#vision-match) does face detection, Face Recognition and hand gestures with the device's camera.

Ground Control is off by default.

## Setup

1. Install Kiosk Satellite Ground Control as a Home Assistant app, or run its Docker container.
2. Turn on **Enable Ground Control**. Kiosks on the same network find it on their own. For Ground Control on another network, enter its address, such as `192.168.1.10:10900`.
3. The kiosk signs in with the Home Assistant token it already has. The first time, the status row shows **Waiting for approval**: open the Ground Control app, go to the Kiosks page and approve the kiosk. The status row then shows **Connected** and the people enrolled.
4. Tap **Open** on the **Ground Control app** row to add people and enroll them. As a Home Assistant app, it opens the app's page in Home Assistant. A Docker container opens its own web page.
5. Turn on the features you want. **Enable Voice Match** is under **Settings > Ground Control > Voice Match** and **Enable Vision Match** is under **Settings > Ground Control > Vision Match**.

## Settings

| Setting | Default | What it does |
| --- | --- | --- |
| Enable Ground Control | off | Connects the kiosk to Kiosk Satellite Ground Control. |
| Address | empty | Empty finds Ground Control on the network. Enter `host:port` for Ground Control on another network. |

## Features

Each feature Ground Control runs has its own page on the Ground Control page below Connection.

| Feature | What it does |
| --- | --- |
| Voice Match | Recognition, Trimming and Isolation. See [Voice Match](voice-match.md). |
| Vision Match | Face recognition, detection, hand gestures and presence detection. See [Vision Match](#vision-match). |

## Vision Match

Navigate to **Settings > Ground Control > Vision Match**. With **Enable Vision Match** on, Face Detection and Hand Gestures run on Ground Control instead of the device. **Dismiss on face** and **Postpone on face** under **Settings > Screensaver > Face Detection** work as before. So do **Show fingers** gestures under **Settings > Gestures**.

| Setting | Default | What it does |
| --- | --- | --- |
| Enable Vision Match | off | Runs the features below on Ground Control. Needs the camera and Ground Control. |
| Enable Face Detection | on | Runs face detection on Ground Control. When it is off, face detection runs on the device. |
| Enable Face Recognition | on | Shows the name of the person looking at the kiosk in the **Face** sensor. Needs Face Detection on Ground Control. |
| Confirm voices with faces | off | Accepts a voice that is close to a person's voiceprint but under the recognition threshold when that person's face is recognized at the kiosk. Needs Voice Match. See [Confirm Voices With Faces](#confirm-voices-with-faces). |
| Enroll a face | | Pick a person from Ground Control or a new one to start the guided capture. See [Face Recognition](#face-recognition). |
| Enable Hand Gestures | on | Runs palm and finger gesture detection on Ground Control. When it is off, gesture detection runs on the device. |


- The finger count is right more often. That includes dim light and hands a few meters away. A face turned away no longer counts as a face looking at the screen. On an Echo Show 5 this frees the CPU time the models used, which was about a tenth of a second for each face look and half a second for each hand look.
- The camera and motion detection stay on the device. Frames go to Ground Control one at a time and only when something moves in front of the camera.
- Ground Control saves the results as vision sessions on its **Sessions** page. Each session also lists what the kiosk did, such as when the screensaver was dismissed or postponed and each finger gesture with its action. While **Keep frames** is on in Ground Control's **Settings > Vision Match**, it keeps up to 8 frames of each session. Deleting a session also deletes its frames.
- Looks are paced to what the machine running Ground Control can keep up with.
- A feature on Ground Control also works on devices that can't run it on their own. Examples are Android 7 devices for any feature and x86 devices for Hand Gestures.
- When Ground Control doesn't answer, looks for the features on Ground Control wait until it answers again. The log records this once. The models on the device run only for a feature that is turned off on this page.

Vision Match needs a Ground Control version with Vision Match. Choose its models in Ground Control under **Settings > Vision Match**. Light runs on any CPU and Accurate needs an NVIDIA GPU. Devices without a screen don't have a Vision Match page.

### Face Recognition

With **Enable Face Recognition** on, Ground Control compares the face looking at the kiosk with the faces enrolled in it. The kiosk's **Face** sensor in Home Assistant shows the name of the person it matches. The sensor is empty when nobody known is in view. It clears 3 seconds after the face leaves. Face Recognition uses Face Detection's looks. With Face Recognition on, those looks also run whenever the screen is on, but still only after something moves.

Ground Control recognizes up to three faces looking at the kiosk at once. The face with the highest score is the person at the kiosk. That is the name in the **Face** sensor and the person shown on the camera preview. Someone else becomes the person at the kiosk only after they score higher two checks in a row or when the person at the kiosk leaves. This keeps the sensor from flipping between two people standing side by side. The **People in view** sensor lists everyone recognized with the person at the kiosk first.

Each person's face is enrolled once with a guided capture through a kiosk's camera. It takes about half a minute. To start it, choose **Enroll a face** on the Vision Match page and pick the person. You can also start it from the person's page in the Ground Control app. The kiosk shows its camera's view and the steps:

1. Look at the screen.
2. Turn your head a little to one side.
3. Now a little to the other side.
4. Take a step back.

Hints under the view show what to fix: no face in view, only one person in view, come closer, turn more or less, too dark. Any other face in view is left out of the capture. Tap **Stop** on the kiosk or on the person's page in the Ground Control app to end it early. The pictures from a finished first step are kept. Starting a capture while the screensaver is up dismisses the screensaver so the screen is at its normal brightness. The screensaver doesn't come back until the capture ends. Ground Control keeps only small pictures of the face. It never keeps the frames.

### Confirm Voices With Faces

With **Confirm voices with faces** on, Voice Match accepts a voice that is close to someone's voiceprint but under the recognition threshold if that same person's face is recognized at the kiosk. This helps most with short commands and answers to questions because they are too short to recognize by voice alone. The voice is only accepted for the person whose voiceprint is closest to it. The setting is off by default because a guest talking while an enrolled person stands at the kiosk can now and then be mistaken for that person. Ground Control's session page shows when a voice was accepted this way.

### Settings That Work With Ground Control

Some settings outside Settings > Ground Control only work with Ground Control. One example is **Show who is recognized** under **Settings > Screensaver > Face Detection > Camera Preview**. These settings have a **GC** tag after their title with Vision Match's face icon or Voice Match's voice icon. Settings in a group named after Ground Control, such as **Ground Control Face Recognition**, have no tag because the group's name already says it. They appear only while that feature is on. Tap the tag to see what it means. The Vision Match page lists them with their values under **Used in other settings**. Tap one to go to that setting.

## Status

| Status | Meaning |
| --- | --- |
| Connected | Signed in. The row lists the people enrolled. |
| Searching | Looking for Ground Control on the network. |
| Connecting | Ground Control was found or its address entered, and the kiosk is signing in. |
| Not reachable | The address does not answer. The kiosk tries again after 2 seconds, then waits longer each time, up to a minute. |
| Sign-in refused | Home Assistant refused the kiosk's token. Check the token under **Settings > Home Assistant**. |
| Waiting for approval | The kiosk connected for the first time. Approve it on the Kiosks page of the Ground Control app. |
| Declined | The kiosk was declined, or its access removed, in the Ground Control app. Approve it on the Kiosks page. |
| Not accepted | Ground Control only accepts Kiosk Satellite releases. A build made from the source code without the release key can't connect. |

While the kiosk is connected, three more rows describe the Ground Control it is connected to:

| Row | What it shows |
| --- | --- |
| Version | The Ground Control version. |
| Architecture | The CPU architecture of the machine Ground Control runs on: `amd64` or `aarch64`. |
| Runs on | **CUDA** when the speaker model runs on an NVIDIA GPU, **CPU** otherwise. |

**Architecture** and **Runs on** need Ground Control 2026.11.10 or newer.

The Kiosks page of the Ground Control app also shows which Voice Match features each kiosk has turned on under **Settings > Ground Control > Voice Match**.
