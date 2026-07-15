# Kiosk Satellite

A modern, cross-platform (Android/iOS) kiosk browser for Home Assistant —
and the companion app for
[Voice Satellite](https://github.com/jxlarrea/voice-satellite-card-integration).

## Why

- **Fully Kiosk, but modern** — the essential kiosk feature set behind a
  clean Material 3 UI, on Android *and* iOS.
- **Home Assistant native** — connect with a long-lived token, pick a
  dashboard, hide the HA header/sidebar, and (soon) expose the device to HA
  via MQTT discovery.
- **Voice Satellite companion** — native wake-word detection (microWakeWord,
  the same models Voice Satellite ships) handed off to the card through the
  `window.kioskSatellite` JavaScript API. Native listening keeps working with
  the screen off — something no browser-based engine can do.
- **Remote management** — an embedded web server (REST + WebSocket + admin
  SPA) that administers every feature of the app.

## Status

Early scaffold. Working today: the kiosk WebView with the JS API bridge,
setup wizard with HA connection + dashboard picker, HA kiosk mode, declarative
settings (local UI + remote API), screensaver (dim/black), screen/brightness
control, the remote REST/WS server, and the full wake-word handoff state
machine (with a `simulateWakeWord` command for end-to-end testing — the TFLite
engine itself is next).

## Documentation

- [Architecture](docs/architecture.md) — managers, event bus, command registry
- [JavaScript API](docs/js-api.md) — `window.kioskSatellite`, wake-word handoff protocol
- [Remote API](docs/remote-api.md) — REST + WebSocket surface

## Development

```sh
cd app
flutter pub get
flutter run          # deploys to the connected device
flutter test
flutter analyze
```

The app lives in [app/](app/), one folder per manager under
[app/lib/managers/](app/lib/managers/). The remote admin SPA will live in
`remote-ui/`.
