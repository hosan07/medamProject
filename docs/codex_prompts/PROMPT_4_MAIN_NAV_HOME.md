# PROMPT 4 — 공통 네비게이션 & 홈 화면

Using master context, implement shared navigation and the Home screen.

## MainScaffold

Create `lib/features/home/widgets/main_scaffold.dart`.

- Floating bottom navigation bar.
- Pill shape with generous radius and elevated shadow.
- Not a full-width flat bar.
- 5 tabs:
  - 홈
  - AI봇
  - 카메라
  - 커뮤니티
  - 마이페이지
- Center camera button should be circular, primary-colored, and slightly raised.
- Use go_router ShellRoute/StatefulShellRoute to keep the nav bar across tab screens.
- Keep phone and tablet layouts responsive without viewport-scaled font sizes.

## HomeScreen

Create `lib/features/home/screens/home_screen.dart`.

AppBar:

- Left: 미담 logo text.
- Right: calendar icon to `/calendar`, notification icon with badge.

Body:

- Use `CustomScrollView`.
- Section 1: 오늘의 기록 카드
  - Calories consumed vs target.
  - 탄수화물 / 단백질 / 지방 progress bars.
  - 자세히 보기 to daily detail.
- Section 2: 식단 추가 horizontal cards
  - 아침 / 점심 / 저녁 / 간식 / 물 / 영양제.
- Section 3: 나의 변화
  - BMI chip.
  - Weight line chart.
  - Latest 3 눈바디 photos.
- Section 4: 나의 활동
  - Exercise duration and type.
  - 운동 추가하기.

Data:

- Use Riverpod `AsyncProvider` to load today's data from Firestore.
- Provide empty/default data so the UI is useful before logs exist.
