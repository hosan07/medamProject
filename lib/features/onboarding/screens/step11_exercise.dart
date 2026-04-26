import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_layout.dart';

class Step11ExerciseScreen extends ConsumerWidget {
  const Step11ExerciseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider).exerciseTypes;
    final options = ['헬스', '유산소', '홈트', '필라테스', '요가', '걷기', '스포츠'];

    return OnboardingLayout(
      step: 11,
      title: '주로 하는 운동이 있나요?',
      subtitle: '여러 개를 선택할 수 있어요.',
      primaryLabel: '다음',
      onPrimary: () => goNext(context, 11),
      secondary: TextButton(
        onPressed: () {
          ref.read(onboardingProvider.notifier).skipExerciseTypes();
          goNext(context, 11);
        },
        child: const Text('건너뛰기'),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final value in options)
            FilterChip(
              label: Text(value),
              selected: selected.contains(value),
              onSelected: (_) => ref
                  .read(onboardingProvider.notifier)
                  .toggleExerciseType(value),
            ),
        ],
      ),
    );
  }
}
