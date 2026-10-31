# Microphone Settings

Navigate to **Settings > Screen & Audio > Microphone settings**.

By default the kiosk records from Android's microphone source, the same path a recorder app uses, and runs its own echo canceller over it. The rest of this page is escape hatches for devices whose Android audio stack is miscalibrated or behaving unpredictably. None of them is a universal upgrade: each trades off a specific capability, and applying them to a device that already hears you well will degrade detection. The exception is the microphone channel selector, which can offer a real quality boost on specialized hardware. It only appears when such hardware is selected.

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

The tester's **Play last 10 seconds** button plays back exactly what the wake word engine heard, on the kiosk's speaker. Say the wake word from your usual spot, then listen. Harsh distortion on loud syllables means the signal is clipping. A faint or muffled recording means it is too quiet or in the wrong format.

To review activations after they happen, turn on **Enable wake word diagnostics** on **Settings > Voice Satellite > Wake word diagnostics**. The kiosk then keeps its last 10 wake word activations and, separately, its last 10 near misses: moments when the score reached 75% of the threshold and fell back without triggering. Each entry shows its score, the threshold it had to clear, the peak and average level of the audio and a 3 second clip you can play on the device or in the remote admin. An activation clip tells you whether a trigger came from you or from the TV. A near miss clip lets you hear why a wake word you said did not register. A clip marked **Clipped** reached full scale, so lower the gain. Turning diagnostics off deletes the recordings.

The **Microphone level** row at the bottom of Microphone settings shows the same level without the tester. It opens the microphone itself when no wake word engine is running, so it also works before Voice Satellite has started. A bar that never moves means no audio reaches the app and the app log says why.

## Capture Mode

**Raw microphone** is the default and the right choice for almost every device. **Voice communication** records on Android's call audio path instead. Some OEM ROMs only deliver a working microphone there: the level stays empty on the raw microphone, or the microphone goes silent after the kiosk plays a chime or an answer and only comes back when a microphone setting changes. Pick **Voice communication** on those devices.

Voice communication only changes where the kiosk records from. Android attaches its own echo canceller, noise suppressor or gain control to the call path on many devices, and the kiosk turns them off, so only its own echo canceller, noise suppression and gain apply. Chimes and answers still play as media. Processing a ROM does inside its audio driver cannot be turned off from an app, so check the level in the wake word tester after switching.

The kiosk also falls back on its own: when every format on the picked mode reads silence, it tries the other capture sources before giving up (see [Capture Format](#capture-format)).

## Echo Cancellation

On by default. It removes the kiosk's own sounds from the microphone with WebRTC's echo canceller, the one video calling apps use, so the wake word hears you over music and a realtime assistant does not hear its own answers and interrupt itself.

It covers everything the kiosk plays itself: chimes, timers, text to speech, the realtime assistant's voice, intercom calls, alarms, the Sendspin player and audio sent over DLNA. Every feature that listens gets the cleaned microphone, so the wake word, Assist, realtime conversations, the intercom and the RTSP stream all benefit. Sound from web pages and the sound of DLNA videos are not covered. The canceller only runs while something plays and for a moment after, so an idle microphone passes through untouched.

The kiosk does not use Android's own echo canceller, noise suppressor or gain control. Android's canceller only worked on the phone call capture path, which some custom ROMs deliver 20 dB quieter than the microphone source, and on most devices it let the assistant hear itself anyway. Devices that process the microphone in their own firmware, such as the Echo Show and the Meta Portal, keep doing so, and the kiosk's canceller takes care of what their hardware canceller leaves.

Turn it off only if a microphone with its own canceller sounds worse with a second one over it. The wake word then hears the kiosk's own sounds.

## Noise Suppression

Off by default. It runs WebRTC's noise suppressor over the microphone, on any capture source, and takes out the steady hiss of a cheap microphone or a high gain setting. Turn it on when the other kiosk hears hiss from this one on intercom calls, or when the wake word tester shows a level that never rests. It changes what the wake word hears, so test the wake word after turning it on.

## Microphone Gain

Adjusts the captured audio from -24 to 24 dB after echo cancellation and noise suppression, so a boost never clips the speaker's echo before the canceller removes it. The wake word engine, the stop word classifier and the speech to text stream sent to Home Assistant all receive the adjusted signal.

To calibrate this, keep the wake word tester open and adjust the gain until normal speech from your usual distance reads around 0.05. As a baseline rule, every 6 dB doubles the signal level; for example, if the tester reads 0.012, you will need roughly 12 dB of gain to hit the target 0.05 mark.

This amplification does not improve the signal to noise ratio, nor is it designed to: background room noise is amplified equally alongside speech. However, it is effective because two of the three supported wake word engines perform no internal level normalization. If audio arrives significantly below the levels used during model training, detection will fail regardless of how clean the audio is. Avoid applying excessive gain, as clipped speech creates severe distortion that breaks recognition.

## Capture Format

The app consumes 16 kHz mono audio and by default asks Android for exactly that, leaving the platform to convert from whatever the microphone records. Some sound cards record at 48 kHz stereo and nothing else, among them the I2S codecs used by Raspberry Pi audio HATs and most USB audio interfaces. Android normally converts in between. A custom ROM whose audio HAL hands the requested format straight to the sound card cannot, and the capture then fails in one of three ways: the open is refused, the reads return nothing, or the card's frames arrive misread as 16 kHz mono, which sounds like noise or crackle and shows on the level meter as a signal that never becomes a detection.

When the ROM's audio configuration itself blocks the microphone, no format helps. The [Raspberry Pi 4](raspberry-pi.md) guide covers two such cases and their fixes.

Capture therefore walks a short ladder of formats: 16 kHz mono, then 48 kHz stereo, then 48 kHz mono. After those it tries the other capture sources: Android's voice recognition source, then whichever of the microphone and call sources **Capture mode** did not pick. That covers firmware such as the Meta Portal Mini's, which hands the microphone source nothing but zeros. A kiosk only reaches them when every format on the picked mode read silence. If one of them delivers audio while the picked mode never did, the kiosk opens it first until the app restarts or the mode changes. It steps to the next one when an open is refused, when the capture reads nothing but zeros or errors for two seconds, when a read delivers nothing at all for three seconds or when the delivered frame rate does not match the rate it was opened at. That last check is what catches a format lie: a capture opened at 16 kHz mono that is really fed 48 kHz stereo arrives six times too fast, and an old HAL that hands over mono under a stereo label arrives at half speed with the pitch doubled. Some devices slow the microphone down while they play a sound, so a rate that comes in short while the kiosk plays something is measured again afterward instead of counting against the format. Too many frames counts at any time. Each step is logged with the rate it delivers, so the log says which format the device ended on and why.

Silence alone proves little, since some microphones hand over exact zeros whenever the room is quiet. A format that has delivered audio is trusted and is only questioned after thirty seconds of silence. When every format on the ladder reads silence, capture returns to the one that delivered audio earlier, or to the first one when none did, and waits a minute before trying the ladder again, doubling that wait up to ten minutes. A microphone that really stopped is retried within minutes, while one that is merely quiet is not reopened every two seconds. Some audio HALs gate a quiet room to exact zeros, such as the Rockchip HAL on many PoE wall panels. If a run of zeros ends with audio on its own, the format is gating rather than dead, so silence never moves capture off it again until the app restarts. After ten minutes of silence it is only reopened on the same format and source.

* **Automatic** (Default): Starts at 16 kHz mono. Most devices never leave it.
* **48 kHz stereo**: Starts at 48 kHz stereo, the sound card's own format, and keeps 16 kHz mono as the last resort. Pick this when the microphone works in other apps but the wake word tester shows nothing, or a level that never becomes a detection.

Anything but 16 kHz mono is converted in the app with a proper low-pass filter ahead of the rate change, so a microphone that really records at 48 kHz loses only what it hears above 8 kHz. A microphone channel selection still applies: the capture opens wide enough to include the chosen channel and forwards that channel alone. Bluetooth and 16 kHz microphones work in either setting, the platform simply converts the other way, so the setting costs nothing on a device that does not need it, but it also gains nothing there.

## Microphone Channel

This row only appears when the microphone selected under Audio Devices explicitly reports more than one physical audio channel. Most built in tablet microphones are single channel, so most devices will never see this option.

Multichannel USB microphone arrays often route differently processed signals to each channel. For example, the reSpeaker XVF3800 delivers call tuned audio on channel 1 (including aggressive noise suppression and automatic gain control intended for human listeners) and a clean voice signal with fixed gain and minimal processing on channel 2 (the exact output recommended by XMOS for speech recognition engines).

* **Downmix** (Default): Averages all available channels together into a single stream, matching historical app behavior. On a multichannel array like the one described above, this blends the call processed audio into the clean channel.
* **Channel N**: Isolates and feeds that specific channel directly to the wake word engine, the stop word classifier, and speech to text processing.

If a multichannel array yields poor wake word performance under Downmix, select its dedicated recognition channel (channel 2 on the XVF3800). If a previously selected channel becomes unavailable (for example, if the array is unplugged and replaced with a simple microphone), the capture automatically falls back to Downmix rather than going silent.

## Microphones That Cut Quiet Sound

Some ROMs run their own noise suppression and gain control inside the audio driver, before any app receives the audio. The Rockchip driver on many PoE wall panels is one of them. Normal speech comes out at a steady level, but anything below a fixed threshold comes out as exact silence. The level meter drops to zero between words and wake word diagnostics clips show long runs of silence before and after the wake word. Speech from across the room falls under the threshold, so the wake word only triggers close to the panel.

No setting in the app can bring that audio back. Microphone gain and noise suppression only change what the driver hands over. Every capture mode and capture format goes through the same driver. If you need the wake word to work from across the room on one of these panels, use a USB microphone. Android records USB audio through a separate driver that does not apply this processing.

## Notes

* Adjusting any of these settings temporarily reopens the microphone. Detection pauses briefly and resumes automatically.
* All settings are applied when the capture session starts, meaning they remain fully active when the screen is off and during background listening.
* These options are also available in the remote admin interface under Screen & Audio.
