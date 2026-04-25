import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static final _storage = FirebaseStorage.instance;

  static Future<String?> _upload(Uint8List bytes, String path, String ext) async {
    try {
      debugPrint('[Storage] upload start: $path');
      final ref = _storage.ref().child(path);
      await ref
          .putData(bytes, SettableMetadata(contentType: 'image/$ext'))
          .timeout(const Duration(seconds: 30));
      final url = await ref.getDownloadURL().timeout(const Duration(seconds: 10));
      debugPrint('[Storage] upload ok: $url');
      return url;
    } on TimeoutException {
      debugPrint('[Storage] TIMEOUT su $path');
      return null;
    } catch (e) {
      debugPrint('[Storage] errore su $path: $e');
      return null;
    }
  }

  static Future<String?> uploadProfilePhoto(Uint8List bytes, String ext) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _upload(bytes, 'users/$uid/profile.$ext', ext);
  }

  static Future<String?> uploadCoverPhoto(Uint8List bytes, String ext) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _upload(bytes, 'users/$uid/cover.$ext', ext);
  }
}
