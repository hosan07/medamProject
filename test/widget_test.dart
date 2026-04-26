import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medam/features/auth/providers/remote_config_provider.dart';
import 'package:medam/features/auth/screens/splash_screen.dart';

void main() {
  testWidgets('미담 앱이 스플래시 라우트로 시작한다', (WidgetTester tester) async {
    // Firebase 초기화가 필요한 앱 shell 대신, 스플래시 화면을 provider override로 격리합니다.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [splashAdVisibleProvider.overrideWith((ref) async => false)],
        child: const MaterialApp(
          home: SplashScreen(enableAutoNavigation: false),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('미담'), findsOneWidget);
    expect(find.text('찍어서 담는 나의 오늘'), findsOneWidget);
  });
}
