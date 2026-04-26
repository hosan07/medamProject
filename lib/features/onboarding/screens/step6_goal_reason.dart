import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_layout.dart';

class Step6GoalReasonScreen extends ConsumerWidget {
  const Step6GoalReasonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final goal = state.goal ?? '목표';
    final reasons = _reasons(goal);

    return OnboardingLayout(
      step: 6,
      title: '$goal을 하려는 이유는?',
      primaryLabel: '다음',
      primaryEnabled: state.goalReason != null,
      onPrimary: () => goNext(context, 6),
      child: ResponsiveOptionGrid(
        children: [
          for (final value in reasons)
            OnboardingOptionCard(
              title: value,
              selected: state.goalReason == value,
              onTap: () =>
                  ref.read(onboardingProvider.notifier).updateGoalReason(value),
            ),
        ],
      ),
    );
  }

  List<String> _reasons(String goal) {
    return switch (goal) {
      '감량' => ['옷핏을 바꾸고 싶어요', '건강검진 결과가 신경 쓰여요', '체력을 올리고 싶어요', '자신감을 되찾고 싶어요'],
      '증량' => ['마른 체형을 바꾸고 싶어요', '근력을 키우고 싶어요', '체력을 늘리고 싶어요', '식습관을 개선하고 싶어요'],
      '유지' => [
        '현재 몸을 오래 유지하고 싶어요',
        '요요를 막고 싶어요',
        '생활 루틴을 만들고 싶어요',
        '건강하게 먹고 싶어요',
      ],
      '근육량 증가' => [
        '탄탄한 몸을 만들고 싶어요',
        '운동 성과를 보고 싶어요',
        '대사량을 높이고 싶어요',
        '자세와 체형을 개선하고 싶어요',
      ],
      _ => [
        '복부 지방을 줄이고 싶어요',
        '눈바디 변화를 보고 싶어요',
        '건강 수치를 개선하고 싶어요',
        '가볍게 움직이고 싶어요',
      ],
    };
  }
}
