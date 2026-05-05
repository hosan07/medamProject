import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/medam_placeholder.dart';
import '../providers/home_provider.dart';
import '../providers/record_detail_provider.dart';

class DailyDetailScreen extends ConsumerWidget {
  const DailyDetailScreen({required this.dateKey, super.key});

  final String dateKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = DateFormat('yyyy-MM-dd').parse(dateKey);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(DateFormat('M월 d일 기록').format(selectedDate)),
          bottom: const TabBar(
            tabs: [
              Tab(text: '일간'),
              Tab(text: '주간'),
              Tab(text: '월간'),
            ],
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: TabBarView(
              children: [
                _DailyTab(dateKey: dateKey),
                _WeeklyTab(dateKey: dateKey),
                _MonthlyTab(dateKey: dateKey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyTab extends ConsumerWidget {
  const _DailyTab({required this.dateKey});

  final String dateKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daily = ref.watch(dailyRecordProvider(dateKey));

    return daily.when(
      data: (data) {
        final grouped = {
          for (final mealType in const ['아침', '점심', '저녁', '간식'])
            mealType:
                data.meals.where((item) => item.mealType == mealType).toList(),
        };

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
          children: [
            _SummaryCard(data: data),
            const SizedBox(height: 14),
            for (final entry in grouped.entries)
              _MealGroup(mealType: entry.key, meals: entry.value),
            _WaterExerciseCard(data: data),
          ],
        );
      },
      loading: () => const MedamListPlaceholder(itemCount: 3),
      error: (error, _) => Center(child: Text(error.toString())),
    );
  }
}

class _WeeklyTab extends ConsumerWidget {
  const _WeeklyTab({required this.dateKey});

  final String dateKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekly = ref.watch(weeklyRecordProvider(dateKey));

    return weekly.when(
      data: (data) => ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
        children: [
          _BarChartCard(title: '최근 7일 칼로리', days: data.days),
          const SizedBox(height: 14),
          _MetricGrid(
            metrics: [
              ('7일 평균 칼로리', '${data.averageCalories}kcal'),
              ('탄수화물 평균', '${data.averageCarbs}g'),
              ('단백질 평균', '${data.averageProtein}g'),
              ('지방 평균', '${data.averageFat}g'),
            ],
          ),
        ],
      ),
      loading: () => const MedamListPlaceholder(itemCount: 3),
      error: (error, _) => Center(child: Text(error.toString())),
    );
  }
}

class _MonthlyTab extends ConsumerWidget {
  const _MonthlyTab({required this.dateKey});

  final String dateKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthly = ref.watch(monthlyRecordProvider(dateKey));

    return monthly.when(
      data: (data) => ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
        children: [
          _BarChartCard(title: '월간 칼로리', days: data.days, dense: true),
          const SizedBox(height: 14),
          _MetricGrid(
            metrics: [
              ('월 평균 칼로리', '${data.averageCalories}kcal'),
              ('가장 많이 먹은 날', _dayText(data.maxDay)),
              ('가장 적게 먹은 날', _dayText(data.minDay)),
            ],
          ),
        ],
      ),
      loading: () => const MedamListPlaceholder(itemCount: 3),
      error: (error, _) => Center(child: Text(error.toString())),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final DailyRecordData data;

  @override
  Widget build(BuildContext context) {
    final rate = data.calorieRate.clamp(0.0, 1.4);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '합계',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 92,
                  height: 92,
                  child: CircularProgressIndicator(
                    value: rate.clamp(0.0, 1.0),
                    strokeWidth: 10,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data.totalCalories} / ${data.targetCalories}kcal',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '목표 대비 ${(data.calorieRate * 100).round()}%',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _MacroRow(carbs: data.carbs, protein: data.protein, fat: data.fat),
          ],
        ),
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  final int carbs;
  final int protein;
  final int fat;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MacroChip(label: '탄수화물', value: '${carbs}g'),
        _MacroChip(label: '단백질', value: '${protein}g'),
        _MacroChip(label: '지방', value: '${fat}g'),
      ],
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label $value'),
      backgroundColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.12),
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w900,
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

class _WaterExerciseCard extends StatelessWidget {
  const _WaterExerciseCard({required this.data});

  final DailyRecordData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _InfoRow(
              icon: Icons.water_drop_rounded,
              title: '물 섭취량',
              value: data.waterMl <= 0 ? '기록 없음' : '${data.waterMl}ml',
            ),
            const Divider(height: 24),
            _InfoRow(
              icon: Icons.fitness_center_rounded,
              title: '운동 기록',
              value: data.exerciseMinutes <= 0
                  ? '기록 없음'
                  : '${data.exerciseType} · ${data.exerciseMinutes}분',
            ),
            if (data.exerciseEntries.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final entry in data.exerciseEntries)
                _InfoRow(
                  icon: Icons.check_rounded,
                  title: entry.exerciseType,
                  value: '${entry.minutes}분',
                  compact: true,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: compact ? 18 : 24),
        SizedBox(width: compact ? 8 : 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _BarChartCard extends StatelessWidget {
  const _BarChartCard({
    required this.title,
    required this.days,
    this.dense = false,
  });

  final String title;
  final List<DailySummaryData> days;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final maxCalories = days.fold<int>(
      1,
      (max, day) => day.calories > max ? day.calories : max,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: dense ? 180 : 220,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final day in days)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: dense ? 1.5 : 4,
                        ),
                        child: _CalorieBar(
                          day: day,
                          maxCalories: maxCalories,
                          dense: dense,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalorieBar extends StatelessWidget {
  const _CalorieBar({
    required this.day,
    required this.maxCalories,
    required this.dense,
  });

  final DailySummaryData day;
  final int maxCalories;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final heightFactor = day.calories <= 0 ? 0.04 : day.calories / maxCalories;
    final label = DateFormat(
      'd',
    ).format(DateFormat('yyyy-MM-dd').parse(day.dateKey));
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (!dense)
          Text(
            '${day.calories}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        const SizedBox(height: 6),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: heightFactor.clamp(0.04, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const SizedBox(width: double.infinity),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
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
        final columns = constraints.maxWidth >= 720 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 104,
          ),
          itemCount: metrics.length,
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      metric.$1,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      metric.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

String _dayText(DailySummaryData? day) {
  if (day == null) {
    return '기록 없음';
  }
  final date = DateFormat('yyyy-MM-dd').parse(day.dateKey);
  return '${DateFormat('M월 d일').format(date)} · ${day.calories}kcal';
}
