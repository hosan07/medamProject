import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

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
