# Ground Control

Navigate to **Settings > Ground Control**, under the **Kiosk Satellite** heading.

[Kiosk Satellite Ground Control](https://github.com/jxlarrea/kiosk-satellite-ground-control) runs the work that is too heavy for a kiosk on a capable machine, as a Home Assistant app or a Docker container on a CPU or an NVIDIA GPU. Its first component is [Voice Match](voice-match.md), with Recognition, Trimming and Isolation: who is talking to the kiosk, and only their voice in the command.

Ground Control is off by default.

## Setup

1. Install Kiosk Satellite Ground Control as a Home Assistant app, or run its Docker container.
2. Turn on **Enable Ground Control**. Kiosks on the same network find it on their own. For Ground Control on another network, enter its address, such as `192.168.1.10:10900`.
3. The kiosk signs in with the Home Assistant token it already has. The first time, the status row shows **Waiting for approval**: open the Ground Control app, go to the Kiosks page and approve the kiosk. The status row then shows **Connected** and the people enrolled.
4. Tap **Open** on the **Ground Control app** row to add people and enroll them. As a Home Assistant app, it opens the app's page in Home Assistant. A Docker container opens its own web page.
5. Turn on the features you want, such as **Enable Voice Match** under **Settings > Voice Satellite > Ground Control Voice Match**.

## Settings

| Setting | Default | What it does |
| --- | --- | --- |
| Enable Ground Control | off | Connects the kiosk to Kiosk Satellite Ground Control. |
| Address | empty | Empty finds Ground Control on the network. Enter `host:port` for Ground Control on another network. |

## Features

Each feature Ground Control runs has a row under **Features**, after Connection.

| Feature | Where its settings are |
| --- | --- |
| Voice Match | Its row opens **Settings > Voice Satellite > Ground Control Voice Match**. See [Voice Match](voice-match.md). |
| Vision Match | Coming soon. Facial recognition using the device's camera. |

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

The Kiosks page of the Ground Control app also shows which Voice Match features each kiosk has on, from **Settings > Voice Satellite > Ground Control Voice Match**.
