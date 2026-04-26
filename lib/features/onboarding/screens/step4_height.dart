import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_layout.dart';

class Step4HeightScreen extends ConsumerWidget {
  const Step4HeightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final height = ref.watch(onboardingProvider).height;

    return OnboardingLayout(
      step: 4,
      title: '키를 알려주세요',
      subtitle: '140cm부터 220cm까지 선택할 수 있어요.',
      primaryLabel: '다음',
      onPrimary: () => goNext(context, 4),
      child: NumberPickerField(
        label: '키',
        value: height.toDouble(),
        min: 140,
        max: 220,
        suffix: 'cm',
        onChanged: (value) =>
            ref.read(onboardingProvider.notifier).updateHeight(value.round()),
      ),
    );
  }
}
