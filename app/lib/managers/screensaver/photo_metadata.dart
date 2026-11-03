/// The photo metadata panel's settings and details, shared by the
/// screensaver modes that carry one: Immich Media, whose server hands over
/// the details, and Home Assistant Media, Local Media and Image URL, which
/// read them from the photo's own EXIF (issue #953).
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../core/locale_dates.dart';
import '../../core/photo_exif.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'screensaver_widgets.dart';

/// One mode's metadata settings: the master switch, the switch behind each
/// line, and the panel's look.
class PhotoMetadataDefs {
  const PhotoMetadataDefs({
    required this.enabled,
    required this.fields,
    required this.position,
    required this.textShadow,
    required this.scale,
    required this.vignette,
    this.caption,
  });

  final defs.SettingDef<bool> enabled;

  /// The panel's lines and the switch that carries each, in the order they
  /// are drawn. `camera` (the model) and `settings` (the exposure) are the
  /// two halves of one line and share a switch.
  final Map<String, defs.SettingDef<bool>> fields;
  final defs.SettingDef<String> position;
  final defs.SettingDef<bool> textShadow;
  final defs.SettingDef<num> scale;
  final defs.SettingDef<num> vignette;

  /// The switch behind the caption, the photo's description centered at
  /// the bottom of the screen (issue #1290). Kept out of [fields] since it
  /// is not a line of the corner panel: a caption alone must not claim a
  /// corner. Null for the modes whose photos carry none.
  final defs.SettingDef<bool>? caption;

  Iterable<defs.SettingDef<Object>> get all => [
    enabled,
    ...fields.values,
    position,
    textShadow,
    scale,
    vignette,
    ?caption,
  ];
}

/// The modes with a metadata panel. A mode missing here has none.
const photoMetadataDefs = <String, PhotoMetadataDefs>{
  'immich': PhotoMetadataDefs(
    enabled: defs.screensaverImmichMetadata,
    fields: {
      'album': defs.screensaverImmichMetadataAlbum,
      'date': defs.screensaverImmichMetadataDate,
      'camera': defs.screensaverImmichMetadataCamera,
      'settings': defs.screensaverImmichMetadataCamera,
      'location': defs.screensaverImmichMetadataLocation,
    },
    position: defs.screensaverImmichMetadataPosition,
    textShadow: defs.screensaverImmichMetadataTextShadow,
    scale: defs.screensaverImmichMetadataScale,
    vignette: defs.screensaverImmichVignetteStrength,
    caption: defs.screensaverImmichMetadataDescription,
  ),
  'media': PhotoMetadataDefs(
    enabled: defs.screensaverMediaMetadata,
    fields: {
      'date': defs.screensaverMediaMetadataDate,
      'camera': defs.screensaverMediaMetadataCamera,
      'settings': defs.screensaverMediaMetadataCamera,
    },
    position: defs.screensaverMediaMetadataPosition,
    textShadow: defs.screensaverMediaMetadataTextShadow,
    scale: defs.screensaverMediaMetadataScale,
    vignette: defs.screensaverMediaVignetteStrength,
  ),
  'local': PhotoMetadataDefs(
    enabled: defs.screensaverLocalMetadata,
    fields: {
      'date': defs.screensaverLocalMetadataDate,
      'camera': defs.screensaverLocalMetadataCamera,
      'settings': defs.screensaverLocalMetadataCamera,
    },
    position: defs.screensaverLocalMetadataPosition,
    textShadow: defs.screensaverLocalMetadataTextShadow,
    scale: defs.screensaverLocalMetadataScale,
    vignette: defs.screensaverLocalVignetteStrength,
  ),
  'url': PhotoMetadataDefs(
    enabled: defs.screensaverUrlMetadata,
    fields: {
      'date': defs.screensaverUrlMetadataDate,
      'camera': defs.screensaverUrlMetadataCamera,
      'settings': defs.screensaverUrlMetadataCamera,
    },
    position: defs.screensaverUrlMetadataPosition,
    textShadow: defs.screensaverUrlMetadataTextShadow,
    scale: defs.screensaverUrlMetadataScale,
    vignette: defs.screensaverUrlVignetteStrength,
  ),
};

/// Whether one line of [mode]'s panel is on. Lines the panel itself is off
/// for never count.
bool photoMetadataFieldOn(SettingsManager settings, String mode, String field) {
  final metadata = photoMetadataDefs[mode];
  final line = metadata?.fields[field];
  return metadata != null &&
      line != null &&
      settings.get(metadata.enabled) &&
      settings.get(line);
}

/// Whether [mode]'s panel has anything left to say: the master switch on
/// and at least one line kept. With every line off the panel stands down
/// entirely rather than claiming a corner for an empty block.
bool photoMetadataVisible(SettingsManager settings, String mode) {
  final metadata = photoMetadataDefs[mode];
  return metadata != null &&
      settings.get(metadata.enabled) &&
      metadata.fields.values.any((def) => settings.get(def));
}

/// Whether [mode] shows its caption: the master switch and the caption's
/// own both on.
bool photoCaptionOn(SettingsManager settings, String mode) {
  final metadata = photoMetadataDefs[mode];
  final caption = metadata?.caption;
  return metadata != null &&
      caption != null &&
      settings.get(metadata.enabled) &&
      settings.get(caption);
}

/// Whether [mode] draws anything over the photo: the corner panel, the
/// caption or both. The panel's own corner claims still follow
/// [photoMetadataVisible] alone.
bool photoMetadataShown(SettingsManager settings, String mode) =>
    photoMetadataVisible(settings, mode) || photoCaptionOn(settings, mode);

/// The corner [mode]'s single-photo panel settles in: its configured
/// corner, or the first free one when a corner widget owns that (the panel
/// steps aside rather than stacking). Null when the panel is off, or on
/// the (unlikely) fully claimed screen where it stands down.
///
/// Shared by the panel itself and the At a Glance row, which narrows and
/// wraps when this lands in a bottom corner so the two never overlap.
String? photoMetadataCorner(SettingsManager settings, String mode) {
  if (!photoMetadataVisible(settings, mode)) return null;
  final claimed = {
    for (final w in decodeScreensaverWidgets(
      settings.get(defs.screensaverWidgets),
    ))
      if (screensaverWidgetAllowedOnMode(w.type, mode)) w.position,
  };
  final preferred = settings.get(photoMetadataDefs[mode]!.position);
  return [
    preferred,
    ...defs.cornerOptions,
  ].where((corner) => !claimed.contains(corner)).firstOrNull;
}

/// The camera line: the model, with the make ahead of it unless the vendor
/// already baked it in ("Canon EOS R5").
String? photoCameraLine(String? make, String? model) {
  final body = (model ?? '').trim();
  if (body.isEmpty) return null;
  final brand = (make ?? '').trim();
  return body.startsWith(brand) ? body : '$brand $body'.trim();
}

/// The exposure line, "26mm  f/1.8  ISO 50", from whichever parts are
/// known. Null when none are.
String? photoExposureLine({num? focalLength, num? fNumber, num? iso}) {
  final shot = <String>[
    if (focalLength != null) '${_trimNum(focalLength)}mm',
    if (fNumber != null) 'f/${_trimNum(fNumber)}',
    if (iso != null) 'ISO ${iso.toInt()}',
  ];
  return shot.isEmpty ? null : shot.join('  ');
}

/// 6.0 reads "6" and 1.7 reads "1.7", the way a camera marks them.
String _trimNum(num value) =>
    value == value.toInt() ? '${value.toInt()}' : value.toStringAsFixed(1);

/// The panel's lines from a photo's EXIF, keyed like Immich's details:
/// `date`, `camera` and `settings`, each absent when the photo lacks it.
Map<String, String> photoExifDetails(PhotoExif? exif) {
  if (exif == null) return const {};
  final taken = exif.taken;
  final camera = photoCameraLine(exif.make, exif.model);
  final settings = photoExposureLine(
    focalLength: exif.focalLength,
    fNumber: exif.fNumber,
    iso: exif.iso,
  );
  return {
    // Localized through the device locale, as Immich's date is.
    'date': ?(taken == null ? null : longDate(taken)),
    'camera': ?camera,
    'settings': ?settings,
  };
}

/// Recent photos' details by source key, so a slideshow that loops does
/// not read every head again.
final _details = <String, Map<String, String>>{};
final _requests = <String, Future<Map<String, String>>>{};

Future<Map<String, String>> _cached(
  String key,
  Future<Uint8List?> Function() head,
) {
  final known = _details[key];
  if (known != null) return Future.value(known);
  return _requests.putIfAbsent(key, () async {
    try {
      final bytes = await head();
      // A failed read is not cached, so a passing hiccup retries next loop.
      if (bytes == null) return const {};
      final details = photoExifDetails(readPhotoExif(bytes));
      if (_details.length >= 300) _details.remove(_details.keys.first);
      _details[key] = details;
      return details;
    } catch (_) {
      return const {};
    } finally {
      _requests.remove(key);
    }
  });
}

/// A photo on this device: the head of the file is all the EXIF needs.
Future<Map<String, String>> localPhotoDetails(String path) =>
    _cached('file:$path', () async {
      final file = await File(path).open();
      try {
        return await file.read(photoExifHeadBytes);
      } finally {
        await file.close();
      }
    });

/// A photo already in memory (the Image URL screensaver's fetch), keyed by
/// [id] since the same address answers with a new photo every time.
Future<Map<String, String>> memoryPhotoDetails(String id, Uint8List bytes) =>
    _cached('memory:$id', () async => bytes);

/// A photo Home Assistant serves at [url], keyed by its media id since the
/// signed URL changes with every resolve. A Range request asks for the head
/// only, and the read stops there even when the server sends it all.
Future<Map<String, String>> remotePhotoDetails(String id, Uri url) =>
    _cached('ha:$id', () async {
      final client = http.Client();
      try {
        final request = http.Request('GET', url)
          ..headers['Range'] = 'bytes=0-${photoExifHeadBytes - 1}';
        final response = await client
            .send(request)
            .timeout(const Duration(seconds: 10));
        if (response.statusCode != 200 && response.statusCode != 206) {
          return null;
        }
        final head = BytesBuilder(copy: false);
        await for (final chunk in response.stream.timeout(
          const Duration(seconds: 10),
        )) {
          head.add(chunk);
          if (head.length >= photoExifHeadBytes) break;
        }
        return head.takeBytes();
      } finally {
        client.close();
      }
    });
