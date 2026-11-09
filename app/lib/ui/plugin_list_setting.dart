import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../core/command_registry.dart';
import '../l10n/gesture_messages.dart';
import '../l10n/messages.dart';
import '../managers/plugins/plugin_manager.dart';
import 'color_picker.dart';
import 'dashboard_view_picker.dart';
import 'entity_picker.dart';
import 'gesture_action_picker.dart';
import 'kit.dart';
import 'mdi_icon.dart';
import 'plugin_setup.dart';
import 'theme.dart';

/// What plugin setting controls reach for: the commands behind the entity
/// picker, the container for dashboards and camera views, and the plugin
/// whose choices row fields pick from. Without a container those two
/// pickers stay read-only, and without a plugin a choices field is text.
class PluginFieldServices {
  const PluginFieldServices({
    required this.commands,
    this.container,
    this.plugins,
    this.pluginId = '',
    this.running = false,
  });

  final CommandRegistry commands;
  final AppContainer? container;
  final PluginManager? plugins;
  final String pluginId;

  /// The plugin is running, so it can refresh its choices.
  final bool running;

  /// The label of the choice [value] at [path] when [field] takes plugin
  /// choices and the plugin lists it.
  String? choiceLabel(Map field, String path, Object? value) {
    final plugins = this.plugins;
    if (field['choices'] != 'plugin' || plugins == null) return null;
    return pluginChoiceList(plugins, pluginId, path)?.find('$value')?.name;
  }
}

/// The default a field starts with. Row fields may leave it out, and then
/// the type supplies one, the same as PluginManifest.defaultOf.
Object? pluginFieldDefault(Map field) {
  if (field.containsKey('default')) return _copy(field['default']);
  return switch (field['type']) {
    'boolean' => false,
    'number' => field['min'],
    'select' => (field['options'] as List).first,
    'color' => '#FFFFFF',
    'list' => <Object?>[],
    'action' => <String, Object?>{},
    _ => '',
  };
}

/// Whether [field] shows, given the other values on its level. A field
/// under a hidden one hides too. Mirrors PluginManifest.visible.
bool pluginFieldVisible(Map field, Map values, List fields) {
  final condition = field['visibleWhen'];
  if (condition is! Map) return true;
  final target = fields
      .whereType<Map>()
      .where((f) => f['key'] == condition['key'])
      .firstOrNull;
  if (target == null) return true;
  if (!pluginFieldVisible(target, values, fields)) return false;
  final value = values.containsKey(target['key'])
      ? values[target['key']]
      : pluginFieldDefault(target);
  if (condition.containsKey('notEmpty')) {
    return value is String
        ? value.isNotEmpty
        : value is bool
        ? value
        : value != null;
  }
  List<Object?> expected(Object? v) => v is List ? v : [v];
  bool same(Object? a, Object? b) =>
      a is num && b is num ? a.toDouble() == b.toDouble() : a == b;
  if (condition.containsKey('equals')) {
    return expected(condition['equals']).any((e) => same(value, e));
  }
  return !expected(condition['notEquals']).any((e) => same(value, e));
}

/// Whether a required field shown on [row] is still empty, or a shown list
/// is short of its minimum. Save waits for both.
bool pluginFieldMissing(Map field, Map row, List fields) {
  if (!pluginFieldVisible(field, row, fields)) return false;
  final value = row[field['key']];
  if (field['type'] == 'list') {
    final rows = value is List ? value : const [];
    final nested = field['fields'] as List;
    return rows.length < ((field['minItems'] as num?)?.toInt() ?? 0) ||
        rows.whereType<Map>().any((r) => !pluginRowComplete(nested, r));
  }
  if (field['type'] == 'action') {
    return field['required'] == true && (value is! Map || value.isEmpty);
  }
  return field['required'] == true && '${value ?? ''}'.trim().isEmpty;
}

bool pluginRowComplete(List fields, Map row) =>
    !fields.whereType<Map>().any((f) => pluginFieldMissing(f, row, fields));

/// Whether the number [field] is typed into a text field instead of
/// dragged on a slider.
bool pluginTypedNumber(Map field) =>
    field['type'] == 'number' && field['input'] == 'field';

/// Why [text] is not a value the number [field] takes, or null when it is.
/// The same checks as PluginManifest.validateValue.
String? pluginNumberError(BuildContext context, Map field, String text) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  if (value == null || !value.isFinite) {
    return pluginText(context, 'Expected a numeric setting');
  }
  final min = (field['min'] as num).toDouble();
  final max = (field['max'] as num).toDouble();
  if (value < min || value > max) {
    return pluginText(context, 'Numeric setting is outside its range');
  }
  final steps = (value - min) / (field['step'] as num? ?? 1);
  if ((steps - steps.round()).abs() >= 0.00001) {
    return pluginText(context, 'Numeric setting does not match its step');
  }
  return null;
}

/// The valid [text] as the number it saves: whole when the step is, the
/// way the slider snaps.
num pluginNumberValue(Map field, String text) {
  final value = double.parse(text.trim().replaceAll(',', '.'));
  return value == value.roundToDouble() && (field['step'] as num? ?? 1) % 1 == 0
      ? value.round()
      : value;
}

/// The keyboard a typed number needs: a sign below zero and a decimal
/// point off whole steps.
TextInputType pluginNumberKeyboard(Map field) =>
    TextInputType.numberWithOptions(
      signed: (field['min'] as num) < 0,
      decimal:
          (field['step'] as num? ?? 1) % 1 != 0 ||
          (field['min'] as num) % 1 != 0,
    );

/// A fresh, complete copy of [row] for editing, every field filled in.
Map<String, Object?> pluginFilledRow(Map list, Map? row) => {
  for (final field in (list['fields'] as List).whereType<Map>())
    '${field['key']}': row != null && row.containsKey(field['key'])
        ? _copy(row[field['key']])
        : pluginFieldDefault(field),
};

Object? _copy(Object? value) =>
    value is List || value is Map ? jsonDecode(jsonEncode(value)) : value;

String? _rowKey(Map list, String part, String type) {
  final declared = (list['row'] as Map?)?[part];
  if (declared is String) return declared;
  // Without a declared title, the first text field names the row.
  final first = (list['fields'] as List)
      .whereType<Map>()
      .where((f) => f['type'] == type)
      .firstOrNull;
  return part == 'subtitle' ? null : first?['key']?.toString();
}

Map? _fieldOf(Map list, String? key) => key == null
    ? null
    : (list['fields'] as List)
          .whereType<Map>()
          .where((f) => f['key'] == key)
          .firstOrNull;

/// The entity a row's title names, when its title is an entity field that
/// holds one. Its item comes from the shared entity list once that loads.
({String id, PickItem? item})? _titleEntity(Map list, Map row) {
  final key = _rowKey(list, 'title', 'string');
  if (_fieldOf(list, key)?['type'] != 'entity') return null;
  final id = '${row[key] ?? ''}'.trim();
  if (id.isEmpty) return null;
  return (id: id, item: PickCatalog.of('entities').value?.find(id));
}

/// The fields a row's title and second line read from.
Iterable<Map> _rowFields(Map list) {
  final declared = (list['row'] as Map?)?['subtitle'];
  return [
    _rowKey(list, 'title', 'string'),
    ...(declared is List ? declared : [?declared]),
  ].map((key) => _fieldOf(list, key?.toString())).whereType<Map>();
}

/// Whether a row's title or second line reads from the entity list.
bool _rowShowsEntities(Map list) =>
    _rowFields(list).any((f) => f['type'] == 'entity');

/// Whether a row's title or second line shows a plugin choice's label.
bool _rowShowsChoices(Map list) =>
    _rowFields(list).any((f) => f['choices'] == 'plugin');

/// The name a row shows, its first text field unless the list names one.
/// An entity shows its friendly name, or its id until the list has it. A
/// plugin choice shows its label once the plugin lists it. [path] is the
/// list's dotted path, its own key unless it is nested.
String pluginRowTitle(
  BuildContext context,
  Map list,
  Map row, {
  PluginFieldServices? services,
  String? path,
}) {
  final entity = _titleEntity(list, row);
  if (entity != null) return entity.item?.name ?? entity.id;
  final key = _rowKey(list, 'title', 'string');
  final value = key == null ? '' : '${row[key] ?? ''}'.trim();
  if (value.isEmpty) return pluginText(context, 'Untitled');
  final field = _fieldOf(list, key);
  final label = field == null
      ? null
      : services?.choiceLabel(field, '${path ?? list['key']}.$key', value);
  return label ?? value;
}

/// The most rows [list] takes.
int _maxItems(Map list) => (list['maxItems'] as num?)?.toInt() ?? 32;

/// Whether the row editor offers Duplicate on a row of [list] holding
/// [count] rows. A plugin turns it on per list, and a full list has no
/// room for the copy.
bool _canDuplicate(Map list, int count) =>
    list['duplicate'] == true && count < _maxItems(list);

String _addTitle(BuildContext context, Map list) =>
    list['addTitle']?.toString() ?? l10n(context).commonAdd;

/// One value as a row's second line shows it: a camera view by its name,
/// a number with its unit, an entity by its name and state, a plugin
/// choice by its label, an action by what it does. Null when there is
/// nothing to say.
String? _displayValue(
  BuildContext context,
  Map field,
  Object? value,
  PluginFieldServices services,
  String path,
) {
  switch (field['type']) {
    case 'string':
      final label = services.choiceLabel(field, '$path.${field['key']}', value);
      if (label != null) return label;
    case 'boolean' || 'list' || 'color':
      return null;
    case 'number':
      return '$value ${field['unit'] ?? ''}'.trim();
    case 'entity':
      final item = PickCatalog.of('entities').value?.find('$value');
      if (item != null) {
        return [item.name, ?item.state].where((t) => t.isNotEmpty).join(' · ');
      }
    case 'cameraView':
      final views = services.container?.camera.config.views ?? const [];
      final view = views.where((v) => v.id == value).firstOrNull;
      if (view != null) return view.name;
    case 'action':
      return value is Map && value.isNotEmpty
          ? localizedGestureAction(context, Map<String, Object?>.from(value))
          : null;
  }
  final text = '${value ?? ''}'.trim();
  return text.isEmpty ? null : text;
}

/// A row's second line: the first declared subtitle with something to
/// say. Without one, an entity title adds its state and id, the way the
/// At a Glance rows do.
String? _rowSubtitle(
  BuildContext context,
  Map list,
  Map row,
  PluginFieldServices services,
  String path,
) {
  final declared = (list['row'] as Map?)?['subtitle'];
  final keys = declared is List ? declared : [?declared];
  final fields = list['fields'] as List;
  for (final key in keys) {
    final field = _fieldOf(list, '$key');
    if (field == null || !pluginFieldVisible(field, row, fields)) continue;
    final text = _displayValue(context, field, row[key], services, path);
    if (text != null) return text;
  }
  // An entity the list lacks already shows its id as the title.
  final item = _titleEntity(list, row)?.item;
  if (item == null) return null;
  final state = item.state ?? '';
  return state.isEmpty ? item.id : '$state · ${item.id}';
}

/// Material Design Icons by name for icon settings, as a grid of tiles
/// like the remote admin's. Names also read as words, so "garage open"
/// finds mdi:garage-open. Like the remote, at most 120 show at a time:
/// drawing all of them stalled even a fast tablet.
PickSpec pluginIconSpec(BuildContext context) => PickSpec(
  key: 'mdiIcons',
  loader: () async => PickList([
    for (final name in await MdiIcons.names())
      PickItem(
        id: 'mdi:$name',
        name: name.replaceAll('-', ' '),
        sub: name,
        icon: 'mdi:$name',
      ),
  ]),
  searchHint: pluginText(context, 'Search icons'),
  noGroup: '',
  chips: false,
  headings: false,
  grid: true,
  limit: 120,
);

/// The kiosk's camera views for camera view settings.
PickSpec pluginCameraViewSpec(
  BuildContext context,
  PluginFieldServices services,
) {
  final strings = l10n(context);
  return PickSpec(
    key: 'pluginCameraViews',
    loader: () async => PickList([
      for (final view in services.container?.camera.config.views ?? const [])
        PickItem(
          id: view.id,
          name: view.name,
          sub: (view.cameraIds.length == 1
              ? strings.screensaverMediaOneCamera
              : strings.screensaverMediaCameras)('${view.cameraIds.length}'),
          icon: 'mdi:cctv',
        ),
    ]),
    searchHint: pluginText(context, 'Search camera views'),
    noGroup: '',
    chips: false,
    headings: false,
  );
}

/// Opens the icon picker with every path held, so scrolling never reads a
/// shard per row. Resolves to the picked name, an empty string for Clear,
/// null when dismissed.
Future<String?> pickPluginIcon(
  BuildContext context, {
  required String title,
  required String value,
}) async {
  unawaited(MdiIcons.hold());
  try {
    final outcome = await showItemPicker(
      context,
      title: title,
      spec: pluginIconSpec(context),
      selected: value.isEmpty ? null : value,
      allowClear: true,
    );
    return outcome == null ? null : outcome.id ?? '';
  } finally {
    MdiIcons.release();
  }
}

/// An action setting's control: what the chosen action does, opening the
/// gesture action chooser, with a Clear button when the action is optional.
/// Without a container it stays read-only.
class PluginActionField extends StatelessWidget {
  const PluginActionField({
    super.key,
    required this.container,
    required this.title,
    required this.value,
    required this.onPick,
    this.required = false,
    this.enabled = true,
  });

  final AppContainer? container;
  final String title;
  final Object? value;
  final bool required;
  final bool enabled;
  final ValueChanged<Map<String, Object?>> onPick;

  @override
  Widget build(BuildContext context) {
    final action = value is Map
        ? Map<String, Object?>.from(value as Map)
        : <String, Object?>{};
    final container = this.container;
    return Row(
      children: [
        Expanded(
          child: ChoiceBox(
            text: action.isEmpty
                ? gestureText(context, 'Choose an action')
                : localizedGestureAction(context, action),
            onTap: container == null || !enabled
                ? null
                : () async {
                    final picked = await GestureActionPicker(
                      context,
                      container,
                    ).pick(action.isEmpty ? null : action);
                    if (picked != null) onPick(picked);
                  },
          ),
        ),
        if (action.isNotEmpty && !required)
          IconButton(
            tooltip: l10n(context).commonClear,
            icon: const Icon(Icons.close),
            onPressed: enabled ? () => onPick(<String, Object?>{}) : null,
          ),
      ],
    );
  }
}

/// An icon at rest in the control box: the glyph and its name.
class PluginIconBox extends StatelessWidget {
  const PluginIconBox({super.key, required this.value, required this.onTap});

  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: onTap == null ? 0.38 : 1,
      child: ControlBox(
        onTap: onTap,
        child: Row(
          children: [
            value.isEmpty
                ? Icon(
                    Icons.emoji_symbols_outlined,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  )
                : MdiIcon(
                    name: value,
                    size: 20,
                    color: scheme.primary,
                    fallback: Icons.help_outline,
                  ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value.isEmpty ? pluginText(context, 'Choose an icon') : value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: value.isEmpty
                    ? TextStyle(fontSize: 15, color: scheme.onSurfaceVariant)
                    : TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13.5,
                        color: scheme.onSurface,
                      ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// The rows of a list setting and the row that adds one. Rows drag by
/// their handle only, so a touch panel scrolls the page without starting
/// a drag. [onOpen] gets the tapped row's index, or null to add one.
class PluginRows extends StatelessWidget {
  const PluginRows({
    super.key,
    required this.list,
    required this.rows,
    required this.services,
    required this.enabled,
    required this.onOpen,
    required this.onReorder,
    this.contentPadding,
    this.path,
  });

  final Map list;
  final List<Map> rows;
  final PluginFieldServices services;
  final bool enabled;
  final ValueChanged<int?> onOpen;
  final void Function(int oldIndex, int newIndex) onReorder;

  /// Rows inside the row editor sit closer to its border.
  final EdgeInsetsGeometry? contentPadding;

  /// The list's dotted path, such as `panels.tiles` for a nested list.
  /// Its own key unless set.
  final String? path;

  String get _path => path ?? '${list['key']}';

  @override
  Widget build(BuildContext context) {
    // Entity names and states come from the shared list and choice labels
    // from the plugin, so the rows redraw once those arrive.
    final entities = _rowShowsEntities(list);
    final plugins = services.plugins;
    final sources = <Listenable>[
      if (entities) PickCatalog.of('entities'),
      if (plugins != null && _rowShowsChoices(list)) plugins.setup,
    ];
    if (entities && PickCatalog.of('entities').value == null) {
      unawaited(loadEntityCatalog(services.commands));
    }
    if (sources.isEmpty) return _rows(context);
    return ListenableBuilder(
      listenable: Listenable.merge(sources),
      builder: (context, _) => _rows(context),
    );
  }

  Widget _rows(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final max = _maxItems(list);
    final iconKey = (list['row'] as Map?)?['icon'] as String?;
    final titleIsEntity =
        _fieldOf(list, _rowKey(list, 'title', 'string'))?['type'] == 'entity';
    final indent = contentPadding == null ? Ks.inset : 12.0;
    final divider = Divider(height: 1, indent: indent, endIndent: indent);
    // A picked icon wins. Without one, an entity title brings its own,
    // or a warning when Home Assistant no longer has it.
    Widget? leading(Map value) {
      final icon = iconKey == null ? '' : '${value[iconKey] ?? ''}';
      if (icon.isNotEmpty) {
        return MdiIcon(
          name: icon,
          size: 24,
          color: scheme.onSurfaceVariant,
          fallback: Icons.circle_outlined,
        );
      }
      if (titleIsEntity) {
        final entity = _titleEntity(list, value);
        final loaded = PickCatalog.of('entities').value != null;
        if (entity != null && entity.item == null && loaded) {
          return Icon(Icons.warning_amber_rounded, color: scheme.error);
        }
        return PickIcon(
          icon: entity?.item?.icon,
          size: 24,
          color: scheme.onSurfaceVariant,
        );
      }
      return iconKey == null ? null : const Icon(Icons.circle_outlined);
    }

    Widget row(int index) {
      final value = rows[index];
      final subtitle = _rowSubtitle(context, list, value, services, _path);
      return SettingsRow(
        contentPadding: contentPadding,
        enabled: enabled,
        leading: leading(value),
        title: Text(
          pluginRowTitle(context, list, value, services: services, path: _path),
        ),
        subtitle: subtitle == null
            ? null
            : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: rows.length < 2
            ? const Icon(Icons.chevron_right)
            : ReorderableDragStartListener(
                index: index,
                enabled: enabled,
                child: Semantics(
                  label: pluginText(context, 'Drag to reorder'),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.drag_indicator),
                  ),
                ),
              ),
        onTap: enabled ? () => onOpen(index) : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (rows.isNotEmpty) ...[
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: rows.length,
            // newIndex is already adjusted for the removal.
            onReorderItem: onReorder,
            itemBuilder: (context, index) => Column(
              key: ObjectKey(rows[index]),
              mainAxisSize: MainAxisSize.min,
              children: [if (index > 0) divider, row(index)],
            ),
          ),
          if (rows.length < max) divider,
        ],
        if (rows.length < max)
          SettingsRow(
            contentPadding: contentPadding,
            enabled: enabled,
            leading: Icon(Icons.add_circle_outline, color: scheme.primary),
            title: Text(_addTitle(context, list)),
            onTap: enabled ? () => onOpen(null) : null,
          ),
      ],
    );
  }
}

/// A list setting on the plugin's page: the rows inline, each opening the
/// row editor. Every completed edit, delete and drag saves the whole list.
class PluginListSetting extends StatelessWidget {
  const PluginListSetting({
    super.key,
    required this.setting,
    required this.rows,
    required this.services,
    required this.enabled,
    required this.onChanged,
    this.showTitle = true,
  });

  final Map setting;
  final List<Map> rows;
  final PluginFieldServices services;
  final bool enabled;
  final ValueChanged<List<Map>> onChanged;

  /// False when the list is alone in its group, whose heading names it.
  final bool showTitle;

  Future<void> _open(BuildContext context, int? index) async {
    final result = await showPluginRowEditor(
      context,
      list: setting,
      row: index == null ? null : rows[index],
      services: services,
      duplicate: _canDuplicate(setting, rows.length),
    );
    if (result == null) return;
    final next = [...rows];
    if (result.row == null) {
      next.removeAt(index!);
    } else if (index == null || result.copied) {
      next.add(result.row!);
    } else {
      next[index] = result.row!;
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final description = setting['description']?.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTitle) ...[
          SettingsRow(
            title: Text('${setting['title']}'),
            subtitle: description == null ? null : Text(description),
          ),
          const Divider(height: 1, indent: Ks.inset, endIndent: Ks.inset),
        ],
        PluginRows(
          list: setting,
          rows: rows,
          services: services,
          enabled: enabled,
          onOpen: (index) => _open(context, index),
          onReorder: (from, to) {
            final next = [...rows];
            next.insert(to, next.removeAt(from));
            onChanged(next);
          },
        ),
        if (!showTitle && description != null) HintRow(description),
      ],
    );
  }
}

/// What the row editor hands back: the saved row, or null for a deleted
/// one. Dismissing the editor resolves to no result at all.
class PluginRowEdit {
  const PluginRowEdit(this.row, {this.copied = false});

  final Map<String, Object?>? row;

  /// The row is a copy made with Duplicate, added after the others
  /// while the row it came from stays as it was.
  final bool copied;
}

/// Edits one row of [list] in a modal. A new row when [row] is null.
/// Save stays off until every shown required field is filled in.
/// [duplicate] offers Duplicate on an existing row, which turns the
/// editor into a new row holding a copy of what it shows.
Future<PluginRowEdit?> showPluginRowEditor(
  BuildContext context, {
  required Map list,
  Map? row,
  required PluginFieldServices services,
  bool duplicate = false,
}) => showDialog<PluginRowEdit>(
  context: context,
  // A stray tap outside must not throw away a half-made row.
  barrierDismissible: false,
  builder: (_) => _PluginRowEditor(
    list: list,
    row: row,
    services: services,
    duplicate: duplicate,
  ),
);

/// A nested row being edited inside the row editor.
class _Entry {
  _Entry(this.list, this.index, this.draft, this.title);

  final Map list;

  /// Null for a new row.
  final int? index;
  final Map<String, Object?> draft;
  final String title;
}

class _PluginRowEditor extends StatefulWidget {
  const _PluginRowEditor({
    required this.list,
    required this.row,
    required this.services,
    required this.duplicate,
  });

  final Map list;
  final Map? row;
  final PluginFieldServices services;
  final bool duplicate;

  @override
  State<_PluginRowEditor> createState() => _PluginRowEditorState();
}

class _PluginRowEditorState extends State<_PluginRowEditor> {
  late final Map<String, Object?> _draft = pluginFilledRow(
    widget.list,
    widget.row,
  );

  /// Duplicate turned the outer row into a new one. The draft keeps what
  /// was on screen and Save adds it, leaving the saved row as it was.
  bool _copied = false;

  /// The nested row shown in place of the outer one. Its Done or Cancel
  /// comes back here, so there is only ever one editing surface.
  _Entry? _entry;

  /// Text typed into number fields that they do not take, by the draft
  /// and key that [_fieldKey] names. The draft keeps the last valid number
  /// and Save waits while a shown field holds such text.
  final _typed = <String, String>{};

  String _fieldKey(Map draft, Object? key) => '${identityHashCode(draft)}:$key';

  /// The dotted path of the list being edited: the setting's key, then
  /// the nested list's.
  String get _path =>
      [widget.list['key'], if (_entry != null) _entry!.list['key']].join('.');

  void _openEntry(Map field, int? index) {
    final rows = _draft[field['key']] as List;
    final row = index == null ? null : rows[index] as Map;
    setState(
      () => _entry = _Entry(
        field,
        index,
        pluginFilledRow(field, row),
        row == null
            ? _addTitle(context, field)
            : pluginRowTitle(
                context,
                field,
                row,
                services: widget.services,
                path: '${widget.list['key']}.${field['key']}',
              ),
      ),
    );
  }

  void _closeEntry({bool save = false, bool delete = false}) {
    final entry = _entry!;
    final rows = _draft[entry.list['key']] as List;
    final typed = _fieldKey(entry.draft, '');
    setState(() {
      _typed.removeWhere((id, _) => id.startsWith(typed));
      if (delete) {
        rows.removeAt(entry.index!);
      } else if (save && entry.index == null) {
        rows.add(entry.draft);
      } else if (save) {
        rows[entry.index!] = entry.draft;
      }
      _entry = null;
    });
  }

  /// Turns the row on screen into a new one holding a copy of it.
  void _duplicate() {
    final entry = _entry;
    setState(() {
      if (entry == null) {
        _copied = true;
      } else {
        _entry = _Entry(
          entry.list,
          null,
          entry.draft,
          _addTitle(context, entry.list),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    final scheme = Theme.of(context).colorScheme;
    final entry = _entry;
    final list = entry?.list ?? widget.list;
    final fields = (list['fields'] as List).whereType<Map>().toList();
    final draft = entry?.draft ?? _draft;
    final isNew = entry == null
        ? widget.row == null || _copied
        : entry.index == null;
    final complete =
        pluginRowComplete(fields, draft) &&
        !fields.any(
          (f) =>
              _typed.containsKey(_fieldKey(draft, f['key'])) &&
              pluginFieldVisible(f, draft, fields),
        );
    final title =
        entry?.title ??
        (isNew
            ? _addTitle(context, list)
            : pluginRowTitle(
                context,
                list,
                widget.row!,
                services: widget.services,
                path: _path,
              ));
    final body = Column(
      key: ObjectKey(draft),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [
        for (final field in fields)
          if (pluginFieldVisible(field, draft, fields))
            _field(field, draft, fields),
      ],
    );
    final header = Row(
      children: [
        if (entry != null) ...[
          IconButton(
            tooltip: strings.commonBack,
            icon: const Icon(Icons.arrow_back),
            onPressed: _closeEntry,
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
    final delete = isNew
        ? null
        : TextButton(
            style: TextButton.styleFrom(foregroundColor: scheme.error),
            onPressed: entry == null
                ? () => Navigator.pop(context, const PluginRowEdit(null))
                : () => _closeEntry(delete: true),
            child: Text(strings.commonDelete),
          );
    final canDuplicate =
        !isNew &&
        (entry == null
            ? widget.duplicate
            : _canDuplicate(
                entry.list,
                (_draft[entry.list['key']] as List).length,
              ));
    final duplicate = canDuplicate
        ? TextButton(
            onPressed: _duplicate,
            child: Text(pluginText(context, 'Duplicate')),
          )
        : null;
    final start = delete == null
        ? null
        : Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [delete, ?duplicate],
          );
    final buttons = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        TextButton(
          onPressed: entry == null
              ? () => Navigator.pop(context)
              : () => _closeEntry(),
          child: Text(strings.commonCancel),
        ),
        FilledButton(
          onPressed: !complete
              ? null
              : entry == null
              ? () => Navigator.pop(
                  context,
                  PluginRowEdit(_draft, copied: _copied),
                )
              : () => _closeEntry(save: true),
          child: Text(
            entry == null ? strings.commonSave : pluginText(context, 'Done'),
          ),
        ),
      ],
    );
    final scroll = EdgeFade(child: SingleChildScrollView(child: body));
    final Widget dialog;
    if (MediaQuery.sizeOf(context).width < 640) {
      dialog = Dialog.fullscreen(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  entry == null ? 24 : 8,
                  16,
                  24,
                  12,
                ),
                child: DefaultTextStyle.merge(
                  style: Theme.of(context).textTheme.titleLarge,
                  child: header,
                ),
              ),
              Expanded(
                child: EdgeFade(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                    child: body,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                // Delete and Duplicate go above Cancel and Save when a
                // phone has no room for all four on one line.
                child: OverflowBar(
                  alignment: start == null
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.spaceBetween,
                  overflowAlignment: OverflowBarAlignment.end,
                  overflowSpacing: 8,
                  children: [?start, buttons],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      dialog = AlertDialog(
        title: header,
        titlePadding: EdgeInsets.fromLTRB(entry == null ? 24 : 12, 20, 24, 0),
        content: SizedBox(width: 560, child: scroll),
        actionsAlignment: isNew
            ? MainAxisAlignment.end
            : MainAxisAlignment.spaceBetween,
        actions: [?start, buttons],
      );
    }
    // Back on an entry returns to its row instead of closing the editor.
    return PopScope(
      canPop: entry == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _entry != null) _closeEntry();
      },
      child: dialog,
    );
  }

  Widget _field(Map field, Map<String, Object?> draft, List<Map> fields) {
    final key = '${field['key']}';
    final title = '${field['title']}';
    final description = field['description']?.toString();
    final value = draft[key];
    void set(Object? next) => setState(() => draft[key] = next);
    final missing = pluginFieldMissing(field, draft, fields);
    Widget labeled(Widget child) => _Labeled(
      label: title,
      helper: description,
      missing: missing,
      child: child,
    );
    final text = '${value ?? ''}';
    final services = widget.services;
    final plugins = services.plugins;
    switch (field['type']) {
      case 'string' when field['choices'] == 'plugin' && plugins != null:
        return labeled(
          PluginChoiceField(
            plugins: plugins,
            pluginId: services.pluginId,
            path: '$_path.$key',
            title: title,
            value: text,
            running: services.running,
            onPick: set,
            emptyText: field['emptyText'] as String?,
          ),
        );
      case 'boolean':
        return SettingsRow(
          contentPadding: EdgeInsets.zero,
          title: Text(title),
          subtitle: description == null ? null : Text(description),
          trailing: Switch(value: value == true, onChanged: set),
        );
      case 'number' when pluginTypedNumber(field):
        final id = _fieldKey(draft, key);
        final typed = _typed[id];
        return labeled(
          TextFormField(
            key: ValueKey(id),
            initialValue: typed ?? text,
            keyboardType: pluginNumberKeyboard(field),
            decoration: InputDecoration(
              suffixText: field['unit']?.toString(),
              errorText: typed == null
                  ? null
                  : pluginNumberError(context, field, typed),
            ),
            onChanged: (next) => setState(() {
              if (pluginNumberError(context, field, next) == null) {
                _typed.remove(id);
                draft[key] = pluginNumberValue(field, next);
              } else {
                _typed[id] = next;
              }
            }),
          ),
        );
      case 'number':
        return labeled(
          _NumberField(field: field, value: value as num, onChanged: set),
        );
      case 'select':
        return labeled(
          KsDropdown<String>(
            value: text,
            expand: true,
            items: [
              for (final option in field['options'] as List)
                DropdownMenuItem(value: '$option', child: Text('$option')),
            ],
            onChanged: set,
          ),
        );
      case 'color':
        final color = Color(
          0xff000000 | int.parse(text.substring(1), radix: 16),
        );
        return labeled(
          ControlBox(
            onTap: () async {
              final rgb = [1, 3, 5]
                  .map((i) => int.parse(text.substring(i, i + 2), radix: 16))
                  .join(',');
              final picked = await pickColor(
                context,
                initial: rgb,
                title: title,
              );
              if (picked != null) {
                set(
                  '#${picked.split(',').map((c) => int.parse(c.trim()).toRadixString(16).padLeft(2, '0')).join().toUpperCase()}',
                );
              }
            },
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(text),
              ],
            ),
          ),
        );
      case 'entity':
        final domain = field['domain'];
        final spec = entitySpec(
          context,
          services.commands,
          domains: [
            if (domain is String) domain,
            if (domain is List)
              for (final d in domain) '$d',
          ],
          includeHidden: field['includeHidden'] == true,
        );
        return labeled(
          PickFieldBox(
            spec: spec,
            value: text,
            onTap: () async {
              final outcome = await showItemPicker(
                context,
                title: title,
                spec: spec,
                selected: text.isEmpty ? null : text,
                allowClear: true,
              );
              if (outcome != null) set(outcome.id ?? '');
            },
          ),
        );
      case 'cameraView':
        final spec = pluginCameraViewSpec(context, services);
        return labeled(
          PickFieldBox(
            spec: spec,
            value: text,
            placeholder: pluginText(context, 'Choose a camera view'),
            enabled: services.container != null,
            onTap: () async {
              final outcome = await showItemPicker(
                context,
                title: title,
                spec: spec,
                selected: text.isEmpty ? null : text,
                allowClear: true,
              );
              if (outcome != null) set(outcome.id ?? '');
            },
          ),
        );
      case 'dashboard':
        final container = services.container;
        return labeled(
          Row(
            children: [
              Expanded(
                child: container == null
                    ? ChoiceBox(
                        text: text.isEmpty
                            ? haText(context, 'Choose a view')
                            : text,
                        onTap: null,
                      )
                    : DashboardField(
                        container: container,
                        value: text,
                        onTap: () async {
                          final picked = await showDashboardPicker(
                            context,
                            container: container,
                            title: title,
                            selected: text,
                          );
                          if (picked != null) set(picked);
                        },
                      ),
              ),
              // The dashboard picker has no Clear of its own.
              if (text.isNotEmpty && field['required'] != true)
                IconButton(
                  tooltip: l10n(context).commonClear,
                  icon: const Icon(Icons.close),
                  onPressed: () => set(''),
                ),
            ],
          ),
        );
      case 'action':
        return labeled(
          PluginActionField(
            container: services.container,
            title: title,
            value: value,
            required: field['required'] == true,
            onPick: set,
          ),
        );
      case 'icon':
        return labeled(
          PluginIconBox(
            value: text,
            onTap: () async {
              final picked = await pickPluginIcon(
                context,
                title: title,
                value: text,
              );
              if (picked != null) set(picked);
            },
          ),
        );
      case 'list':
        final rows = (value as List).whereType<Map>().toList();
        return labeled(
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(Ks.radiusRow),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Ks.radiusRow),
              child: Material(
                type: MaterialType.transparency,
                child: PluginRows(
                  list: field,
                  rows: rows,
                  services: services,
                  path: '$_path.$key',
                  enabled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  onOpen: (index) => _openEntry(field, index),
                  onReorder: (from, to) =>
                      setState(() => (value).insert(to, value.removeAt(from))),
                ),
              ),
            ),
          ),
        );
      default:
        return labeled(
          TextFormField(
            key: ValueKey('${identityHashCode(draft)}:$key'),
            initialValue: text,
            maxLength: 512,
            decoration: const InputDecoration(counterText: ''),
            onChanged: set,
          ),
        );
    }
  }
}

/// A field's label above it and its description beneath, the way
/// [LabeledField] lays them out, with Required beside an empty required
/// field.
class _Labeled extends StatelessWidget {
  const _Labeled({
    required this.label,
    required this.child,
    required this.missing,
    this.helper,
  });

  final String label;
  final Widget child;
  final bool missing;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = theme.textTheme.bodySmall?.copyWith(
      fontSize: 12.5,
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: label),
              if (missing)
                TextSpan(
                  text: ' · ${pluginText(context, 'Required')}',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
            ],
          ),
          style: note,
        ),
        const SizedBox(height: 6),
        child,
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(helper!, style: note),
        ],
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final Map field;
  final num value;
  final ValueChanged<num> onChanged;

  @override
  Widget build(BuildContext context) {
    final min = (field['min'] as num).toDouble();
    final max = (field['max'] as num).toDouble();
    final step = (field['step'] as num? ?? 1).toDouble();
    final unit = field['unit'] ?? '';
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: value.toDouble().clamp(min, max),
            min: min,
            max: max,
            divisions: ((max - min) / step).round(),
            label: '$value $unit'.trim(),
            onChanged: (v) {
              final snapped = double.parse(
                (min + ((v - min) / step).round() * step).toStringAsFixed(6),
              );
              onChanged(
                snapped == snapped.roundToDouble() && step % 1 == 0
                    ? snapped.round()
                    : snapped,
              );
            },
          ),
        ),
        Text('$value $unit'.trim()),
      ],
    );
  }
}
