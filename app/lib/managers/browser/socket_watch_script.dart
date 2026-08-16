/// Document-start script that tells the app when the page's Home Assistant
/// websocket closes.
///
/// The dashboard watchdog (BrowserManager) polls for a connection that is
/// down, which finds every way of dying but takes minutes to do it. The page
/// already knows the instant it happens, and a closed socket is the one event
/// worth reacting to immediately: Home Assistant drops a client that cannot
/// keep up with its outgoing queue (4096 pending messages) and the frontend
/// then refuses to reconnect for as long as it believes the page is in the
/// background, which is exactly what leaves a kiosk stranded on "Connection
/// lost. Reconnecting…" (issue #228). Hearing the close turns three minutes
/// of polling into ten seconds.
///
/// Reports only, and only for Home Assistant's own socket. Every other
/// websocket on the page (cameras, Sendspin, an integration's own) is passed
/// through untouched, and the socket handed back is the real one — the ws
/// filter wraps the same constructor, so both have to compose.
const haSocketWatchScript = '''
(function () {
  if (window.__ksSockWatch) return;
  var Native = window.WebSocket;
  if (!Native) return;
  var S = { closes: 0, lastAt: 0 };
  window.__ksSockWatch = S;
  window.WebSocket = function (url, protocols) {
    var ws = protocols === undefined ? new Native(url) : new Native(url, protocols);
    if (/\\/api\\/websocket\\/?(\$|\\?)/.test('' + url)) {
      ws.addEventListener('close', function () {
        S.closes++;
        S.lastAt = Date.now();
        try {
          window.flutter_inappwebview.callHandler('ksHaSocketClosed');
        } catch (e) {}
      });
    }
    return ws;
  };
  window.WebSocket.prototype = Native.prototype;
  window.WebSocket.CONNECTING = Native.CONNECTING;
  window.WebSocket.OPEN = Native.OPEN;
  window.WebSocket.CLOSING = Native.CLOSING;
  window.WebSocket.CLOSED = Native.CLOSED;
})();
''';
