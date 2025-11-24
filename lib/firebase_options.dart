// File generated manually from Firebase project configuration
// Project ID: dinnr-b3eaf

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA0rHWhrv3ge00k9E1TQA1zumrW-xLmf5I',
    appId: '1:252261870708:web:61b9bae79ff636a7c33521',
    messagingSenderId: '252261870708',
    projectId: 'dinnr-b3eaf',
    authDomain: 'dinnr-b3eaf.firebaseapp.com',
    storageBucket: 'dinnr-b3eaf.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA0rHWhrv3ge00k9E1TQA1zumrW-xLmf5I',
    appId: '1:252261870708:web:bac5ee48758f64c8c33521',
    messagingSenderId: '252261870708',
    projectId: 'dinnr-b3eaf',
    storageBucket: 'dinnr-b3eaf.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA0rHWhrv3ge00k9E1TQA1zumrW-xLmf5I',
    appId: '1:252261870708:android:67ec52e16e551c2ec33521',
    messagingSenderId: '252261870708',
    projectId: 'dinnr-b3eaf',
    storageBucket: 'dinnr-b3eaf.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA0rHWhrv3ge00k9E1TQA1zumrW-xLmf5I',
    appId: '1:252261870708:ios:78fc3c3e251923e3c33521',
    messagingSenderId: '252261870708',
    projectId: 'dinnr-b3eaf',
    storageBucket: 'dinnr-b3eaf.firebasestorage.app',
    iosBundleId: 'com.dinnrteam.dinnrapp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA0rHWhrv3ge00k9E1TQA1zumrW-xLmf5I',
    appId: '1:252261870708:ios:e247d99c3756256bc33521',
    messagingSenderId: '252261870708',
    projectId: 'dinnr-b3eaf',
    storageBucket: 'dinnr-b3eaf.firebasestorage.app',
    iosBundleId: 'com.dinnrteam.dinnrapp',
  );
}
