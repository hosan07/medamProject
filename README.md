# 미담 Medam

카메라 촬영으로 음식 칼로리를 계산하고, 눈바디 기록과 AI 코치, 커뮤니티, 채팅, 식단 다이어리, 운동 관리를 함께 제공하는 한국어 건강 및 다이어트 트래킹 앱입니다.

## 개발 기준

- Flutter 3.38.6
- Dart 3.10.7
- Package ID: `com.medam.app`
- State management: Riverpod
- Routing: go_router
- Backend: Firebase
  - Auth
  - Firestore
  - Messaging
  - Remote Config
  - Analytics
  - Crashlytics

## 브랜치 규칙

- `main`: 배포 가능한 기준 브랜치
- `chore/...`: 설정, 빌드, Firebase, 문서 관리
- `feature/...`: 기능 개발
- `fix/...`: 버그 수정
- `refactor/...`: 동작 변경 없는 구조 개선

## 현재 작업

- `chore/firebase-setup`: Flutter 초기 세팅 및 Firebase 연결
