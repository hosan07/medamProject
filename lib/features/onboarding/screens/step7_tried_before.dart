import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_layout.dart';

class Step7TriedBeforeScreen extends ConsumerWidget {
  const Step7TriedBeforeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final triedBefore = ref.watch(onboardingProvider).triedBefore;
    final options = ['처음이에요', '몇 번 시도 후 실패', '꾸준히 해봤어요'];

    return OnboardingLayout(
      step: 7,
      title: '이전에 시도해본 적 있나요?',
      primaryLabel: '다음',
      primaryEnabled: triedBefore != null,
      onPrimary: () => goNext(context, 7),
      child: ResponsiveOptionGrid(
        children: [
          for (final value in options)
            OnboardingOptionCard(
              title: value,
              selected: triedBefore == value,
              onTap: () => ref
                  .read(onboardingProvider.notifier)
                  .updateTriedBefore(value),
            ),
        ],
      ),
    );
  }
}
