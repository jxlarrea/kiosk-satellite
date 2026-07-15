import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'mww_manifest.dart';

class MwwModel {
  MwwModel(this.manifest, this.tfliteBytes);
  final MwwManifest manifest;
  final Uint8List tfliteBytes;
}

/// Downloads microWakeWord models from the HA instance
/// (`<ha>/voice_satellite/models/<name>.{json,tflite}`), caching the weights on
/// disk so a restart does not re-download them.
///
/// Same shape as [VswwModelStore]; kept separate rather than generalised
/// because the two differ in the only places that matter (file extension,
/// manifest schema) and sharing would mean a parameterised store with two
/// callers.
class MwwModelStore {
  Future<Directory> _cacheDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/mww_models');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<MwwModel> fetch(String manifestUrl) async {
    final manifestResp = await http
        .get(Uri.parse(manifestUrl))
        .timeout(const Duration(seconds: 30));
    if (manifestResp.statusCode != 200) {
      throw StateError('manifest HTTP ${manifestResp.statusCode}: $manifestUrl');
    }
    final manifest = MwwManifest.fromJson(
        jsonDecode(manifestResp.body) as Map<String, Object?>);
    if (manifest == null) {
      throw StateError('not a microWakeWord manifest: $manifestUrl');
    }
    final bytes = await _fetchTfliteCached(_tfliteUrlFor(manifestUrl));
    return MwwModel(manifest, bytes);
  }

  /// Derive the `.tflite` URL from the manifest URL, preserving any query
  /// string (Voice Satellite appends `?v=<version>` for cache-busting, so the
  /// extension swap has to touch the path only).
  static String _tfliteUrlFor(String manifestUrl) {
    final q = manifestUrl.indexOf('?');
    final path = q >= 0 ? manifestUrl.substring(0, q) : manifestUrl;
    final query = q >= 0 ? manifestUrl.substring(q) : '';
    final tflitePath = path.endsWith('.json')
        ? '${path.substring(0, path.length - 5)}.tflite'
        : '$path.tflite';
    return '$tflitePath$query';
  }

  Future<Uint8List> _fetchTfliteCached(String url) async {
    final dir = await _cacheDir();
    final key = sha256.convert(utf8.encode(url)).toString().substring(0, 24);
    final file = File('${dir.path}/$key.tflite');
    if (await file.exists() && await file.length() > 0) {
      return file.readAsBytes();
    }
    final resp =
        await http.get(Uri.parse(url)).timeout(const Duration(seconds: 60));
    if (resp.statusCode != 200) {
      throw StateError('tflite HTTP ${resp.statusCode}: $url');
    }
    await file.writeAsBytes(resp.bodyBytes, flush: true);
    return resp.bodyBytes;
  }
}
