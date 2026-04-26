import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routes.dart';
import 'theme.dart';

class MedamApp extends ConsumerWidget {
  const MedamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 라우터와 테마 모드는 Riverpod에서 관리해 화면 전체가 즉시 반응하도록 둡니다.
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

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
