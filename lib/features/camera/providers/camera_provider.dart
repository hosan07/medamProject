import 'dart:io';

import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/network/openai_service.dart';
import '../../../data/models/food_analysis_result.dart';
import '../../../data/repositories/photo_repository.dart';
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

  Future<File?> captureVideo() async {
    final permission = await cameraPermissionStatus();
    if (!permission.isGranted) {
      return null;
    }

    final video = await _picker.pickVideo(source: ImageSource.camera);
    if (video == null) {
      return null;
    }
    return File(video.path);
  }
}

enum CameraPhase { idle, captured, analyzing, result, saving, cancelled }

class CameraState {
  const CameraState({
    this.phase = CameraPhase.idle,
    this.capturedImage,
    this.mediaType = 'image',
    this.analysisResult,
    this.isSaving = false,
    this.uploadProgress = 0,
    this.errorMessage,
  });

  final CameraPhase phase;
  final File? capturedImage;
  final String mediaType;
  final FoodAnalysisResult? analysisResult;
  final bool isSaving;
  final double uploadProgress;
  final String? errorMessage;

  CameraState copyWith({
    CameraPhase? phase,
    File? capturedImage,
    String? mediaType,
    FoodAnalysisResult? analysisResult,
    bool? clearImage,
    bool? clearAnalysis,
    bool? isSaving,
    double? uploadProgress,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CameraState(
      phase: phase ?? this.phase,
      capturedImage: clearImage == true
          ? null
          : capturedImage ?? this.capturedImage,
      mediaType: mediaType ?? this.mediaType,
      analysisResult: clearAnalysis == true
          ? null
          : analysisResult ?? this.analysisResult,
      isSaving: isSaving ?? this.isSaving,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final cameraProvider = AsyncNotifierProvider<CameraNotifier, CameraState>(
  CameraNotifier.new,
);

class CameraNotifier extends AsyncNotifier<CameraState> {
  bool _isCapturing = false;

  @override
  Future<CameraState> build() async {
    return const CameraState();
  }

  CameraState get _value => state.value ?? const CameraState();

  Future<void> captureImage() async {
    if (_isCapturing) {
      return;
    }
    _isCapturing = true;

    try {
      state = AsyncData(
        _value.copyWith(
          phase: CameraPhase.idle,
          clearImage: true,
          clearAnalysis: true,
          mediaType: 'image',
          uploadProgress: 0,
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
            phase: CameraPhase.cancelled,
            clearImage: true,
            clearAnalysis: true,
            clearError: true,
          ),
        );
        return;
      }

      state = AsyncData(
        CameraState(
          phase: CameraPhase.captured,
          capturedImage: image,
          mediaType: 'image',
        ),
      );
    } on Object {
      state = AsyncData(
        _value.copyWith(
          phase: CameraPhase.idle,
          clearImage: true,
          clearAnalysis: true,
          errorMessage: '카메라를 열지 못했어요. 다시 시도해주세요.',
        ),
      );
    } finally {
      _isCapturing = false;
    }
  }

  Future<void> captureVideo() async {
    if (_isCapturing) {
      return;
    }
    _isCapturing = true;

    try {
      state = AsyncData(
        _value.copyWith(
          phase: CameraPhase.idle,
          clearImage: true,
          clearAnalysis: true,
          mediaType: 'video',
          uploadProgress: 0,
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

      final video = await cameraService.captureVideo();
      if (video == null) {
        state = AsyncData(
          _value.copyWith(
            phase: CameraPhase.cancelled,
            clearImage: true,
            clearAnalysis: true,
            clearError: true,
          ),
        );
        return;
      }

      state = AsyncData(
        CameraState(
          phase: CameraPhase.captured,
          capturedImage: video,
          mediaType: 'video',
        ),
      );
    } on Object {
      state = AsyncData(
        _value.copyWith(
          phase: CameraPhase.idle,
          clearImage: true,
          clearAnalysis: true,
          errorMessage: '카메라를 열지 못했어요. 다시 시도해주세요.',
        ),
      );
    } finally {
      _isCapturing = false;
    }
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
      final result = await ref
          .read(openAIServiceProvider)
          .analyzeFoodImage(image);
      state = AsyncData(
        _value.copyWith(
          phase: CameraPhase.result,
          capturedImage: image,
          analysisResult: result,
        ),
      );
    } on OpenAIServiceException catch (error) {
      state = AsyncData(
        _value.copyWith(
          phase: CameraPhase.captured,
          capturedImage: image,
          errorMessage: error.message,
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

  Future<bool> saveBodyPhoto(File image) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncData(_value.copyWith(errorMessage: '로그인이 필요해요.'));
      return false;
    }

    state = AsyncData(
      _value.copyWith(
        phase: CameraPhase.saving,
        isSaving: true,
        uploadProgress: 0,
        clearError: true,
      ),
    );

    try {
      var localPath = image.path;
      try {
        final result = await ImageGallerySaver.saveFile(
          image.path,
          isReturnPathOfIOS: true,
        );
        localPath = _galleryPathFromResult(result) ?? image.path;
      } on Object {
        // 갤러리 저장 실패 시에도 촬영 파일 경로로 앱 기록은 남깁니다.
      }

      await ref
          .read(photoRepositoryProvider)
          .addLocalPhoto(
            uid: user.uid,
            localPath: localPath,
            type: 'body',
            mediaType: _value.mediaType,
            category: 'all',
          );

      ref.invalidate(todayHomeDataProvider);

      state = AsyncData(
        _value.copyWith(
          phase: CameraPhase.saving,
          capturedImage: image,
          isSaving: false,
          uploadProgress: 1,
          clearError: true,
        ),
      );
      return true;
    } on Object {
      state = AsyncData(
        _value.copyWith(
          phase: CameraPhase.captured,
          capturedImage: image,
          isSaving: false,
          uploadProgress: 0,
          errorMessage: '저장에 실패했어요. 다시 시도해주세요',
        ),
      );
      return false;
    }
  }

  Future<bool> saveFoodLog(String mealType) async {
    final user = ref.read(currentUserProvider);
    final image = _value.capturedImage;
    final result = _value.analysisResult;
    if (user == null || image == null || result == null) {
      state = AsyncData(_value.copyWith(errorMessage: '저장할 음식 기록이 없어요.'));
      return false;
    }

    state = AsyncData(
      _value.copyWith(isSaving: true, uploadProgress: 0, clearError: true),
    );

    try {
      var localPath = image.path;
      try {
        final galleryResult = await ImageGallerySaver.saveFile(
          image.path,
          isReturnPathOfIOS: true,
        );
        localPath = _galleryPathFromResult(galleryResult) ?? image.path;
      } on Object {
        // 갤러리 저장 실패 시에도 촬영 파일 경로로 앱 기록은 남깁니다.
      }

      await ref
          .read(photoRepositoryProvider)
          .addLocalPhoto(
            uid: user.uid,
            localPath: localPath,
            type: 'food',
            foodName: result.foodName,
            calories: result.calories,
          );
      await ref
          .read(homeRepositoryProvider)
          .addMeal(
            uid: user.uid,
            mealType: mealType,
            foodName: result.foodName,
            calories: result.calories,
            carbs: result.carbs,
            protein: result.protein,
            fat: result.fat,
            imageUrl: localPath,
          );

      ref
        ..invalidate(todayHomeDataProvider)
        ..invalidate(todayMealsProvider);

      state = AsyncData(
        _value.copyWith(isSaving: false, uploadProgress: 1, clearError: true),
      );
      return true;
    } on Object {
      state = AsyncData(
        _value.copyWith(
          isSaving: false,
          errorMessage: '식단 기록 저장에 실패했어요. 다시 시도해주세요.',
        ),
      );
      return false;
    }
  }

  void reset() {
    state = const AsyncData(CameraState());
  }

  String? _galleryPathFromResult(Object? result) {
    if (result is Map) {
      final value = result['filePath'] ?? result['path'];
      if (value is String && value.trim().isNotEmpty) {
        return value.replaceFirst('file://', '');
      }
    }
    return null;
  }
}
