import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_layout.dart';

class Step8WeightScreen extends ConsumerWidget {
  const Step8WeightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);

    return OnboardingLayout(
      step: 8,
      title: '현재와 목표 체중을 알려주세요',
      primaryLabel: '다음',
      onPrimary: () => goNext(context, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 560;
          final fields = [
            NumberPickerField(
              label: '현재 체중',
              value: state.currentWeight,
              min: 30,
              max: 180,
              step: 0.5,
              suffix: 'kg',
              onChanged: ref
                  .read(onboardingProvider.notifier)
                  .updateCurrentWeight,
            ),
            NumberPickerField(
              label: '목표 체중',
              value: state.targetWeight,
              min: 30,
              max: 180,
              step: 0.5,
              suffix: 'kg',
              onChanged: ref
                  .read(onboardingProvider.notifier)
                  .updateTargetWeight,
            ),
          ];

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: fields[0]),
                const SizedBox(width: 12),
                Expanded(child: fields[1]),
              ],
            );
          }

          return Column(
            children: [fields[0], const SizedBox(height: 12), fields[1]],
          );
        },
      ),
    );
  }
}
