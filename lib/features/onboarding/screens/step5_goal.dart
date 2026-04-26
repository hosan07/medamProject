import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_layout.dart';

class Step5GoalScreen extends ConsumerWidget {
  const Step5GoalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(onboardingProvider).goal;
    final goals = ['감량', '증량', '유지', '근육량 증가', '체지방률 감소'];

    return OnboardingLayout(
      step: 5,
      title: '가장 중요한 목표는 무엇인가요?',
      primaryLabel: '다음',
      primaryEnabled: goal != null,
      onPrimary: () => goNext(context, 5),
      child: ResponsiveOptionGrid(
        children: [
          for (final value in goals)
            OnboardingOptionCard(
              title: value,
              selected: goal == value,
              onTap: () =>
                  ref.read(onboardingProvider.notifier).updateGoal(value),
            ),
        ],
      ),
    );
  }
}
