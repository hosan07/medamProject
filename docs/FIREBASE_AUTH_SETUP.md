# Firebase Auth 설정 체크리스트

프로젝트: `medam-c9446`

## Google 로그인

현재 앱 코드는 Firebase Auth Google 로그인을 실제로 수행합니다. 단, Firebase 설정 파일에는 OAuth client 정보가 포함되어 있어야 합니다.

확인할 파일:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

필수 값:

- Android `google-services.json`
  - `client.oauth_client`에 Android client 또는 Web client가 포함되어야 합니다.
  - SHA-1/SHA-256을 Firebase Console에 추가한 뒤 파일을 다시 다운로드해야 반영됩니다.

- iOS `GoogleService-Info.plist`
  - `CLIENT_ID`
  - `REVERSED_CLIENT_ID`

iOS Google 로그인은 `REVERSED_CLIENT_ID`를 Xcode URL Scheme에도 등록해야 합니다. Firebase에서 새 `GoogleService-Info.plist`를 받은 뒤 Xcode의 Runner target > Info > URL Types에 `REVERSED_CLIENT_ID` 값을 추가하세요.

## Apple 로그인

앱에는 `ios/Runner/Runner.entitlements`가 추가되어 있고 Runner target에 연결되어 있습니다.

Firebase Console:

- Authentication > Sign-in method > Apple 활성화
- Apple Developer 계정에서 Bundle ID `com.medam.fit.app`에 Sign in with Apple capability 활성화

Android에서 Apple 로그인을 지원하려면 Apple Services ID와 redirect URI 기반 웹 인증 설정이 추가로 필요합니다. 현재 코드는 지원되지 않는 환경에서 안내 메시지를 표시합니다.
