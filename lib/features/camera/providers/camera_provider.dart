import 'dart:io';

import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/network/openai_service.dart';
import '../../../data/models/food_analysis_result.dart';
import '../../../data/repositories/food_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/home_provider.dart';

final imagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());

final cameraCaptureProvider = Provider<CameraCaptureService>((ref) {
  return CameraCaptureService(ref.watch(imagePickerProvider));
});

class CameraCaptureService {
  const CameraCaptureService(this._picker);

  final ImagePicker _picker;

  Future<PermissionStatus> cameraPermissionStatus() {
    return Permission.camera.status;
  }

  Future<PermissionStatus> requestCameraPermission() {
    return Permission.camera.request();
  }

  Future<bool> openCameraSettings() {
    return openAppSettings();
  }

  Future<File?> capturePhoto() async {
    final permission = await cameraPermissionStatus();
    if (!permission.isGranted) {
      return null;
    }

    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 92,
      maxWidth: 1800,
    );
    if (photo == null) {
      return null;
    }
    return File(photo.path);
  }
}

enum CameraPhase { idle, captured, analyzing, result, saving }

class CameraState {
  const CameraState({
    this.phase = CameraPhase.idle,
    this.capturedImage,
    this.analysisResult,
    this.isSaving = false,
    this.errorMessage,
  });

  final CameraPhase phase;
  final File? capturedImage;
  final FoodAnalysisResult? analysisResult;
  final bool isSaving;
  final String? errorMessage;

  CameraState copyWith({
    CameraPhase? phase,
    File? capturedImage,
    FoodAnalysisResult? analysisResult,
    bool? clearImage,
    bool? clearAnalysis,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CameraState(
      phase: phase ?? this.phase,
      capturedImage:
          clearImage == true ? null : capturedImage ?? this.capturedImage,
      analysisResult:
          clearAnalysis == true ? null : analysisResult ?? this.analysisResult,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final cameraProvider = AsyncNotifierProvider<CameraNotifier, CameraState>(
  CameraNotifier.new,
);

class CameraNotifier extends AsyncNotifier<CameraState> {
  @override
  Future<CameraState> build() async {
    return const CameraState();
  }

  CameraState get _value => state.value ?? const CameraState();

  Future<void> captureImage() async {
    state = AsyncData(
      _value.copyWith(
        phase: CameraPhase.idle,
        clearImage: true,
        clearAnalysis: true,
        clearError: true,
      ),
    );

    final cameraService = ref.read(cameraCaptureProvider);
    final status = await cameraService.cameraPermissionStatus();
    if (status.isDenied || status.isLimited) {
      final result = await cameraService.requestCameraPermission();
      if (!result.isGranted) {
        state = AsyncData(
          _value.copyWith(
            phase: CameraPhase.idle,
            errorMessage: '카메라 권한이 필요해요.',
          ),
        );
        return;
      }
    } else if (status.isPermanentlyDenied || status.isRestricted) {
      await cameraService.openCameraSettings();
      state = AsyncData(
        _value.copyWith(
          phase: CameraPhase.idle,
          errorMessage: '설정 > 미담 > 카메라를 허용해주세요.',
        ),
      );
      return;
    }

    final image = await cameraService.capturePhoto();
    if (image == null) {
      state = AsyncData(
        _value.copyWith(
          phase: CameraPhase.idle,
          clearImage: true,
          clearAnalysis: true,
          errorMessage: '촬영이 취소되었어요.',
        ),
      );
      return;
    }

    state = AsyncData(
      CameraState(phase: CameraPhase.captured, capturedImage: image),
    );
  }

  Future<void> analyzeFood(File image) async {
    state = AsyncData(
      _value.copyWith(
        phase: CameraPhase.analyzing,
        capturedImage: image,
        clearAnalysis: true,
        clearError: true,
      ),
    );

    try {
      final result =
          await ref.read(openAIServiceProvider).analyzeFoodImageOrMock(image);
      state = AsyncData(
        _value.copyWith(
          phase: CameraPhase.result,
          capturedImage: image,
          analysisResult: result,
        ),
      );
    } on Object {
      state = AsyncData(
        _value.copyWith(
          phase: CameraPhase.captured,
          capturedImage: image,
          errorMessage: '음식 분석에 실패했어요. 다시 시도해주세요.',
        ),
      );
    }
  }

  void updateFoodName(String foodName) {
    final result = _value.analysisResult;
    if (result == null) {
      return;
    }
    state = AsyncData(
      _value.copyWith(
        analysisResult: FoodAnalysisResult(
          foodName: foodName,
          calories: result.calories,
          carbs: result.carbs,
          protein: result.protein,
          fat: result.fat,
          description: result.description,
        ),
      ),
    );
  }

  Future<void> saveBodyPhoto(File image) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncData(_value.copyWith(errorMessage: '로그인이 필요해요.'));
      return;
    }

    state = AsyncData(
      _value.copyWith(phase: CameraPhase.saving, isSaving: true),
    );

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

    state = AsyncData(
      _value.copyWith(
        phase: CameraPhase.saving,
        capturedImage: image,
        isSaving: false,
      ),
    );
  }

  Future<void> saveFoodLog(String mealType) async {
    final user = ref.read(currentUserProvider);
    final image = _value.capturedImage;
    final result = _value.analysisResult;
    if (user == null || image == null || result == null) {
      state = AsyncData(_value.copyWith(errorMessage: '저장할 음식 기록이 없어요.'));
      return;
    }

    state = AsyncData(_value.copyWith(isSaving: true, clearError: true));

    final repository = ref.read(foodRepositoryProvider);
    final imageUrl = await repository.uploadImage(
      uid: user.uid,
      file: image,
      folder: 'food_photos',
    );
    await ref.read(homeRepositoryProvider).addMeal(
          uid: user.uid,
          mealType: mealType,
          foodName: result.foodName,
          calories: result.calories,
          carbs: result.carbs,
          protein: result.protein,
          fat: result.fat,
          imageUrl: imageUrl,
        );

    state = AsyncData(_value.copyWith(isSaving: false));
  }

  void reset() {
    state = const AsyncData(CameraState());
  }
}
