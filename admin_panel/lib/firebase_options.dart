// ⚠️  Run `flutterfire configure --project=serafy-agentics` to auto-generate,
// or fill in manually from Firebase Console → Project Settings → Web app.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError('Only web is supported in this build.');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'serafy-agentics',
    authDomain: 'serafy-agentics.firebaseapp.com',
    storageBucket: 'serafy-agentics.firebasestorage.app',
  );
}
