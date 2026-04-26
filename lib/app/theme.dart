import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const Color medamPrimaryColor = Color(0xFF4CAF82);
const Color medamDarkBackgroundColor = Color(0xFF131416);

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  // 초기 세팅 단계에서는 메모리 상태로 두고, 설정 화면에서 SharedPreferences 저장을 붙입니다.
  void setSystem() => state = ThemeMode.system;

  void setLight() => state = ThemeMode.light;

  void setDark() => state = ThemeMode.dark;
}

class MedamTheme {
  const MedamTheme._();

  static ThemeData get light {
    return _base(
      brightness: Brightness.light,
      background: Colors.white,
      foreground: Colors.black,
      surface: const Color(0xFFF7F8FA),
    );
  }

  static ThemeData get dark {
    return _base(
      brightness: Brightness.dark,
      background: medamDarkBackgroundColor,
      foreground: Colors.white,
      surface: const Color(0xFF1D1F22),
    );
  }

  static ThemeData _base({
    required Brightness brightness,
    required Color background,
    required Color foreground,
    required Color surface,
  }) {
    // Material 3 ColorScheme을 기준으로 두되, 미담의 핵심 색과 배경색은 명시합니다.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: medamPrimaryColor,
      brightness: brightness,
      primary: medamPrimaryColor,
      surface: surface,
      onSurface: foreground,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Pretendard',
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      textTheme: Typography.material2021(platform: TargetPlatform.iOS).black
          .apply(
            fontFamily: 'Pretendard',
            bodyColor: foreground,
            displayColor: foreground,
          ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: foreground,
        titleTextStyle: TextStyle(
          color: foreground,
          fontFamily: 'Pretendard',
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: medamPrimaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: medamPrimaryColor, width: 1.4),
        ),
      ),
    );
  }
}
