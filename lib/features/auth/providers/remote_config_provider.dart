import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final splashAdVisibleProvider = FutureProvider<bool>((ref) async {
  final remoteConfig = FirebaseRemoteConfig.instance;

  await remoteConfig.setDefaults(const {'splash_ad_enabled': false});

  await remoteConfig.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 4),
      minimumFetchInterval: const Duration(hours: 1),
    ),
  );

  await remoteConfig.fetchAndActivate();
  return remoteConfig.getBool('splash_ad_enabled');
});
