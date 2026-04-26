import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_layout.dart';

class Step12AiCoachScreen extends ConsumerWidget {
  const Step12AiCoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coach = ref.watch(onboardingProvider).aiCoach;
    final options = [
      ('다온', '차분하게 루틴을 잡아주는 코치', Icons.spa_rounded),
      ('루미', '밝고 가볍게 응원해주는 코치', Icons.wb_sunny_rounded),
      ('하준', '데이터로 정확하게 피드백하는 코치', Icons.insights_rounded),
    ];

    return OnboardingLayout(
      step: 12,
      title: 'AI 코치를 선택해주세요',
      primaryLabel: '다음',
      primaryEnabled: coach != null,
      onPrimary: () => goNext(context, 12),
      child: ResponsiveOptionGrid(
        children: [
          for (final option in options)
            OnboardingOptionCard(
              title: option.$1,
              subtitle: option.$2,
              icon: option.$3,
              selected: coach == option.$1,
              onTap: () => ref
                  .read(onboardingProvider.notifier)
                  .updateAiCoach(option.$1),
            ),
        ],
      ),
    );
  }
}
