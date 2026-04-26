# PROMPT 5 — 카메라 화면

Using master context, implement the Camera feature tab.

## CameraMenuScreen

Create `lib/features/camera/screens/camera_menu_screen.dart`.

- Two large CTA cards:
  - `눈바디 사진 찍기`: body icon, `나의 변화를 기록해요`
  - `음식 칼로리 계산`: fork/food icon, `찍으면 칼로리가 계산돼요`
- Keep layouts responsive for phone and tablet without viewport-scaled font sizes.

## BodyCameraScreen

- Check/request camera permission before opening camera.
- Capture body photo.
- After capture, show preview and `저장하기`.
- Save to:
  - device gallery through `ImageGallerySaver`
  - Firebase Storage
  - Firestore body photo album
- Album view:
  - grid of past body photos
  - sorted by date descending
  - reusable from Home `나의 변화` and MyPage later

## FoodCameraScreen

- Check/request camera permission before opening camera.
- Capture food photo.
- After capture, show loading state: `AI가 분석 중이에요...`
- AI call is a mock for now with a TODO for real API integration.
- Result screen:
  - editable food name
  - calorie estimate
  - 탄/단/지 chips
  - `기록에 추가하기`
  - meal selector bottom sheet: 아침 / 점심 / 저녁 / 간식
  - save to Firestore today's log and food album
  - `다시 찍기`

## FoodRepository

Create `lib/data/repositories/food_repository.dart`.

- `saveFood(uid, mealType, foodData, imageUrl)`
- `getTodayFoods(uid, date)`
- `getFoodAlbum(uid)`
- body photo upload/save/watch helpers

## Notes

- This implementation uses `image_picker` with `ImageSource.camera` for stable iOS/Android capture.
- Firebase Storage is added for image upload.
- Real AI analysis should replace the mock function in `camera_provider.dart`.
