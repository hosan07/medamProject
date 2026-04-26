import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medam/app/app.dart';

void main() {
  testWidgets('미담 앱이 스플래시 라우트로 시작한다', (WidgetTester tester) async {
    // Firebase 초기화는 main.dart에서 담당하므로, 위젯 테스트는 앱 shell만 검증합니다.
    await tester.pumpWidget(const ProviderScope(child: MedamApp()));

    await tester.pump();

    expect(find.text('미담'), findsOneWidget);
    expect(find.text('스플래시 화면'), findsOneWidget);
  });
}
