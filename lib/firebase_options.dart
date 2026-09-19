// File generated from android/app/google-services.json and
// ios/Runner/GoogleService-Info.plist (project motirong-32a1c), in the format
// `flutterfire configure` produces. Re-run `flutterfire configure` to refresh.
// ignore_for_file: type=lint
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
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDsTwNPUb1imoylDRUyHfWmYdMdyqWV168',
    appId: '1:168910544315:android:8fd94c6bfede98d784389e',
    messagingSenderId: '168910544315',
    projectId: 'motirong-32a1c',
    storageBucket: 'motirong-32a1c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDrPBhPidDiVbNAaf1h5SG6Q3CLCxc8Lig',
    appId: '1:168910544315:ios:ce532bf74cd5ac0184389e',
    messagingSenderId: '168910544315',
    projectId: 'motirong-32a1c',
    storageBucket: 'motirong-32a1c.firebasestorage.app',
    iosBundleId: 'com.jabulile.motiroong',
  );
}
