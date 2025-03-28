// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options-old.dart';
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
    apiKey: 'AIzaSyC89OJSutb4Ae3KkfsF4KBAhlqCw8urPoI',
    appId: '1:1090702313790:web:56da7841482d2101e5446f',
    messagingSenderId: '1090702313790',
    projectId: 'frizerskisalon-b34f6',
    authDomain: 'frizerskisalon-b34f6.firebaseapp.com',
    storageBucket: 'frizerskisalon-b34f6.firebasestorage.app',
    measurementId: 'G-JGQW12PS52',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBqmdXbPD1vBeX6PIMxke70uDBRPaYu1GI',
    appId: '1:1090702313790:android:379dd323221a0a80e5446f',
    messagingSenderId: '1090702313790',
    projectId: 'frizerskisalon-b34f6',
    storageBucket: 'frizerskisalon-b34f6.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCuWZLhxUJ4yWDnM0f7Rzki0Jkx-76amzI',
    appId: '1:1090702313790:ios:fbe6d05f5327402ae5446f',
    messagingSenderId: '1090702313790',
    projectId: 'frizerskisalon-b34f6',
    storageBucket: 'frizerskisalon-b34f6.firebasestorage.app',
    iosBundleId: 'com.example.frizerskiSalon',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCuWZLhxUJ4yWDnM0f7Rzki0Jkx-76amzI',
    appId: '1:1090702313790:ios:fbe6d05f5327402ae5446f',
    messagingSenderId: '1090702313790',
    projectId: 'frizerskisalon-b34f6',
    storageBucket: 'frizerskisalon-b34f6.firebasestorage.app',
    iosBundleId: 'com.example.frizerskiSalon',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC89OJSutb4Ae3KkfsF4KBAhlqCw8urPoI',
    appId: '1:1090702313790:web:4e3f4e45d65f2836e5446f',
    messagingSenderId: '1090702313790',
    projectId: 'frizerskisalon-b34f6',
    authDomain: 'frizerskisalon-b34f6.firebaseapp.com',
    storageBucket: 'frizerskisalon-b34f6.firebasestorage.app',
    measurementId: 'G-LK92645ZPE',
  );
}
