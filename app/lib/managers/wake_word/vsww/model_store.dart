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
  VswwModel(this.manifest, this.manifestJson, this.onnxBytes, this.precision);
  final VswwManifest manifest;
  final String manifestJson;
  final Uint8List onnxBytes;

  /// 'int8' when the quantized sibling was fetched, 'fp32' otherwise.
  final String precision;
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
  ///
  /// With [preferInt8], the quantized sibling under `int8/` is tried first
  /// (same manifest, ~35% faster inference); any failure falls back to the
  /// fp32 file, so a server without the int8 build keeps working untouched.
  Future<VswwModel> fetch(String manifestUrl, {bool preferInt8 = false}) async {
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
    if (preferInt8) {
      try {
        final bytes = await _fetchOnnxCached(_int8UrlFor(onnxUrl));
        return VswwModel(manifest, manifestResp.body, bytes, 'int8');
      } catch (_) {
        // No int8 sibling on this server (or it failed to load): fp32 is
        // always the safe answer, and the browser runner requires it anyway.
      }
    }
    final onnxBytes = await _fetchOnnxCached(onnxUrl);
    return VswwModel(manifest, manifestResp.body, onnxBytes, 'fp32');
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

  /// The quantized sibling lives in an `int8/` subfolder next to the fp32
  /// file: `.../vswakeword/ok_nova.onnx` -> `.../vswakeword/int8/ok_nova.onnx`
  /// (query preserved, it carries the cache-busting version).
  static String _int8UrlFor(String onnxUrl) {
    final q = onnxUrl.indexOf('?');
    final path = q >= 0 ? onnxUrl.substring(0, q) : onnxUrl;
    final query = q >= 0 ? onnxUrl.substring(q) : '';
    final slash = path.lastIndexOf('/');
    if (slash < 0) return onnxUrl;
    return '${path.substring(0, slash)}/int8${path.substring(slash)}$query';
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
