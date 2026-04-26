import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_layout.dart';

class Step15DietTypeScreen extends ConsumerWidget {
  const Step15DietTypeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diet = ref.watch(onboardingProvider).recommendedDiet;
    final options = [
      ('운동(단백질)', '단백질을 충분히 챙기는 방식'),
      ('일반(탄단지)', '탄수화물, 단백질, 지방을 균형 있게'),
      ('키토제닉', '탄수화물을 낮추고 지방 비율을 높게'),
      ('비건', '식물성 식단 중심으로 건강하게'),
    ];

    return OnboardingLayout(
      step: 15,
      title: '추천 식단 유형을 선택해주세요',
      primaryLabel: '다음',
      primaryEnabled: diet != null,
      onPrimary: () => goNext(context, 15),
      child: ResponsiveOptionGrid(
        children: [
          for (final option in options)
            OnboardingOptionCard(
              title: option.$1,
              subtitle: option.$2,
              selected: diet == option.$1,
              onTap: () => ref
                  .read(onboardingProvider.notifier)
                  .updateRecommendedDiet(option.$1),
            ),
        ],
      ),
    );
  }
}
