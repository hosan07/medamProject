import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'core/ads/ad_manager.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 기반 기능(Auth, Firestore, Analytics 등)을 앱 시작 전에 준비합니다.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('ko_KR', null);
  await AdManager.initialize();
  AdManager.instance.initInterstitialAd();

  runApp(const ProviderScope(child: MedamApp()));
}
