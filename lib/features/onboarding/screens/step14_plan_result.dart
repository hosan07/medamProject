import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_layout.dart';

class Step14PlanResultScreen extends ConsumerWidget {
  const Step14PlanResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);

    return OnboardingLayout(
      step: 14,
      title: '${state.nickname}님의 기본 계획이에요',
      primaryLabel: '계획 확인하기',
      onPrimary: () => goNext(context, 14),
      child: Column(
        children: [
          _SummaryCard(
            rows: [
              ('목표', state.goal ?? '-'),
              ('목표 이유', state.goalReason ?? '-'),
              ('현재 체중', '${state.currentWeight.toStringAsFixed(1)}kg'),
              ('목표 체중', '${state.targetWeight.toStringAsFixed(1)}kg'),
              ('AI 코치', state.aiCoach ?? '-'),
            ],
          ),
          const SizedBox(height: 12),
          _MetricGrid(
            metrics: [
              ('기초대사량', '${state.bmr}kcal'),
              ('활동 대사량', '${state.tdee}kcal'),
              ('목표 칼로리', '${state.targetCalories}kcal'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Expanded(child: Text(row.$1)),
                  Text(
                    row.$2,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<(String, String)> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 560;
        return GridView.count(
          crossAxisCount: isWide ? 3 : 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: isWide ? 1.5 : 4,
          children: [
            for (final metric in metrics)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(metric.$1),
                    const SizedBox(height: 6),
                    Text(
                      metric.$2,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
