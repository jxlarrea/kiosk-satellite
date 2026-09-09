# Microphone Settings

Navigate to **Settings > Screen & Audio > Microphone settings**.

These settings serve as escape hatches for devices whose Android audio stack is miscalibrated or behaving unpredictably. By default, every setting matches the app's historical baseline, so an untouched installation captures audio exactly as it always has. None of these toggles represent a universal upgrade: each one trades off a specific capability, and applying them to a device that already hears you well will actually degrade detection performance. The single exception is the microphone channel selector, which can offer a genuine quality boost on specialized hardware; this option only appears when supported hardware is selected.

## When You Need Them

The primary symptom requiring these adjustments is a kiosk that only triggers when you speak directly next to it, regardless of how high you set the wake word sensitivity. Sensitivity controls how strictly the AI model evaluates the audio it receives, but it cannot compensate if the incoming audio signal itself is simply too quiet.

Before adjusting anything, measure your actual input level. Go to **Settings > Voice Satellite > Wake Word Tester** to view the live **Mic level**, which displays a linear RMS value of the microphone signal:

| Mic Level | Meaning |
| --- | --- |
| Below 0.005 | Far too quiet. Detection will be completely unreliable at any distance. |
| 0.01 to 0.02 | Low input. Works up close, but rarely succeeds from across the room. |
| 0.05 to 0.1 | Healthy speech level. This is the optimal range expected by wake word models. |
| Above 0.3 sustained | Too hot. Loud speech will clip and distort. |

Speak at a normal volume from the distance where you typically use the device. If a standard voice recorder app sounds fine but the tester displays a very low value, the issue lies within Android's capture path rather than the physical microphone.

## Capture Mode

This setting determines which of Android's internal microphone audio paths the app records from.

* **Voice communication** (Default): Requests Android's call capture path and hardware echo cancellation. Native assistant playback also uses a communication audio session on supported outputs so the canceller can remove speaker audio while the kiosk listens for a stop word.
* **Voice recognition** and **Raw microphone**: Completely bypass the phone call capture path.

On custom ROMs, the call capture path is frequently miscalibrated because it undergoes the least testing during development. A custom ROM might deliver audio on the call path 20 dB quieter than the raw microphone, even though a standard recording app on the raw source sounds perfectly clear. This setting exists specifically to resolve that issue.

Echo cancellation on other capture modes depends on the device. An enabled effect does not guarantee that Android supplies the playback signal it needs. The kiosk may then hear its own speaker output and process it as speech.

While native capture uses the built-in microphone and speaker, the app keeps its communication route and a silent output track open between assistant sounds. This avoids rebuilding the hardware playback path at every chime and TTS response. The route is released when native capture and its last sound end or the selected devices change. Capture watchdog suppression still follows actual assistant sounds, not the silent output track. Master and assistant volume controls apply through software gain. External microphones and media outputs such as Bluetooth A2DP and HDMI keep their selected routes. Devices without an Android echo canceller need echo processing in their microphone hardware or another audio path.

**Full assistant volume range**, below Assistant volume in Screen & Audio, is on by default. It sets the built-in speaker's call volume to 100% when the native assistant audio route is acquired after startup or re-enabling the setting. Initialization waits until the app can acquire its communication route without taking over an existing call. When re-enabled during capture, it applies the next time the route is acquired. The level is an intentional baseline shared with other apps using call audio. Playback cleanup and turning the toggle off do not restore the previous level. Later call-volume adjustments are preserved until the next initialization. With the toggle off or call volume subsequently reduced, the system call volume can limit maximum assistant output.

Android can briefly mute other media when native capture first establishes its route or releases it. Native voice interactions reuse the established route. Browser microphone handoff and device changes can still require a transition. This routing behavior is separate from the app's voice-interaction ducking setting.

## Automatic Gain Control

Enabling Automatic Gain Control delegates volume levelling to Android rather than applying a fixed gain boost, ensuring both quiet and loud speech arrive at a usable level.

This feature is disabled by default because it continuously adapts to ambient sound. When no one is speaking, it automatically boosts background room noise up to speech levels. Wake word models are not trained to process signals with fluctuating noise floors. Furthermore, on many budget or misconfigured devices, Android's built in AGC implementation does nothing at all.

Turning this setting on automatically hides the manual gain slider. They control the same underlying value, and combining a fixed gain with an adaptive algorithm causes them to fight each other.

## Microphone Gain

Amplifies the captured audio from 0 to 24 dB before it reaches any downstream processing. The wake word engine, the stop word classifier, and the speech to text stream sent to Home Assistant all receive this boosted signal.

To calibrate this, keep the wake word tester open and adjust the gain until normal speech from your usual distance reads around 0.05. As a baseline rule, every 6 dB doubles the signal level; for example, if the tester reads 0.012, you will need roughly 12 dB of gain to hit the target 0.05 mark.

This amplification does not improve the signal to noise ratio, nor is it designed to: background room noise is amplified equally alongside speech. However, it is effective because two of the three supported wake word engines perform no internal level normalization. If audio arrives significantly below the levels used during model training, detection will fail regardless of how clean the audio is. Avoid applying excessive gain, as clipped speech creates severe distortion that breaks recognition.

## Microphone Channel

This row only appears when the microphone selected under Audio Devices explicitly reports more than one physical audio channel. Most built in tablet microphones are single channel, so most devices will never see this option.

Multichannel USB microphone arrays often route differently processed signals to each channel. For example, the reSpeaker XVF3800 delivers call tuned audio on channel 1 (including aggressive noise suppression and automatic gain control intended for human listeners) and a clean voice signal with fixed gain and minimal processing on channel 2 (the exact output recommended by XMOS for speech recognition engines).

* **Downmix** (Default): Averages all available channels together into a single stream, matching historical app behavior. On a multichannel array like the one described above, this blends the call processed audio into the clean channel.
* **Channel N**: Isolates and feeds that specific channel directly to the wake word engine, the stop word classifier, and speech to text processing.

If a multichannel array yields poor wake word performance under Downmix, select its dedicated recognition channel (channel 2 on the XVF3800). If a previously selected channel becomes unavailable (for example, if the array is unplugged and replaced with a simple microphone), the capture automatically falls back to Downmix rather than going silent.

## Notes

* Adjusting any of these settings temporarily reopens the microphone. Detection pauses briefly and resumes automatically.
* All settings are applied when the capture session starts, meaning they remain fully active when the screen is off and during background listening.
* These options are also available in the remote admin interface under the Voice Satellite section.
