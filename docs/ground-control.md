# Ground Control

Navigate to **Settings > Ground Control**, under the **Kiosk Satellite** heading.

[Kiosk Satellite Ground Control](https://github.com/jxlarrea/kiosk-satellite-ground-control) is a companion service for Kiosk Satellite. It runs on a computer or server in your home and handles the voice and vision processing that kiosks don't have the computing power for. Install it as a Home Assistant app, or run it in Docker on a CPU or an NVIDIA GPU.

Ground Control currently has two components: [Voice Match](voice-match.md) which does speaker voice recognition, trimming and isolation. [Vision Match](#vision-match) which does face detection and hand gestures with the device's camera. Facial recognition is coming soon.

Ground Control is off by default.

## Setup

1. Install Kiosk Satellite Ground Control as a Home Assistant app, or run its Docker container.
2. Turn on **Enable Ground Control**. Kiosks on the same network find it on their own. For Ground Control on another network, enter its address, such as `192.168.1.10:10900`.
3. The kiosk signs in with the Home Assistant token it already has. The first time, the status row shows **Waiting for approval**: open the Ground Control app, go to the Kiosks page and approve the kiosk. The status row then shows **Connected** and the people enrolled.
4. Tap **Open** on the **Ground Control app** row to add people and enroll them. As a Home Assistant app, it opens the app's page in Home Assistant. A Docker container opens its own web page.
5. Turn on the features you want: **Enable Voice Match** under **Settings > Ground Control > Voice Match**, or **Enable Vision Match** under **Settings > Ground Control > Vision Match**.

## Settings

| Setting | Default | What it does |
| --- | --- | --- |
| Enable Ground Control | off | Connects the kiosk to Kiosk Satellite Ground Control. |
| Address | empty | Empty finds Ground Control on the network. Enter `host:port` for Ground Control on another network. |

## Features

Each feature Ground Control runs has its own page on the Ground Control page, after Connection.

| Feature | What it does |
| --- | --- |
| Voice Match | Recognition, Trimming and Isolation. See [Voice Match](voice-match.md). |
| Vision Match | Face recognition, detection, hand gestures and presence detection. See [Vision Match](#vision-match). |

## Vision Match

Navigate to **Settings > Ground Control > Vision Match**. With **Enable Vision Match** on, Face Detection and Hand Gestures run on Ground Control instead of the device. They work as before: **Dismiss on face** and **Postpone on face** under **Settings > Screensaver > Face Detection**, and **Show fingers** gestures under **Settings > Gestures**.

| Setting | Default | What it does |
| --- | --- | --- |
| Enable Vision Match | off | Runs the features below on Ground Control. Needs the camera and Ground Control. |
| Enable Face Detection | on | Runs face detection on Ground Control. Off, it runs on the device. |
| Enable Hand Gestures | on | Runs palm and finger gesture detection on Ground Control. Off, it runs on the device. |


- The finger count is right more often, also in dim light and a few meters away, and a face turned away no longer counts as one looking at the screen. On an Echo Show 5 the CPU the models used is free again: about a tenth of a second for each face look and half a second for each hand look.
- The camera and motion detection stay on the device. A frame goes to Ground Control only when something moves in front of the camera, one at a time, and Ground Control doesn't keep it.
- Looks are paced to what the machine running Ground Control keeps up with.
- A feature on Ground Control also works on devices that can't run it on their own, such as Android 7 devices and x86 devices for hands.
- When Ground Control doesn't answer, the looks of the features on Ground Control wait for it and the log says so once. The models on the device are used only for a feature that is off here.

Vision Match needs a Ground Control version with Vision Match. Choose its models in Ground Control under **Settings > Vision Match**: Light runs on any CPU, Accurate needs an NVIDIA GPU. A device without a screen has no Vision Match page.

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

The Kiosks page of the Ground Control app also shows which Voice Match features each kiosk has on, from **Settings > Ground Control > Voice Match**.
