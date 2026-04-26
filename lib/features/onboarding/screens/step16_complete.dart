import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_layout.dart';

class Step16CompleteScreen extends ConsumerStatefulWidget {
  const Step16CompleteScreen({super.key});

  @override
  ConsumerState<Step16CompleteScreen> createState() =>
      _Step16CompleteScreenState();
}

class _Step16CompleteScreenState extends ConsumerState<Step16CompleteScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);

    return OnboardingLayout(
      step: 16,
      title: '준비가 끝났어요',
      subtitle: '${state.nickname}님의 오늘을 미담에 담아볼까요?',
      primaryLabel: _saving ? '저장 중...' : '시작하기',
      primaryEnabled: !_saving,
      onPrimary: _complete,
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Lottie.network(
              'https://assets10.lottiefiles.com/packages/lf20_touohxv0.json',
              repeat: true,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.celebration_rounded,
                  size: 96,
                  color: Theme.of(context).colorScheme.primary,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Row(label: '목표', value: state.goal ?? '-'),
                _Row(label: '목표 칼로리', value: '${state.targetCalories}kcal'),
                _Row(label: '식단 유형', value: state.recommendedDiet ?? '-'),
                _Row(label: 'AI 코치', value: state.aiCoach ?? '-'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _complete() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      context.go('/login');
      return;
    }

    setState(() => _saving = true);
    await ref.read(onboardingProvider.notifier).saveProfile(user.uid);
    await Permission.notification.request();
    ref.invalidate(hasUserProfileProvider);

    if (!mounted) {
      return;
    }
    context.go('/home');
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
