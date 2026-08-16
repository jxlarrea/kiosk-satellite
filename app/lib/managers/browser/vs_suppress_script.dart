/// Document-start script that keeps Voice Satellite from starting on a Home
/// Assistant page shown outside the dashboard.
///
/// Voice Satellite runs per page, not per card: its engine boots on every
/// Home Assistant page that loads its module, builds a card instance so its
/// overlay renders with no card on any dashboard, and starts the session.
/// That is exactly right on the dashboard and wrong everywhere else here — a
/// Home Assistant page opened from a link, shown by the rotation, or set as
/// the website screensaver would open a second microphone and register a
/// second time as the same satellite, against the dashboard that is already
/// doing both underneath. The visible half is a stray mic button over a wall
/// clock; the rest is two sessions on one satellite entity.
///
/// The engine guards its own bootstrap against running twice, on a global
/// flag, so claiming that flag before Voice Satellite's module runs is
/// enough: the page keeps every other thing it does, and the satellite stays
/// the dashboard's. Only for pages on this Home Assistant, which are the only
/// ones that could load Voice Satellite in the first place.
///
/// A Voice Satellite card placed on such a page by hand still builds — that
/// is somebody deliberately putting one there, not the engine bringing itself
/// up uninvited.
const vsSuppressScript = '''
(function () {
  try {
    if (!window.__vsEngine) window.__vsEngine = true;
  } catch (e) {}
})();
''';
