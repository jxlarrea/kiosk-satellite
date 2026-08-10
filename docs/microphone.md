# Microphone settings

Settings → Screen & Audio → **Microphone settings**.

Escape hatches for devices whose audio stack does not behave. Every
default is what the app has always done, so an untouched install captures
exactly as it did before these existed. Nothing here is a general improvement:
each one trades something away, and on a device that already hears you well
they will make detection worse. The one exception is the microphone channel,
which on the right hardware is a genuine improvement; it appears only when
that hardware is selected.

## When you need them

The symptom is a device that only wakes when you are right next to it, where
the wake word sensitivity setting makes no difference. Sensitivity decides how
strict the model is about what it hears; it cannot help when the audio arriving
at the model is simply too quiet.

Check the level before changing anything. Settings → Voice Satellite → **Wake
Word Tester** shows a live **Mic level**, a linear RMS of what the microphone
is delivering:

| Mic level | What it means |
| --- | --- |
| below 0.005 | far too quiet, detection will be unreliable at any distance |
| 0.01 to 0.02 | low, works up close and rarely at room distance |
| 0.05 to 0.1 | healthy speech level, what the models expect |
| above 0.3 sustained | too hot, loud speech will clip |

Speak normally from where you actually use the device. If a plain recorder app
sounds fine and the tester reads far lower, the capture path is the problem,
not the microphone.

## Capture mode

Which of Android's microphone paths to record from.

- **Voice communication** (default) is the phone-call capture path. It is the
  only one echo cancellation works on, which is why it is the default: the
  device listens for the stop word while its own speech is playing.
- **Voice recognition** and **Raw microphone** skip that path entirely.

On custom ROMs the call path is the one most likely to be miscalibrated, since
it is the least tested. A ROM can deliver it 20 dB below the raw microphone
while a recorder app on the plain source sounds perfectly fine. That is the
case this setting exists for.

The cost of moving off Voice communication is echo cancellation: the device may
hear its own speech through its own speaker and score it, so it talks over
itself or wakes on its own voice. Move the speaker further from the microphone,
or lower the volume, if that starts happening.

## Automatic gain control

Hands the levelling to Android instead of a fixed gain, so quiet and loud
speech both arrive at a usable level.

It is off by default because it adapts continuously: with nobody speaking it
lifts the room noise up to speaking level, and wake word models are not trained
on a signal whose level moves underneath them. On many devices, particularly
the ones with a broken capture path in the first place, it does nothing at all.

Turning it on hides the gain slider. They are two controls over one number, and
a fixed gain underneath an adaptive one just fights it.

## Microphone gain

Amplifies the captured audio, 0 to 24 dB, before anything hears it: the wake
word engine, the stop word, and the audio streamed to Home Assistant for speech
to text all get the boosted signal.

Set it with the wake word tester open and aim for around 0.05 while speaking
normally from your usual distance. As a starting point, every 6 dB doubles the
level, so a tester reading of 0.012 needs roughly 12 dB to reach 0.05.

This does not improve the signal to noise ratio, and it is not meant to: room
noise comes up with the speech. It works because two of the three wake word
engines do no level compensation of their own, so audio arriving well below
what a model was trained on lands in the wrong place regardless of how clean it
is. Too much gain is worse than none, since clipped speech is distorted speech.

## Microphone channel

Only shown when the microphone selected under Audio Devices reports more than
one channel. Most built-in microphones do not, so most devices never see this
row.

Multichannel USB microphones often put a differently processed signal on each
channel. The reSpeaker XVF3800 is the motivating example: channel 1 carries
its call output, tuned to sound good to a person on the other end of a call
(noise suppression and automatic gain control), while channel 2 carries the
same picked-up voice with a fixed gain and lighter processing, the output XMOS
recommends for feeding recognition engines.

- **Downmix** (default) lets Android average every channel together, which is
  what the app has always done. On an array like the one above that mixes the
  call-processed channel into the clean one.
- **Channel N** feeds that channel alone to the wake word engine, the stop
  word and speech to text.

If a multichannel array underperforms on wake words, pick its recognition
channel; on the XVF3800 that is channel 2. If a chosen channel cannot be
opened (the array was swapped for a simpler microphone), capture falls back
to the downmix rather than going silent.

## Notes

- Changing any of these reopens the microphone. Detection stops for a moment
  and resumes on its own.
- All of them are applied when capture starts, so they are equally in force
  with the screen off and while background listening is running.
- The settings appear in the remote admin in the same place, under Voice
  Satellite.
