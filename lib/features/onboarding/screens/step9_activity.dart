import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_layout.dart';

class Step9ActivityScreen extends ConsumerWidget {
  const Step9ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(onboardingProvider).activityLevel;
    final options = [
      ('매우 적음', Icons.chair_rounded),
      ('적음', Icons.directions_walk_rounded),
      ('보통', Icons.directions_run_rounded),
      ('많음', Icons.fitness_center_rounded),
      ('매우 많음', Icons.local_fire_department_rounded),
    ];

    return OnboardingLayout(
      step: 9,
      title: '평소 활동량은 어떤 편인가요?',
      primaryLabel: '다음',
      primaryEnabled: activity != null,
      onPrimary: () => goNext(context, 9),
      child: ResponsiveOptionGrid(
        children: [
          for (final option in options)
            OnboardingOptionCard(
              title: option.$1,
              icon: option.$2,
              selected: activity == option.$1,
              onTap: () => ref
                  .read(onboardingProvider.notifier)
                  .updateActivityLevel(option.$1),
            ),
        ],
      ),
    );
  }
}
