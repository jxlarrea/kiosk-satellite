import 'dart:convert';

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../l10n/gesture_messages.dart';
import '../l10n/messages.dart';
import 'dashboard_view_picker.dart';
import 'entity_picker.dart';
import 'kit.dart';

/// The action chooser's groups of (type, label, icon); config dialogs
/// switch on the type.
const _actionGroups = <(String, List<(String, String, IconData)>)>[
  (
    'Kiosk Satellite',
    [
      ('navigate', 'Go to a dashboard view', Icons.dashboard_outlined),
      ('refresh', 'Refresh the dashboard', Icons.refresh),
      ('url', 'Open a web page', Icons.public),
      ('camera_view', 'Show a camera view', Icons.videocam_outlined),
      ('sendspin_player', 'Show the floating player', Icons.speaker_outlined),
      ('now_playing', 'Show Now Playing', Icons.play_circle_outline),
      ('music_assistant', 'Open Music Assistant', Icons.library_music_outlined),
      ('music_library', 'Open Music Library', Icons.queue_music_rounded),
      ('media_play_pause', 'Play or pause media', Icons.play_arrow_outlined),
      ('app_launcher', 'Open the app launcher', Icons.apps_outlined),
      ('intercom_open', 'Open Call a kiosk', Icons.speaker_phone_outlined),
      ('intercom_call', 'Call a kiosk', Icons.phone_outlined),
      ('intercom_hangup', 'End the intercom call', Icons.call_end_outlined),
      ('intercom_answer', 'Accept intercom call', Icons.call_outlined),
      (
        'intercom_decline',
        'Decline intercom call',
        Icons.phone_disabled_outlined,
      ),
      ('alarm_stop', 'Stop the alarm', Icons.alarm_off_outlined),
      ('alarm_snooze', 'Snooze the alarm', Icons.snooze_outlined),
      ('alarms', 'Open the alarm list', Icons.alarm_outlined),
      ('alarm_next', 'Open the next alarm', Icons.alarm_on_outlined),
      ('timers', 'Open the timers', Icons.timer_outlined),
      ('calendar', 'Open the calendar', Icons.calendar_month_outlined),
      ('voice_wake', 'Start a voice command', Icons.mic_none_outlined),
      ('voice_stop', 'Stop the voice assistant', Icons.stop_circle_outlined),
      ('voice_mute', 'Mute or unmute Voice Satellite', Icons.mic_off_outlined),
      ('screensaver', 'Start the screensaver', Icons.nightlight_outlined),
      ('screensaver_stop', 'Stop the screensaver', Icons.light_mode_outlined),
      ('hold_mode', 'Toggle hold mode', Icons.pause_circle_outline),
      ('ha_kiosk', 'Toggle HA kiosk mode', Icons.fullscreen),
      ('plugin_action', 'Run a plugin action', Icons.extension_outlined),
    ],
  ),
  (
    'Android',
    [
      ('launch_app', 'Open another app', Icons.apps_outlined),
      ('open_uri', 'Open a deep link', Icons.link_outlined),
      ('android_settings', 'Open Android Settings', Icons.android_outlined),
    ],
  ),
  (
    'Home Assistant',
    [
      ('ha_service', 'Call a service', Icons.home_outlined),
      ('ha_script', 'Run a script', Icons.description_outlined),
      ('ha_automation', 'Trigger an automation', Icons.play_circle_outline),
      ('ha_event', 'Fire an event', Icons.campaign_outlined),
    ],
  ),
];

/// The action chooser behind a gesture's action and a plugin's action
/// setting: a list of action types, then the chosen type's own dialog. Both
/// save the action object GesturesManager.runGestureAction runs.
class GestureActionPicker {
  GestureActionPicker(this.context, this.c);

  final BuildContext context;
  final AppContainer c;

  /// The action chooser, then the chosen type's own configuration dialog.
  Future<Map<String, Object?>?> _configurePluginAction() async {
    final actions = c.plugins.actions
        .where((action) => action['available'] == true)
        .toList();
    return showDialog<Map<String, Object?>>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(gestureText(context, 'Plugin action')),
        children: [
          if (actions.isEmpty)
            Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                gestureText(
                  context,
                  'Enable a plugin with actions in Plugin Manager first.',
                ),
              ),
            ),
          for (final action in actions)
            SimpleDialogOption(
              // Only the IDs are saved. The names are the manifest's to
              // change, so every row looks them up when it draws.
              onPressed: () => Navigator.pop(context, <String, Object?>{
                'type': 'plugin_action',
                'pluginId': action['pluginId'],
                'command': action['command'],
              }),
              child: ListTile(
                title: Text('${action['title']}'),
                subtitle: Text('${action['pluginName']}'),
              ),
            ),
        ],
      ),
    );
  }

  Future<Map<String, Object?>?> pick(Map<String, Object?>? current) async {
    final type = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(gestureText(context, 'Action')),
        children: [
          for (final (group, actions) in _actionGroups) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
              child: Text(
                group,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            for (final (value, label, icon) in actions)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, value),
                child: Row(
                  children: [
                    Icon(icon, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(gestureText(context, label))),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
    if (type == null || !context.mounted) return null;
    final carried = current != null && '${current['type']}' == type
        ? current
        : null;
    return switch (type) {
      'plugin_action' => _configurePluginAction(),
      // Actions with nothing to configure skip the second dialog.
      'android_settings' ||
      'refresh' ||
      'sendspin_player' ||
      'now_playing' ||
      'music_assistant' ||
      'media_play_pause' ||
      'app_launcher' ||
      'intercom_open' ||
      'intercom_hangup' ||
      'intercom_answer' ||
      'intercom_decline' ||
      'alarm_stop' ||
      'alarm_snooze' ||
      'alarms' ||
      'alarm_next' ||
      'timers' ||
      'calendar' ||
      'music_library' ||
      'voice_wake' ||
      'voice_stop' ||
      'voice_mute' ||
      'screensaver' ||
      'screensaver_stop' ||
      'hold_mode' ||
      'ha_kiosk' => {'type': type},
      'navigate' => _configureNavigate(carried),
      'url' => _configureText(
        carried,
        type: 'url',
        title: 'Open a web page',
        field: 'url',
        label: 'URL',
        hint: 'https://example.com',
        keyboard: TextInputType.url,
        validate: (v) {
          final uri = Uri.tryParse(v);
          return uri != null &&
                  (uri.scheme == 'http' || uri.scheme == 'https') &&
                  uri.host.isNotEmpty
              ? null
              : 'Enter a full http(s) URL.';
        },
      ),
      'camera_view' => _configureCameraView(carried),
      'intercom_call' => _configureIntercomCall(carried),
      'launch_app' => _configureText(
        carried,
        type: 'launch_app',
        title: 'Open another app',
        field: 'package',
        label: 'Package name',
        hint: 'com.android.deskclock',
        validate: (v) => v.contains('.') ? null : 'Enter a package name.',
      ),
      'open_uri' => _configureText(
        carried,
        type: 'open_uri',
        title: 'Open a deep link',
        field: 'uri',
        label: 'URI',
        hint: 'myapp://path',
        keyboard: TextInputType.url,
        validate: (v) =>
            Uri.tryParse(v)?.hasScheme == true ? null : 'Enter a full URI.',
      ),
      'ha_service' => _configureHaService(carried),
      'ha_script' => _configureHaEntity(
        carried,
        type: 'ha_script',
        title: 'Run a script',
        domain: 'script',
      ),
      'ha_automation' => _configureHaEntity(
        carried,
        type: 'ha_automation',
        title: 'Trigger an automation',
        domain: 'automation',
      ),
      'ha_event' => _configureHaEvent(carried),
      _ => Future<Map<String, Object?>?>.value(),
    };
  }

  /// One required text field; the shape of the URL, app and deep link
  /// dialogs.
  Future<Map<String, Object?>?> _configureText(
    Map<String, Object?>? current, {
    required String type,
    required String title,
    required String field,
    required String label,
    required String hint,
    required String? Function(String) validate,
    TextInputType? keyboard,
  }) async {
    final controller = TextEditingController(text: '${current?[field] ?? ''}');
    String? error;
    final route = DialogRoute<Map<String, Object?>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void submit() {
            final value = controller.text.trim();
            final invalid = validate(value);
            if (invalid != null) {
              setDialogState(() => error = invalid);
              return;
            }
            Navigator.pop(context, {'type': type, field: value});
          }

          return AlertDialog(
            title: Text(gestureText(context, title)),
            content: SizedBox(
              width: 480,
              child: LabeledField(
                label: gestureText(context, label),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: keyboard,
                  decoration: InputDecoration(
                    hintText: hint,
                    errorText: error == null
                        ? null
                        : gestureError(context, error!),
                  ),
                  onSubmitted: (_) => submit(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(gestureText(context, 'Cancel')),
              ),
              FilledButton(
                onPressed: submit,
                child: Text(gestureText(context, 'OK')),
              ),
            ],
          );
        },
      ),
    );
    final result = await Navigator.of(context).push(route);
    await route.completed;
    controller.dispose();
    return result;
  }

  /// Run haValidateAction and reduce its answer to one sentence for the
  /// dialog's status line. Returns (ok, message).
  Future<(bool, String)> _validateHaAction({
    required String domain,
    required String service,
    String entity = '',
  }) async {
    final result = await c.commands.execute('haValidateAction', {
      'domain': domain,
      'service': service,
      if (entity.isNotEmpty) 'entity_id': entity,
    });
    if (!result.ok) return (false, result.error ?? 'Could not validate.');
    final data = result.data is Map ? result.data as Map : const {};
    if (data['domain'] == false) return (false, 'Domain $domain not found.');
    if (data['service'] == false) {
      return (false, 'Service $domain.$service not found.');
    }
    if (data['entity'] == false) return (false, 'Entity $entity not found.');
    return (true, 'Looks good.');
  }

  /// The dialog's Validate row: button plus status line.
  Widget _validateRow(
    BuildContext context, {
    required bool checking,
    required (bool, String)? verdict,
    required VoidCallback? onValidate,
  }) => Row(
    children: [
      TextButton.icon(
        onPressed: checking ? null : onValidate,
        icon: checking
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.checklist_outlined, size: 18),
        label: Text(gestureText(context, 'Validate')),
      ),
      const SizedBox(width: 8),
      if (verdict != null)
        Expanded(
          child: Text(
            gestureError(context, verdict.$2),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: verdict.$1
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
            ),
          ),
        ),
    ],
  );

  /// One Home Assistant entity plus a Validate check: the script and
  /// automation dialogs.
  Future<Map<String, Object?>?> _configureHaEntity(
    Map<String, Object?>? current, {
    required String type,
    required String title,
    required String domain,
  }) async {
    // The entity picker over this domain's entities: picked from Home
    // Assistant's own list, there is nothing to type or validate.
    final picked = await showEntityPicker(
      context,
      c,
      title: gestureText(context, title),
      selected: '${current?['entityId'] ?? ''}',
      domains: [domain],
    );
    final id = picked?.id;
    return id == null ? null : {'type': type, 'entityId': id};
  }

  Future<Map<String, Object?>?> _configureNavigate(
    Map<String, Object?>? current,
  ) async {
    // The dashboard picker every dashboard view setting opens.
    final path = await showDashboardPicker(
      context,
      container: c,
      title: gestureText(context, 'Go to a dashboard view'),
      selected: '${current?['path'] ?? ''}',
    );
    return path == null ? null : {'type': 'navigate', 'path': path};
  }

  /// The kiosk a Call a kiosk gesture rings: every kiosk the intercom
  /// has heard, whatever its state today, since a mapping outlives a
  /// kiosk being off for the afternoon.
  Future<Map<String, Object?>?> _configureIntercomCall(
    Map<String, Object?>? current,
  ) async {
    final r = await c.commands.execute('intercomStatus', const {});
    final kiosks = [
      for (final k in ((r.data as Map?)?['kiosks'] as List? ?? const []))
        if (k is Map) k.cast<String, Object?>(),
    ];
    if (!context.mounted) return null;
    final currentId = '${current?['kioskId'] ?? ''}';
    return showDialog<Map<String, Object?>>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(gestureText(context, 'Call a kiosk')),
        children: [
          for (final k in kiosks)
            ListTile(
              leading: Icon(
                currentId == '${k['id']}'
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
              title: Text('${k['name']}'),
              subtitle: Text('${k['address']}'),
              onTap: () => Navigator.pop(context, {
                'type': 'intercom_call',
                'kioskId': '${k['id']}',
                'kioskName': '${k['name']}',
              }),
            ),
          if (kiosks.isEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Text(
                gestureText(context, 'No kiosk found on the network yet.'),
              ),
            ),
        ],
      ),
    );
  }

  Future<Map<String, Object?>?> _configureCameraView(
    Map<String, Object?>? current,
  ) async {
    final views = c.camera.config.views;
    final currentMode = '${current?['mode'] ?? 'show'}';
    final currentView = '${current?['viewId'] ?? ''}';
    return showDialog<Map<String, Object?>>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(gestureText(context, 'Camera view')),
        children: [
          for (final view in views)
            ListTile(
              leading: Icon(
                currentMode == 'show' && currentView == view.id
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
              title: Text(l10n(context).gestureCameraShow(view.name)),
              onTap: () => Navigator.pop(context, {
                'type': 'camera_view',
                'mode': 'show',
                'viewId': view.id,
                'viewName': view.name,
              }),
            ),
          ListTile(
            leading: Icon(
              currentMode == 'hide'
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
            ),
            title: Text(gestureText(context, 'Close the camera view')),
            onTap: () =>
                Navigator.pop(context, {'type': 'camera_view', 'mode': 'hide'}),
          ),
          if (views.isEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Text(
                gestureText(context, 'No camera views configured yet.'),
              ),
            ),
        ],
      ),
    );
  }

  Future<Map<String, Object?>?> _configureHaService(
    Map<String, Object?>? current,
  ) async {
    // One pick, `domain.service`, stored split as before.
    final domain = '${current?['domain'] ?? ''}';
    final service = '${current?['service'] ?? ''}';
    var serviceId = domain.isEmpty || service.isEmpty ? '' : '$domain.$service';
    var entityId = '${current?['entityId'] ?? ''}';
    final data = TextEditingController(
      text: current?['data'] is Map ? jsonEncode(current!['data']) : '',
    );
    String? error;
    var checking = false;
    (bool, String)? verdict;
    final route = DialogRoute<Map<String, Object?>>(
      context: context,
      builder: (context) => StatefulBuilder(
        // Again when the services load: what the entity field offers
        // follows the picked service.
        builder: (context, setDialogState) => ValueListenableBuilder(
          valueListenable: PickCatalog.of('services'),
          builder: (context, _, _) {
            // The entity domains the service acts on: null for none, empty
            // for any.
            final entityDomains = serviceEntityDomainsOf(serviceId);
            final (pickedDomain, pickedService) = _splitService(serviceId);
            void submit() {
              Object? parsed;
              if (data.text.trim().isNotEmpty) {
                try {
                  parsed = jsonDecode(data.text);
                  if (parsed is! Map) throw const FormatException();
                } catch (_) {
                  setDialogState(
                    () => error = 'Service data must be a JSON object.',
                  );
                  return;
                }
              }
              Navigator.pop(context, {
                'type': 'ha_service',
                'domain': pickedDomain,
                'service': pickedService,
                if (entityId.isNotEmpty) 'entityId': entityId,
                'data': ?parsed,
              });
            }

            return AlertDialog(
              title: Text(
                gestureText(context, 'Call a Home Assistant service'),
              ),
              content: SizedBox(
                width: 480,
                child: EdgeFade(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 16,
                      children: [
                        // Picked from Home Assistant's own services, under
                        // their domains.
                        LabeledField(
                          label: gestureText(context, 'Service'),
                          child: PickFieldBox(
                            spec: serviceSpec(context, c.commands),
                            value: serviceId,
                            placeholder: gestureText(
                              context,
                              'Choose a service',
                            ),
                            onTap: () async {
                              final picked = await showItemPicker(
                                context,
                                title: gestureText(context, 'Service'),
                                spec: serviceSpec(context, c.commands),
                                selected: serviceId.isEmpty ? null : serviceId,
                              );
                              if (picked?.id == null) return;
                              setDialogState(() {
                                serviceId = picked!.id!;
                                verdict = null;
                                // An entity the new service cannot act on
                                // goes with the old one.
                                final domains = serviceEntityDomainsOf(
                                  serviceId,
                                );
                                if (domains == null ||
                                    (domains.isNotEmpty &&
                                        !domains.contains(
                                          entityId.split('.').first,
                                        ))) {
                                  entityId = '';
                                }
                              });
                            },
                          ),
                        ),
                        // Only the entities the service acts on. Off until a
                        // service is picked, and for one that takes none.
                        LabeledField(
                          label: gestureText(context, 'Entity (optional)'),
                          child: PickFieldBox(
                            spec: entitySpec(
                              context,
                              c.commands,
                              domains: entityDomains ?? const [],
                            ),
                            value: entityId,
                            enabled: entityDomains != null,
                            placeholder:
                                serviceId.isNotEmpty && entityDomains == null
                                ? gestureText(
                                    context,
                                    'Not used by this service',
                                  )
                                : null,
                            onTap: () async {
                              final picked = await showItemPicker(
                                context,
                                title: gestureText(
                                  context,
                                  'Entity (optional)',
                                ),
                                spec: entitySpec(
                                  context,
                                  c.commands,
                                  domains: entityDomains ?? const [],
                                ),
                                selected: entityId.isEmpty ? null : entityId,
                                allowClear: true,
                              );
                              if (picked == null) return;
                              setDialogState(() => entityId = picked.id ?? '');
                            },
                          ),
                        ),
                        LabeledField(
                          label: gestureText(
                            context,
                            'Service data (optional)',
                          ),
                          child: TextField(
                            controller: data,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: '{"brightness_pct": 60}',
                              errorText: error == null
                                  ? null
                                  : gestureError(context, error!),
                            ),
                          ),
                        ),
                        _validateRow(
                          context,
                          checking: checking,
                          verdict: verdict,
                          onValidate: serviceId.isEmpty
                              ? null
                              : () async {
                                  setDialogState(() {
                                    checking = true;
                                    verdict = null;
                                  });
                                  final checked = await _validateHaAction(
                                    domain: pickedDomain,
                                    service: pickedService,
                                    entity: entityId,
                                  );
                                  if (!context.mounted) return;
                                  setDialogState(() {
                                    checking = false;
                                    verdict = checked;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(gestureText(context, 'Cancel')),
                ),
                FilledButton(
                  onPressed: serviceId.isEmpty ? null : submit,
                  child: Text(gestureText(context, 'OK')),
                ),
              ],
            );
          },
        ),
      ),
    );
    final result = await Navigator.of(context).push(route);
    await route.completed;
    data.dispose();
    return result;
  }

  /// `light.turn_on` as its domain and service.
  (String, String) _splitService(String id) {
    final dot = id.indexOf('.');
    return dot < 0 ? ('', id) : (id.substring(0, dot), id.substring(dot + 1));
  }

  Future<Map<String, Object?>?> _configureHaEvent(
    Map<String, Object?>? current,
  ) async {
    final event = TextEditingController(text: '${current?['event'] ?? ''}');
    final data = TextEditingController(
      text: current?['data'] is Map ? jsonEncode(current!['data']) : '',
    );
    String? error;
    final route = DialogRoute<Map<String, Object?>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void submit() {
            if (event.text.trim().isEmpty) {
              setDialogState(() => error = 'Event type is required.');
              return;
            }
            Object? parsed;
            if (data.text.trim().isNotEmpty) {
              try {
                parsed = jsonDecode(data.text);
                if (parsed is! Map) throw const FormatException();
              } catch (_) {
                setDialogState(
                  () => error = 'Event data must be a JSON object.',
                );
                return;
              }
            }
            Navigator.pop(context, {
              'type': 'ha_event',
              'event': event.text.trim(),
              'data': ?parsed,
            });
          }

          return AlertDialog(
            title: Text(gestureText(context, 'Fire a Home Assistant event')),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 16,
                children: [
                  LabeledField(
                    label: gestureText(context, 'Event type'),
                    child: TextField(
                      controller: event,
                      decoration: InputDecoration(
                        hintText: 'kiosk_satellite_gesture',
                        errorText: error == null
                            ? null
                            : gestureError(context, error!),
                      ),
                    ),
                  ),
                  LabeledField(
                    label: gestureText(context, 'Event data (optional)'),
                    child: TextField(
                      controller: data,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: '{"room": "kitchen"}',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(gestureText(context, 'Cancel')),
              ),
              FilledButton(
                onPressed: submit,
                child: Text(gestureText(context, 'OK')),
              ),
            ],
          );
        },
      ),
    );
    final result = await Navigator.of(context).push(route);
    await route.completed;
    event.dispose();
    data.dispose();
    return result;
  }
}
