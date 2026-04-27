# PROMPT 9 — 수익 구조 (광고 & 구독)

마스터 컨텍스트 기준으로 광고, 크레딧, 구독 화면을 구현한다.

## 구현 범위

- `AdManager`
  - `google_mobile_ads` 초기화
  - 배너 광고 생성
  - 전면 광고 로드/표시
  - 개발용 Google 테스트 광고 ID 사용

- 크레딧 시스템
  - `CreditNotifier`
  - `currentCredits`, `earnCredits(n)`, `spendCredits(n)`
  - Firestore `users/{uid}/wallet/credits` 저장

- 구독 상태
  - `SubscriptionNotifier`
  - Firestore `users/{uid}/subscription/main`에서 `isActive` 확인
  - 구독 중이면 광고 숨김

- `SubscriptionScreen`
  - 현재 플랜 badge
  - 무료/구독 혜택 비교
  - 구독하기 stub
  - 구독 복원 stub
  - 광고 보고 크레딧 지급

## 메모

- 실제 인앱 결제는 StoreKit/BillingClient 연결 단계에서 stub을 교체한다.
- 폰트 크기는 viewport 기준으로 키우지 않는다.
