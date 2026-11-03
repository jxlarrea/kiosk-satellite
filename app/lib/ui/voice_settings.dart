import 'dart:async';

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../core/events.dart';
import '../l10n/messages.dart';
import '../managers/settings/definitions.dart' as defs;
import '../managers/voice/realtime/openai_realtime_backend.dart';
import '../managers/voice/voice_manager.dart';
import 'assist/assist_skins.dart';
import 'kit.dart';
import 'theme.dart';
import 'toast.dart';

/// The notice on the Voice Satellite page while the kiosk still runs the
/// integration's engine in the dashboard, with the way out.
class VoiceMigrationNotice extends StatelessWidget {
  const VoiceMigrationNotice({super.key, required this.container});

  final AppContainer container;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = voiceText(
      context,
      'Voice Satellite is currently installed as an integration in Home '
      'Assistant. Migrate to a native experience inside Kiosk Satellite.',
    );
    final button = FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.onTertiaryContainer,
        foregroundColor: scheme.tertiaryContainer,
      ),
      onPressed: () => showVoiceMigrationWizard(context, container),
      child: Text(voiceText(context, 'Migrate')),
    );
    final body = Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontSize: 13.5,
        height: 1.45,
        color: scheme.onTertiaryContainer,
      ),
    );
    final icon = Icon(
      Icons.warning_amber_rounded,
      size: 20,
      color: scheme.onTertiaryContainer,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: Ks.cardGap),
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: tightPane(context)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: [
                    icon,
                    Expanded(child: body),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: button,
                ),
              ],
            )
          : Row(
              spacing: 12,
              children: [
                icon,
                Expanded(child: body),
                button,
              ],
            ),
    );
  }
}

/// The top of the native Voice Satellite page: whether it runs, what Home
/// Assistant calls it, or what is missing before it can.
class VoiceStatusCard extends StatefulWidget {
  const VoiceStatusCard({
    super.key,
    required this.container,
    required this.rows,
  });

  final AppContainer container;

  /// The setting rows that follow the status in the same card (enable,
  /// mute, background listening).
  final List<Widget> rows;

  @override
  State<VoiceStatusCard> createState() => _VoiceStatusCardState();
}

class _VoiceStatusCardState extends State<VoiceStatusCard> {
  AppContainer get c => widget.container;
  StreamSubscription<Object?>? _wakeSub;
  StreamSubscription<Object?>? _statusSub;

  @override
  void initState() {
    super.initState();
    c.voice.homeAssistant.addListener(_changed);
    _wakeSub = c.bus.on<WakeWordStateChanged>().listen((_) => _changed());
    // A turn starting or ending: the kiosk announces it for the status rows.
    _statusSub = c.bus.on<RemoteStatusChanged>().listen((e) {
      if (e.topic == 'voice-status') _changed();
    });
  }

  @override
  void dispose() {
    c.voice.homeAssistant.removeListener(_changed);
    _wakeSub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final settings = c.settings;
    final scheme = Theme.of(context).colorScheme;
    final enabled = settings.get(defs.voiceEnabled);
    final ha = c.voice.homeAssistant.value;
    final esphome = settings.get(defs.esphomeEnabled);
    final muted = settings.get(defs.voiceMute);
    final listening = c.wakeWord.listening;
    final busy = c.voice.busy;
    // Neither in a turn nor listening: the wake word engine is down.
    final down = !busy && !listening;
    Widget statusWord(String text, Color color) => Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
    final rows = <Widget>[
      ...widget.rows.take(1),
      if (enabled) ...[
        SettingsRow(
          title: Text(voiceText(context, 'Status')),
          subtitle: Text(
            !esphome
                ? voiceText(context, 'The ESPHome server is off.')
                : !ha.subscribed
                ? voiceText(
                    context,
                    'This kiosk is not added to Home Assistant yet.',
                  )
                : muted
                ? voiceText(context, 'The microphone is muted.')
                : down
                ? voiceText(context, 'The wake word is not listening.')
                : voiceText(context, 'Listening for the wake word.'),
          ),
          trailing: statusWord(
            !esphome || !ha.subscribed
                ? voiceText(context, 'Not added')
                : muted
                ? voiceText(context, 'Muted')
                : busy
                ? voiceText(context, 'Busy')
                : listening
                ? voiceText(context, 'Listening')
                : voiceText(context, 'Not listening'),
            !esphome || !ha.subscribed || (!muted && down)
                ? scheme.tertiary
                : muted
                ? scheme.onSurfaceVariant
                : scheme.primary,
          ),
        ),
        SettingsRow(
          title: Text(voiceText(context, 'Home Assistant')),
          subtitle: Text(
            ha.satelliteEntity.isNotEmpty && ha.selectsMissing
                ? voiceText(context, _reloadHint)
                : ha.satelliteEntity.isNotEmpty
                ? ha.satelliteEntity
                : esphome
                ? voiceText(
                    context,
                    'Add this kiosk under Settings, Devices & services in '
                    'Home Assistant, where it shows up as discovered. If Home '
                    'Assistant had it before, it asks there for the new '
                    'Encryption key from the ESPHome page.',
                  )
                : voiceText(
                    context,
                    'Turn on the ESPHome server so Home Assistant can add '
                    'this kiosk as a satellite.',
                  ),
          ),
          trailing: esphome
              ? statusWord(
                  ha.satelliteEntity.isEmpty
                      ? voiceText(context, 'Not added')
                      : ha.selectsMissing
                      ? voiceText(context, 'Reload needed')
                      : voiceText(context, 'Added'),
                  ha.satelliteEntity.isNotEmpty && !ha.selectsMissing
                      ? scheme.primary
                      : scheme.tertiary,
                )
              : FilledButton(
                  onPressed: () async {
                    await settings.set(defs.esphomeEnabled, true);
                    _changed();
                  },
                  child: Text(voiceText(context, 'Turn on')),
                ),
        ),
      ],
      ...widget.rows.skip(1),
    ];
    return SettingsCard(children: rows);
  }
}

/// Home Assistant added the satellite but not its selects, and the kiosk's
/// token could not reload the entry.
const _reloadHint =
    'Home Assistant has not loaded the Assistant and Wake word selects. '
    "Reload this kiosk's ESPHome entry under Settings, Devices & services. "
    'Restarting Home Assistant also works.';

/// One of Home Assistant's selects on the kiosk's device (the Assistant
/// and Wake word pickers), as a dropdown row that writes it live. The
/// Assistant selects also offer the validated realtime provider.
class VoiceHaSelects extends StatefulWidget {
  const VoiceHaSelects({
    super.key,
    required this.container,
    required this.rows,
  });

  final AppContainer container;

  /// (key, title, description) per row, keys as voiceHaSelects answers.
  final List<(String, String, String)> rows;

  @override
  State<VoiceHaSelects> createState() => _VoiceHaSelectsState();
}

class _VoiceHaSelectsState extends State<VoiceHaSelects> {
  Map<String, Object?>? _data;
  Timer? _poll;
  StreamSubscription<RemoteStatusChanged>? _optionsSub;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    // Home Assistant has new choices, a custom model added or deleted.
    _optionsSub = widget.container.bus.on<RemoteStatusChanged>().listen((e) {
      if (e.topic == 'voice-selects' && mounted) unawaited(_load());
    });
    // Home Assistant, a voice command or the remote admin can change them.
    _poll = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && ModalRoute.of(context)?.isCurrent != false) {
        unawaited(_load());
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _optionsSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await widget.container.commands.execute(
      'voiceHaSelects',
      const {},
    );
    if (!mounted) return;
    setState(
      () => _data = result.ok && result.data is Map
          ? (result.data as Map).cast<String, Object?>()
          : const {},
    );
  }

  String _label(String key, String option) {
    if (option == 'preferred') return voiceText(context, 'Preferred');
    if (option == 'no_wake_word') return voiceText(context, 'None');
    if (key == 'vad_sensitivity') return voiceVadOption(context, option);
    return option;
  }

  /// The realtime choice as voiceHaSelects reports it.
  Map<String, Object?> get _realtime =>
      (_data?['realtime'] as Map?)?.cast<String, Object?>() ?? const {};

  Future<void> _set(String key, String option) async {
    final realtime = _realtime;
    final provider = [
      for (final o in (realtime['options'] as List? ?? const []))
        if (o is Map && o['value'] == option) option,
    ].firstOrNull;
    setState(() {
      if (realtime.containsKey(key)) {
        _data = {
          ...?_data,
          'realtime': {...realtime, key: provider},
        };
      }
      if (provider == null) {
        final entity = (_data?[key] as Map?)?.cast<String, Object?>();
        if (entity != null) entity['state'] = option;
      }
    });
    await widget.container.commands.execute('voiceSelectOption', {
      'key': key,
      'option': option,
    });
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (key, title, description) in widget.rows)
          _row(context, key, title, description, data[key]),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    String key,
    String title,
    String description,
    Object? raw,
  ) {
    final entity = raw is Map ? raw.cast<String, Object?>() : null;
    final options = [
      for (final o in (entity?['options'] as List? ?? const [])) '$o',
    ];
    // Another engine's wake words, which Home Assistant learns as it
    // reconnects to the kiosk.
    if (entity != null &&
        _data?['wakeWordsPending'] == true &&
        (key == 'wake_word' || key == 'wake_word_2')) {
      return DropdownRow<String>(
        title: voiceText(context, title),
        description: voiceText(context, description),
        value: null,
        options: [for (final o in options) (o, _label(key, o))],
        onChanged: null,
        loading: true,
      );
    }
    if (entity == null || entity['available'] != true || options.isEmpty) {
      return SettingsRow(
        title: Text(voiceText(context, title)),
        subtitle: Text(voiceText(context, description)),
        trailing: Text(
          voiceText(
            context,
            widget.container.voice.homeAssistant.value.selectsMissing
                ? 'Reload needed'
                : 'Not available',
          ),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    final state = '${entity['state'] ?? ''}';
    // An Assistant select also offers every realtime provider whose
    // connection is validated.
    final realtime = _realtime;
    final offers = realtime.containsKey(key)
        ? [
            for (final o in (realtime['options'] as List? ?? const []))
              if (o is Map) ('${o['value']}', '${o['provider']}'),
          ]
        : const <(String, String)>[];
    final picked = realtime[key];
    final current = picked is String && offers.any((o) => o.$1 == picked)
        ? picked
        : state;
    return DropdownRow<String>(
      title: voiceText(context, title),
      description: voiceText(context, description),
      value: options.contains(current) || offers.any((o) => o.$1 == current)
          ? current
          : null,
      options: [
        for (final o in options) (o, _label(key, o)),
        for (final (value, provider) in offers)
          (value, l10n(context).voiceRealtimeOption(provider)),
      ],
      onChanged: (v) {
        if (v != null && v != current) unawaited(_set(key, v));
      },
    );
  }
}

/// A realtime provider's row in the Providers group: its status under its
/// name and Configure, which opens its settings. Mirrored on the remote
/// (realtimeProviderRow in vs_native.js).
class RealtimeProviderRow extends StatelessWidget {
  const RealtimeProviderRow({
    super.key,
    required this.container,
    required this.provider,
    required this.onChanged,
  });

  final AppContainer container;
  final RealtimeProvider provider;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: container.voice.realtimeStatusRevision,
    builder: (context, _, _) {
      final status = container.voice.realtimeStatus(provider);
      final messages = l10n(context);
      return SettingsRow(
        title: Text(VoiceManager.providerName(provider)),
        subtitle: Text(switch (status.status) {
          RealtimeStatus.unconfigured => voiceText(context, 'Not configured'),
          RealtimeStatus.unvalidated => voiceText(context, 'Not validated'),
          RealtimeStatus.validated => voiceText(
            context,
            'Connection validated',
          ),
          RealtimeStatus.failed when status.tools =>
            messages.voiceRealtimeToolsUnavailable(
              voiceText(context, status.error),
            ),
          RealtimeStatus.failed => messages.voiceRealtimeConnectFailed(
            status.error,
          ),
        }),
        trailing: OutlinedButton(
          onPressed: () async {
            final saved = await showRealtimeProviderDialog(
              context,
              container,
              provider,
            );
            if (saved) onChanged();
          },
          child: Text(voiceText(context, 'Configure')),
        ),
      );
    },
  );
}

/// A provider's settings in a dialog. Save & Validate connects with them
/// first: a connection the provider takes saves them and closes, a refused
/// one shows why and keeps the dialog and the stored settings as they
/// were. Clear puts the provider back to Not configured. Answers true when
/// it saved or cleared.
Future<bool> showRealtimeProviderDialog(
  BuildContext context,
  AppContainer container,
  RealtimeProvider provider,
) async {
  final settings = container.settings;
  // OpenAI's and Gemini's lists end with Reasoning effort, which xAI has
  // no say in. xAI's and Gemini's switches follow.
  final [keyDef, modelDef, voiceDef, endpointDef, ...more] =
      defs.realtimeProviderSettings[provider.id]!;
  final reasoningDef = more.firstOrNull;
  final switchDefs = defs.realtimeProviderSwitches[provider.id] ?? const [];
  final switches = {for (final def in switchDefs) def: settings.get(def)};
  // A switch's name in voiceRealtimeSave: its key after the provider's.
  String param(defs.SettingDef<bool> def) =>
      def.key.substring('voice.realtime_${provider.id}_'.length);
  final apiKey = TextEditingController(text: settings.get(keyDef));
  final endpoint = TextEditingController(text: settings.get(endpointDef));
  var model = settings.get(modelDef);
  var voice = settings.get(voiceDef);
  var reasoning = reasoningDef == null ? '' : settings.get(reasoningDef);
  var saving = false;
  String? error;
  // Clear shows once there is something to clear.
  final configured =
      container.voice.realtimeStatus(provider).status !=
      RealtimeStatus.unconfigured;

  Widget picker(
    BuildContext ctx,
    defs.SettingDef<String> def,
    String value,
    ValueChanged<String> onChanged,
  ) {
    final options = [
      ...settings.optionsFor(def),
      if (!settings.optionsFor(def).contains(value)) value,
    ];
    String label(String option) => def.localizedOption(
      ctx,
      option,
      settings.optionLabel(def, option) ?? option,
    );
    return LabeledField(
      label: def.localizedTitle(ctx),
      helper: def.localizedDescription(ctx),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: const InputDecoration(),
        items: [
          for (final option in options)
            DropdownMenuItem(value: option, child: Text(label(option))),
        ],
        onChanged: saving ? null : (v) => onChanged(v ?? ''),
      ),
    );
  }

  final route = DialogRoute<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        final scheme = Theme.of(ctx).colorScheme;
        Future<void> save() async {
          setDialogState(() {
            saving = true;
            error = null;
          });
          final result = await container.commands.execute('voiceRealtimeSave', {
            'provider': provider.id,
            'apiKey': apiKey.text,
            'endpoint': endpoint.text,
            'model': model,
            'voice': voice,
            'reasoning': reasoning,
            for (final MapEntry(:key, :value) in switches.entries)
              param(key): value,
          });
          if (!ctx.mounted) return;
          final data = result.data is Map
              ? (result.data as Map).cast<String, Object?>()
              : const <String, Object?>{};
          if (result.ok && data['connected'] == true) {
            Navigator.pop(ctx, true);
            return;
          }
          setDialogState(() {
            saving = false;
            error = l10n(ctx).voiceRealtimeConnectFailed(
              '${data['error'] ?? result.error ?? ''}',
            );
          });
        }

        Future<void> clear() async {
          setDialogState(() => saving = true);
          await container.commands.execute('voiceRealtimeClear', {
            'provider': provider.id,
          });
          if (ctx.mounted) Navigator.pop(ctx, true);
        }

        return AlertDialog(
          title: Text(VoiceManager.providerName(provider)),
          content: SizedBox(
            width: 480,
            child: EdgeFade(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [
                    LabeledField(
                      label: keyDef.localizedTitle(ctx),
                      helper: keyDef.localizedDescription(ctx),
                      child: TextField(
                        controller: apiKey,
                        enabled: !saving,
                        obscureText: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: const InputDecoration(),
                      ),
                    ),
                    picker(
                      ctx,
                      modelDef,
                      model,
                      (v) => setDialogState(() => model = v),
                    ),
                    picker(
                      ctx,
                      voiceDef,
                      voice,
                      (v) => setDialogState(() => voice = v),
                    ),
                    if (reasoningDef != null)
                      picker(
                        ctx,
                        reasoningDef,
                        reasoning,
                        (v) => setDialogState(() => reasoning = v),
                      ),
                    for (final def in switchDefs)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(def.localizedTitle(ctx)),
                        subtitle: Text(def.localizedDescription(ctx)),
                        value: switches[def]!,
                        onChanged: saving
                            ? null
                            : (v) => setDialogState(() => switches[def] = v),
                      ),
                    LabeledField(
                      label: endpointDef.localizedTitle(ctx),
                      helper: endpointDef.localizedDescription(ctx),
                      child: TextField(
                        controller: endpoint,
                        enabled: !saving,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        decoration: InputDecoration(
                          hintText: endpointDef.localizedPlaceholder(ctx),
                        ),
                      ),
                    ),
                    if (error != null)
                      Text(
                        error!,
                        style: Theme.of(
                          ctx,
                        ).textTheme.bodyMedium?.copyWith(color: scheme.error),
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            if (configured) ...[
              TextButton(
                style: TextButton.styleFrom(foregroundColor: scheme.error),
                onPressed: saving ? null : clear,
                child: Text(voiceText(ctx, 'Clear')),
              ),
              const SizedBox(width: 24),
            ],
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx, false),
              child: Text(voiceText(ctx, 'Cancel')),
            ),
            FilledButton(
              onPressed: saving ? null : save,
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : Text(voiceText(ctx, 'Save & Validate')),
            ),
          ],
        );
      },
    ),
  );
  final saved = await Navigator.of(context, rootNavigator: true).push(route);
  await route.completed;
  apiKey.dispose();
  endpoint.dispose();
  return saved ?? false;
}

/// A skin's name in the kiosk's language.
String skinName(BuildContext context, AssistSkin skin) =>
    defs.voiceSkin.localizedOption(context, skin.id, skin.name);

/// The Skin setting's [value] by name: a built-in skin's, or the plugin's
/// whose voice skin it is.
String voiceSkinName(
  BuildContext context,
  AppContainer container,
  String value,
) => defs.isPluginVoiceSkin(value)
    ? container.plugins.voiceSkinOptions[value] ??
          voiceText(context, 'Unavailable plugin skin')
    : skinName(context, assistSkinById(value));

/// A Skin row, Skin or Assistant 2 skin: the current skin's name,
/// opening the picker.
class VoiceSkinRow extends StatelessWidget {
  const VoiceSkinRow({
    super.key,
    required this.container,
    required this.onChanged,
    this.def = defs.voiceSkin,
  });

  final AppContainer container;
  final VoidCallback onChanged;
  final defs.SettingDef<String> def;

  @override
  Widget build(BuildContext context) {
    final skin = container.settings.get(def);
    return SettingsRow(
      title: Text(def.localizedTitle(context)),
      subtitle: Text(def.localizedDescription(context)),
      onTap: () async {
        final picked = await showVoiceSkinPicker(context, container, def: def);
        if (picked != null) {
          await container.settings.set(def, picked);
          onChanged();
        }
      },
      trailing: Text(
        voiceSkinName(context, container, skin),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

/// A skin in miniature: a screenshot of its overlay answering, taken on a
/// tablet with the text at 150% and no dashboard showing through. Light
/// where the skin has a light palette.
class VoiceSkinThumbnail extends StatelessWidget {
  const VoiceSkinThumbnail({super.key, required this.skin});

  final AssistSkin skin;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/voice_skins/${skin.id}.webp',
    fit: BoxFit.cover,
    filterQuality: FilterQuality.medium,
  );
}

/// A plugin's voice skin: the picture the plugin ships, or the plugin mark
/// for one that ships none.
class _PluginSkinThumbnail extends StatelessWidget {
  const _PluginSkinThumbnail({required this.container, required this.id});

  final AppContainer container;

  /// The plugin's id.
  final String id;

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: container.plugins.voiceSkinThumbnail(id),
    builder: (context, snapshot) => snapshot.data != null
        ? Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, _, _) => _mark(context),
          )
        : _mark(context),
  );

  Widget _mark(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.extension_outlined,
          size: 40,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Every skin as a thumbnail, the current one of [def] ringed. Installed
/// plugins that offer a voice skin follow the built-in ones.
Future<String?> showVoiceSkinPicker(
  BuildContext context,
  AppContainer container, {
  defs.SettingDef<String> def = defs.voiceSkin,
}) {
  final current = container.settings.get(def);
  return showDialog<String>(
    context: context,
    builder: (context) {
      final wide = MediaQuery.sizeOf(context).width >= 640;
      final skins = <(String, String, Widget)>[
        for (final skin in assistSkins)
          (skin.id, skinName(context, skin), VoiceSkinThumbnail(skin: skin)),
        for (final MapEntry(:key, :value)
            in container.plugins.voiceSkinOptions.entries)
          (
            key,
            value,
            _PluginSkinThumbnail(
              container: container,
              id: key.substring('plugin:'.length),
            ),
          ),
      ];
      return AlertDialog(
        title: Text(def.localizedTitle(context)),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        content: SizedBox(
          width: wide ? 560 : 320,
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: wide ? 3 : 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.25,
            children: [
              for (final (id, name, thumbnail) in skins)
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.of(context).pop(id),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 6,
                    children: [
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              width: id == current ? 3 : 1,
                              color: id == current
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).dividerColor,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: thumbnail,
                          ),
                        ),
                      ),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// The Background row: a slider whose far left reads Skin default.
class VoiceBackgroundRow extends StatelessWidget {
  const VoiceBackgroundRow({
    super.key,
    required this.container,
    required this.onChanged,
  });

  final AppContainer container;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final value = container.settings
        .get(defs.voiceBackgroundOpacity)
        .toDouble();
    final label = value < 0
        ? voiceText(context, 'Skin default')
        : '${value.round()}%';
    return Padding(
      padding: const EdgeInsets.fromLTRB(Ks.inset, 12, Ks.inset, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      voiceText(context, 'Background'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      voiceText(
                        context,
                        'How much of the dashboard shows through.',
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(label),
            ],
          ),
          Slider(
            min: -5,
            max: 100,
            divisions: 21,
            value: value < 0 ? -5 : value,
            onChanged: (v) async {
              await container.settings.set(
                defs.voiceBackgroundOpacity,
                v < 0 ? -1 : v.roundToDouble(),
              );
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}

/// The Preview row: the overlay over the screen for five seconds.
class VoicePreviewRow extends StatelessWidget {
  const VoicePreviewRow({super.key, required this.container});

  final AppContainer container;

  @override
  Widget build(BuildContext context) => SettingsRow(
    title: Text(voiceText(context, 'Preview')),
    subtitle: Text(
      voiceText(context, 'Show the overlay on this screen for five seconds.'),
    ),
    trailing: OutlinedButton(
      onPressed: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
        unawaited(container.commands.execute('voicePreview', const {}));
      },
      child: Text(voiceText(context, 'Preview')),
    ),
  );
}

/// Run from the dashboard again, while the integration is still installed.
class VoiceRollbackCard extends StatelessWidget {
  const VoiceRollbackCard({super.key, required this.container});

  final AppContainer container;

  @override
  Widget build(BuildContext context) => SettingsCard(
    children: [
      SettingsRow(
        title: Text(voiceText(context, 'Run from the dashboard again')),
        subtitle: Text(
          voiceText(
            context,
            'Go back to the Voice Satellite integration. Nothing set here is '
            'lost.',
          ),
        ),
        trailing: OutlinedButton(
          onPressed: () async {
            final ok = await showConfirmDialog(
              context,
              title: voiceText(context, 'Run from the dashboard again?'),
              message: voiceText(
                context,
                'The dashboard runs Voice Satellite again through the '
                'integration, with the settings it had before. What you set '
                'here stays for next time.',
              ),
              confirmLabel: voiceText(context, 'Switch back'),
            );
            if (ok) {
              await container.commands.execute('vsRollback', const {});
            }
          },
          child: Text(voiceText(context, 'Switch back')),
        ),
      ),
    ],
  );
}

// ── the migration wizard ─────────────────────────────────────────────────

/// True once the kiosk migrated. [onboarding] is the migration offered at
/// setup: Home Assistant was just checked and cannot have added the kiosk
/// yet, so there is no check step, and the old satellite's selects are set
/// once it does.
Future<bool> showVoiceMigrationWizard(
  BuildContext context,
  AppContainer container, {
  bool onboarding = false,
}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _MigrationWizard(container: container, onboarding: onboarding),
    ) ==
    true;

class _MigrationWizard extends StatefulWidget {
  const _MigrationWizard({required this.container, required this.onboarding});
  final AppContainer container;
  final bool onboarding;

  @override
  State<_MigrationWizard> createState() => _MigrationWizardState();
}

class _MigrationWizardState extends State<_MigrationWizard> {
  AppContainer get c => widget.container;

  /// The pages in order; past the last is the switch itself.
  late final List<String> _pages = widget.onboarding
      ? const ['pick', 'plan', 'automations', 'ready']
      : const ['pick', 'check', 'plan', 'automations', 'ready'];
  int _step = 0;

  /// The integration's satellites, and the one this kiosk takes over.
  List<Map<String, Object?>>? _satellites;
  String _satellite = '';
  Map<String, Object?>? _check;
  Map<String, Object?>? _plan;
  List<Map<String, Object?>>? _automations;
  final _groups = <String>{
    'voice',
    'appearance',
    'conversation',
    'assistant',
    'timers',
  };
  bool _switching = false;
  Map<String, Object?>? _result;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSatellites());
    c.voice.migrationSteps.addListener(_changed);
  }

  Future<void> _loadSatellites() async {
    final result = await c.commands.execute('haListVoiceSatellites', const {});
    if (!mounted) return;
    final list = [
      for (final s in (result.data as List? ?? const []))
        if (s is Map) s.cast<String, Object?>(),
    ];
    final assigned = c.settings.get(defs.haSatelliteEntity).trim();
    setState(() {
      _satellites = list;
      _satellite = list.any((s) => s['entity_id'] == assigned)
          ? assigned
          : list.isEmpty
          ? ''
          : '${list.first['entity_id']}';
    });
  }

  void _go(String page) {
    setState(() => _step = _pages.indexOf(page));
    switch (page) {
      case 'check':
        unawaited(_runCheck());
      case 'plan':
        if (_plan == null) unawaited(_loadPlan());
      case 'automations':
        if (_automations == null) unawaited(_loadAutomations());
    }
  }

  @override
  void dispose() {
    c.voice.migrationSteps.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _runCheck() async {
    setState(() => _check = null);
    final result = await c.commands.execute('voiceMigrationCheck', const {});
    if (!mounted) return;
    setState(
      () => _check = result.ok && result.data is Map
          ? (result.data as Map).cast<String, Object?>()
          : const {'checks': [], 'ready': false},
    );
  }

  Future<void> _loadPlan() async {
    final result = await c.commands.execute('voiceMigrationPlan', {
      'satellite': _satellite,
    });
    if (!mounted) return;
    setState(
      () => _plan = result.ok && result.data is Map
          ? (result.data as Map).cast<String, Object?>()
          : const {'groups': []},
    );
  }

  Future<void> _loadAutomations() async {
    final result = await c.commands.execute('voiceMigrationAutomations', {
      'satellite': _satellite,
    });
    if (!mounted) return;
    final items = result.ok && result.data is Map
        ? (result.data as Map)['items']
        : null;
    setState(
      () => _automations = [
        for (final i in (items as List? ?? const []))
          if (i is Map) i.cast<String, Object?>(),
      ],
    );
  }

  Future<void> _switch() async {
    setState(() {
      _switching = true;
      _step = _pages.length;
    });
    final result = await c.commands.execute('vsMigrate', {
      'groups': _groups.toList(),
      'satellite': _satellite,
      'deferred': widget.onboarding,
    });
    if (!mounted) return;
    setState(() {
      _switching = false;
      _result = {
        'ok': result.ok,
        'error': result.error,
        'fallbacks': result.data is Map
            ? (result.data as Map)['fallbacks']
            : null,
      };
    });
  }

  Widget _stepper(String page) {
    final n = _pages.indexOf(page) + 1;
    final total = _pages.length;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        spacing: 8,
        children: [
          for (var i = 0; i < total; i++)
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: i < n
                      ? scheme.primary
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          Text(
            l10n(context).voiceMigrationStep('$n', '$total'),
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _checkRow(Map<String, Object?> check) {
    final scheme = Theme.of(context).colorScheme;
    final ok = check['ok'] == true;
    final warnOnly = check['warnOnly'] == true;
    final (title, good, bad) = switch (check['id']) {
      'homeAssistant' => (
        'Home Assistant',
        'Connected.',
        'Not connected. Check Home Assistant Setup.',
      ),
      'esphome' => (
        'This kiosk in Home Assistant',
        'Added through ESPHome.',
        check['esphomeOn'] == true
            ? 'Not added yet. Home Assistant lists this kiosk as discovered '
                  'under Settings, Devices & services. Add it there, then '
                  'come back.'
            : 'The ESPHome server is off. Turn it on, then add this kiosk in '
                  'Home Assistant.',
      ),
      'admin' => (
        'Administrator token',
        'Tool use and results will show.',
        check['unknown'] == true
            ? 'Could not check the token. Tool use and results need an '
                  'administrator\'s.'
            : 'The token is a regular user\'s. Voice Satellite works, tool '
                  'use and results will not show.',
      ),
      'microphone' => (
        'Microphone',
        'Allowed.',
        'Not allowed. Grant it under Required system permissions.',
      ),
      _ => ('${check['id']}', '', ''),
    };
    final color = ok
        ? scheme.primary
        : warnOnly
        ? scheme.tertiary
        : scheme.error;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          Icon(
            ok
                ? Icons.check_circle_outline
                : warnOnly
                ? Icons.warning_amber_rounded
                : Icons.error_outline,
            color: color,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  voiceText(context, title),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  voiceText(context, ok ? good : bad),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ok ? scheme.onSurfaceVariant : color,
                  ),
                ),
              ],
            ),
          ),
          if (check['id'] == 'esphome' && check['esphomeOn'] != true)
            TextButton(
              onPressed: () async {
                await c.settings.set(defs.esphomeEnabled, true);
                await _runCheck();
              },
              child: Text(voiceText(context, 'Turn on ESPHome')),
            ),
        ],
      ),
    );
  }

  static const _groupTitles = {
    'voice': 'Voice',
    'appearance': 'Appearance',
    'conversation': 'Conversation',
    'assistant': 'Assistant',
    'timers': 'Timers',
  };

  @override
  Widget build(BuildContext context) {
    final page = _step < _pages.length ? _pages[_step] : 'switch';
    final (title, body, actions) = switch (page) {
      'pick' => _pickStep(),
      'check' => _stepOne(),
      'plan' => _stepTwo(),
      'automations' => _stepThree(),
      'ready' => _stepFour(),
      _ => _switchingStep(),
    };
    return AlertDialog(
      title: title == null ? null : Text(title),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: body,
          ),
        ),
      ),
      actions: actions,
    );
  }

  (String?, List<Widget>, List<Widget>) _pickStep() {
    final satellites = _satellites;
    return (
      voiceText(context, 'Migrate Voice Satellite'),
      [
        _stepper('pick'),
        Text(
          voiceText(
            context,
            'Pick the Voice Satellite integration\'s satellite this kiosk '
            'takes over. Its settings come over to this kiosk.',
          ),
        ),
        const SizedBox(height: 8),
        if (satellites == null)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (satellites.isEmpty)
          Text(
            voiceText(
              context,
              'The Voice Satellite integration has no satellites.',
            ),
          )
        else
          RadioGroup<String>(
            groupValue: _satellite,
            onChanged: (v) => setState(() {
              _satellite = v ?? _satellite;
              _plan = null;
              _automations = null;
            }),
            child: Column(
              children: [
                for (final s in satellites)
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: '${s['entity_id']}',
                    title: Text('${s['name']}'),
                    subtitle: Text('${s['entity_id']}'),
                  ),
              ],
            ),
          ),
      ],
      [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(voiceText(context, 'Cancel')),
        ),
        FilledButton(
          onPressed: _satellite.isEmpty
              ? null
              : () => _go(widget.onboarding ? 'plan' : 'check'),
          child: Text(voiceText(context, 'Next')),
        ),
      ],
    );
  }

  (String?, List<Widget>, List<Widget>) _stepOne() {
    final check = _check;
    final checks = [
      for (final raw in (check?['checks'] as List? ?? const []))
        if (raw is Map) raw.cast<String, Object?>(),
    ];
    return (
      voiceText(context, 'Migrate Voice Satellite'),
      [
        _stepper('check'),
        Text(
          voiceText(
            context,
            'This kiosk becomes the voice satellite itself. The Voice '
            'Satellite integration is not needed after this.',
          ),
        ),
        const SizedBox(height: 8),
        if (check == null)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          for (final c in checks) _checkRow(c),
      ],
      [
        TextButton(
          onPressed: () => _go('pick'),
          child: Text(voiceText(context, 'Back')),
        ),
        if (check != null && check['ready'] != true)
          TextButton(
            onPressed: _runCheck,
            child: Text(voiceText(context, 'Check again')),
          ),
        FilledButton(
          onPressed: check?['ready'] == true ? () => _go('plan') : null,
          child: Text(voiceText(context, 'Next')),
        ),
      ],
    );
  }

  (String?, List<Widget>, List<Widget>) _stepTwo() {
    final plan = _plan;
    final groups = [
      for (final raw in (plan?['groups'] as List? ?? const []))
        if (raw is Map) raw.cast<String, Object?>(),
    ];
    final scheme = Theme.of(context).colorScheme;
    return (
      voiceText(context, 'Settings to bring over'),
      [
        _stepper('plan'),
        if (plan == null)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          for (final g in groups)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _groups.contains(g['id']),
              onChanged: (v) => setState(
                () => v == true
                    ? _groups.add('${g['id']}')
                    : _groups.remove('${g['id']}'),
              ),
              title: Text(
                voiceText(context, _groupTitles['${g['id']}'] ?? '${g['id']}'),
              ),
              subtitle: '${g['values']}'.isEmpty
                  ? null
                  : Text('${g['values']}'),
            ),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              voiceText(
                context,
                'Not carried over: custom CSS, the browser microphone '
                'processing and the conversation memory length. Custom '
                'microWakeWord models work from config/custom_wake_words in '
                'Home Assistant.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ],
      [
        TextButton(
          onPressed: () => _go(widget.onboarding ? 'pick' : 'check'),
          child: Text(voiceText(context, 'Back')),
        ),
        FilledButton(
          onPressed: plan == null ? null : () => _go('automations'),
          child: Text(voiceText(context, 'Next')),
        ),
      ],
    );
  }

  (String?, List<Widget>, List<Widget>) _stepThree() {
    final items = _automations;
    final satellite = _satellite;
    return (
      voiceText(context, 'Automations and scripts'),
      [
        _stepper('automations'),
        if (items == null)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (items.isEmpty)
          Row(
            spacing: 12,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              Expanded(
                child: Text(
                  voiceText(
                    context,
                    'Nothing in Home Assistant points at the old satellite.',
                  ),
                ),
              ),
            ],
          )
        else ...[
          Text(l10n(context).voiceMigrationStillPoint(satellite)),
          const SizedBox(height: 8),
          for (final item in items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                item['kind'] == 'Script'
                    ? Icons.code
                    : Icons.auto_mode_outlined,
              ),
              title: Text('${item['name']}'),
              subtitle: Text(
                '${voiceText(context, '${item['kind']}')} · '
                '${(item['refs'] as List? ?? const []).join(', ')}',
              ),
            ),
        ],
      ],
      [
        TextButton(
          onPressed: () => _go('plan'),
          child: Text(voiceText(context, 'Back')),
        ),
        FilledButton(
          onPressed: items == null ? null : () => _go('ready'),
          child: Text(voiceText(context, 'Next')),
        ),
      ],
    );
  }

  (String?, List<Widget>, List<Widget>) _stepFour() {
    final settings = (_plan?['groups'] as List? ?? const [])
        .whereType<Map>()
        .firstWhere(
          (g) => g['id'] == 'appearance',
          orElse: () => const {},
        )['settings'];
    final skinId = settings is Map
        ? '${settings[defs.voiceSkin.key] ?? c.settings.get(defs.voiceSkin)}'
        : c.settings.get(defs.voiceSkin);
    final skin = assistSkinById(skinId);
    return (
      voiceText(context, 'Ready to switch'),
      [
        _stepper('ready'),
        for (final line in [
          'This kiosk listens, answers and draws the overlay.',
          if (widget.onboarding)
            'Its Assistant and wake words are set once Home Assistant adds '
                'this kiosk.'
          else
            'The dashboard stops running Voice Satellite on this kiosk.',
          'The old satellite stays in Home Assistant, unused.',
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('•  ${voiceText(context, line)}'),
          ),
        const SizedBox(height: 10),
        Row(
          spacing: 14,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 120,
                height: 75,
                child: VoiceSkinThumbnail(skin: skin),
              ),
            ),
            Expanded(
              child: Text(
                skinName(context, skin),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ],
      [
        TextButton(
          onPressed: () => _go('automations'),
          child: Text(voiceText(context, 'Back')),
        ),
        FilledButton(
          onPressed: _switch,
          child: Text(voiceText(context, 'Switch now')),
        ),
      ],
    );
  }

  (String?, List<Widget>, List<Widget>) _switchingStep() {
    final result = _result;
    final scheme = Theme.of(context).colorScheme;
    if (result != null) {
      final ok = result['ok'] == true;
      return (
        null,
        [
          const SizedBox(height: 8),
          Center(
            child: CircleAvatar(
              radius: 32,
              backgroundColor: ok
                  ? scheme.primaryContainer
                  : scheme.errorContainer,
              child: Icon(
                ok ? Icons.check : Icons.error_outline,
                size: 32,
                color: ok ? scheme.onPrimaryContainer : scheme.onErrorContainer,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            ok
                ? voiceText(context, 'Voice Satellite runs here now')
                : voiceText(context, 'Could not switch'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            ok
                ? widget.onboarding
                      ? voiceText(
                          context,
                          'Finish the setup, then add this kiosk in Home '
                          'Assistant. Once no other device uses the Voice '
                          'Satellite integration, uninstall it from HACS.',
                        )
                      : voiceText(
                          context,
                          'Say the wake word to try it. Once no other device '
                          'uses the Voice Satellite integration, uninstall it '
                          'from HACS.',
                        )
                : widget.onboarding
                ? voiceText(context, '${result['error'] ?? ''}')
                : '${voiceText(context, '${result['error'] ?? ''}')} ${voiceText(context, 'Voice Satellite runs from the dashboard again.')}',
            textAlign: TextAlign.center,
          ),
        ],
        [
          if (!ok)
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(voiceText(context, 'Close')),
            ),
          FilledButton(
            onPressed: ok
                ? () => Navigator.of(context).pop(true)
                : () => setState(() {
                    _result = null;
                    _step = _pages.indexOf('ready');
                  }),
            child: Text(
              ok ? voiceText(context, 'Done') : voiceText(context, 'Try again'),
            ),
          ),
        ],
      );
    }
    final titles = {
      'save': 'Save the settings',
      'stop': 'Stop the dashboard engine',
      'start': 'Start listening here',
      'entities': widget.onboarding
          ? 'Turn on Voice Satellite on this kiosk'
          : 'Set the kiosk\'s entities in Home Assistant',
      'check': 'Check the satellite in Home Assistant',
    };
    return (
      voiceText(context, 'Switching…'),
      [
        for (final step in c.voice.migrationSteps.value)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              spacing: 14,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: switch (step['state']) {
                    'done' => Icon(
                      Icons.check_circle_outline,
                      color: scheme.primary,
                      size: 22,
                    ),
                    'failed' => Icon(
                      Icons.error_outline,
                      color: scheme.error,
                      size: 22,
                    ),
                    'run' => const CircularProgressIndicator(strokeWidth: 3),
                    _ => Icon(
                      Icons.radio_button_unchecked,
                      color: scheme.outline,
                      size: 22,
                    ),
                  },
                ),
                Expanded(
                  child: Text(voiceText(context, titles[step['id']] ?? '')),
                ),
              ],
            ),
          ),
      ],
      const [],
    );
  }

  bool get switching => _switching;
}

/// The page's rows that pick the pipelines: Home Assistant's selects.
const voicePipelineRows = [
  ('pipeline', 'Assistant 1', 'Answers wake word 1.'),
  ('pipeline_2', 'Assistant 2', 'Answers wake word 2.'),
  (
    'vad_sensitivity',
    'Finished speaking detection',
    'How long a pause ends a voice command.',
  ),
];

/// The page's rows that pick the wake words: Home Assistant's selects.
const voiceWakeWordRows = [
  ('wake_word', 'Wake word 1', 'The word that starts a voice command.'),
  (
    'wake_word_2',
    'Wake word 2',
    'A second wake word, answered by Assistant 2.',
  ),
];

/// Shows a toast after a switch or rollback from anywhere.
void voiceToast(BuildContext context, String message) =>
    showToast(context, title: 'Voice Satellite', message: message);
