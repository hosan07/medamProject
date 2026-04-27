import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/medam_logo.dart';
import '../../../data/repositories/auth_repository.dart';
import '../providers/auth_provider.dart';

enum _SignInProviderType { google, apple }

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_authErrorMessage(error))));
        },
      );
    });

    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 36),
                  const MedamLogo(size: 82),
                  const SizedBox(height: 18),
                  Text(
                    '찍어서 담는 나의 오늘',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  _LoginButton(
                    label: 'Google로 시작하기',
                    iconText: 'G',
                    isLoading: isLoading,
                    onPressed: () => _showConsentSheet(
                      context: context,
                      ref: ref,
                      providerType: _SignInProviderType.google,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LoginButton(
                    label: 'Apple로 시작하기',
                    iconText: 'A',
                    isDark: true,
                    isLoading: isLoading,
                    onPressed: () => _showConsentSheet(
                      context: context,
                      ref: ref,
                      providerType: _SignInProviderType.apple,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showConsentSheet({
    required BuildContext context,
    required WidgetRef ref,
    required _SignInProviderType providerType,
  }) async {
    final agreed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _ConsentBottomSheet(),
    );

    if (agreed != true || !context.mounted) {
      return;
    }

    final notifier = ref.read(authProvider.notifier);
    switch (providerType) {
      case _SignInProviderType.google:
        await notifier.signInWithGoogle();
      case _SignInProviderType.apple:
        await notifier.signInWithApple();
    }
  }

  String _authErrorMessage(Object error) {
    if (error is AuthRepositoryException) {
      return error.message;
    }
    return '로그인 중 문제가 발생했어요. 잠시 후 다시 시도해 주세요.';
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.label,
    required this.iconText,
    required this.onPressed,
    required this.isLoading,
    this.isDark = false,
  });

  final String label;
  final String iconText;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final background = isDark ? Colors.black : Colors.white;
    final foreground = isDark ? Colors.white : Colors.black;

    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background.withValues(alpha: 0.5),
          disabledForegroundColor: foreground.withValues(alpha: 0.5),
          side: isDark
              ? BorderSide.none
              : BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: isLoading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    iconText,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(label),
                ],
              ),
      ),
    );
  }
}

class _ConsentBottomSheet extends StatefulWidget {
  const _ConsentBottomSheet();

  @override
  State<_ConsentBottomSheet> createState() => _ConsentBottomSheetState();
}

class _ConsentBottomSheetState extends State<_ConsentBottomSheet> {
  final Map<_ConsentType, bool> _checks = {
    for (final type in _ConsentType.values) type: false,
  };

  bool get _allChecked => _checks.values.every((checked) => checked);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '서비스 이용 동의',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _allChecked,
            onChanged: (value) => _setAll(value ?? false),
            title: const Text('전체 동의'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(height: 12),
          for (final type in _ConsentType.values)
            _ConsentTile(
              type: type,
              checked: _checks[type] ?? false,
              onChanged: (value) => setState(() {
                _checks[type] = value;
              }),
            ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _allChecked
                ? () => Navigator.of(context).pop(true)
                : null,
            child: const Text('동의하고 계속하기'),
          ),
        ],
      ),
    );
  }

  void _setAll(bool value) {
    setState(() {
      for (final type in _ConsentType.values) {
        _checks[type] = value;
      }
    });
  }
}

class _ConsentTile extends StatelessWidget {
  const _ConsentTile({
    required this.type,
    required this.checked,
    required this.onChanged,
  });

  final _ConsentType type;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: checked,
      onChanged: (value) => onChanged(value ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Expanded(child: Text(type.label)),
          IconButton(
            tooltip: '${type.title} 보기',
            onPressed: () => _openTerms(context, type.url),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  Future<void> _openTerms(BuildContext context, Uri url) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!opened) {
      messenger.showSnackBar(const SnackBar(content: Text('약관 페이지를 열 수 없어요.')));
    }
  }
}

enum _ConsentType {
  terms(
    title: '이용약관',
    label: '이용약관 동의 (필수)',
    urlText: 'https://medam.app/terms',
  ),
  privacy(
    title: '개인정보 수집 및 이용 동의',
    label: '개인정보 수집 및 이용 동의 (필수)',
    urlText: 'https://medam.app/privacy',
  ),
  sensitive(
    title: '민감정보 수집 및 이용 동의',
    label: '민감정보 수집 및 이용 동의 (필수)',
    urlText: 'https://medam.app/sensitive-info',
  ),
  age(
    title: '만 14세 이상 확인',
    label: '만 14세 이상입니다 (필수)',
    urlText: 'https://medam.app/age-policy',
  );

  const _ConsentType({
    required this.title,
    required this.label,
    required this.urlText,
  });

  final String title;
  final String label;
  final String urlText;

  Uri get url => Uri.parse(urlText);
}
