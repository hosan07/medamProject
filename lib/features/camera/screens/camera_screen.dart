import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/food_analysis_result.dart';
import '../providers/camera_provider.dart';

enum _CameraSheetStep { choice, bodySaved, analyzing, result }

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  final _foodNameController = TextEditingController();
  _CameraSheetStep _sheetStep = _CameraSheetStep.choice;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cameraProvider.notifier).captureImage();
    });
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<CameraState>>(cameraProvider, (previous, next) {
      final data = next.value;
      final previousData = previous?.value;
      final errorMessage = data?.errorMessage;
      if (errorMessage != null &&
          errorMessage.isNotEmpty &&
          errorMessage != previousData?.errorMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }

      final result = data?.analysisResult;
      if (result != null && result.foodName != _foodNameController.text) {
        _foodNameController.text = result.foodName;
      }
    });

    final cameraState = ref.watch(cameraProvider).value ?? const CameraState();
    final image = cameraState.capturedImage;

    return PopScope(
      onPopInvokedWithResult: (_, _) =>
          ref.read(cameraProvider.notifier).reset(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(child: _CameraBody(image: image)),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: IconButton.filledTonal(
                    tooltip: '닫기',
                    onPressed: _close,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ),
            ),
            if (image != null)
              _CameraDecisionSheet(
                step: _sheetStep,
                state: cameraState,
                foodNameController: _foodNameController,
                onBodySave: () => _saveBodyPhoto(image),
                onFoodAnalyze: () => _analyzeFood(image),
                onRetake: _retake,
                onFoodNameChanged: (value) =>
                    ref.read(cameraProvider.notifier).updateFoodName(value),
                onAddFood: _selectMealAndSave,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _retake() async {
    setState(() => _sheetStep = _CameraSheetStep.choice);
    _foodNameController.clear();
    await ref.read(cameraProvider.notifier).captureImage();
  }

  Future<void> _saveBodyPhoto(File image) async {
    setState(() => _sheetStep = _CameraSheetStep.bodySaved);
    await ref.read(cameraProvider.notifier).saveBodyPhoto(image);
    if (!mounted) {
      return;
    }
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) {
      _close();
    }
  }

  Future<void> _analyzeFood(File image) async {
    setState(() => _sheetStep = _CameraSheetStep.analyzing);
    await ref.read(cameraProvider.notifier).analyzeFood(image);
    if (!mounted) {
      return;
    }
    final result = ref.read(cameraProvider).value?.analysisResult;
    setState(() {
      _sheetStep =
          result == null ? _CameraSheetStep.choice : _CameraSheetStep.result;
    });
  }

  Future<void> _selectMealAndSave() async {
    final mealType = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) => const _MealTypeSheet(),
    );
    if (mealType == null || !mounted) {
      return;
    }

    await ref.read(cameraProvider.notifier).saveFoodLog(mealType);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$mealType 기록에 추가했어요.')));
    _close();
  }

  void _close() {
    ref.read(cameraProvider.notifier).reset();
    context.go('/home');
  }
}

class _CameraBody extends StatelessWidget {
  const _CameraBody({required this.image});

  final File? image;

  @override
  Widget build(BuildContext context) {
    if (image == null) {
      return const Center(
        child: Text(
          '카메라를 여는 중이에요...',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          flex: 2,
          child: SizedBox(
            width: double.infinity,
            child: Image.file(image!, fit: BoxFit.cover),
          ),
        ),
        const Expanded(child: SizedBox.expand()),
      ],
    );
  }
}

class _CameraDecisionSheet extends StatelessWidget {
  const _CameraDecisionSheet({
    required this.step,
    required this.state,
    required this.foodNameController,
    required this.onBodySave,
    required this.onFoodAnalyze,
    required this.onRetake,
    required this.onFoodNameChanged,
    required this.onAddFood,
  });

  final _CameraSheetStep step;
  final CameraState state;
  final TextEditingController foodNameController;
  final VoidCallback onBodySave;
  final VoidCallback onFoodAnalyze;
  final VoidCallback onRetake;
  final ValueChanged<String> onFoodNameChanged;
  final VoidCallback onAddFood;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.45,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            children: [
              const _SheetHandle(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: switch (step) {
                  _CameraSheetStep.choice => _ChoiceContent(
                      onBodySave: onBodySave,
                      onFoodAnalyze: onFoodAnalyze,
                      onRetake: onRetake,
                    ),
                  _CameraSheetStep.bodySaved => const _BodySavedContent(),
                  _CameraSheetStep.analyzing => const _AnalyzingContent(),
                  _CameraSheetStep.result => _FoodResultContent(
                      result: state.analysisResult,
                      controller: foodNameController,
                      isSaving: state.isSaving,
                      onChanged: onFoodNameChanged,
                      onAddFood: onAddFood,
                      onRetake: onRetake,
                    ),
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 5,
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class _ChoiceContent extends StatelessWidget {
  const _ChoiceContent({
    required this.onBodySave,
    required this.onFoodAnalyze,
    required this.onRetake,
  });

  final VoidCallback onBodySave;
  final VoidCallback onFoodAnalyze;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('choice'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '이 사진을 어떻게 할까요?',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 60,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: Theme.of(context).colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: onBodySave,
                  icon: const Icon(Icons.accessibility_new_rounded),
                  label:
                      const _ButtonLabel(title: '눈바디 저장', subtitle: '내 앨범에 저장'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 60,
                child: FilledButton.icon(
                  onPressed: onFoodAnalyze,
                  icon: const Icon(Icons.restaurant_rounded),
                  label:
                      const _ButtonLabel(title: '음식 분석', subtitle: '칼로리 계산하기'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextButton(onPressed: onRetake, child: const Text('다시 찍기')),
      ],
    );
  }
}

class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, height: 1.1),
        ),
      ],
    );
  }
}

class _BodySavedContent extends StatelessWidget {
  const _BodySavedContent();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      key: ValueKey('bodySaved'),
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF82), size: 42),
          SizedBox(height: 14),
          Text(
            '눈바디 앨범에 저장했어요 ✓',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _AnalyzingContent extends StatelessWidget {
  const _AnalyzingContent();

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('analyzing'),
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 18),
          const Text(
            'AI가 분석 중이에요...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _FoodResultContent extends StatelessWidget {
  const _FoodResultContent({
    required this.result,
    required this.controller,
    required this.isSaving,
    required this.onChanged,
    required this.onAddFood,
    required this.onRetake,
  });

  final FoodAnalysisResult? result;
  final TextEditingController controller;
  final bool isSaving;
  final ValueChanged<String> onChanged;
  final VoidCallback onAddFood;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final data = result;
    if (data == null) {
      return const SizedBox.shrink(key: ValueKey('emptyResult'));
    }

    return Column(
      key: const ValueKey('result'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          decoration: const InputDecoration(labelText: '음식 이름'),
        ),
        const SizedBox(height: 16),
        Text(
          '${data.calories} kcal',
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        if (data.description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            data.description,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _MacroCard(label: '탄수화물', value: data.carbs)),
            const SizedBox(width: 8),
            Expanded(child: _MacroCard(label: '단백질', value: data.protein)),
            const SizedBox(width: 8),
            Expanded(child: _MacroCard(label: '지방', value: data.fat)),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: isSaving ? null : onAddFood,
            child: Text(isSaving ? '저장 중...' : '기록에 추가하기'),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
            onPressed: isSaving ? null : onRetake, child: const Text('다시 찍기')),
      ],
    );
  }
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text('$value g', style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _MealTypeSheet extends StatelessWidget {
  const _MealTypeSheet();

  @override
  Widget build(BuildContext context) {
    const meals = ['아침', '점심', '저녁', '간식'];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '어느 끼니에 추가할까요?',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            for (final meal in meals)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  height: 52,
                  child: FilledButton.tonal(
                    onPressed: () => Navigator.of(context).pop(meal),
                    child: Text(meal),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
