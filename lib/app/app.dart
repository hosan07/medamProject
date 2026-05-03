import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/notification_repository.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/notification/providers/notification_provider.dart';
import 'routes.dart';
import 'theme.dart';

class MedamApp extends ConsumerStatefulWidget {
  const MedamApp({super.key});

  @override
  ConsumerState<MedamApp> createState() => _MedamAppState();
}

class _MedamAppState extends ConsumerState<MedamApp> {
  String? _syncedUid;

  @override
  Widget build(BuildContext context) {
    // 라우터와 테마 모드는 Riverpod에서 관리해 화면 전체가 즉시 반응하도록 둡니다.
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final user = ref.watch(currentUserProvider);

    if (user != null && _syncedUid != user.uid) {
      _syncedUid = user.uid;
      unawaited(
        ref
            .read(notificationRepositoryProvider)
            .requestPermissionAndSaveFcmToken(
              user.uid,
            ),
      );
    }

    ref.listen(notificationDeepLinkProvider, (previous, next) {
      final route = next.value;
      if (route != null && route.isNotEmpty) {
        router.push(route);
      }
    });

    return MaterialApp.router(
      title: '미담',
      debugShowCheckedModeBanner: false,
      theme: MedamTheme.light,
      darkTheme: MedamTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
