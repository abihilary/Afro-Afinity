import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../api/api_client.dart';
import '../util/json.dart';

/// The only correct upload sequence (API_WIRING §7.3):
///   1. `POST /uploads/sign {bucket, ext}` → `{path, token}`
///   2. PUT the bytes to that signed URL
///   3. hand the returned **path** to the endpoint that owns it.
///
/// Every path starts with the member's uid; storage policies and the routes
/// both re-check that, so nothing here may build a path itself.
class StorageService {
  StorageService(this._api);
  final ApiClient _api;

  Future<String> upload({
    required String bucket,
    required Uint8List bytes,
    required String ext,
    String? filename,
  }) async {
    final e = _normaliseExt(ext);
    final signed = await _api.postJson('/uploads/sign', data: {
      'bucket': bucket,
      'ext': e,
      'filename': ?filename,
    });
    final path = asString(signed['path']);
    final token = asString(signed['token']);
    if (path == null || token == null) {
      throw ApiException(code: 'storage_error', message: 'Upload could not be signed', details: const {}, statusCode: 500);
    }
    await Supabase.instance.client.storage.from(bucket).uploadBinaryToSignedUrl(
          path,
          token,
          bytes,
          FileOptions(contentType: _contentType(e), upsert: false),
        );
    return path;
  }

  static String _normaliseExt(String ext) {
    final e = ext.toLowerCase().replaceFirst('.', '');
    return e == 'jpeg' ? 'jpg' : e;
  }

  static String _contentType(String ext) => switch (ext) {
        'jpg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        'heic' => 'image/heic',
        'm4a' => 'audio/mp4',
        'mp3' => 'audio/mpeg',
        'ogg' => 'audio/ogg',
        'webm' => 'audio/webm',
        'pdf' => 'application/pdf',
        _ => 'application/octet-stream',
      };
}

final storageServiceProvider = Provider<StorageService>((ref) => StorageService(ref.read(apiClientProvider)));

/// Extension of a picked file name, defaulting to jpg (the image picker
/// re-encodes to JPEG when it resizes).
String extOf(String name) {
  final i = name.lastIndexOf('.');
  if (i < 0) return 'jpg';
  final e = name.substring(i + 1).toLowerCase();
  return const {'jpg', 'jpeg', 'png', 'webp', 'heic', 'm4a', 'mp3', 'ogg', 'webm', 'pdf'}.contains(e) ? e : 'jpg';
}
