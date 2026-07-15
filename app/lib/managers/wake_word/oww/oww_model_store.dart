import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'onnx_ir.dart';

/// openWakeWord's three ONNX stages. The first two are shared by every wake
/// word; only the classifier is per-model.
class OwwSharedModels {
  OwwSharedModels(this.melspectrogram, this.embedding);
  final Uint8List melspectrogram;
  final Uint8List embedding;
}

/// Downloads openWakeWord models from the HA instance
/// (`<ha>/voice_satellite/models/openwakeword/*.onnx`), caching weights on disk.
///
/// openWakeWord has no manifests: Voice Satellite sends the classifier URL
/// directly and resolves the cutoff itself, so this store only fetches bytes.
/// The two shared models live in the same directory as the classifier and are
/// fetched once for all wake words.
class OwwModelStore {
  OwwSharedModels? _shared;
  String? _sharedBase;

  Future<Directory> _cacheDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/oww_models');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// The directory a classifier URL lives in, query string preserved.
  static String baseOf(String modelUrl) {
    final q = modelUrl.indexOf('?');
    final path = q >= 0 ? modelUrl.substring(0, q) : modelUrl;
    final slash = path.lastIndexOf('/');
    return slash >= 0 ? path.substring(0, slash) : path;
  }

  static String _queryOf(String modelUrl) {
    final q = modelUrl.indexOf('?');
    return q >= 0 ? modelUrl.substring(q) : '';
  }

  /// mel + embedding, fetched once per base URL and reused across wake words.
  Future<OwwSharedModels> shared(String modelUrl) async {
    final base = baseOf(modelUrl);
    final cached = _shared;
    if (cached != null && _sharedBase == base) return cached;
    final query = _queryOf(modelUrl);
    final mel = await fetchModel('$base/melspectrogram.onnx$query');
    final emb = await fetchModel('$base/embedding_model.onnx$query');
    _shared = OwwSharedModels(mel, emb);
    _sharedBase = base;
    return _shared!;
  }

  /// Fetch an .onnx, from disk when we have it, and make it loadable by the
  /// bundled runtime (see [downgradeIrVersion]).
  Future<Uint8List> fetchModel(String url) async {
    final dir = await _cacheDir();
    final key = sha256.convert(utf8.encode(url)).toString().substring(0, 24);
    final file = File('${dir.path}/$key.onnx');
    Uint8List bytes;
    if (await file.exists() && await file.length() > 0) {
      bytes = await file.readAsBytes();
    } else {
      final resp =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 60));
      if (resp.statusCode != 200) {
        throw StateError('onnx HTTP ${resp.statusCode}: $url');
      }
      bytes = Uint8List.fromList(resp.bodyBytes);
      await file.writeAsBytes(bytes, flush: true);
    }
    // Patch a copy each load rather than rewriting the cache file: the cache
    // should hold what the server served, so a future runtime that supports
    // IR 10 natively gets the original.
    final patched = Uint8List.fromList(bytes);
    downgradeIrVersion(patched);
    return patched;
  }
}
