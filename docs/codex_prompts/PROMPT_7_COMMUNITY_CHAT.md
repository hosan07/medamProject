# PROMPT 7 — 커뮤니티 & 채팅

마스터 컨텍스트 기준으로 Firebase 기반 커뮤니티와 1:1 채팅을 구현한다.

## Firestore 구조

- `posts/{postId}`: 게시글 본문, 이미지, 카운터, 삭제/차단 상태
- `posts/{postId}/comments/{commentId}`: 댓글/답글. 답글은 `parentId`로 연결
- `posts/{postId}/likes/{uid}`: 좋아요 marker
- `posts/{postId}/scraps/{uid}`: 스크랩 marker
- `users/{uid}/following/{targetUid}`: 팔로잉
- `users/{uid}/followers/{targetUid}`: 팔로워
- `users/{uid}/blocked/{targetUid}`: 차단 사용자
- `chats/{chatId}`: 참여자, 마지막 메시지, 안 읽은 수
- `chats/{chatId}/messages/{msgId}`: 텍스트/이미지 메시지, 읽음 상태
- `reports/{reportId}`: 신고 기록

## 보안 규칙 메모

- `users/{uid}`: 인증 사용자는 읽기 가능, 본인만 쓰기 가능
- `posts`: 인증 사용자는 읽기 가능, 인증 사용자만 생성 가능
- `posts/{postId}/comments`: 인증 사용자만 읽기/생성 가능
- `posts/{postId}/likes`, `scraps`: 본인 uid marker만 쓰기 가능
- `chats/{chatId}`: `participants`에 포함된 사용자만 읽기/쓰기 가능
- `reports`: 인증 사용자 create only, 사용자 read 불가
- `users/{uid}/blocked`: 본인만 읽기/쓰기 가능

## 반응형

- 폰: 단일 컬럼 리스트와 상세 화면
- 태블릿: 게시글 목록은 2열 grid, 상세/채팅은 넓은 최대폭으로 중앙 정렬
- 폰트 크기는 viewport 기준으로 키우지 않는다.
