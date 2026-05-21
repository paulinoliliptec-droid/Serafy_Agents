import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;

  Future<String> uploadLogo(String clientId, Uint8List bytes, String ext) async {
    final ref = _storage.ref('tenants/$clientId/logo.$ext');
    final task = await ref.putData(bytes, SettableMetadata(contentType: 'image/$ext'));
    return task.ref.getDownloadURL();
  }
}
