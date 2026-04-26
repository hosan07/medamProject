import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeData = ref.watch(todayHomeDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('미담'),
        actions: [
          IconButton(
            tooltip: '캘린더',
            onPressed: () => context.push('/calendar'),
            icon: const Icon(Icons.calendar_month_rounded),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: '알림',
                onPressed: () => context.push('/notification'),
                icon: const Icon(Icons.notifications_rounded),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: homeData.when(
        data: (data) => _HomeBody(data: data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _HomeBody(data: TodayHomeData.empty()),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.data});

  final TodayHomeData data;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 112),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 760;

                    if (!isWide) {
                      return Column(
                        children: [
                          _TodayRecordCard(data: data),
                          const SizedBox(height: 14),
                          _MealAddSection(data: data),
                          const SizedBox(height: 14),
                          _ChangeSection(data: data),
                          const SizedBox(height: 14),
                          _ActivitySection(data: data),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: _TodayRecordCard(data: data),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 4,
                              child: _ActivitySection(data: data),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _MealAddSection(data: data),
                        const SizedBox(height: 14),
                        _ChangeSection(data: data),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _TodayRecordCard extends StatelessWidget {
  const _TodayRecordCard({required this.data});

  final TodayHomeData data;

  @override
  Widget build(BuildContext context) {
    return _HomeCard(
      onTap: () => context.push('/daily-detail'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: '오늘의 기록',
            actionLabel: '자세히 보기',
            onAction: () => context.push('/daily-detail'),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 112,
                height: 112,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: data.calorieProgress,
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.outlineVariant,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${data.consumedCalories}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text('/ ${data.targetCalories}kcal'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    _MacroProgress(
                      label: '탄수화물',
                      value: data.carbs,
                      target: data.carbsTarget,
                    ),
                    const SizedBox(height: 10),
                    _MacroProgress(
                      label: '단백질',
                      value: data.protein,
                      target: data.proteinTarget,
                    ),
                    const SizedBox(height: 10),
                    _MacroProgress(
                      label: '지방',
                      value: data.fat,
                      target: data.fatTarget,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroProgress extends StatelessWidget {
  const _MacroProgress({
    required this.label,
    required this.value,
    required this.target,
  });

  final String label;
  final int value;
  final int target;

  @override
  Widget build(BuildContext context) {
    final progress = target <= 0 ? 0.0 : (value / target).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Text('$value/$target g'),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(value: progress, minHeight: 8),
        ),
      ],
    );
  }
}

class _MealAddSection extends StatelessWidget {
  const _MealAddSection({required this.data});

  final TodayHomeData data;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('아침', Icons.wb_sunny_rounded),
      ('점심', Icons.restaurant_rounded),
      ('저녁', Icons.nights_stay_rounded),
      ('간식', Icons.cookie_rounded),
      ('물', Icons.water_drop_rounded),
      ('영양제', Icons.medication_rounded),
    ];

    return _HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: '식단 추가'),
          const SizedBox(height: 16),
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final item = items[index];
                final count = data.mealCounts[item.$1] ?? 0;
                return _MealAddCard(
                  label: item.$1,
                  icon: item.$2,
                  count: count,
                );
              },
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemCount: items.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealAddCard extends StatelessWidget {
  const _MealAddCard({
    required this.label,
    required this.icon,
    required this.count,
  });

  final String label;
  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const Spacer(),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.add_circle_rounded, size: 18),
              const SizedBox(width: 4),
              Text(count > 0 ? '$count개' : '추가'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChangeSection extends StatelessWidget {
  const _ChangeSection({required this.data});

  final TodayHomeData data;

  @override
  Widget build(BuildContext context) {
    return _HomeCard(
      onTap: () => context.push('/body-album'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: '나의 변화'),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 640;
              final chart = _WeightChart(values: data.weightChange);
              final album = _BodyPhotoPreview(urls: data.bodyPhotoUrls);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BmiChip(value: data.bmi),
                  const SizedBox(height: 14),
                  if (isWide)
                    Row(
                      children: [
                        Expanded(child: chart),
                        const SizedBox(width: 14),
                        Expanded(child: album),
                      ],
                    )
                  else ...[
                    chart,
                    const SizedBox(height: 14),
                    album,
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BmiChip extends StatelessWidget {
  const _BmiChip({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final label = value < 18.5
        ? '저체중'
        : value < 23
        ? '정상'
        : value < 25
        ? '과체중'
        : '관리 필요';
    final color = value < 23
        ? Theme.of(context).colorScheme.primary
        : const Color(0xFFE59F3A);

    return Chip(
      avatar: Icon(Icons.monitor_weight_rounded, color: color, size: 18),
      label: Text('BMI ${value.toStringAsFixed(1)} · $label'),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w900),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide.none,
    );
  }
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: CustomPaint(
        painter: _WeightLinePainter(
          values: values,
          color: Theme.of(context).colorScheme.primary,
          gridColor: Theme.of(context).colorScheme.outlineVariant,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _WeightLinePainter extends CustomPainter {
  const _WeightLinePainter({
    required this.values,
    required this.color,
    required this.gridColor,
  });

  final List<double> values;
  final Color color;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) {
      return;
    }

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = (maxValue - minValue).abs() < 0.1 ? 1.0 : maxValue - minValue;
    final path = Path();

    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - ((values[i] - minValue) / range * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _WeightLinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.gridColor != gridColor;
  }
}

class _BodyPhotoPreview extends StatelessWidget {
  const _BodyPhotoPreview({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: urls.isEmpty
          ? Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Text('아직 눈바디 사진이 없어요'),
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    urls[index],
                    width: 112,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemCount: urls.length,
            ),
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({required this.data});

  final TodayHomeData data;

  @override
  Widget build(BuildContext context) {
    return _HomeCard(
      onTap: () => context.push('/exercise-detail'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: '나의 활동'),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.fitness_center_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data.exerciseMinutes}분',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(data.exerciseType),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => context.push('/exercise'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('운동 추가하기'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}
