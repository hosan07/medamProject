import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../data/repositories/food_repository.dart';

final imagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());

final cameraCaptureProvider = Provider<CameraCaptureService>((ref) {
  return CameraCaptureService(ref.watch(imagePickerProvider));
});

class CameraCaptureService {
  const CameraCaptureService(this._picker);

  final ImagePicker _picker;

  Future<File?> capturePhoto() async {
    final permission = await Permission.camera.request();
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

Future<FoodData> analyzeFoodMock(File image) async {
  await Future<void>.delayed(const Duration(seconds: 2));

  // TODO: 실제 AI API(OpenAI/Anthropic/서버 프록시 등)로 교체합니다.
  return const FoodData(
    foodName: '닭가슴살 샐러드',
    calories: 430,
    carbs: 28,
    protein: 38,
    fat: 18,
  );
}
