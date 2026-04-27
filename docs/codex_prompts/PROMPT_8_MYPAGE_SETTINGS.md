# PROMPT 8 — 마이페이지 & 설정

마스터 컨텍스트 기준으로 마이페이지, 설정, 알림 설정, 타인 프로필을 구현한다.

## 구현 범위

- `MyPageScreen`
  - 프로필 배경 preset 변경
  - 프로필 아바타 preset 변경
  - 닉네임, 소개 수정
  - 피드/팔로워/팔로잉 통계
  - 피드 grid
  - 식단 사진 + 눈바디 사진 통합 앨범 grid
  - 메뉴 목록: 쪽지함, 알림 설정, 공지사항, 테마 설정, 라이선스, 차단 유저, 팔로우 요청, 공개 범위, 위젯 안내, 친구 초대, 업데이트 내역, 약관 및 보안, 로그아웃

- `SettingsScreen`
  - 시스템 / 라이트 / 다크 테마 선택
  - `SharedPreferences` 저장
  - 변경 즉시 `MaterialApp.router`에 반영

- `NotificationSettingsScreen`
  - 알림 받기, 진동, 소리
  - 댓글/좋아요/팔로우/채팅 알림
  - Firestore `users/{uid}/settings/notification` 저장

- `ProfileScreen`
  - 다른 유저 아바타, 닉네임, 소개
  - 팔로우, 차단
  - 공개 피드 grid

## 반응형

- 폰: 단일 컬럼 스크롤
- 태블릿: 마이페이지 최대 폭 확장, 피드/앨범 영역을 넓게 표시
- 폰트 크기는 viewport 기준으로 키우지 않는다.
