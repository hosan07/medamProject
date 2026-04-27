import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/home_provider.dart';

class DailyDetailScreen extends ConsumerWidget {
  const DailyDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meals = ref.watch(todayMealsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('오늘의 식단')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: meals.when(
            data: (items) {
              if (items.isEmpty) {
                return const Center(child: Text('오늘 기록한 식단이 없어요.'));
              }

              final grouped = {
                for (final mealType in const ['아침', '점심', '저녁', '간식'])
                  mealType: items
                      .where((item) => item.mealType == mealType)
                      .toList(),
              };

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                children: [
                  for (final entry in grouped.entries)
                    _MealGroup(mealType: entry.key, meals: entry.value),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text(error.toString())),
          ),
        ),
      ),
    );
  }
}

class _MealGroup extends StatelessWidget {
  const _MealGroup({required this.mealType, required this.meals});

  final String mealType;
  final List<HomeMealEntry> meals;

  @override
  Widget build(BuildContext context) {
    final calories = meals.fold<int>(
      0,
      (previous, meal) => previous + meal.calories,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    mealType,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${meals.length}개 · ${calories}kcal',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (meals.isEmpty)
              Text(
                '기록 없음',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              for (final meal in meals) _MealTile(meal: meal),
          ],
        ),
      ),
    );
  }
}

class _MealTile extends StatelessWidget {
  const _MealTile({required this.meal});

  final HomeMealEntry meal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.foodName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  '탄 ${meal.carbs}g · 단 ${meal.protein}g · 지 ${meal.fat}g',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${meal.calories}kcal',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
