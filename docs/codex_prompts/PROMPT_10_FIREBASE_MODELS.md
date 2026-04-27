# PROMPT 10 — Firebase 보안 규칙 & 데이터 모델

마스터 컨텍스트 기준으로 Firestore 보안 규칙, Dart 모델, repository 계층을 정리한다.

## Firestore Security Rules

- `users/{uid}`: 인증 사용자는 읽기 가능, 본인만 쓰기 가능
- `posts`: 인증 사용자는 읽기 가능, 인증 사용자만 생성 가능
- `posts/{postId}/comments`: 인증 사용자만 읽기/생성 가능
- `chats/{chatId}`: `participants`에 포함된 사용자만 읽기/쓰기 가능
- `reports`: 인증 사용자 create only, 사용자 read 불가
- `users/{uid}/blocked`: 본인만 읽기/쓰기 가능

## Models

- `user_model.dart`
- `post_model.dart`
- `comment_model.dart`
- `chat_model.dart`
- `food_log_model.dart`
- `body_photo_model.dart`
- `exercise_log_model.dart`

모든 모델은 `fromJson()`, `toJson()`, `copyWith()`를 제공한다.

## Repositories

- `user_repository.dart`
- `post_repository.dart`
- `chat_repository.dart`
- `food_repository.dart`
- `exercise_repository.dart`

모든 repository는 Riverpod provider를 통해 `FirebaseFirestore` 또는 필요한 Firebase 클라이언트를 주입받는다.
