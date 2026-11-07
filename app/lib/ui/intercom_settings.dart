import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_container.dart';
import '../core/app_locales.dart';
import '../l10n/messages.dart';
import '../core/events.dart';
import '../managers/device/device_details.dart';
import '../managers/intercom/intercom_manager.dart' show IntercomManager;
import '../managers/settings/definitions.dart' as defs;
import 'entity_picker.dart';
import 'kit.dart';
import 'settings_search.dart';
import 'theme.dart';
import 'toast.dart';

/// The Intercom pieces the definitions cannot draw: the setup card the
/// page opens with when the remote admin is off, the Change key row and
/// its dialog, the Kiosks card, the Call a kiosk screen the kiosk menu
/// opens and the call screen. The remote admin mirrors the page
/// (intercom.js); the two screens are the kiosk's alone, a browser cannot
/// talk.

// ── The page ───────────────────────────────────────────────────────────

/// The Intercom page: the setup card when the remote admin or Find other
/// kiosks is off, the definition-drawn [cards], then the Kiosks card. The
/// roster comes from `intercomStatus`, which also asks the manager to
/// probe stale kiosks, and redraws on every [IntercomStateChanged] and on
/// a 30 s timer while the page is open.
class IntercomSettingsPanel extends StatefulWidget {
  const IntercomSettingsPanel({
    super.key,
    required this.container,
    required this.cards,
  });

  final AppContainer container;

  /// The generic cards for the category, built by the settings screen.
  final List<Widget> cards;

  @override
  State<IntercomSettingsPanel> createState() => _IntercomSettingsPanelState();
}

class _IntercomSettingsPanelState extends State<IntercomSettingsPanel> {
  late Map<String, Object?> _status = widget.container.intercom.status();
  StreamSubscription<IntercomStateChanged>? _sub;
  Timer? _poll;

  AppContainer get c => widget.container;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _sub = c.bus.on<IntercomStateChanged>().listen((e) {
      if (mounted) setState(() => _status = e.status);
    });
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _sub?.cancel();
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final r = await c.commands.execute('intercomStatus', const {});
    if (!mounted || !r.ok || r.data is! Map) return;
    setState(() => _status = (r.data as Map).cast<String, Object?>());
  }

  Future<void> _call(String id) async {
    final r = await c.commands.execute('intercomCall', {'id': id});
    if (!mounted || r.ok) return;
    showToast(
      context,
      title: intercomText(context, "Could not call"),
      message: r.error == null
          ? null
          : intercomError(context, r.error!, status: c.intercom.status()),
      kind: ToastKind.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final available = _status['available'] == true;
    // The roster is worth nothing with the intercom off: the switch is
    // the whole page then.
    final enabled = _status['enabled'] == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!available) ...[
          SettingsCard(
            children: [
              SettingsRow(
                leading: Icon(Icons.cloud_off_outlined),
                title: Text(
                  intercomText(context, "The intercom needs the remote admin"),
                ),
                subtitle: Text(
                  intercomText(
                    context,
                    "Kiosks find and reach each other through it. Turn on Remote management and Find other kiosks under Device, then come back.",
                  ),
                ),
              ),
            ],
          ),
        ],
        ...widget.cards,
        if (_status['video'] == true && _status['cameraReady'] != true)
          GroupNote(
            intercomText(
              context,
              "The camera is off. This kiosk can show video but not send it.",
            ),
          ),
        if (enabled) ...[
          SectionHeading(intercomText(context, "Kiosks")),
          SearchLandingTarget(
            id: 'x:intercom_kiosks',
            child: SettingsCard(
              children: [
                ..._kioskRows(context),
                HintRow(
                  intercomText(
                    context,
                    "Discovered kiosks and saved fleet members. A kiosk is ready when it is reachable with intercom on, the same key and matching encryption settings.",
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _kioskRows(BuildContext context) {
    final kiosks = [
      for (final k in (_status['kiosks'] as List? ?? const []))
        if (k is Map) k.cast<String, Object?>(),
    ];
    if (kiosks.isEmpty) {
      return [
        SettingsRow(
          title: Text(intercomText(context, "No other kiosks found")),
          subtitle: Text(
            intercomText(
              context,
              "Kiosks with Remote management and Find other kiosks on show up here.",
            ),
          ),
        ),
      ];
    }
    final scheme = Theme.of(context).colorScheme;
    return [
      for (final k in kiosks)
        Opacity(
          opacity: k['status'] == 'offline' ? 0.45 : 1,
          child: SettingsRow(
            leading: const Icon(Icons.tablet_android_outlined),
            title: Text('${k['name']}'),
            subtitle: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('${k['address']}'),
                if ('${k['version'] ?? ''}'.isNotEmpty)
                  IntercomTag('${k['version']}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  intercomText(context, '${k['statusText']}'),
                  style: TextStyle(
                    fontSize: 13,
                    color: intercomStatusColor(context, '${k['status']}'),
                  ),
                ),
                if (k['status'] == 'ready') ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _call('${k['id']}'),
                    icon: Icon(
                      Icons.phone_outlined,
                      size: 18,
                      color: scheme.onSurface,
                    ),
                    label: Text(intercomText(context, "Call")),
                  ),
                ],
              ],
            ),
          ),
        ),
    ];
  }
}

/// The status word's color: ok green for Ready, the warning tone for a
/// different key, muted for the rest. The remote admin's --ok and --warn.
Color intercomStatusColor(BuildContext context, String status) {
  final theme = Theme.of(context);
  return switch (status) {
    'ready' => theme.brightness == Brightness.dark ? ksSage : ksSageOnLight,
    'key' || 'tls' || 'unreachable' => theme.colorScheme.tertiary,
    _ => theme.colorScheme.onSurfaceVariant,
  };
}

/// The small uppercase tag beside a kiosk's address: its version. The
/// remote admin's `.tag`, the fleet page's shape.
class IntercomTag extends StatelessWidget {
  const IntercomTag(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: .4,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ── The key ────────────────────────────────────────────────────────────

/// The row under the key's copy box: opens the Change key dialog.
class IntercomChangeKeyRow extends StatelessWidget {
  const IntercomChangeKeyRow({
    super.key,
    required this.container,
    required this.onChanged,
  });

  final AppContainer container;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => SettingsRow(
    title: Text(intercomText(context, "Change key")),
    subtitle: Text(
      intercomText(
        context,
        "Paste the key from another kiosk, or make a new one.",
      ),
    ),
    trailing: OutlinedButton(
      onPressed: () async {
        final changed = await showIntercomKeyDialog(context, container);
        if (changed) onChanged();
      },
      child: Text(intercomText(context, "Change")),
    ),
  );
}

/// The Change key dialog: the key in a field to paste over, Regenerate for
/// a fresh one. Answers true when the key changed.
Future<bool> showIntercomKeyDialog(
  BuildContext context,
  AppContainer container,
) async {
  final controller = TextEditingController(
    text: container.settings.get(defs.intercomKey),
  );
  final overlay = Overlay.of(context, rootOverlay: true);
  Future<bool> run(Map<String, Object?> params) async {
    final r = await container.commands.execute('intercomSetKey', params);
    if (!r.ok && context.mounted) {
      showToastIn(
        overlay,
        title: intercomText(context, "Could not change the key"),
        message: r.error == null
            ? null
            : intercomError(
                context,
                r.error!,
                status: container.intercom.status(),
              ),
        kind: ToastKind.error,
      );
    }
    return r.ok;
  }

  final route = DialogRoute<bool>(
    context: context,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return AlertDialog(
        title: Text(intercomText(ctx, "Intercom key")),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                autocorrect: false,
                enableSuggestions: false,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13.5),
              ),
              const SizedBox(height: 8),
              Text(
                intercomText(
                  ctx,
                  "Kiosks with this key can call each other. A new key cuts this kiosk off from the others until they get it too.",
                ),
                style: Theme.of(
                  ctx,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: OverflowBar(
              alignment: MainAxisAlignment.end,
              overflowAlignment: OverflowBarAlignment.end,
              spacing: 10,
              overflowSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () async {
                    final ok = await run(const {'regenerate': true});
                    if (ok && ctx.mounted) Navigator.pop(ctx, true);
                  },
                  child: Text(intercomText(ctx, "Regenerate")),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(intercomText(ctx, "Cancel")),
                ),
                FilledButton(
                  onPressed: () async {
                    final ok = await run({'key': controller.text});
                    if (ok && ctx.mounted) Navigator.pop(ctx, true);
                  },
                  child: Text(intercomText(ctx, "Save")),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
  final changed = await Navigator.of(context, rootNavigator: true).push(route);
  await route.completed;
  controller.dispose();
  return changed ?? false;
}

// ── The sheet ──────────────────────────────────────────────────────────

/// A Text to speech engine row, Announcements' or Alarms': the picked
/// entity's name in a control box, and a tap opens the radio picker over
/// every text to speech entity Home Assistant has, First available on
/// top. Mirrored on the remote.
class AnnouncementTtsEngineRow extends StatefulWidget {
  const AnnouncementTtsEngineRow({
    super.key,
    required this.container,
    this.def = defs.announcementsTtsEngine,
    this.languageDef = defs.announcementsTtsLanguage,
    this.voiceDef = defs.announcementsTtsVoice,
  });

  final AppContainer container;
  final defs.SettingDef<String> def;

  /// Cleared with a new engine: another engine's languages and voices
  /// are not these.
  final defs.SettingDef<String> languageDef;
  final defs.SettingDef<String> voiceDef;

  @override
  State<AnnouncementTtsEngineRow> createState() =>
      _AnnouncementTtsEngineRowState();
}

class _AnnouncementTtsEngineRowState extends State<AnnouncementTtsEngineRow> {
  StreamSubscription<SettingChanged>? _sub;

  AppContainer get c => widget.container;

  @override
  void initState() {
    super.initState();
    _sub = c.bus.on<SettingChanged>().listen((e) {
      if (e.key == widget.def.key && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _pick(String? id) async {
    // Clear is First available: the empty engine.
    final picked = id ?? '';
    if (picked == c.settings.get(widget.def).trim()) return;
    await c.settings.set(widget.def, picked);
    await c.settings.set(widget.languageDef, '');
    await c.settings.set(widget.voiceDef, '');
  }

  @override
  Widget build(BuildContext context) {
    return SearchLandingTarget(
      id: widget.def.key,
      child: PickRow(
        title: widget.def.localizedTitle(context),
        description: widget.def.localizedDescription(context),
        dialogTitle: esphomeText(context, 'Text to speech engine'),
        spec: entitySpec(context, c.commands, domains: const ['tts']),
        value: c.settings.get(widget.def).trim(),
        placeholder: esphomeText(context, 'First available'),
        allowClear: true,
        onPick: _pick,
      ),
    );
  }
}

/// A text to speech Language or Voice row under an engine row: the pick's
/// name in a control box, and a tap opens the list Home Assistant has for
/// the engine, Default on top. Voices come for the Language row's pick,
/// or Home Assistant's own language when that is Default. Mirrored on the
/// remote (intercom.js, attachTtsVoicePicker).
class TtsVoiceRow extends StatefulWidget {
  const TtsVoiceRow({
    super.key,
    required this.container,
    required this.def,
    required this.engineDef,
    required this.languageDef,
    required this.voiceDef,
  });

  final AppContainer container;

  /// [languageDef] or [voiceDef]: which of the two this row picks.
  final defs.SettingDef<String> def;
  final defs.SettingDef<String> engineDef;
  final defs.SettingDef<String> languageDef;
  final defs.SettingDef<String> voiceDef;

  @override
  State<TtsVoiceRow> createState() => _TtsVoiceRowState();
}

class _TtsVoiceRowState extends State<TtsVoiceRow> {
  StreamSubscription<SettingChanged>? _sub;
  List<String> _languages = const [];
  Map<String, String> _languageNames = const {};
  List<Map<String, String>> _voices = const [];

  AppContainer get c => widget.container;
  bool get _isLanguage => widget.def.key == widget.languageDef.key;
  String _get(defs.SettingDef<String> def) => c.settings.get(def).trim();

  @override
  void initState() {
    super.initState();
    final keys = {
      widget.engineDef.key,
      widget.languageDef.key,
      widget.voiceDef.key,
    };
    _sub = c.bus.on<SettingChanged>().listen((e) {
      if (!keys.contains(e.key) || !mounted) return;
      setState(() {});
      if (e.key != widget.voiceDef.key && _get(widget.def).isNotEmpty) {
        unawaited(_load());
      }
    });
    // Only a pick needs a name from Home Assistant; Default has its own.
    if (_get(widget.def).isNotEmpty) unawaited(_load());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// The engine's languages and the voices for [language], or the Language
  /// row's pick. False when Home Assistant did not answer.
  Future<bool> _load({String? language}) async {
    final engine = _get(widget.engineDef);
    if (engine.isEmpty) return false;
    final r = await c.commands.execute('ttsVoices', {
      'engine': engine,
      'language': language ?? _get(widget.languageDef),
    });
    if (!mounted || !r.ok || r.data is! Map) return false;
    final data = r.data as Map;
    final languages = [
      for (final l in (data['languages'] as List?) ?? const []) '$l',
    ];
    final voices = [
      for (final v in (data['voices'] as List?) ?? const [])
        if (v is Map) {'voice_id': '${v['voice_id']}', 'name': '${v['name']}'},
    ];
    final names = _isLanguage
        ? await DeviceDetails.languageNames(languages, appLanguageTag(context))
        : const <String, String>{};
    if (!mounted) return false;
    setState(() {
      _languages = languages;
      _languageNames = names;
      _voices = voices;
    });
    return true;
  }

  String _labelOf(String id) {
    if (id.isEmpty) return esphomeText(context, 'Default');
    if (_isLanguage) return _languageNames[id] ?? id;
    for (final v in _voices) {
      if (v['voice_id'] == id) return v['name']!;
    }
    return id;
  }

  Future<void> _pick() async {
    final ok = await _load();
    if (!mounted) return;
    if (!ok) {
      showToast(
        context,
        title: esphomeText(context, 'Could not reach Home Assistant'),
        kind: ToastKind.error,
      );
      return;
    }
    final choices = _isLanguage
        ? ([for (final l in _languages) (l, _languageNames[l] ?? l)]
            ..sort((a, b) => a.$2.toLowerCase().compareTo(b.$2.toLowerCase())))
        : [for (final v in _voices) (v['voice_id']!, v['name']!)];
    if (choices.isEmpty) {
      showToast(context, title: esphomeText(context, 'No voices to pick'));
      return;
    }
    final current = _get(widget.def);
    final picked = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(widget.def.localizedTitle(context)),
        children: [
          RadioGroup<String>(
            groupValue: current,
            onChanged: (value) => Navigator.of(context).pop(value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  value: '',
                  title: Text(esphomeText(context, 'Default')),
                ),
                // The id under the name, the way the engine picker shows
                // entity ids: it is what the announce action takes.
                for (final (id, name) in choices)
                  RadioListTile<String>(
                    value: id,
                    title: Text(name),
                    subtitle: id == name ? null : Text(id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (picked == null || picked == current) return;
    await c.settings.set(widget.def, picked);
    if (!_isLanguage) return;
    // A voice the new language lists too stays, Kokoro's and OpenAI's
    // case; a voice it does not is dropped for the engine's own.
    final voice = _get(widget.voiceDef);
    if (voice.isEmpty || !await _load(language: picked)) return;
    if (!_voices.any((v) => v['voice_id'] == voice)) {
      await c.settings.set(widget.voiceDef, '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _get(widget.def);
    return SearchLandingTarget(
      id: widget.def.key,
      child: SettingsRow(
        stack: true,
        title: Text(widget.def.localizedTitle(context)),
        subtitle: Text(widget.def.localizedDescription(context)),
        trailing: ControlBox(
          onTap: _pick,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(
                  _labelOf(current),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.expand_more, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── The Call a kiosk screen ────────────────────────────────────────────

/// The Call a kiosk screen the kiosk menu, a gesture or `intercomOpen`
/// opens: the app launcher's ground and close disc, the title with the
/// ready count, Announce to all and the roster as rounded rows, two
/// columns on a wide screen. A ready kiosk's row calls it; the others stay
/// on the list with their reason. Shown and hidden through the
/// manager's [IntercomManager.rosterVisible], so the menu, a gesture, the
/// remote admin, back, HOME, a call starting and the screensaver all meet
/// at one place.
class IntercomRosterOverlay extends StatelessWidget {
  const IntercomRosterOverlay({super.key, required this.container});

  final AppContainer container;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: container.intercom.rosterVisible,
    builder: (context, visible, _) {
      if (!visible) return const SizedBox.shrink();
      return Positioned.fill(child: _RosterScreen(container: container));
    },
  );
}

/// Whether the roster is being driven by dpad or keyboard keys: a key
/// arms the focus highlight, a touch stands it down, every open starts
/// without it. Same reasoning as the app launcher's wall (issue #377).
final _rosterKeysDriving = ValueNotifier<bool>(false);

class _RosterScreen extends StatefulWidget {
  const _RosterScreen({required this.container});

  final AppContainer container;

  @override
  State<_RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<_RosterScreen> {
  AppContainer get c => widget.container;

  late Map<String, Object?> _status = c.intercom.status();
  StreamSubscription<IntercomStateChanged>? _sub;

  /// The roster's own focus scope, so a directional search never wanders
  /// out to the dashboard's platform view underneath.
  final _scope = FocusScopeNode(debugLabel: 'intercom roster');
  final _first = FocusNode(debugLabel: 'intercom roster first');

  @override
  void initState() {
    super.initState();
    _rosterKeysDriving.value = false;
    _sub = c.bus.on<IntercomStateChanged>().listen((e) {
      if (mounted) setState(() => _status = e.status);
    });
    // Asks the manager to probe whatever has gone stale.
    unawaited(c.commands.execute('intercomStatus', const {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _first.requestFocus();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _first.dispose();
    _scope.dispose();
    super.dispose();
  }

  void _close() => c.intercom.rosterVisible.value = false;

  /// Places the call or starts the announcement. A call that starts takes
  /// the roster down through the manager; one refused leaves it up with
  /// the reason as a toast.
  Future<void> _pick(String command, Map<String, Object?> params) async {
    final r = await c.commands.execute(command, params);
    if (r.ok || !mounted) return;
    showToast(
      context,
      source: 'intercom',
      title: command == 'intercomBroadcast'
          ? intercomText(context, "Could not talk to everyone")
          : intercomText(context, "Could not call"),
      message: r.error == null
          ? null
          : intercomError(context, r.error!, status: c.intercom.status()),
      kind: ToastKind.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final all = [
      for (final k in (_status['kiosks'] as List? ?? const []))
        if (k is Map) k.cast<String, Object?>(),
    ];
    // Ready kiosks first, in the roster's order, then the rest with
    // their reasons.
    final ready = [
      for (final k in all)
        if (k['status'] == 'ready') k,
    ];
    final rest = [
      for (final k in all)
        if (k['status'] != 'ready') k,
    ];
    final kiosks = [...ready, ...rest];
    final count = ready.length;
    final line = switch (count) {
      0 => intercomText(context, "No kiosk is ready."),
      1 => intercomText(context, "1 kiosk is ready."),
      _ => l10n(context).intercomManyReady('$count'),
    };
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (_, event) {
        _rosterKeysDriving.value = true;
        return KeyEventResult.ignored;
      },
      child: FocusScope(
        node: _scope,
        child: Listener(
          onPointerDown: (_) => _rosterKeysDriving.value = false,
          child: GestureDetector(
            // The ground only shields the dashboard underneath: a tap on it
            // does nothing. The screen closes with the X, back or a back
            // swipe, never by a stray touch.
            behavior: HitTestBehavior.opaque,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: ksGroundGradient(scheme.surface, theme.brightness),
              ),
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final compact = width < 600;
                    final stackedHeader =
                        width < 800 ||
                        MediaQuery.textScalerOf(context).scale(16) > 20;
                    // Two columns only where a name still has room: a phone
                    // on its side keeps one column and scrolls.
                    final twoColumns = width >= 960;
                    final inset = math.max(
                      compact ? 20.0 : 40.0,
                      (width - 1120) / 2,
                    );
                    final announce = count == 0
                        ? null
                        : _AnnouncePill(
                            focusNode: _first,
                            onTap: () => _pick('intercomBroadcast', const {}),
                          );
                    final title = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          intercomText(context, "Call a kiosk"),
                          style: TextStyle(
                            fontSize: compact ? 28 : 36,
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          line,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    );
                    final rows = <Widget>[];
                    for (
                      var i = 0;
                      i < kiosks.length;
                      i += twoColumns ? 2 : 1
                    ) {
                      Widget row(int j) => j < kiosks.length
                          ? _KioskRow(
                              key: ValueKey('kiosk-${kiosks[j]['id']}'),
                              kiosk: kiosks[j],
                              compact: compact,
                              focusNode: announce == null && j == 0
                                  ? _first
                                  : null,
                              onCall: () => _pick('intercomCall', {
                                'id': '${kiosks[j]['id']}',
                              }),
                              onVideoCall:
                                  kiosks[j]['video'] == true &&
                                      c.intercom.cameraReady
                                  ? () => _pick('intercomVideoCall', {
                                      'id': '${kiosks[j]['id']}',
                                    })
                                  : null,
                            )
                          : const SizedBox.shrink();
                      if (rows.isNotEmpty) {
                        rows.add(const SizedBox(height: 12));
                      }
                      rows.add(
                        twoColumns
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: row(i)),
                                  const SizedBox(width: 16),
                                  Expanded(child: row(i + 1)),
                                ],
                              )
                            : row(i),
                      );
                    }
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              inset,
                              compact ? 24 : 32,
                              inset,
                              40,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // The mark and the screen's name lead the
                                // list and scroll with it, the way a page
                                // title does; only the close disc stays put.
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: compact ? 20 : 28,
                                  ),
                                  child: KsEyebrow(
                                    label: intercomText(context, "Intercom"),
                                    compact: compact,
                                  ),
                                ),
                                if (stackedHeader) ...[
                                  title,
                                  if (announce != null) ...[
                                    const SizedBox(height: 20),
                                    Align(
                                      alignment:
                                          AlignmentDirectional.centerStart,
                                      child: announce,
                                    ),
                                  ],
                                ] else
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(child: title),
                                      if (announce != null) ...[
                                        const SizedBox(width: 32),
                                        announce,
                                      ],
                                    ],
                                  ),
                                SizedBox(height: compact ? 24 : 32),
                                ...rows,
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: l10n(context).commonClose,
                            iconSize: 28,
                            color: scheme.onSurfaceVariant,
                            onPressed: _close,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Announce to all: the one filled pill on the roster, the megaphone and
/// the label.
class _AnnouncePill extends StatefulWidget {
  const _AnnouncePill({required this.focusNode, required this.onTap});

  final FocusNode focusNode;
  final VoidCallback onTap;

  @override
  State<_AnnouncePill> createState() => _AnnouncePillState();
}

class _AnnouncePillState extends State<_AnnouncePill> {
  bool _focused = false;

  void _onKeys() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _rosterKeysDriving.addListener(_onKeys);
  }

  @override
  void dispose() {
    _rosterKeysDriving.removeListener(_onKeys);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ring = _focused && _rosterKeysDriving.value;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      constraints: const BoxConstraints(minHeight: 52),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: ring ? scheme.onSurface : Colors.transparent,
          width: 3,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(100),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          focusNode: widget.focusNode,
          onFocusChange: (f) => setState(() => _focused = f),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.campaign_outlined,
                  size: 24,
                  color: scheme.onPrimary,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    intercomText(context, "Announce to all"),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One kiosk on the roster: its name and status, and a button for each way
/// to call it. Unavailable kiosks keep their names and reasons legible
/// without looking actionable.
class _KioskRow extends StatelessWidget {
  const _KioskRow({
    super.key,
    required this.kiosk,
    required this.compact,
    required this.focusNode,
    required this.onCall,
    required this.onVideoCall,
  });

  final Map<String, Object?> kiosk;
  final bool compact;
  final FocusNode? focusNode;
  final VoidCallback onCall;

  /// Null where a video call is not possible.
  final VoidCallback? onVideoCall;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ready = kiosk['status'] == 'ready';
    final okColor = theme.brightness == Brightness.dark
        ? ksSage
        : ksSageOnLight;
    return Material(
      color: ready
          ? scheme.surfaceContainerLow
          : scheme.surfaceContainerLow.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Ks.radiusCard),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: compact ? 88 : 96),
        child: Padding(
          padding: EdgeInsets.all(compact ? 16 : 20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${kiosk['name']}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 18 : 20,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                        color: ready
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: ready ? okColor : scheme.outline,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            intercomText(context, '${kiosk['statusText']}'),
                            style: TextStyle(
                              fontSize: compact ? 16 : 18,
                              height: 1.3,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (ready) ...[
                const SizedBox(width: 12),
                _RosterButton(
                  icon: Icons.call,
                  label: intercomText(context, "Voice call"),
                  focusNode: focusNode,
                  onTap: onCall,
                ),
                if (onVideoCall != null) ...[
                  const SizedBox(width: 8),
                  _RosterButton(
                    icon: Icons.videocam,
                    label: intercomText(context, "Video call"),
                    onTap: onVideoCall!,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A 56 px square button on a roster row, outlined while a remote drives.
class _RosterButton extends StatefulWidget {
  const _RosterButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.focusNode,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final FocusNode? focusNode;

  @override
  State<_RosterButton> createState() => _RosterButtonState();
}

class _RosterButtonState extends State<_RosterButton> {
  bool _focused = false;

  void _onKeys() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _rosterKeysDriving.addListener(_onKeys);
  }

  @override
  void dispose() {
    _rosterKeysDriving.removeListener(_onKeys);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final highlight = _focused && _rosterKeysDriving.value;
    final radius = BorderRadius.circular(Ks.radiusRow);
    return Semantics(
      button: true,
      label: widget.label,
      child: Material(
        color: scheme.primaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: highlight
              ? BorderSide(color: scheme.primary, width: 2)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          focusNode: widget.focusNode,
          onFocusChange: (f) => setState(() => _focused = f),
          borderRadius: radius,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(
              widget.icon,
              size: 28,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

/// The call screen over the kiosk screen, full screen on the launcher's
/// ground: calling, ringing (with the auto answer countdown), in a call
/// with push to talk or hands free, a broadcast going out or coming in,
/// and the ended screen. Nothing for idle and missed, which is a toast
/// with Call back instead. Sits in the outer Stack after the
/// notifications and under the Lockdown shield.
class IntercomCallOverlay extends StatefulWidget {
  const IntercomCallOverlay({super.key, required this.container});

  final AppContainer container;

  @override
  State<IntercomCallOverlay> createState() => _IntercomCallOverlayState();
}

class _IntercomCallOverlayState extends State<IntercomCallOverlay> {
  late Map<String, Object?> _status = widget.container.intercom.status();
  StreamSubscription<IntercomStateChanged>? _stateSub;
  StreamSubscription<IntercomLevel>? _levelSub;
  Timer? _tick;
  Timer? _levelDecay;
  double _near = 0;
  double _far = 0;
  bool _held = false;

  /// Whether the details over the video show. They come up for
  /// [_detailsFor] on a tap or a key press and as the call connects. Over
  /// a picture the controls come and go with them.
  bool _details = true;
  Timer? _detailsTimer;
  static const _detailsFor = Duration(seconds: 3);

  AppContainer get c => widget.container;
  String get _state => '${_status['state']}';
  Map<String, Object?> get _call =>
      (_status['call'] as Map?)?.cast<String, Object?>() ?? const {};
  Map<String, Object?> get _peer =>
      (_call['peer'] as Map?)?.cast<String, Object?>() ?? const {};

  Map<String, Object?> get _video =>
      (_call['video'] as Map?)?.cast<String, Object?>() ?? const {};

  static const _shown = IntercomManager.callScreenStates;

  /// The picture takes the whole screen, with the controls over it: the
  /// other kiosk's, or this one's while the call is being placed.
  bool get _overVideo {
    final video = _video;
    return (_state == 'ringing' || _state == 'in_call') &&
            video['farTexture'] != null &&
            video['farShown'] == true ||
        _state == 'calling' && video['selfTexture'] != null;
  }

  void _showDetails() {
    _detailsTimer?.cancel();
    _detailsTimer = Timer(_detailsFor, () {
      if (mounted) setState(() => _details = false);
    });
    if (!_details && mounted) setState(() => _details = true);
  }

  bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent && _shown.contains(_state)) _showDetails();
    return false;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _stateSub = c.bus.on<IntercomStateChanged>().listen(_onState);
    _levelSub = c.bus.on<IntercomLevel>().listen((e) {
      // Nothing over a picture shows the levels, and each one would
      // rebuild the screen a dozen times a second.
      if (!mounted || _video['farShown'] == true) return;
      setState(() {
        _near = e.near;
        _far = e.far;
      });
      // Levels only arrive while audio flows: silence must fall back to
      // rest on its own.
      _levelDecay?.cancel();
      _levelDecay = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _near = 0;
            _far = 0;
          });
        }
      });
    });
    _syncTick();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _stateSub?.cancel();
    _levelSub?.cancel();
    _tick?.cancel();
    _levelDecay?.cancel();
    _detailsTimer?.cancel();
    super.dispose();
  }

  void _onState(IntercomStateChanged e) {
    if (!mounted) return;
    final was = _state;
    final wasPeer = _peer;
    final wasShown = _video['farShown'] == true;
    setState(() => _status = e.status);
    if (_state != 'in_call' && _state != 'broadcasting') _held = false;
    if (_state == 'in_call' &&
        (was != 'in_call' || (!wasShown && _video['farShown'] == true))) {
      _showDetails();
    }
    if (_state == 'missed' && was == 'ringing') _missedToast(wasPeer);
    _syncTick();
  }

  /// A one second tick for the timer and the countdown, only while the
  /// card is up.
  void _syncTick() {
    final live = _shown.contains(_state);
    if (live && _tick == null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!live) {
      _tick?.cancel();
      _tick = null;
    }
  }

  void _missedToast(Map<String, Object?> peer) {
    final id = '${peer['id'] ?? ''}';
    final overlay = Overlay.of(context, rootOverlay: true);
    showToastIn(
      overlay,
      source: 'intercom',
      title: l10n(context).intercomMissedFrom('${peer['name']}'),
      message: l10n(
        context,
      ).intercomRangFor(c.settings.get(defs.intercomRingSeconds)),
      duration: const Duration(seconds: 8),
      actionLabel: id.isEmpty ? null : intercomText(context, "Call back"),
      onAction: id.isEmpty ? null : () => _run('intercomCall', {'id': id}),
    );
  }

  Future<void> _run(
    String command, [
    Map<String, Object?> params = const {},
  ]) async {
    final r = await c.commands.execute(command, params);
    if (r.ok || !mounted) return;
    showToast(
      context,
      source: 'intercom',
      title: intercomText(context, "Intercom"),
      message: r.error == null
          ? null
          : intercomError(context, r.error!, status: c.intercom.status()),
      kind: ToastKind.error,
    );
  }

  void _talk(bool on) {
    if (_held == on) return;
    setState(() => _held = on);
    if (!on) _showDetails();
    unawaited(c.commands.execute('intercomTalk', {'on': on}));
  }

  static String _mmss(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }

  int _elapsed() {
    final since = _call['since'];
    if (since is! num) return -1;
    return DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(since.toInt()))
        .inSeconds;
  }

  String _reasonText(String reason) => switch (reason) {
    'declined' => intercomText(context, "Declined"),
    'busy' => intercomText(context, "Busy"),
    'dnd' => intercomText(context, "Do not disturb"),
    'off' => intercomText(context, "Its intercom is off"),
    'key' => intercomText(context, "Different intercom key"),
    'tls' => intercomText(
      context,
      'Encryption mismatch. Enable Encrypt communications on all kiosks in the call.',
    ),
    'no_answer' => intercomText(context, "No answer"),
    'unreachable' => intercomText(context, "Did not answer"),
    'failed' => intercomText(context, "The voice link failed"),
    'cancelled' => intercomText(context, "Cancelled"),
    'mic_busy' => intercomText(context, "The page took the microphone"),
    'no_targets' => intercomText(context, "Nobody could take it"),
    'broadcast_over' => intercomText(context, "Done"),
    'time_limit' => intercomText(context, "Maximum call duration reached"),
    _ => intercomText(context, "Call ended"),
  };

  @override
  Widget build(BuildContext context) {
    final state = _state;
    if (!_shown.contains(state)) return const SizedBox.shrink();
    // An announcement from Home Assistant has a card of its own.
    if (_call['automated'] == true && _call['outgoing'] != true) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return SizedBox.expand(
      child: DecoratedBox(
        // Black in either theme around a picture, safe area included.
        decoration: _overVideo
            ? const BoxDecoration(color: Colors.black)
            : BoxDecoration(
                gradient: ksGroundGradient(
                  theme.colorScheme.surface,
                  theme.brightness,
                ),
              ),
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _showDetails(),
          child: SafeArea(child: LayoutBuilder(builder: _screen)),
        ),
      ),
    );
  }

  /// The whole screen: the mark and the talk mode top left, then one
  /// centered column on one rhythm: the name block, the meter, the
  /// controls and, with push to talk, End or Done under the pill. A phone
  /// or a short landscape gets the compact sizes so the column still fits
  /// without a scroll; the scroll view is the fallback for a translation
  /// or a name that runs long.
  Widget _screen(BuildContext context, BoxConstraints constraints) {
    final scheme = Theme.of(context).colorScheme;
    final state = _state;
    final call = _call;
    final kind = '${call['kind'] ?? 'call'}';
    final outgoing = call['outgoing'] == true;
    final broadcast = kind == 'broadcast';
    final peerName = '${_peer['name'] ?? ''}';
    final talkMode = '${_status['talkMode'] ?? 'ptt'}';
    final reason = '${call['reason'] ?? ''}';
    final automated = call['automated'] == true;
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final compact = height < 480 || width < 600;
    final video = _video;
    final selfTexture = video['selfTexture'] as int?;
    final farTexture = video['farTexture'] as int?;
    final overVideo = _overVideo;
    final canCamera =
        kind == 'call' &&
        state == 'in_call' &&
        video['peer'] == true &&
        _status['cameraReady'] == true;
    // It shows with the kiosk's name, so it never takes room from the
    // controls.
    final canSwitch =
        kind == 'call' &&
        (state == 'calling' || state == 'in_call') &&
        video['camera'] == true &&
        _status['canSwitchCamera'] == true;
    // A short landscape (a phone on its side) has no room for a disc
    // under the pill: End sits beside it there, under it everywhere else.
    final short = height < 480;

    // The name and the line under it.
    var name = peerName;
    String? sub;
    if (broadcast && outgoing && state == 'ended') {
      name = intercomText(context, "Announcement");
    } else if (broadcast && outgoing) {
      final listening = [
        for (final t in (call['targets'] as List? ?? const []))
          if (t is Map && t['status'] == 'listening') '${t['name']}',
      ];
      name = listening.isEmpty
          ? intercomText(context, "Announcement")
          : intercomAnnouncing(context, listening.length);
      sub = listening.join(', ');
    } else if (state == 'ringing') {
      sub = intercomText(context, "is calling");
    } else if (state == 'listening') {
      sub = intercomText(context, "is announcing");
    }

    // This kiosk is on camera and the other is not: say so where the
    // picture would be.
    if (state == 'in_call' &&
        video['camera'] == true &&
        video['farCamera'] != true) {
      sub = intercomText(context, "Camera off");
    }

    // The state line: the timer, or who hears you while the talk button
    // is held.
    String stateLine;
    var stateColor = scheme.onSurfaceVariant;
    switch (state) {
      case 'calling':
        stateLine = intercomText(context, "Calling…");
      case 'ringing':
        final auto = call['autoAnswerAt'];
        if (auto is num) {
          final left = (auto.toInt() - DateTime.now().millisecondsSinceEpoch);
          final seconds = '${math.max(0, (left / 1000).ceil())}';
          final withCamera =
              _status['autoAnswerCamera'] == true &&
              _status['cameraReady'] == true &&
              video['farCamera'] == true;
          stateLine = withCamera
              ? l10n(context).intercomAnswersWithCameraIn(seconds)
              : l10n(context).intercomAnswersIn(seconds);
        } else {
          stateLine = intercomText(context, "Ringing");
        }
      case 'in_call' || 'broadcasting':
        if (_held) {
          stateLine = state == 'broadcasting'
              ? l10n(context).intercomAllHearYou
              : l10n(context).intercomHearsYou(peerName);
          stateColor = scheme.primary;
        } else {
          final elapsed = _elapsed();
          stateLine = elapsed < 0
              ? intercomText(context, "Connecting…")
              : _mmss(elapsed);
          if (elapsed >= 0) stateColor = scheme.onSurface;
        }
      case 'listening':
        stateLine = '';
      case 'ended':
        final duration = (call['duration'] as num?)?.toInt() ?? 0;
        stateLine = reason == 'ended' || reason.isEmpty
            ? broadcast && outgoing
                  ? l10n(context).intercomDoneDuration(_mmss(duration))
                  : l10n(context).intercomEndedDuration(_mmss(duration))
            : _reasonText(reason);
      default:
        stateLine = '';
    }

    // Whether this kiosk's own voice is what the meter should show.
    final sending = switch (state) {
      'in_call' ||
      'broadcasting' => talkMode == 'handsfree' ? call['muted'] != true : _held,
      _ => false,
    };
    final live =
        state == 'in_call' || state == 'broadcasting' || state == 'listening';
    final level = !live ? 0.0 : (sending ? _near : _far);

    final micBusy = _status['micBusy'] == true;
    final micDenied =
        (_status['micGranted'] == false || micBusy) &&
        (state == 'in_call' || state == 'broadcasting');

    // The controls row and, for push to talk, the disc under the pill.
    final pillWidth = math.min(
      compact ? 360.0 : 480.0,
      short || (overVideo && width >= 640)
          ? width - 48 - (canCamera ? 2 : 1) * ((compact ? 88 : 128) + 28)
          : width - 48,
    );
    final controls = <Widget>[];
    final below = <Widget>[];
    _Disc disc(IconData icon, String label, _DiscKind kind, String command) =>
        _Disc(
          icon: icon,
          label: label,
          kind: kind,
          compact: compact,
          overVideo: overVideo,
          onTap: () => _run(command),
        );
    Widget cameraDisc() {
      final on = video['camera'] == true;
      return _Disc(
        icon: on ? Icons.videocam : Icons.videocam_off,
        label: on
            ? intercomText(context, "Camera")
            : intercomText(context, "Camera off"),
        kind: on ? _DiscKind.plain : _DiscKind.dark,
        compact: compact,
        overVideo: overVideo,
        onTap: () => _run('intercomCamera', {'on': !on}),
      );
    }

    switch (state) {
      case 'calling':
        if (selfTexture != null) controls.add(cameraDisc());
        controls.add(
          disc(
            Icons.call_end,
            intercomText(context, "Cancel"),
            _DiscKind.end,
            'intercomHangup',
          ),
        );
      case 'ringing':
        controls.add(
          disc(
            Icons.call_end,
            intercomText(context, "Decline"),
            _DiscKind.end,
            'intercomDecline',
          ),
        );
        if (video['farCamera'] == true && _status['cameraReady'] == true) {
          controls.addAll([
            disc(
              Icons.call,
              intercomText(context, "Voice only"),
              _DiscKind.plain,
              'intercomAnswer',
            ),
            _Disc(
              icon: Icons.videocam,
              label: intercomText(context, "Video"),
              kind: _DiscKind.primary,
              compact: compact,
              overVideo: overVideo,
              onTap: () => _run('intercomAnswer', {'video': true}),
            ),
          ]);
        } else {
          controls.add(
            disc(
              Icons.call,
              intercomText(context, "Answer"),
              _DiscKind.primary,
              'intercomAnswer',
            ),
          );
        }
      case 'in_call' || 'broadcasting':
        final end = state == 'broadcasting'
            ? disc(
                Icons.close,
                intercomText(context, "Done"),
                _DiscKind.plain,
                'intercomHangup',
              )
            : disc(
                Icons.call_end,
                intercomText(context, "End"),
                _DiscKind.end,
                'intercomHangup',
              );
        if (automated) {
          // A clip from Home Assistant plays: nothing to hold or mute.
          controls.add(
            disc(
              Icons.stop,
              intercomText(context, "Stop"),
              _DiscKind.plain,
              'intercomHangup',
            ),
          );
        } else if (talkMode == 'ptt') {
          final pill = _TalkPill(
            held: _held,
            width: pillWidth,
            compact: compact,
            onDown: () => _talk(true),
            onUp: () => _talk(false),
          );
          // Over video the pill shares a row with the discs wherever they
          // fit, so the controls cover as little of the picture as they can.
          final oneRow = short || (overVideo && width >= 640);
          if (oneRow) {
            controls.add(
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (canCamera) ...[cameraDisc(), const SizedBox(width: 28)],
                  // The pill centers on the disc itself, not on the disc
                  // plus its label, so the two read as one row.
                  Padding(
                    padding: EdgeInsets.only(bottom: compact ? 24 : 28),
                    child: pill,
                  ),
                  const SizedBox(width: 28),
                  end,
                ],
              ),
            );
          } else {
            controls.add(pill);
            if (canCamera) below.add(cameraDisc());
            below.add(end);
          }
        } else {
          final muted = call['muted'] == true;
          controls.addAll([
            _Disc(
              icon: muted ? Icons.mic_off : Icons.mic,
              label: muted
                  ? intercomText(context, "Muted")
                  : intercomText(context, "Mute"),
              kind: muted ? _DiscKind.dark : _DiscKind.plain,
              compact: compact,
              overVideo: overVideo,
              onTap: () => _run('intercomMute', {'on': !muted}),
            ),
            if (canCamera) cameraDisc(),
            end,
          ]);
        }
      case 'listening':
        controls.addAll([
          _Disc(
            icon: Icons.call,
            label: intercomText(context, "Reply"),
            kind: _DiscKind.primary,
            compact: compact,
            onTap: () => _run('intercomCall', {'id': '${_peer['id']}'}),
          ),
          disc(
            Icons.close,
            intercomText(context, "Dismiss"),
            _DiscKind.plain,
            'intercomHangup',
          ),
        ]);
      case 'ended':
        // A broadcast has no one kiosk to call again.
        if (reason != 'broadcast_over' && !(broadcast && outgoing)) {
          controls.add(
            _Disc(
              icon: Icons.call,
              label: intercomText(context, "Call again"),
              kind: _DiscKind.primary,
              compact: compact,
              onTap: () => _run(
                video['hadCamera'] == true && _status['cameraReady'] == true
                    ? 'intercomVideoCall'
                    : 'intercomCall',
                {'id': '${_peer['id']}'},
              ),
            ),
          );
        }
        controls.add(
          disc(
            Icons.close,
            intercomText(context, "Close"),
            _DiscKind.plain,
            'intercomDismiss',
          ),
        );
    }

    // A short landscape with room across (a phone on its side) keeps the
    // full rhythm and a mid-size name; only a tiny screen packs tight.
    final roomy = width >= 600;
    final gap = compact ? (roomy ? 36.0 : 16.0) : 40.0;
    final nameSize = compact
        ? (roomy ? 40.0 : 30.0)
        : (width < 900 ? 48.0 : 64.0);
    final meterScale = compact ? (roomy ? 1.2 : 0.9) : 1.8;
    // The name block and the meter scroll when a name or a translation
    // runs long; the controls never do, so End stays under a thumb
    // whatever the screen (and a scroll view ignores taps under it while
    // the talk button is held, which the controls must not).
    final details = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (broadcast) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.campaign_outlined,
                size: compact ? 16 : 18,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  intercomText(context, "Announcement").toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: compact ? 12.5 : 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .8,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 16),
        ],
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: nameSize,
            fontWeight: FontWeight.w600,
            height: 1.1,
            letterSpacing: -0.5,
            color: scheme.onSurface,
          ),
        ),
        if (sub != null && sub.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            sub,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 16 : 22,
              height: 1.3,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        if (stateLine.isNotEmpty) ...[
          SizedBox(height: compact ? 8 : 12),
          Text(
            stateLine,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 17 : 24,
              fontWeight: FontWeight.w500,
              height: 1.3,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: stateColor,
            ),
          ),
        ],
        if (canSwitch) ...[
          SizedBox(height: compact ? 12 : 16),
          _SwitchCameraPill(
            compact: compact,
            overVideo: false,
            onTap: () => _run('intercomSwitchCamera'),
          ),
        ],
        SizedBox(height: gap),
        _Meter(level: level, live: live, scale: meterScale),
        if (micDenied) ...[
          const SizedBox(height: 12),
          Text(
            micBusy
                ? intercomText(
                    context,
                    "The dashboard holds the microphone, listening only.",
                  )
                : intercomText(
                    context,
                    "Microphone not granted, listening only.",
                  ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 13 : 15,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );

    final selfTile = selfTexture != null || (overVideo && canCamera)
        ? Positioned(
            top: compact ? 12 : 24,
            right: compact ? 12 : 28,
            child: _SelfTile(
              texture: selfTexture,
              videoWidth: (video['selfWidth'] as int?) ?? 0,
              videoHeight: (video['selfHeight'] as int?) ?? 0,
              portrait: height > width,
              compact: compact,
              roomy: width >= 1000,
            ),
          )
        : null;
    if (overVideo) {
      final overlay = state == 'calling' || state == 'ringing'
          ? true
          : _held || _details;
      return _videoStage(
        far: state != 'calling',
        texture: state == 'calling' ? selfTexture! : farTexture!,
        compact: compact,
        size: Size(width, height),
        eyebrow: KsEyebrow(
          label: intercomText(context, "Intercom"),
          // A phone has no room for it beside the self view.
          trail: width < 600
              ? null
              : talkMode == 'handsfree'
              ? intercomText(context, "Hands free")
              : intercomText(context, "Push to talk"),
          compact: compact,
          color: Colors.white,
        ),
        name: name,
        sub: sub,
        stateLine: stateLine,
        overlay: overlay,
        switchCamera: canSwitch
            ? _SwitchCameraPill(
                compact: compact,
                overVideo: true,
                onTap: () => _run('intercomSwitchCamera'),
              )
            : null,
        selfTile: state == 'calling' ? null : selfTile,
        controls: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: compact ? 28 : 56,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: controls,
            ),
            if (below.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: compact ? 28 : 56,
                alignment: WrapAlignment.center,
                children: below,
              ),
            ],
          ],
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            // The column centers in the band under the eyebrow, not in
            // the whole screen, so the name never crowds the mark while
            // the bottom margin sits empty.
            padding: EdgeInsets.fromLTRB(
              24,
              compact ? 64 : 96,
              24,
              compact ? 20 : 64,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      child: Padding(
                        // A long name wraps instead of running under the
                        // self view.
                        padding: EdgeInsets.symmetric(
                          horizontal: selfTexture != null && width > height
                              ? (compact ? 180 : 220)
                              : 0,
                        ),
                        child: details,
                      ),
                    ),
                  ),
                  SizedBox(height: gap),
                  Wrap(
                    spacing: compact ? 28 : 56,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.start,
                    children: controls,
                  ),
                  if (below.isNotEmpty) ...[
                    SizedBox(height: compact ? 16 : 28),
                    Wrap(
                      spacing: compact ? 28 : 56,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: below,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: compact ? 12 : 20,
          left: compact ? 16 : 28,
          child: KsEyebrow(
            label: intercomText(context, "Intercom"),
            trail: automated
                ? null
                : talkMode == 'handsfree'
                ? intercomText(context, "Hands free")
                : intercomText(context, "Push to talk"),
            compact: compact,
          ),
        ),
        ?selfTile,
      ],
    );
  }

  /// A call with a picture: the video fills the screen and everything else
  /// floats over it. The gradients are fixed, so nothing here blurs or
  /// repaints the frame.
  Widget _videoStage({
    required bool far,
    required int texture,
    required bool compact,
    required Size size,
    required Widget eyebrow,
    required String name,
    required String? sub,
    required String stateLine,
    required bool overlay,
    required Widget? switchCamera,
    required Widget? selfTile,
    required Widget controls,
  }) {
    final video = _video;
    final w = (video[far ? 'farWidth' : 'selfWidth'] as int?) ?? 0;
    final h = (video[far ? 'farHeight' : 'selfHeight'] as int?) ?? 0;
    // A portrait picture on a landscape screen would lose most of itself
    // to a crop.
    final fit = far && h > w && size.width > size.height
        ? BoxFit.contain
        : BoxFit.cover;
    final stalled = far && video['farStalled'] == true;
    const shade = Color(0xA8000000);
    const fade = Duration(milliseconds: 200);
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: Colors.black,
          child: _VideoFrame(texture: texture, width: w, height: h, fit: fit),
        ),
        if (stalled) const ColoredBox(color: Color(0x8C000000)),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: compact ? 170 : 300,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: overlay ? 1 : 0,
              duration: fade,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [shade, Color(0x00000000)],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: IgnorePointer(
            ignoring: !overlay,
            child: AnimatedOpacity(
              opacity: overlay ? 1 : 0,
              duration: fade,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [shade, Color(0x00000000)],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 16 : 28,
                    compact ? 12 : 20,
                    compact ? 120 : 300,
                    compact ? 40 : 72,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      eyebrow,
                      SizedBox(height: compact ? 10 : 16),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? 30 : 40,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                          letterSpacing: -0.5,
                          color: Colors.white,
                        ),
                      ),
                      if (sub != null && sub.isNotEmpty)
                        Text(
                          sub,
                          style: TextStyle(
                            fontSize: compact ? 16 : 22,
                            height: 1.3,
                            color: Colors.white,
                          ),
                        ),
                      if (stateLine.isNotEmpty)
                        Text(
                          stateLine,
                          style: TextStyle(
                            fontSize: compact ? 17 : 24,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: Colors.white,
                          ),
                        ),
                      if (switchCamera != null) ...[
                        SizedBox(height: compact ? 10 : 16),
                        switchCamera,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (stalled)
          Align(
            alignment: const Alignment(0, -0.2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xDB202124),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.videocam_off,
                    size: 24,
                    color: Color(0xFFE8EAED),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      intercomText(context, "Video reconnecting…"),
                      style: TextStyle(
                        fontSize: compact ? 16 : 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ?selfTile,
        Positioned(
          left: 24,
          right: 24,
          bottom: compact ? 14 : 32,
          // Hidden, a tap or a key press only brings them back: nothing
          // here should end a call nobody can see the button for.
          child: ExcludeFocus(
            excluding: !overlay,
            child: IgnorePointer(
              ignoring: !overlay,
              child: AnimatedOpacity(
                opacity: overlay ? 1 : 0,
                duration: fade,
                child: Center(child: controls),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A native video texture, scaled to fill its box.
class _VideoFrame extends StatelessWidget {
  const _VideoFrame({
    required this.texture,
    required this.width,
    required this.height,
    required this.fit,
  });

  final int texture;
  final int width;
  final int height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: FittedBox(
        fit: fit,
        child: SizedBox(
          width: width > 0 ? width.toDouble() : 640,
          height: height > 0 ? height.toDouble() : 480,
          child: Texture(textureId: texture, filterQuality: FilterQuality.low),
        ),
      ),
    );
  }
}

/// This kiosk's own picture in the corner of a call, or a tile saying the
/// camera is off. While the camera sends this stays on screen.
class _SelfTile extends StatelessWidget {
  const _SelfTile({
    required this.texture,
    required this.videoWidth,
    required this.videoHeight,
    required this.portrait,
    required this.compact,
    required this.roomy,
  });

  final int? texture;

  /// The picture's own size: a phone held upright sends a tall one.
  final int videoWidth;
  final int videoHeight;
  final bool portrait;
  final bool compact;
  final bool roomy;

  @override
  Widget build(BuildContext context) {
    final size = portrait
        ? const Size(96, 128)
        : compact
        ? const Size(160, 100)
        : roomy
        ? const Size(256, 160)
        : const Size(192, 120);
    final id = texture;
    return IgnorePointer(
      child: Container(
        width: size.width,
        height: size.height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF303136),
          borderRadius: BorderRadius.circular(Ks.radiusRow),
          border: Border.all(color: const Color(0x52FFFFFF)),
        ),
        child: id != null
            ? _VideoFrame(
                texture: id,
                width: videoWidth,
                height: videoHeight,
                fit: BoxFit.cover,
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam_off,
                    size: compact ? 24 : 32,
                    color: const Color(0xFFB6BABF),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      intercomText(context, "Your camera is off"),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: compact ? 13 : 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFE8EAED),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Twelve level bars. At rest every bar is one short stub in the outline
/// color. Live they take the text color and rise with the voice toward
/// their own heights, the logo's four bars in the middle and shorter ones
/// out to the sides, each a little differently so the row reads as sound
/// rather than a gauge.
class _Meter extends StatelessWidget {
  const _Meter({required this.level, required this.live, required this.scale});

  final double level;
  final bool live;

  /// Pixels per logo unit: 1.8 on a tablet (the tallest bar 77 px), less
  /// on a phone.
  final double scale;

  /// Full heights in the logo's units: its house bars are 26.6, 22, 42.6
  /// and 22.6 tall on an 8.6 wide bar with a 4 gap.
  static const _shape = [
    14.0,
    22.0,
    17.0,
    25.0,
    26.6,
    22.0,
    42.6,
    22.6,
    28.0,
    16.0,
    23.0,
    14.0,
  ];
  static const _rest = 8.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final on = live && level > 0.02;
    final k = scale;
    final w = 8.6 * k;
    final rise = math.min(1.0, level * 1.6);
    return SizedBox(
      height: 42.6 * k,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < _shape.length; i++) ...[
            if (i > 0) SizedBox(width: 4 * k),
            AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              width: w,
              height: (on ? _rest + (_shape[i] - _rest) * rise : _rest) * k,
              decoration: BoxDecoration(
                color: on ? scheme.onSurface : scheme.outline,
                borderRadius: BorderRadius.circular(w / 2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _DiscKind { plain, primary, end, dark }

/// A round call button with its label beneath: 96 on the tablet, 64 on
/// a phone or a short landscape.
class _Disc extends StatelessWidget {
  const _Disc({
    required this.icon,
    required this.label,
    required this.kind,
    required this.compact,
    required this.onTap,
    this.overVideo = false,
  });

  final IconData icon;
  final String label;
  final _DiscKind kind;
  final bool compact;
  final VoidCallback onTap;

  /// Over a picture the discs and their labels read on any frame, in
  /// either theme.
  final bool overVideo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (kind) {
      _DiscKind.plain when overVideo => (
        const Color(0xC7202124),
        const Color(0xFFE8EAED),
      ),
      _DiscKind.dark when overVideo => (
        const Color(0xFFE8EAED),
        const Color(0xFF202124),
      ),
      _DiscKind.plain => (scheme.surfaceContainerHighest, scheme.onSurface),
      _DiscKind.primary => (scheme.primary, scheme.onPrimary),
      _DiscKind.end => (scheme.error, scheme.onError),
      _DiscKind.dark => (scheme.onSurface, scheme.surface),
    };
    final d = compact ? 64.0 : 96.0;
    return SizedBox(
      width: compact ? 88 : 128,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: bg,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                width: d,
                height: d,
                child: Icon(icon, size: compact ? 27 : 40, color: fg),
              ),
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 13 : 16,
              fontWeight: FontWeight.w500,
              color: overVideo ? Colors.white : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Moves the call to the other camera. It lives under the kiosk's name
/// and comes and goes with it.
class _SwitchCameraPill extends StatelessWidget {
  const _SwitchCameraPill({
    required this.compact,
    required this.overVideo,
    required this.onTap,
  });

  final bool compact;
  final bool overVideo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = overVideo
        ? const Color(0xC7202124)
        : scheme.surfaceContainerHighest;
    final fg = overVideo ? const Color(0xFFE8EAED) : scheme.onSurface;
    return Material(
      color: bg,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 24,
            vertical: compact ? 10 : 14,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cameraswitch, size: compact ? 20 : 26, color: fg),
              SizedBox(width: compact ? 8 : 12),
              Flexible(
                child: Text(
                  intercomText(context, "Switch camera"),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 14 : 18,
                    fontWeight: FontWeight.w500,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Push to talk: one wide pill held down for as long as the kiosk should
/// send. Idle, it fills primary. Held, it uses a tinted fill, outline and
/// soft ring. The line under the name says who hears you.
class _TalkPill extends StatelessWidget {
  const _TalkPill({
    required this.held,
    required this.width,
    required this.compact,
    required this.onDown,
    required this.onUp,
  });

  final bool held;
  final double width;
  final bool compact;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = held ? scheme.onPrimaryContainer : scheme.onPrimary;
    return Listener(
      onPointerDown: (_) => onDown(),
      onPointerUp: (_) => onUp(),
      onPointerCancel: (_) => onUp(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: width,
        height: compact ? 60 : 96,
        decoration: BoxDecoration(
          color: held ? scheme.primaryContainer : scheme.primary,
          borderRadius: BorderRadius.circular(999),
          border: held ? Border.all(color: scheme.primary) : null,
          boxShadow: held
              ? [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.28),
                    spreadRadius: compact ? 6 : 10,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic, size: compact ? 26 : 32, color: fg),
            SizedBox(width: compact ? 12 : 16),
            Flexible(
              child: Text(
                intercomText(context, "Hold to talk"),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 18 : 22,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The card an announcement from Home Assistant shows while it plays: who
/// it is from, the spoken text large enough to read across the room (or
/// the clip's name when it was a file) and Dismiss. Its own overlay,
/// apart from the intercom's call card: no meter, no one to call back.
class AnnouncementOverlay extends StatefulWidget {
  const AnnouncementOverlay({super.key, required this.container});

  final AppContainer container;

  @override
  State<AnnouncementOverlay> createState() => _AnnouncementOverlayState();
}

class _AnnouncementOverlayState extends State<AnnouncementOverlay> {
  late Map<String, Object?> _status = widget.container.intercom.status();
  StreamSubscription<IntercomStateChanged>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.container.bus.on<IntercomStateChanged>().listen((e) {
      if (mounted) setState(() => _status = e.status);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = '${_status['state']}';
    final call = (_status['call'] as Map?)?.cast<String, Object?>();
    if (call == null ||
        call['automated'] != true ||
        call['audioOnly'] == true ||
        call['outgoing'] == true ||
        (state != 'listening' && state != 'ended')) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    final message = '${call['message'] ?? ''}'.trim();
    final playing = state == 'listening';
    final tight = MediaQuery.sizeOf(context).width < 480;
    return Stack(
      fit: StackFit.expand,
      children: [
        const ModalBarrier(color: Colors.black54, dismissible: false),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Material(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(Ks.radiusCard),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    tight ? 20 : 32,
                    24,
                    tight ? 20 : 32,
                    20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.campaign_outlined,
                            size: 18,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'HOME ASSISTANT',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: .8,
                              color: scheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        message.isEmpty
                            ? intercomText(context, "Announcement")
                            : message,
                        textAlign: TextAlign.center,
                        maxLines: 8,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: tight ? 22 : 26,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        playing
                            ? intercomText(context, "Playing")
                            : intercomText(context, "Done"),
                        style: TextStyle(
                          fontSize: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _Disc(
                        icon: Icons.close,
                        label: intercomText(context, "Dismiss"),
                        kind: _DiscKind.plain,
                        compact: true,
                        onTap: () => widget.container.commands.execute(
                          playing ? 'intercomHangup' : 'intercomDismiss',
                          const {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
