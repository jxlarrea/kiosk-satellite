# Ground Control

Navigate to **Settings > Ground Control**, under the **Kiosk Satellite** heading.

[Kiosk Satellite Ground Control](https://github.com/jxlarrea/kiosk-satellite-ground-control) is a companion service for Kiosk Satellite. It runs on a computer or server in your home and handles the voice and vision processing that kiosks don't have the computing power for. Install it as a Home Assistant app or run it in Docker on a CPU or an NVIDIA GPU.

Ground Control currently has two components. [Voice Match](voice-match.md) does speaker voice recognition, trimming and isolation. [Vision Match](vision-match.md) does Face Detection, Hand Gestures and Face Recognition with the device's camera.

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
| Vision Match | Face Detection, Hand Gestures and Face Recognition. See [Vision Match](vision-match.md). |

## Settings That Work With Ground Control

Some settings outside Settings > Ground Control only work with Ground Control. One example is **Detect faces** under **Settings > Screensaver > Face Detection > Ground Control Vision Match**. These settings have a **GC** tag after their title with Vision Match's face icon or Voice Match's voice icon. They appear only while that feature is on. Tap the tag to see what it means. The Vision Match page lists them with their values under **Used in other settings**. Tap one to go to that setting.

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
| Runs on | **CUDA**, **OpenVINO** or **Vulkan** when Ground Control runs models on a GPU, named after the image it uses. **CPU** otherwise. |

**Architecture** and **Runs on** need Ground Control 2026.11.10 or newer. Up to Ground Control 2026.11.16 the row shows **CUDA** or **CPU** only.

The Kiosks page of the Ground Control app also shows which Voice Match and Vision Match features each kiosk has turned on under **Settings > Ground Control**.
