import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../data/repositories/food_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/home_provider.dart';
import '../providers/camera_provider.dart';

enum _CameraMode {
  body('눈바디 찍기', Icons.accessibility_new_rounded),
  food('음식 칼로리 계산', Icons.restaurant_rounded);

  const _CameraMode(this.label, this.icon);

  final String label;
  final IconData icon;
}

class CameraMenuScreen extends ConsumerStatefulWidget {
  const CameraMenuScreen({super.key});

  @override
  ConsumerState<CameraMenuScreen> createState() => _CameraMenuScreenState();
}

class _CameraMenuScreenState extends ConsumerState<CameraMenuScreen> {
  _CameraMode _mode = _CameraMode.body;
  File? _image;
  FoodData? _foodResult;
  PermissionStatus? _permissionStatus;
  bool _openingCamera = false;
  bool _analyzing = false;
  bool _saving = false;
  late final TextEditingController _foodNameController;

  @override
  void initState() {
    super.initState();
    _foodNameController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPermission());
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final status = await ref
        .read(cameraCaptureProvider)
        .cameraPermissionStatus();
    if (!mounted) {
      return;
    }

    setState(() => _permissionStatus = status);
    if (status.isGranted) {
      await _capture();
    }
  }

  Future<void> _requestPermission() async {
    final service = ref.read(cameraCaptureProvider);
    final current = await service.cameraPermissionStatus();

    if (current.isPermanentlyDenied || current.isRestricted) {
      await service.openCameraSettings();
      if (!mounted) {
        return;
      }
      setState(() => _permissionStatus = current);
      return;
    }

    final next = await service.requestCameraPermission();
    if (!mounted) {
      return;
    }

    setState(() => _permissionStatus = next);
    if (next.isGranted) {
      await _capture();
    }
  }

  Future<void> _openSettings() async {
    await ref.read(cameraCaptureProvider).openCameraSettings();
    if (mounted) {
      await _checkPermission();
    }
  }

  Future<void> _capture() async {
    if (_openingCamera || _saving) {
      return;
    }

    final status = await ref
        .read(cameraCaptureProvider)
        .cameraPermissionStatus();
    if (!mounted) {
      return;
    }

    setState(() => _permissionStatus = status);
    if (status.isDenied || status.isLimited) {
      await _requestPermission();
      return;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return;
    }
    if (!status.isGranted) {
      return;
    }

    setState(() {
      _openingCamera = true;
      _foodResult = null;
      _analyzing = false;
    });

    final image = await ref.read(cameraCaptureProvider).capturePhoto();
    if (!mounted) {
      return;
    }

    setState(() {
      _openingCamera = false;
      _image = image;
    });

    if (image == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('촬영이 취소되었어요.')));
      return;
    }

    if (_mode == _CameraMode.food) {
      await _analyzeFood(image);
    }
  }

  Future<void> _analyzeFood(File image) async {
    setState(() => _analyzing = true);
    final analyzed = await analyzeFoodMock(image);
    if (!mounted) {
      return;
    }
    _foodNameController.text = analyzed.foodName;
    setState(() {
      _foodResult = analyzed;
      _analyzing = false;
    });
  }

  Future<void> _saveBodyPhoto() async {
    final image = _image;
    final user = ref.read(currentUserProvider);
    if (image == null || user == null) {
      return;
    }

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final repository = ref.read(foodRepositoryProvider);

    final imageUrl = await repository.uploadImage(
      uid: user.uid,
      file: image,
      folder: 'body_photos',
    );
    await repository.saveBodyPhotoToPublicPath(
      uid: user.uid,
      imageUrl: imageUrl,
    );
    await repository.saveBodyPhoto(uid: user.uid, imageUrl: imageUrl);
    await ImageGallerySaver.saveFile(image.path);

    if (!mounted) {
      return;
    }
    setState(() {
      _saving = false;
      _image = null;
    });
    messenger.showSnackBar(const SnackBar(content: Text('눈바디 사진을 저장했어요.')));
  }

  Future<void> _saveFood() async {
    final image = _image;
    final result = _foodResult;
    final user = ref.read(currentUserProvider);
    if (image == null || result == null || user == null) {
      return;
    }

    final mealType = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
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

    await ref
        .read(homeRepositoryProvider)
        .addMeal(
          uid: user.uid,
          mealType: mealType,
          foodName: _foodNameController.text.trim().isEmpty
              ? result.foodName
              : _foodNameController.text.trim(),
          calories: result.calories,
          carbs: result.carbs,
          protein: result.protein,
          fat: result.fat,
          imageUrl: imageUrl,
        );

    if (!mounted) {
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text('$mealType 기록에 추가했어요.')));
    context.go('/home');
  }

  void _changeMode(_CameraMode mode) {
    if (_mode == mode || _saving) {
      return;
    }
    setState(() {
      _mode = mode;
      _image = null;
      _foodResult = null;
      _analyzing = false;
    });
    if (_permissionStatus?.isGranted ?? false) {
      _capture();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('카메라'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
              child: _ModeToggle(selected: _mode, onChanged: _changeMode),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.black,
                child: Center(child: _buildContent(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final permission = _permissionStatus;
    if (permission == null) {
      return const _CameraStatus(message: '카메라 권한을 확인하고 있어요...');
    }
    if (permission.isDenied || permission.isLimited) {
      return _PermissionGuide(
        title: '카메라 권한이 필요해요',
        description: '음식과 눈바디 사진을 촬영하려면 카메라 권한을 허용해 주세요.',
        buttonLabel: '권한 허용하기',
        icon: Icons.camera_alt_rounded,
        onPressed: _requestPermission,
      );
    }
    if (permission.isPermanentlyDenied || permission.isRestricted) {
      return _PermissionGuide(
        title: '설정에서 허용해주세요',
        description: '카메라 권한이 차단되어 있어요. 설정 앱에서 미담의 카메라 접근을 켜주세요.',
        buttonLabel: '설정으로 이동',
        icon: Icons.settings_rounded,
        onPressed: _openSettings,
      );
    }

    if (_openingCamera) {
      return const _CameraStatus(message: '카메라를 여는 중이에요...');
    }

    final image = _image;
    if (image == null) {
      return _CameraEmpty(onCapture: _capture);
    }

    if (_mode == _CameraMode.food && _analyzing) {
      return _CameraPreviewScaffold(
        image: image,
        bottom: const _CameraStatus(message: 'AI가 분석 중이에요...'),
      );
    }

    return _CameraPreviewScaffold(
      image: image,
      bottom: _mode == _CameraMode.body
          ? _BodyActions(
              saving: _saving,
              onSave: _saveBodyPhoto,
              onRetake: _capture,
            )
          : _FoodResultActions(
              result: _foodResult,
              controller: _foodNameController,
              saving: _saving,
              onSave: _saveFood,
              onRetake: _capture,
            ),
    );
  }
}

class _PermissionGuide extends StatelessWidget {
  const _PermissionGuide({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 44),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.selected, required this.onChanged});

  final _CameraMode selected;
  final ValueChanged<_CameraMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_CameraMode>(
      segments: [
        for (final mode in _CameraMode.values)
          ButtonSegment(
            value: mode,
            icon: Icon(mode.icon),
            label: Text(mode.label),
          ),
      ],
      selected: {selected},
      onSelectionChanged: (values) => onChanged(values.first),
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }
}

class _CameraPreviewScaffold extends StatelessWidget {
  const _CameraPreviewScaffold({required this.image, required this.bottom});

  final File image;
  final Widget bottom;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(image, fit: BoxFit.contain),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: bottom,
            ),
          ),
        ),
      ],
    );
  }
}

class _CameraStatus extends StatelessWidget {
  const _CameraStatus({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(message, style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _CameraEmpty extends StatelessWidget {
  const _CameraEmpty({required this.onCapture});

  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 42),
          const SizedBox(height: 12),
          const Text(
            '촬영을 시작해 주세요.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCapture,
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('카메라 열기'),
          ),
        ],
      ),
    );
  }
}

class _BodyActions extends StatelessWidget {
  const _BodyActions({
    required this.saving,
    required this.onSave,
    required this.onRetake,
  });

  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    return _ActionPanel(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: saving ? null : onRetake,
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('다시 찍기'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: saving ? null : onSave,
            icon: const Icon(Icons.save_rounded),
            label: Text(saving ? '저장 중...' : '저장하기'),
          ),
        ),
      ],
    );
  }
}

class _FoodResultActions extends StatelessWidget {
  const _FoodResultActions({
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
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final data = result;
    if (data == null) {
      return const _CameraStatus(message: 'AI 분석 결과를 준비하고 있어요...');
    }

    return _ActionPanel(
      isColumn: true,
      children: [
        TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '음식 이름'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                '${data.calories}kcal',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _MacroChip(label: '탄', value: data.carbs),
            const SizedBox(width: 6),
            _MacroChip(label: '단', value: data.protein),
            const SizedBox(width: 6),
            _MacroChip(label: '지', value: data.fat),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: saving ? null : onRetake,
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('다시 찍기'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: saving ? null : onSave,
                icon: const Icon(Icons.check_rounded),
                label: Text(saving ? '저장 중...' : '기록 추가'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({required this.children, this.isColumn = false});

  final List<Widget> children;
  final bool isColumn;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: isColumn
            ? Column(mainAxisSize: MainAxisSize.min, children: children)
            : Row(children: children),
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
    return Chip(label: Text('$label $value g'));
  }
}

class _MealTypeSheet extends StatelessWidget {
  const _MealTypeSheet();

  @override
  Widget build(BuildContext context) {
    const meals = ['아침', '점심', '저녁', '간식'];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
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
