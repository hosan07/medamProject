import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_layout.dart';

class Step3GenderScreen extends ConsumerWidget {
  const Step3GenderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gender = ref.watch(onboardingProvider).gender;

    return OnboardingLayout(
      step: 3,
      title: '성별을 선택해주세요',
      subtitle: '기초대사량 계산에만 사용돼요.',
      primaryLabel: '다음',
      primaryEnabled: gender != null,
      onPrimary: () => goNext(context, 3),
      child: ResponsiveOptionGrid(
        children: [
          for (final value in ['남성', '여성'])
            OnboardingOptionCard(
              title: value,
              icon: value == '남성' ? Icons.male_rounded : Icons.female_rounded,
              selected: gender == value,
              onTap: () =>
                  ref.read(onboardingProvider.notifier).updateGender(value),
            ),
        ],
      ),
    );
  }
}
