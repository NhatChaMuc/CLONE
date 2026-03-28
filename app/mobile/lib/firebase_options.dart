// lib/firebase_options.dart
// ignore_for_file: constant_identifier_names
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web; // ✅ Web
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android; // ✅ Android
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'FirebaseOptions is not configured for ${defaultTargetPlatform.name}.',
        );
      default:
        throw UnsupportedError(
          'FirebaseOptions are not configured for this platform.',
        );
    }
  }

  /// ✅ Android (com.edu.app)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAB6p9Pm3PdQhAH9WuS3ACaagm0a_fLfg8',
    appId: '1:274550405803:android:443888e1391cbbd1ce95ee',
    messagingSenderId: '274550405803',
    projectId: 'apps-9a11d',
    storageBucket: 'apps-9a11d.appspot.com',
  );

  /// ✅ Web (theo cấu hình bạn chụp) — CHÚ Ý: bucket dùng *.appspot.com
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBdH8rRlKDI_lOxAB1fSvQhEa7hX_rjQXQ',
    authDomain: 'apps-9a11d.firebaseapp.com',
    projectId: 'apps-9a11d',
    storageBucket:
        'apps-9a11d.appspot.com', // ✅ sửa từ firebasestorage.app → appspot.com
    messagingSenderId: '274550405803',
    appId: '1:274550405803:web:bc22362e90be1189ce95ee',
    measurementId: 'G-SFW60LMVVT', // dùng đúng mã bạn dán
  );
}
