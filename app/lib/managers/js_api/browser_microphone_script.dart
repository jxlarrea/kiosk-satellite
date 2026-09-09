/// Track browser microphone ownership before opening getUserMedia.
const browserMicrophoneScript = r'''
  if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
    const devices = navigator.mediaDevices;
    const original = devices.getUserMedia.bind(devices);
    const documentId = Math.random().toString(36).slice(2);
    let serial = 0;
    devices.getUserMedia = async function (constraints) {
      if (!constraints || !constraints.audio) return original(constraints);
      const id = documentId + ':' + String(++serial);
      await call('browserMicrophone', {id: id, active: true});
      const live = new Set();
      let released = false;
      function release() {
        if (released || live.size) return;
        released = true;
        call('browserMicrophone', {id: id, active: false});
      }
      function watch(track) {
        if (track.readyState === 'ended') return;
        live.add(track);
        function ended() { live.delete(track); release(); }
        track.addEventListener('ended', ended, {once: true});
        const stop = track.stop.bind(track);
        track.stop = function () { stop(); ended(); };
        const clone = track.clone.bind(track);
        track.clone = function () {
          const copy = clone();
          watch(copy);
          return copy;
        };
      }
      try {
        const stream = await original(constraints);
        function watchStream(value) {
          value.getAudioTracks().forEach(watch);
          const clone = value.clone.bind(value);
          value.clone = function () {
            const copy = clone();
            watchStream(copy);
            return copy;
          };
        }
        watchStream(stream);
        release();
        return stream;
      } catch (error) {
        release();
        throw error;
      }
    };
  }
''';
