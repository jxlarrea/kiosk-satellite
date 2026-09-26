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

The tester's **Play last 10 seconds** button plays back exactly what the wake word engine heard, on the kiosk's speaker. Say the wake word from your usual spot, then listen. Harsh distortion on loud syllables means the signal is clipping. A faint or muffled recording means it is too quiet or the capture mode is wrong.

To review activations after they happen, turn on **Enable wake word diagnostics** on **Settings > Voice Satellite > Wake word diagnostics**. The kiosk then keeps its last 10 wake word activations and, separately, its last 10 near misses: moments when the score reached 75% of the threshold and fell back without triggering. Each entry shows its score, the threshold it had to clear, the peak and average level of the audio and a 3 second clip you can play on the device or in the remote admin. An activation clip tells you whether a trigger came from you or from the TV. A near miss clip lets you hear why a wake word you said did not register. A clip marked **Clipped** reached full scale, so lower the gain. Turning diagnostics off deletes the recordings.

The **Microphone level** row at the bottom of Microphone settings shows the same level without the tester. It opens the microphone itself when no wake word engine is running, so it also works before Voice Satellite has started. A bar that never moves means no audio reaches the app and the app log says why.

## Capture Mode

This setting determines which of Android's internal microphone audio paths the app records from.

* **Voice communication** (Default): Requests Android's call capture path and hardware echo cancellation. Native assistant playback also uses a communication audio session on supported outputs so the canceller can remove speaker audio while the kiosk listens for a stop word.
* **Voice recognition** and **Raw microphone**: Completely bypass the phone call capture path.

On custom ROMs, the call capture path is frequently miscalibrated because it undergoes the least testing during development. A custom ROM might deliver audio on the call path 20 dB quieter than the raw microphone, even though a standard recording app on the raw source sounds perfectly clear. This setting exists specifically to resolve that issue.

Echo cancellation on other capture modes depends on the device. An enabled effect does not guarantee that Android supplies the playback signal it needs. The kiosk may then hear its own speaker output and process it as speech.

While native capture uses the built-in microphone and speaker, the app keeps its communication route and a silent output track open between assistant sounds. This avoids rebuilding the hardware playback path at every chime and TTS response. The route is released when native capture and its last sound end or the selected devices change. Capture watchdog suppression still follows actual assistant sounds, not the silent output track. Master and assistant volume controls apply through software gain. External microphones and media outputs such as Bluetooth A2DP and HDMI keep their selected routes. Devices without an Android echo canceller need echo processing in their microphone hardware or another audio path.

**Full assistant volume range**, below Assistant volume in Screen & Audio, is on by default. It sets the built-in speaker's call volume to 100% when the native assistant audio route is acquired after startup or re-enabling the setting. Initialization waits until the app can acquire its communication route without taking over an existing call. When re-enabled during capture, it applies the next time the route is acquired. The level is an intentional baseline shared with other apps using call audio. Playback cleanup and turning the toggle off do not restore the previous level. Later call-volume adjustments are preserved until the next initialization. With the toggle off or call volume subsequently reduced, the system call volume can limit maximum assistant output.

Android can briefly mute other media when native capture first establishes its route or releases it. Native voice interactions reuse the established route. Browser microphone handoff and device changes can still require a transition. This routing behavior is separate from the app's voice-interaction ducking setting.

## Echo Cancellation

On by default, and on for every capture the app has ever opened: the stop word listens while the kiosk's own speaker plays a response, and without the canceller the microphone hears that speech and scores it. The canceller only gets a playback reference on the Voice communication capture mode. On the other two modes the effect still attaches and what it does then is up to the device.

Turn it off only when it does harm. On some MediaTek tablets a canceller attached to a Voice recognition or Raw microphone capture attenuates the whole signal to a whisper, a level the gain slider cannot bring back, while a recorder app on the same source sounds fine. With it off, expect the stop word to hear the kiosk's own responses.

## Automatic Gain Control

Enabling Automatic Gain Control delegates volume levelling to Android rather than applying a fixed gain boost, ensuring both quiet and loud speech arrive at a usable level.

This feature is disabled by default because it continuously adapts to ambient sound. When no one is speaking, it automatically boosts background room noise up to speech levels. Wake word models are not trained to process signals with fluctuating noise floors. Furthermore, on many budget or misconfigured devices, Android's built in AGC implementation does nothing at all.

Turning this setting on automatically hides the manual gain slider. They control the same underlying value, and combining a fixed gain with an adaptive algorithm causes them to fight each other.

## Microphone Gain

Amplifies the captured audio from 0 to 24 dB before it reaches any downstream processing. The wake word engine, the stop word classifier, and the speech to text stream sent to Home Assistant all receive this boosted signal.

To calibrate this, keep the wake word tester open and adjust the gain until normal speech from your usual distance reads around 0.05. As a baseline rule, every 6 dB doubles the signal level; for example, if the tester reads 0.012, you will need roughly 12 dB of gain to hit the target 0.05 mark.

This amplification does not improve the signal to noise ratio, nor is it designed to: background room noise is amplified equally alongside speech. However, it is effective because two of the three supported wake word engines perform no internal level normalization. If audio arrives significantly below the levels used during model training, detection will fail regardless of how clean the audio is. Avoid applying excessive gain, as clipped speech creates severe distortion that breaks recognition.

## Capture Format

The app consumes 16 kHz mono audio and by default asks Android for exactly that, leaving the platform to convert from whatever the microphone records. Some sound cards record at 48 kHz stereo and nothing else, among them the I2S codecs used by Raspberry Pi audio HATs and most USB audio interfaces. Android normally converts in between. A custom ROM whose audio HAL hands the requested format straight to the sound card cannot, and the capture then fails in one of three ways: the open is refused, the reads return nothing, or the card's frames arrive misread as 16 kHz mono, which sounds like noise or crackle and shows on the level meter as a signal that never becomes a detection.

When the ROM's audio configuration itself blocks the microphone, no format helps. The [Raspberry Pi 4](raspberry-pi.md) guide covers two such cases and their fixes.

Capture therefore walks a short ladder of formats: 16 kHz mono, then 48 kHz stereo, then 48 kHz mono. It steps to the next one when an open is refused, when the capture reads nothing but zeros or errors for two seconds, when a read delivers nothing at all for three seconds or when the delivered frame rate does not match the rate it was opened at. That last check is what catches a format lie: a capture opened at 16 kHz mono that is really fed 48 kHz stereo arrives six times too fast, and an old HAL that hands over mono under a stereo label arrives at half speed with the pitch doubled. Each step is logged with the rate it delivers, so the log says which format the device ended on and why.

Silence alone proves little, since some microphones hand over exact zeros whenever the room is quiet. A format that has delivered audio is trusted and is only questioned after thirty seconds of silence. When every format on the ladder reads silence, capture returns to the one that delivered audio earlier, or to the first one when none did, and waits a minute before trying the ladder again, doubling that wait up to ten minutes. A microphone that really stopped is retried within minutes, while one that is merely quiet is not reopened every two seconds.

* **Automatic** (Default): Starts at 16 kHz mono. Most devices never leave it.
* **48 kHz stereo**: Starts at 48 kHz stereo, the sound card's own format, and keeps 16 kHz mono as the last resort. Pick this when the microphone works in other apps but the wake word tester shows nothing, or a level that never becomes a detection.

Anything but 16 kHz mono is converted in the app with a proper low-pass filter ahead of the rate change, so a microphone that really records at 48 kHz loses only what it hears above 8 kHz. A microphone channel selection still applies: the capture opens wide enough to include the chosen channel and forwards that channel alone. Bluetooth and 16 kHz microphones work in either setting, the platform simply converts the other way, so the setting costs nothing on a device that does not need it, but it also gains nothing there.

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
