import 'dart:async';

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../core/events.dart';
import '../managers/camera/models.dart';
import '../managers/settings/definitions.dart' as defs;
import 'kit.dart';
import 'toast.dart';
import 'settings_search.dart';

class CameraSettingsPanel extends StatefulWidget {
  const CameraSettingsPanel({super.key, required this.container});

  final AppContainer container;

  @override
  State<CameraSettingsPanel> createState() => _CameraSettingsPanelState();
}

class _CameraSettingsPanelState extends State<CameraSettingsPanel> {
  StreamSubscription<CameraConfigurationChanged>? _subscription;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _subscription = widget.container.bus
        .on<CameraConfigurationChanged>()
        .listen((_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _message(
    String title, {
    String? message,
    ToastKind kind = ToastKind.info,
  }) {
    if (!mounted) return;
    showToast(context, title: title, message: message, kind: kind);
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.container.camera.config;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeading('Home Assistant'),
        SettingsCard(
          children: [
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Import cameras from Home Assistant'),
              subtitle: const Text(
                'Add every camera of the connected Home Assistant, playing '
                'over WebRTC, HLS or MJPEG. Importing again merges new '
                'cameras.',
              ),
              onTap: _busy ? null : _importHomeAssistant,
            ),
          ],
        ),
        const SectionHeading('Go2RTC servers'),
        SettingsCard(
          children: [
            for (final server in config.servers)
              SettingsRow(
                leading: const Icon(Icons.dns_outlined),
                title: Text(server.name),
                subtitle: Text(server.baseUrl),
                onTap: () => _editServer(server),
                trailing: Wrap(
                  spacing: 2,
                  children: [
                    IconButton(
                      tooltip: 'Import streams',
                      icon: const Icon(Icons.download_outlined),
                      onPressed: _busy ? null : () => _import(server),
                    ),
                    IconButton(
                      tooltip: 'Delete server',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: _busy ? null : () => _deleteServer(server),
                    ),
                  ],
                ),
              ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add Go2RTC server'),
              subtitle: const Text(
                'Connect to a server and import its streams.',
              ),
              onTap: _busy ? null : () => _editServer(null),
            ),
          ],
        ),
        const SectionHeading('Cameras'),
        SettingsCard(
          children: [
            if (config.cameras.isEmpty)
              const ListTile(
                leading: Icon(Icons.videocam_off_outlined),
                title: Text('No cameras configured'),
                subtitle: Text(
                  'Import cameras from Home Assistant or Go2RTC, or add one '
                  'manually.',
                ),
              ),
            for (final camera in config.cameras)
              ListTile(
                leading: Icon(
                  camera.missing
                      ? Icons.link_off_outlined
                      : Icons.videocam_outlined,
                ),
                title: Text(camera.name),
                subtitle: Text(_cameraSubtitle(camera, config)),
                onTap: () => _editCamera(camera),
                trailing: IconButton(
                  tooltip: 'Delete camera',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _busy ? null : () => _deleteCamera(camera),
                ),
              ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add camera manually'),
              subtitle: const Text(
                'Use a Go2RTC stream name, a WHEP URL or a Home Assistant '
                'camera entity.',
              ),
              onTap: _busy ? null : () => _editCamera(null),
            ),
          ],
        ),
        const SectionHeading('Views'),
        SettingsCard(
          children: [
            for (final view in config.views)
              SettingsRow(
                leading: Icon(
                  view.isDefault
                      ? Icons.star_outline
                      : Icons.grid_view_outlined,
                ),
                title: Text(view.name),
                subtitle: Text(
                  view.cameraIds.isEmpty
                      ? 'No cameras yet'
                      : '${view.cameraIds.length} camera'
                            '${view.cameraIds.length == 1 ? '' : 's'}'
                            ' · Names '
                            '${view.showCameraNames ? 'shown' : 'hidden'}',
                ),
                onTap: () => _editView(view),
                trailing: Wrap(
                  spacing: 2,
                  children: [
                    IconButton(
                      tooltip: 'Show view',
                      icon: const Icon(Icons.play_arrow),
                      onPressed: view.cameraIds.isEmpty
                          ? null
                          : () => _showView(view),
                    ),
                    // The default view is permanent: emptying it is how it
                    // gets retired, so it carries no delete.
                    if (!view.isDefault)
                      IconButton(
                        tooltip: 'Delete view',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: _busy ? null : () => _deleteView(view),
                      ),
                  ],
                ),
              ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Create camera view'),
              subtitle: Text(
                config.cameras.isEmpty
                    ? 'Add a camera first.'
                    : 'Choose and order up to 12 cameras.',
              ),
              enabled: config.cameras.isNotEmpty && !_busy,
              onTap: config.cameras.isEmpty || _busy
                  ? null
                  : () => _editView(null),
            ),
          ],
        ),
        const SectionHeading('Playback'),
        SettingsCard(
          children: [
            SearchLandingTarget(
              id: defs.cameraAllowH265.key,
              child: SwitchListTile(
                title: Text(defs.cameraAllowH265.title),
                subtitle: Text(defs.cameraAllowH265.description),
                value: widget.container.settings.get(defs.cameraAllowH265),
                onChanged: (value) async {
                  await widget.container.settings.setFromJson(
                    defs.cameraAllowH265.key,
                    value,
                  );
                  if (mounted) setState(() {});
                },
              ),
            ),
            SearchLandingTarget(
              id: defs.cameraPreferMse.key,
              child: SwitchListTile(
                title: Text(defs.cameraPreferMse.title),
                subtitle: Text(defs.cameraPreferMse.description),
                value: widget.container.settings.get(defs.cameraPreferMse),
                onChanged: (value) async {
                  await widget.container.settings.setFromJson(
                    defs.cameraPreferMse.key,
                    value,
                  );
                  if (mounted) setState(() {});
                },
              ),
            ),
            SearchLandingTarget(
              id: defs.cameraPreferHls.key,
              child: SwitchListTile(
                title: Text(defs.cameraPreferHls.title),
                subtitle: Text(defs.cameraPreferHls.description),
                value: widget.container.settings.get(defs.cameraPreferHls),
                onChanged: (value) async {
                  await widget.container.settings.setFromJson(
                    defs.cameraPreferHls.key,
                    value,
                  );
                  if (mounted) setState(() {});
                },
              ),
            ),
            SearchLandingTarget(
              id: defs.cameraSingleAudio.key,
              child: SwitchListTile(
                title: Text(defs.cameraSingleAudio.title),
                subtitle: Text(defs.cameraSingleAudio.description),
                value: widget.container.settings.get(defs.cameraSingleAudio),
                onChanged: (value) async {
                  await widget.container.settings.setFromJson(
                    defs.cameraSingleAudio.key,
                    value,
                  );
                  if (mounted) setState(() {});
                },
              ),
            ),
            SearchLandingTarget(
              id: defs.cameraPinchZoom.key,
              child: SwitchListTile(
                title: Text(defs.cameraPinchZoom.title),
                subtitle: Text(defs.cameraPinchZoom.description),
                value: widget.container.settings.get(defs.cameraPinchZoom),
                onChanged: (value) async {
                  await widget.container.settings.setFromJson(
                    defs.cameraPinchZoom.key,
                    value,
                  );
                  if (mounted) setState(() {});
                },
              ),
            ),
            SearchLandingTarget(
              id: defs.cameraAutoDismissSeconds.key,
              child: _autoDismissRow(context),
            ),
          ],
        ),
        const GroupNote(
          'Grids with several cameras are video-only. For low-power devices, '
          'use lower resolution Go2RTC streams in views and optionally set a '
          'separate fullscreen stream.',
        ),
      ],
    );
  }

  /// Value under the finger mid-drag; null reads the stored setting.
  double? _autoDismissDrag;

  /// The auto-dismiss slider (0 = off, shown as such). Mirrors the generic
  /// def-backed slider; hand-built here because the Playback card is.
  Widget _autoDismissRow(BuildContext context) {
    final def = defs.cameraAutoDismissSeconds;
    final value =
        _autoDismissDrag ??
        (widget.container.settings.get(
          def,
        )).toDouble().clamp(def.min!.toDouble(), def.max!.toDouble());
    return Column(
      children: [
        ListTile(
          title: Text(def.title),
          subtitle: Text(def.description),
          trailing: Text(
            value <= 0 ? 'Off' : '${value.round()} s',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Slider(
            value: value,
            min: def.min!.toDouble(),
            max: def.max!.toDouble(),
            divisions: ((def.max! - def.min!) / def.step!).round(),
            onChanged: (v) => setState(() => _autoDismissDrag = v),
            onChangeEnd: (v) async {
              setState(() => _autoDismissDrag = null);
              await widget.container.settings.setFromJson(def.key, v.round());
              if (mounted) setState(() {});
            },
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ),
  );

  String _cameraName(List<CameraSource> cameras, String id) =>
      cameras
          .where((camera) => camera.id == id)
          .map((camera) => camera.name)
          .firstOrNull ??
      'Unknown camera';

  Future<void> _showView(CameraViewConfig view) async {
    final result = await widget.container.camera.showView(view.id);
    if (!result.ok) {
      _message(
        'Could not show the view',
        message: result.error,
        kind: ToastKind.error,
      );
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  /// The stream formats this camera can play with, for its list row.
  /// Mirrored in remote-ui/static/cameras.js.
  String _cameraFormats(CameraSource camera) {
    switch (camera.kind) {
      case 'go2rtc':
        return 'WebRTC, MSE';
      case 'ha':
        // MJPEG is always on the list: every Home Assistant camera
        // entity serves the camera proxy stream, stills-only ones
        // exclusively so.
        final types = camera.streamTypes;
        if (types == null) return 'WebRTC, HLS, MJPEG';
        return [
          if (types.contains('web_rtc')) 'WebRTC',
          if (types.contains('hls')) 'HLS',
          'MJPEG',
        ].join(', ');
      default:
        return 'WebRTC';
    }
  }

  String _cameraSubtitle(
    CameraSource camera,
    CameraConfiguration configuration,
  ) {
    final formats = ' · ${_cameraFormats(camera)}';
    if (camera.kind == 'whep') return '${camera.whepUrl ?? 'WHEP'}$formats';
    final status = camera.missing ? ' (missing)' : '';
    if (camera.kind == 'ha') {
      return 'Home Assistant: ${camera.entityId ?? ''}$status$formats';
    }
    final server = configuration.servers
        .where((item) => item.id == camera.serverId)
        .firstOrNull;
    return '${server?.name ?? 'Unknown server'}: '
        '${camera.streamName ?? ''}$status$formats';
  }

  Future<void> _import(CameraServer server) => _run(() async {
    final result = await widget.container.commands.execute(
      'cameraImportGo2Rtc',
      {'serverId': server.id},
    );
    if (!result.ok) {
      _message('Import failed', message: result.error, kind: ToastKind.error);
      return;
    }
    final data = result.data as Map;
    _message(
      'Import complete',
      message: "${data['added']} added, ${data['missing']} missing.",
      kind: ToastKind.success,
    );
  });

  Future<void> _importHomeAssistant() => _run(() async {
    final result = await widget.container.commands.execute(
      'cameraImportHomeAssistant',
      const {},
    );
    if (!result.ok) {
      _message('Import failed', message: result.error, kind: ToastKind.error);
      return;
    }
    final data = result.data as Map;
    _message(
      'Import complete',
      message: "${data['added']} added, ${data['missing']} missing.",
      kind: ToastKind.success,
    );
  });

  Future<void> _editServer(CameraServer? server) async {
    final name = TextEditingController(text: server?.name ?? 'Go2RTC');
    final url = TextEditingController(text: server?.baseUrl ?? '');
    final username = TextEditingController(text: server?.username ?? '');
    final password = TextEditingController();
    var invalidCertificate = server?.allowInvalidCertificate ?? false;
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(server == null ? 'Add Go2RTC server' : 'Edit server'),
          content: SizedBox(
            width: 480,
            child: EdgeFade(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 16,
                  children: [
                    LabeledField(
                      label: 'Name',
                      child: TextField(
                        controller: name,
                        decoration: const InputDecoration(),
                      ),
                    ),
                    LabeledField(
                      label: 'Base URL',
                      child: TextField(
                        controller: url,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          hintText: 'http://192.168.1.10:1984',
                        ),
                      ),
                    ),
                    LabeledField(
                      label: 'Username (optional)',
                      child: TextField(
                        controller: username,
                        decoration: const InputDecoration(),
                      ),
                    ),
                    LabeledField(
                      label: server?.password.isNotEmpty == true
                          ? 'New password (leave blank to keep)'
                          : 'Password (optional)',
                      child: TextField(
                        controller: password,
                        obscureText: true,
                        decoration: InputDecoration(),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Allow invalid TLS certificate'),
                      value: invalidCertificate,
                      onChanged: (value) =>
                          setDialogState(() => invalidCertificate = value),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (submitted != true) return;
    await _run(() async {
      final params = <String, Object?>{
        'id': server?.id ?? '',
        'name': name.text,
        'baseUrl': url.text,
        'username': username.text,
        'allowInvalidCertificate': invalidCertificate,
        if (password.text.isNotEmpty || server == null)
          'password': password.text,
      };
      final result = await widget.container.commands.execute(
        'cameraPutServer',
        params,
      );
      if (!result.ok) {
        _message(
          'Could not save the server',
          message: result.error,
          kind: ToastKind.error,
        );
      }
    });
  }

  Future<void> _editCamera(CameraSource? camera) async {
    final config = widget.container.camera.config;
    final name = TextEditingController(text: camera?.name ?? '');
    final stream = TextEditingController(text: camera?.streamName ?? '');
    final whep = TextEditingController(text: camera?.whepUrl ?? '');
    final entity = TextEditingController(text: camera?.entityId ?? '');
    final fullscreen = TextEditingController(
      text: camera?.fullscreenStreamName ?? '',
    );
    var kind = camera?.kind ?? 'go2rtc';
    var serverId =
        camera?.serverId ??
        (config.servers.isEmpty ? '' : config.servers.first.id);
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(camera == null ? 'Add camera' : 'Edit camera'),
          content: SizedBox(
            width: 480,
            child: EdgeFade(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 16,
                  children: [
                    LabeledField(
                      label: 'Name',
                      child: TextField(
                        controller: name,
                        decoration: const InputDecoration(),
                      ),
                    ),
                    LabeledField(
                      label: 'Type',
                      child: DropdownButtonFormField<String>(
                        initialValue: kind,
                        decoration: const InputDecoration(),
                        items: const [
                          DropdownMenuItem(
                            value: 'go2rtc',
                            child: Text('Go2RTC stream'),
                          ),
                          DropdownMenuItem(
                            value: 'whep',
                            child: Text('Direct WHEP URL'),
                          ),
                          DropdownMenuItem(
                            value: 'ha',
                            child: Text('Home Assistant camera'),
                          ),
                        ],
                        onChanged: (value) =>
                            setDialogState(() => kind = value ?? kind),
                      ),
                    ),
                    if (kind == 'ha')
                      LabeledField(
                        label: 'Camera entity',
                        child: TextField(
                          controller: entity,
                          decoration: const InputDecoration(
                            hintText: 'camera.front_door',
                          ),
                        ),
                      )
                    else if (kind == 'go2rtc') ...[
                      LabeledField(
                        label: 'Server',
                        child: DropdownButtonFormField<String>(
                          initialValue:
                              config.servers.any(
                                (server) => server.id == serverId,
                              )
                              ? serverId
                              : null,
                          decoration: const InputDecoration(),
                          items: [
                            for (final server in config.servers)
                              DropdownMenuItem(
                                value: server.id,
                                child: Text(server.name),
                              ),
                          ],
                          onChanged: (value) =>
                              setDialogState(() => serverId = value ?? ''),
                        ),
                      ),
                      LabeledField(
                        label: 'Stream name',
                        child: TextField(
                          controller: stream,
                          decoration: const InputDecoration(),
                        ),
                      ),
                      LabeledField(
                        label: 'Fullscreen stream (optional)',
                        child: TextField(
                          controller: fullscreen,
                          decoration: const InputDecoration(),
                        ),
                      ),
                    ] else
                      LabeledField(
                        label: 'WHEP URL',
                        child: TextField(
                          controller: whep,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (submitted != true) return;
    await _run(() async {
      final result = await widget.container.commands
          .execute('cameraPutSource', {
            'id': camera?.id ?? '',
            'name': name.text,
            'kind': kind,
            'serverId': serverId,
            'streamName': stream.text,
            'whepUrl': whep.text,
            'entityId': entity.text,
            'fullscreenStreamName': fullscreen.text,
          });
      if (!result.ok) {
        _message(
          'Could not save the camera',
          message: result.error,
          kind: ToastKind.error,
        );
      }
    });
  }

  Future<void> _editView(CameraViewConfig? view) async {
    final cameras = widget.container.camera.config.cameras;
    final name = TextEditingController(text: view?.name ?? '');
    final selected = [...?view?.cameraIds];
    var showCameraNames = view?.showCameraNames ?? true;
    int? grid = view?.grid;
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(view == null ? 'Create camera view' : 'Edit view'),
          content: SizedBox(
            width: 640,
            child: EdgeFade(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LabeledField(
                      label: 'Name',
                      child: TextField(
                        controller: name,
                        decoration: const InputDecoration(),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show camera names'),
                      value: showCameraNames,
                      onChanged: (value) =>
                          setDialogState(() => showCameraNames = value),
                    ),
                    const SizedBox(height: 12),
                    // Order is the grid order, so the chosen cameras get their
                    // own list you can drag: reading position off a checkbox
                    // list meant re-ticking everything to move one tile.
                    if (selected.isNotEmpty) ...[
                      _sectionLabel(context, 'Grid'),
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        child: KsDropdown<int>(
                          expand: true,
                          value: (grid ?? selected.length).clamp(
                            selected.length,
                            12,
                          ),
                          items: [
                            for (var size = selected.length; size <= 12; size++)
                              DropdownMenuItem(
                                value: size,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CameraGridPreview(
                                      count: size,
                                      width: 34,
                                      height: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Text('$size Camera${size == 1 ? '' : 's'}'),
                                  ],
                                ),
                              ),
                          ],
                          onChanged: (value) =>
                              setDialogState(() => grid = value),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 12),
                        child: CameraGridPreview(
                          count: (grid ?? selected.length).clamp(
                            selected.length,
                            12,
                          ),
                          filled: selected.length,
                        ),
                      ),
                      _sectionLabel(context, 'In this view'),
                      ReorderableListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        // onReorderItem: newIndex is already adjusted for the
                        // removal, unlike the deprecated onReorder.
                        onReorderItem: (oldIndex, newIndex) =>
                            setDialogState(() {
                              selected.insert(
                                newIndex,
                                selected.removeAt(oldIndex),
                              );
                            }),
                        children: [
                          for (final (index, id) in selected.indexed)
                            SettingsRow(
                              key: ValueKey(id),
                              contentPadding: EdgeInsets.zero,
                              leading: ReorderableDragStartListener(
                                index: index,
                                child: const Icon(Icons.drag_handle),
                              ),
                              title: Text(_cameraName(cameras, id)),
                              subtitle: Text('Position ${index + 1}'),
                              // A tablet has no drag: the same reordering,
                              // one step at a time.
                              trailing: OrderActions(
                                first: index == 0,
                                last: index == selected.length - 1,
                                onUp: () => setDialogState(
                                  () => selected.insert(
                                    index - 1,
                                    selected.removeAt(index),
                                  ),
                                ),
                                onDown: () => setDialogState(
                                  () => selected.insert(
                                    index + 1,
                                    selected.removeAt(index),
                                  ),
                                ),
                                onRemove: () =>
                                    setDialogState(() => selected.remove(id)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (cameras.any((c) => !selected.contains(c.id))) ...[
                      _sectionLabel(context, 'Available'),
                      for (final camera in cameras)
                        if (!selected.contains(camera.id))
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              camera.missing
                                  ? Icons.link_off_outlined
                                  : Icons.videocam_outlined,
                            ),
                            title: Text(camera.name),
                            subtitle: camera.missing
                                ? const Text('Missing from Go2RTC')
                                : null,
                            trailing: const Icon(Icons.add_circle_outline),
                            enabled: selected.length < 12,
                            onTap: selected.length >= 12
                                ? null
                                : () => setDialogState(() {
                                    selected.add(camera.id);
                                    if (grid != null &&
                                        grid! < selected.length) {
                                      grid = selected.length;
                                    }
                                  }),
                          ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              // The default view may be saved empty — that is how it is
              // retired, since it cannot be deleted.
              onPressed: selected.isEmpty && view?.isDefault != true
                  ? null
                  : () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (submitted != true) return;
    await _run(() async {
      final result = await widget.container.commands.execute('cameraPutView', {
        'id': view?.id ?? '',
        'name': name.text,
        'cameraIds': selected,
        'showCameraNames': showCameraNames,
        if (selected.isNotEmpty)
          'grid': (grid ?? selected.length).clamp(selected.length, 12),
      });
      if (!result.ok) {
        _message(
          'Could not save the view',
          message: result.error,
          kind: ToastKind.error,
        );
      }
    });
  }

  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _deleteServer(CameraServer server) async {
    if (!await _confirm(
      'Delete ${server.name}?',
      'Its cameras will be removed from every view.',
    )) {
      return;
    }
    await _run(() async {
      await widget.container.commands.execute('cameraDeleteServer', {
        'id': server.id,
      });
    });
  }

  Future<void> _deleteCamera(CameraSource camera) async {
    if (!await _confirm(
      'Delete ${camera.name}?',
      'It will be removed from every view.',
    )) {
      return;
    }
    await _run(() async {
      await widget.container.commands.execute('cameraDeleteSource', {
        'id': camera.id,
      });
    });
  }

  Future<void> _deleteView(CameraViewConfig view) async {
    if (!await _confirm('Delete ${view.name}?', 'This cannot be undone.')) {
      return;
    }
    await _run(() async {
      await widget.container.commands.execute('cameraDeleteView', {
        'id': view.id,
      });
    });
  }
}

/// A miniature of a camera grid: the UniFi Protect layout for [count]
/// slots, numbered in view order up to [filled]. Cameras fill the largest
/// tiles first, matching the live view, so number one always sits on the
/// biggest tile and unfilled slots are the smallest. Small sizes drop the
/// numbers and serve as the dropdown's layout icons. The layout tables
/// mirror assets/camera-view/camera-view.js and the remote UI preview.
class CameraGridPreview extends StatelessWidget {
  const CameraGridPreview({
    super.key,
    required this.count,
    this.filled,
    this.width = 210,
    this.height = 126,
  });

  final int count;

  /// Slots holding a camera; the rest render as empty cells. Defaults to
  /// every slot.
  final int? filled;

  final double width;
  final double height;

  /// [columns, rows] in layout units per grid size.
  static const _grids = <int, List<int>>{
    1: [1, 1],
    2: [2, 1],
    3: [2, 2],
    4: [2, 2],
    5: [4, 2],
    6: [3, 3],
    7: [4, 4],
    8: [3, 4],
    9: [3, 3],
    10: [4, 4],
    11: [5, 4],
    12: [6, 6],
  };

  /// [columnSpan, rowSpan] of the leading tiles that cover several units;
  /// every other tile is a single unit placed in reading order.
  static const _spans = <int, List<List<int>>>{
    3: [
      [1, 2],
    ],
    5: [
      [2, 2],
    ],
    6: [
      [2, 2],
    ],
    7: [
      [2, 2],
      [2, 2],
      [2, 2],
    ],
    8: [
      [1, 2],
      [1, 2],
      [1, 1],
      [1, 1],
      [1, 2],
      [1, 2],
    ],
    10: [
      [2, 2],
      [1, 1],
      [1, 1],
      [1, 1],
      [1, 1],
      [2, 2],
    ],
    11: [
      [2, 2],
      [2, 2],
      [1, 1],
      [1, 1],
      [2, 2],
    ],
    12: [
      [3, 3],
      [3, 3],
      [3, 3],
    ],
  };

  @override
  Widget build(BuildContext context) {
    final grid = _grids[count];
    if (grid == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final columns = grid[0];
    final rows = grid[1];
    final cameras = filled ?? count;
    final numbered = height >= 60;
    final inset = height >= 60 ? 1.5 : 0.7;
    final spans = _spans[count] ?? const <List<int>>[];
    final tiles = _place(count, columns, rows, spans);
    // Cameras take the largest tiles first, exactly like the live view:
    // rank[slot] is which camera (by view order) sits in that slot.
    int area(int slot) =>
        slot < spans.length ? spans[slot][0] * spans[slot][1] : 1;
    final priority = [for (var slot = 0; slot < count; slot++) slot]
      ..sort((a, b) {
        final byArea = area(b) - area(a);
        return byArea != 0 ? byArea : a - b;
      });
    final rank = List<int>.filled(count, 0);
    for (var position = 0; position < count; position++) {
      rank[priority[position]] = position;
    }
    return Center(
      child: SizedBox(
        width: width,
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cellWidth = constraints.maxWidth / columns;
            final cellHeight = constraints.maxHeight / rows;
            return Stack(
              children: [
                for (final (index, tile) in tiles.indexed)
                  Positioned(
                    left: tile[0] * cellWidth,
                    top: tile[1] * cellHeight,
                    width: tile[2] * cellWidth,
                    height: tile[3] * cellHeight,
                    child: Padding(
                      padding: EdgeInsets.all(inset),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: rank[index] < cameras
                              ? scheme.surfaceContainerHighest
                              : null,
                          border: Border.all(
                            color: rank[index] < cameras
                                ? scheme.outline
                                : scheme.outlineVariant,
                          ),
                          borderRadius: BorderRadius.circular(
                            numbered ? 4 : 1.5,
                          ),
                        ),
                        child: numbered && rank[index] < cameras
                            ? Center(
                                child: Text(
                                  '${rank[index] + 1}',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Reading-order auto-placement, the rule CSS grid auto-flow applies in
  /// the live view. Returns [column, row, columnSpan, rowSpan] per tile.
  static List<List<int>> _place(
    int count,
    int columns,
    int rows,
    List<List<int>> spans,
  ) {
    final occupied = [
      for (var row = 0; row < rows; row++) List.filled(columns, false),
    ];
    final tiles = <List<int>>[];
    for (var index = 0; index < count; index++) {
      final span = index < spans.length ? spans[index] : const [1, 1];
      search:
      for (var row = 0; row + span[1] <= rows; row++) {
        for (var col = 0; col + span[0] <= columns; col++) {
          var free = true;
          for (var r = row; r < row + span[1] && free; r++) {
            for (var c = col; c < col + span[0]; c++) {
              if (occupied[r][c]) {
                free = false;
                break;
              }
            }
          }
          if (!free) continue;
          for (var r = row; r < row + span[1]; r++) {
            for (var c = col; c < col + span[0]; c++) {
              occupied[r][c] = true;
            }
          }
          tiles.add([col, row, span[0], span[1]]);
          break search;
        }
      }
    }
    return tiles;
  }
}
