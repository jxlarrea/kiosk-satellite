import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'manifest.dart';

/// A downloaded vsWakeWord model: its parsed manifest, the raw manifest JSON
/// (so it can be re-parsed inside the compute isolate), and the ONNX bytes.
class VswwModel {
  VswwModel(this.manifest, this.manifestJson, this.onnxBytes);
  final VswwManifest manifest;
  final String manifestJson;
  final Uint8List onnxBytes;
}

/// Downloads vsWakeWord models + manifests from the URLs the Voice Satellite
/// card hands us (served by the VS integration at
/// `<ha>/voice_satellite/models/vswakeword/<name>.{json,onnx}`), caching the
/// ONNX bytes on disk so we don't re-download every launch.
class VswwModelStore {
  Future<Directory> _cacheDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/vsww_models');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Fetch manifest (always fresh) + ONNX (disk-cached by URL hash).
  Future<VswwModel> fetch(String manifestUrl) async {
    final manifestResp = await http
        .get(Uri.parse(manifestUrl))
        .timeout(const Duration(seconds: 20));
    if (manifestResp.statusCode != 200) {
      throw StateError('manifest HTTP ${manifestResp.statusCode}: $manifestUrl');
    }
    final manifest = VswwManifest.fromJson(
        jsonDecode(manifestResp.body) as Map<String, dynamic>);
    if (!manifest.isCtc) {
      throw StateError('unsupported vsWakeWord format: ${manifest.format}');
    }

    final onnxUrl = _onnxUrlFor(manifestUrl);
    final onnxBytes = await _fetchOnnxCached(onnxUrl);
    return VswwModel(manifest, manifestResp.body, onnxBytes);
  }

  /// Derive the `.onnx` URL from the manifest URL, preserving any query
  /// string (Voice Satellite appends `?v=<version>` for cache-busting, so we
  /// must swap the extension in the path only and keep the query).
  static String _onnxUrlFor(String manifestUrl) {
    final q = manifestUrl.indexOf('?');
    final path = q >= 0 ? manifestUrl.substring(0, q) : manifestUrl;
    final query = q >= 0 ? manifestUrl.substring(q) : '';
    final onnxPath = path.endsWith('.json')
        ? '${path.substring(0, path.length - 5)}.onnx'
        : '$path.onnx';
    return '$onnxPath$query';
  }

  Future<Uint8List> _fetchOnnxCached(String onnxUrl) async {
    final dir = await _cacheDir();
    final key = sha256.convert(utf8.encode(onnxUrl)).toString().substring(0, 24);
    final file = File('${dir.path}/$key.onnx');
    if (await file.exists() && await file.length() > 0) {
      return file.readAsBytes();
    }
    final resp =
        await http.get(Uri.parse(onnxUrl)).timeout(const Duration(seconds: 60));
    if (resp.statusCode != 200) {
      throw StateError('onnx HTTP ${resp.statusCode}: $onnxUrl');
    }
    await file.writeAsBytes(resp.bodyBytes, flush: true);
    return resp.bodyBytes;
  }
}
