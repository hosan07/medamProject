import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ads/ad_manager.dart';
import '../../../core/widgets/medam_placeholder.dart';
import '../../auth/providers/auth_provider.dart';
import '../../mypage/providers/monetization_provider.dart';
import '../../notification/providers/notification_provider.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeData = ref.watch(todayHomeDataProvider);
    final showAds = !ref.watch(isSubscribedProvider);
    final hasUnread = ref.watch(hasUnreadNotificationsProvider).value ?? false;

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
              if (hasUnread)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF3B30),
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
        data: (data) => _HomeBody(data: data, showAds: showAds),
        loading: () => const MedamListPlaceholder(itemCount: 3),
        error: (error, stackTrace) =>
            _HomeBody(data: TodayHomeData.empty(), showAds: showAds),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.data, required this.showAds});

  final TodayHomeData data;
  final bool showAds;

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
                          if (showAds) ...[
                            const SizedBox(height: 14),
                            const _HomeAdCard(),
                          ],
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
                        if (showAds) ...[
                          const SizedBox(height: 14),
                          const _HomeAdCard(),
                        ],
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

class _HomeAdCard extends StatelessWidget {
  const _HomeAdCard();

  @override
  Widget build(BuildContext context) {
    return _HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '추천',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const MedamBannerAd(),
        ],
      ),
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
                width: 110,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: data.calorieProgress,
                      strokeWidth: 8,
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
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '/ ${data.targetCalories}kcal',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.1,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              for (final item in items)
                _MealAddCard(
                  label: item.$1,
                  icon: item.$2,
                  count: data.mealCounts[item.$1] ?? 0,
                  onTap: () => _onMealTap(context, item.$1),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _onMealTap(BuildContext context, String mealType) {
    if (!const ['아침', '점심', '저녁', '간식'].contains(mealType)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$mealType 기록은 다음 단계에서 연결할게요.')));
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _MealEntryBottomSheet(mealType: mealType),
    );
  }
}

class _MealAddCard extends StatelessWidget {
  const _MealAddCard({
    required this.label,
    required this.icon,
    required this.count,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle_rounded, size: 18),
                const SizedBox(width: 4),
                Text(count > 0 ? '$count개' : '추가'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MealEntryBottomSheet extends ConsumerStatefulWidget {
  const _MealEntryBottomSheet({required this.mealType});

  final String mealType;

  @override
  ConsumerState<_MealEntryBottomSheet> createState() =>
      _MealEntryBottomSheetState();
}

class _MealEntryBottomSheetState extends ConsumerState<_MealEntryBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _foodNameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _carbsController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _foodNameController.dispose();
    _caloriesController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.mealType} 식단 추가',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _foodNameController,
              decoration: const InputDecoration(labelText: '음식명'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? '음식명을 입력해 주세요.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _caloriesController,
              decoration: const InputDecoration(labelText: '칼로리(kcal)'),
              keyboardType: TextInputType.number,
              validator: _requiredNumber,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _carbsController,
                    decoration: const InputDecoration(labelText: '탄수화물(g)'),
                    keyboardType: TextInputType.number,
                    validator: _requiredNumber,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _proteinController,
                    decoration: const InputDecoration(labelText: '단백질(g)'),
                    keyboardType: TextInputType.number,
                    validator: _requiredNumber,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _fatController,
                    decoration: const InputDecoration(labelText: '지방(g)'),
                    keyboardType: TextInputType.number,
                    validator: _requiredNumber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text('저장하기'),
            ),
          ],
        ),
      ),
    );
  }

  String? _requiredNumber(String? value) {
    final number = int.tryParse(value?.trim() ?? '');
    if (number == null || number < 0) {
      return '0 이상 숫자';
    }
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref
          .read(homeRepositoryProvider)
          .addMeal(
            uid: user.uid,
            mealType: widget.mealType,
            foodName: _foodNameController.text.trim(),
            calories: int.parse(_caloriesController.text.trim()),
            carbs: int.parse(_carbsController.text.trim()),
            protein: int.parse(_proteinController.text.trim()),
            fat: int.parse(_fatController.text.trim()),
          );
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _ChangeSection extends StatefulWidget {
  const _ChangeSection({required this.data});

  final TodayHomeData data;

  @override
  State<_ChangeSection> createState() => _ChangeSectionState();
}

class _ChangeSectionState extends State<_ChangeSection>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_index != _tabController.index) {
        setState(() => _index = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: '나의 변화'),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelPadding: const EdgeInsets.only(right: 22),
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: '체중 그래프'),
              Tab(text: '눈바디 앨범'),
            ],
          ),
          const SizedBox(height: 16),
          IndexedStack(
            index: _index,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BmiChip(value: widget.data.bmi),
                  const SizedBox(height: 14),
                  _WeightChart(values: widget.data.weightChange),
                ],
              ),
              _BodyAlbumTab(urls: widget.data.bodyPhotoUrls),
            ],
          ),
        ],
      ),
    );
  }
}

class _BodyAlbumTab extends StatelessWidget {
  const _BodyAlbumTab({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push('/photo-album'),
            child: const Text('앨범 보기 >'),
          ),
        ),
        _BodyPhotoPreview(urls: urls),
      ],
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
    final visibleUrls = urls.where((url) {
      if (url.startsWith('http')) {
        return true;
      }
      return File(url).existsSync();
    }).toList();

    return SizedBox(
      height: 160,
      child: visibleUrls.isEmpty
          ? Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [Text('아직 눈바디 사진이 없어요')],
              ),
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final path = visibleUrls[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: path.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: path,
                          width: 112,
                          height: 160,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => ColoredBox(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainer,
                          ),
                          errorWidget: (context, url, error) => ColoredBox(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainer,
                            child: const Icon(
                              Icons.image_not_supported_rounded,
                            ),
                          ),
                        )
                      : Image.file(
                          File(path),
                          width: 112,
                          height: 160,
                          fit: BoxFit.cover,
                        ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemCount: visibleUrls.length,
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
