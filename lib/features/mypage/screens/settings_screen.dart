import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('테마 설정')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _ThemeTile(
                title: '시스템 설정',
                subtitle: '기기의 라이트/다크 모드를 따라가요',
                selected: themeMode == ThemeMode.system,
                onTap: () => ref.read(themeModeProvider.notifier).setSystem(),
              ),
              _ThemeTile(
                title: '라이트 모드',
                subtitle: '흰 배경과 검은 텍스트로 표시해요',
                selected: themeMode == ThemeMode.light,
                onTap: () => ref.read(themeModeProvider.notifier).setLight(),
              ),
              _ThemeTile(
                title: '다크 모드',
                subtitle: 'Toss 스타일의 어두운 배경으로 표시해요',
                selected: themeMode == ThemeMode.dark,
                onTap: () => ref.read(themeModeProvider.notifier).setDark(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
        trailing: selected
            ? Icon(
                Icons.check_circle_rounded,
                color: Theme.of(context).colorScheme.primary,
              )
            : const Icon(Icons.circle_outlined),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
