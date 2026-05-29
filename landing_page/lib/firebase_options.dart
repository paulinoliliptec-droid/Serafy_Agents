import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError('Only web is supported in this build.');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCboJ6a28KvUnzK8gvf3x6GUPl0xWI52k4',
    appId: '1:815347505144:web:95b65e7f54d2ab445b280d',
    messagingSenderId: '815347505144',
    projectId: 'serafy-agentics-fe12b',
    authDomain: 'serafy-agentics-fe12b.firebaseapp.com',
    storageBucket: 'serafy-agentics-fe12b.firebasestorage.app',
    measurementId: 'G-HZVR9HLK64',
  );
}
