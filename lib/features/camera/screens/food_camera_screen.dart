import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/food_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/camera_provider.dart';

class FoodCameraScreen extends ConsumerStatefulWidget {
  const FoodCameraScreen({super.key});

  @override
  ConsumerState<FoodCameraScreen> createState() => _FoodCameraScreenState();
}

class _FoodCameraScreenState extends ConsumerState<FoodCameraScreen> {
  File? _image;
  FoodData? _result;
  bool _analyzing = false;
  bool _saving = false;
  late final TextEditingController _foodNameController;

  @override
  void initState() {
    super.initState();
    _foodNameController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final image = await ref.read(cameraCaptureProvider).capturePhoto();
    if (!mounted || image == null) {
      return;
    }
    setState(() {
      _image = image;
      _result = null;
      _analyzing = true;
    });

    final analyzed = await analyzeFoodMock(image);
    if (!mounted) {
      return;
    }
    _foodNameController.text = analyzed.foodName;
    setState(() {
      _result = analyzed;
      _analyzing = false;
    });
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider);
    final image = _image;
    final result = _result;
    if (user == null || image == null || result == null) {
      return;
    }

    final mealType = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => const _MealTypeSheet(),
    );
    if (mealType == null || !mounted) {
      return;
    }

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final repository = ref.read(foodRepositoryProvider);
    final imageUrl = await repository.uploadImage(
      uid: user.uid,
      file: image,
      folder: 'food_photos',
    );
    await repository.saveFood(
      uid: user.uid,
      mealType: mealType,
      foodData: result.copyWith(foodName: _foodNameController.text.trim()),
      imageUrl: imageUrl,
    );

    if (!mounted) {
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text('$mealType 기록에 추가했어요.')));
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('음식 칼로리 계산')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 112),
              child: _buildBody(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_image == null) {
      return const Center(child: Text('촬영할 음식을 준비해 주세요.'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 680;
        final preview = ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.file(_image!, fit: BoxFit.cover),
        );
        final result = _analyzing
            ? const _AnalyzingPanel()
            : _FoodResultPanel(
                result: _result,
                controller: _foodNameController,
                saving: _saving,
                onSave: _save,
                onRetake: _saving ? null : _capture,
              );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AspectRatio(aspectRatio: 3 / 4, child: preview),
              ),
              const SizedBox(width: 16),
              Expanded(child: result),
            ],
          );
        }

        return ListView(
          children: [
            AspectRatio(aspectRatio: 3 / 4, child: preview),
            const SizedBox(height: 16),
            result,
          ],
        );
      },
    );
  }
}

class _AnalyzingPanel extends StatelessWidget {
  const _AnalyzingPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 18),
          Text('AI가 분석 중이에요...'),
        ],
      ),
    );
  }
}

class _FoodResultPanel extends StatelessWidget {
  const _FoodResultPanel({
    required this.result,
    required this.controller,
    required this.saving,
    required this.onSave,
    required this.onRetake,
  });

  final FoodData? result;
  final TextEditingController controller;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback? onRetake;

  @override
  Widget build(BuildContext context) {
    final data = result;
    if (data == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: '음식 이름'),
          ),
          const SizedBox(height: 18),
          Text(
            '${data.calories}kcal',
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MacroChip(label: '탄수화물', value: data.carbs),
              _MacroChip(label: '단백질', value: data.protein),
              _MacroChip(label: '지방', value: data.fat),
            ],
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: saving ? null : onSave,
            icon: const Icon(Icons.check_rounded),
            label: Text(saving ? '저장 중...' : '기록에 추가하기'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRetake,
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('다시 찍기'),
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label ${value}g'));
  }
}

class _MealTypeSheet extends StatelessWidget {
  const _MealTypeSheet();

  @override
  Widget build(BuildContext context) {
    const meals = ['아침', '점심', '저녁', '간식'];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '어느 식사에 추가할까요?',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            for (final meal in meals)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(meal),
                  child: Text(meal),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
