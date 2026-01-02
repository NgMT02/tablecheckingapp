import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Placeholder Firebase configuration.
/// Replace the values with your project's settings or regenerate this file with
/// `flutterfire configure` before shipping.
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
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not set for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBQYUT1Pyi_SKF2Rk6IfHdcJpuYT2cB87Q',
    appId: '1:52196131424:web:a0208f39cfd9de577f7905',
    messagingSenderId: '52196131424',
    projectId: 'tablecheckingapp-13820',
    authDomain: 'tablecheckingapp-13820.firebaseapp.com',
    storageBucket: 'tablecheckingapp-13820.firebasestorage.app',
    measurementId: 'G-LQSLNW4SCR',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBjg8fH-DT2_zu3_8CZYjR0s3nRwJTSt9A',
    appId: '1:52196131424:android:c257da6a9d7376947f7905',
    messagingSenderId: '52196131424',
    projectId: 'tablecheckingapp-13820',
    storageBucket: 'tablecheckingapp-13820.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyChOdQHUrz5gHpmbu3R1nxJezpQCQbGtgk',
    appId: '1:52196131424:ios:770c236564e04dac7f7905',
    messagingSenderId: '52196131424',
    projectId: 'tablecheckingapp-13820',
    storageBucket: 'tablecheckingapp-13820.firebasestorage.app',
    iosBundleId: 'com.example.tableCheckingApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyChOdQHUrz5gHpmbu3R1nxJezpQCQbGtgk',
    appId: '1:52196131424:ios:770c236564e04dac7f7905',
    messagingSenderId: '52196131424',
    projectId: 'tablecheckingapp-13820',
    storageBucket: 'tablecheckingapp-13820.firebasestorage.app',
    iosBundleId: 'com.example.tableCheckingApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBQYUT1Pyi_SKF2Rk6IfHdcJpuYT2cB87Q',
    appId: '1:52196131424:web:dd8c67d6aecb48a67f7905',
    messagingSenderId: '52196131424',
    projectId: 'tablecheckingapp-13820',
    authDomain: 'tablecheckingapp-13820.firebaseapp.com',
    storageBucket: 'tablecheckingapp-13820.firebasestorage.app',
    measurementId: 'G-TQM91QV9XE',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'YOUR_LINUX_API_KEY',
    appId: 'YOUR_LINUX_APP_ID',
    messagingSenderId: 'YOUR_LINUX_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
  );
}