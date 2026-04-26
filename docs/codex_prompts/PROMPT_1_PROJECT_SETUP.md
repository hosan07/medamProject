# PROMPT 1 — 프로젝트 초기 세팅

Using the master context above, scaffold the full Flutter project for 미담 (Medam).

## Tasks

1. Create `pubspec.yaml` with these dependencies:
   - `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`
   - `go_router`
   - `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_messaging`,
     `firebase_remote_config`, `firebase_analytics`, `firebase_crashlytics`
   - `camera`, `image_picker`
   - `image_gallery_saver`
   - `share_plus`
   - `table_calendar`
   - `shared_preferences`
   - `flutter_secure_storage`
   - `dio`
   - `google_sign_in`
   - `sign_in_with_apple`
   - `flutter_local_notifications`
   - `google_mobile_ads`
   - `intl`
   - `cached_network_image`
   - `permission_handler`
   - `lottie`

2. Create the full folder structure under `lib/` as defined in master context.

3. Create `lib/app/theme.dart`:
   - Light theme: bg `#FFFFFF`, text `#000000`
   - Dark theme: bg `#131416`, text `#FFFFFF`
   - Primary color: `#4CAF82`
   - Font family: Pretendard
   - ThemeMode toggling via Riverpod provider

4. Create `lib/app/routes.dart` using `go_router`:
   Define named routes for:
   `splash`, `login`, `onboarding` steps 1~4, `home`, `ai_chat`, `camera`,
   `community`, `mypage`, `settings`, `calendar`, `notification`, `profile`.

5. Create `lib/app/app.dart` wiring `MaterialApp.router` with go_router and theme.

6. Create `lib/main.dart` with `ProviderScope` and Firebase initialization.

7. Add Android permissions to `AndroidManifest.xml`:
   `CAMERA`, `READ/WRITE_EXTERNAL_STORAGE`, `INTERNET`, `NOTIFICATIONS`,
   `USE_BIOMETRIC`, `VIBRATE`.

8. Add iOS permissions to `Info.plist`:
   `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`,
   `NSPhotoLibraryAddUsageDescription`.

## Current Project Notes

- Active Package ID: `com.medam.fit.app`
- Flutter: 3.38.6
- Dart: 3.10.7
- Firebase project: `medam-c9446`
- `image_gallery_saver` is patched through `third_party/image_gallery_saver` for Flutter 3.38 / AGP 8+ compatibility.
