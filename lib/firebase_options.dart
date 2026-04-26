// File generated for the Medam Firebase project configuration.
//
// FlutterFire CLI 실행 환경이 전역 Firebase CLI/Node 버전과 충돌해서,
// 현재 프로젝트에 포함된 google-services.json 및 GoogleService-Info.plist 값을 기준으로 생성했습니다.
// 다른 Flutter 프로젝트나 전역 SDK 설정에는 영향을 주지 않습니다.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        '미담은 현재 iOS와 Android 우선으로 Firebase가 설정되어 있습니다.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          '미담은 현재 iOS와 Android 우선으로 Firebase가 설정되어 있습니다.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDV5YIF7lPabubEe-btk2j7UPQ7Fod68Fs',
    appId: '1:144719086854:android:c48ff2b928873006acca87',
    messagingSenderId: '144719086854',
    projectId: 'medam-c9446',
    storageBucket: 'medam-c9446.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAVzQ59vBMUrzHoP0SyoR47x-ZNLAb1-Xo',
    appId: '1:144719086854:ios:35fb6fc8c5df14eeacca87',
    messagingSenderId: '144719086854',
    projectId: 'medam-c9446',
    storageBucket: 'medam-c9446.firebasestorage.app',
    iosBundleId: 'com.medam.app',
  );
}
