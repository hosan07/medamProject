# PROMPT 6 — AI 챗봇 화면

마스터 컨텍스트 기준으로 미담 AI 챗봇 화면을 구현한다.

## 요구사항

- `AIChatScreen`
  - AppBar: 온보딩에서 선택한 AI 코치 이름과 아바타
  - 상단 개인 맞춤 설정 chip row: 목표, 목표 칼로리, 설정 진입
  - 채팅 리스트: `ListView.builder`, `reverse: true`
  - 사용자 bubble: 오른쪽, primary color
  - AI bubble: 왼쪽, surface color, 코치 아바타
  - 빠른 답장 chip 지원
  - 하단 입력바: TextField, 전송 버튼, 음식 사진 분석 첨부 버튼

- `AIChatNotifier`
  - Riverpod `AsyncNotifier<List<ChatMessage>>`
  - `sendMessage(String text)`에서 사용자 메시지 추가 후 mock AI 응답 추가
  - 실제 OpenAI/Anthropic API 연결을 위한 TODO 주석 유지
  - Firestore `users/{uid}/ai_chat_history`에 대화 저장

- `ChatMessage` 모델
  - `id`, `role`, `content`, `timestamp`, `messageType`
  - `fromJson()`, `toJson()`, `copyWith()`

## 반응형

- 폰에서는 단일 채팅 화면 중심.
- 태블릿에서는 채팅 본문 최대 너비를 넓히고 중앙 정렬하되, 글자 크기는 viewport 기준으로 키우지 않는다.
