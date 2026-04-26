import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_layout.dart';

class Step10WaterScreen extends ConsumerWidget {
  const Step10WaterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final water = ref.watch(onboardingProvider).waterIntake;
    final options = ['0.5L 이하', '1L', '1.5L', '2L', '2.5L 이상', '모름'];

    return OnboardingLayout(
      step: 10,
      title: '하루에 물을 얼마나 마시나요?',
      primaryLabel: '다음',
      primaryEnabled: water != null,
      onPrimary: () => goNext(context, 10),
      child: ResponsiveOptionGrid(
        children: [
          for (final value in options)
            OnboardingOptionCard(
              title: value,
              icon: Icons.water_drop_rounded,
              selected: water == value,
              onTap: () => ref
                  .read(onboardingProvider.notifier)
                  .updateWaterIntake(value),
            ),
        ],
      ),
    );
  }
}
