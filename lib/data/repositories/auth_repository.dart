import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firebaseFirestoreProvider),
    googleSignIn: GoogleSignIn.instance,
  );
});

class AuthRepository {
  AuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  }) : _auth = auth,
       _firestore = firestore,
       _googleSignIn = googleSignIn;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  Future<void>? _googleInitFuture;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();

      final googleUser = await _googleSignIn.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw const AuthRepositoryException(
          code: AuthRepositoryErrorCode.googleMissingIdToken,
          message:
              'Google ID 토큰을 받을 수 없어요. Firebase Console에서 SHA 설정 후 google-services.json과 GoogleService-Info.plist를 다시 내려받아야 합니다.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await _auth.signInWithCredential(credential);
      await _upsertAuthUser(
        userCredential.user,
        provider: 'google',
        fallbackDisplayName: googleUser.displayName,
      );
      return userCredential;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthRepositoryException(
          code: AuthRepositoryErrorCode.cancelled,
          message: 'Google 로그인이 취소되었어요.',
        );
      }
      throw AuthRepositoryException(
        code: AuthRepositoryErrorCode.googleSignInFailed,
        message: error.description ?? 'Google 로그인 중 문제가 발생했어요.',
        cause: error,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthRepositoryException.fromFirebase(error);
    }
  }

  Future<UserCredential> signInWithApple() async {
    try {
      final available = await SignInWithApple.isAvailable();
      if (!available) {
        throw const AuthRepositoryException(
          code: AuthRepositoryErrorCode.appleUnavailable,
          message: '이 기기에서는 Apple 로그인을 사용할 수 없어요.',
        );
      }

      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final identityToken = appleCredential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw const AuthRepositoryException(
          code: AuthRepositoryErrorCode.appleMissingIdentityToken,
          message: 'Apple 로그인 토큰을 받을 수 없어요. 잠시 후 다시 시도해 주세요.',
        );
      }

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: identityToken,
        accessToken: appleCredential.authorizationCode,
        rawNonce: rawNonce,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final appleName = _appleDisplayName(appleCredential);
      await _upsertAuthUser(
        userCredential.user,
        provider: 'apple',
        fallbackDisplayName: appleName,
      );
      return userCredential;
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        throw const AuthRepositoryException(
          code: AuthRepositoryErrorCode.cancelled,
          message: 'Apple 로그인이 취소되었어요.',
        );
      }
      throw AuthRepositoryException(
        code: AuthRepositoryErrorCode.appleSignInFailed,
        message: 'Apple 로그인 중 문제가 발생했어요.',
        cause: error,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthRepositoryException.fromFirebase(error);
    }
  }

  Future<void> signOut() async {
    await _ensureGoogleInitialized();
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut().catchError((Object _) => null),
    ]);
  }

  Future<bool> hasProfile(String uid) async {
    final snapshot = await _firestore.doc('users/$uid/profile/main').get();
    return snapshot.exists;
  }

  Future<void> _ensureGoogleInitialized() {
    _googleInitFuture ??= _googleSignIn.initialize();
    return _googleInitFuture!;
  }

  Future<void> _upsertAuthUser(
    User? user, {
    required String provider,
    String? fallbackDisplayName,
  }) async {
    if (user == null) {
      return;
    }

    final userRef = _firestore.doc('users/${user.uid}');
    final now = FieldValue.serverTimestamp();
    final snapshot = await userRef.get();
    final displayName = user.displayName ?? fallbackDisplayName;

    // 온보딩 프로필과 인증 기본 정보는 분리해서 저장합니다.
    await userRef.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': displayName,
      'photoURL': user.photoURL,
      'provider': provider,
      'lastLoginAt': now,
      if (!snapshot.exists) 'createdAt': now,
    }, SetOptions(merge: true));

    if (displayName != null && displayName.trim().isNotEmpty) {
      await user.updateDisplayName(displayName);
    }
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  String? _appleDisplayName(AuthorizationCredentialAppleID credential) {
    final parts = [
      credential.givenName?.trim(),
      credential.familyName?.trim(),
    ].where((part) => part != null && part.isNotEmpty).cast<String>();
    final name = parts.join(' ');
    return name.isEmpty ? null : name;
  }
}

enum AuthRepositoryErrorCode {
  cancelled,
  googleMissingIdToken,
  googleSignInFailed,
  appleUnavailable,
  appleMissingIdentityToken,
  appleSignInFailed,
  firebaseAuthFailed,
}

class AuthRepositoryException implements Exception {
  const AuthRepositoryException({
    required this.code,
    required this.message,
    this.cause,
  });

  factory AuthRepositoryException.fromFirebase(FirebaseAuthException error) {
    return AuthRepositoryException(
      code: AuthRepositoryErrorCode.firebaseAuthFailed,
      message: switch (error.code) {
        'account-exists-with-different-credential' =>
          '이미 다른 로그인 방식으로 가입된 이메일이에요.',
        'invalid-credential' => '로그인 인증 정보가 올바르지 않아요.',
        'operation-not-allowed' => 'Firebase 콘솔에서 해당 로그인 제공자를 활성화해 주세요.',
        _ => 'Firebase 로그인 중 문제가 발생했어요. (${error.code})',
      },
      cause: error,
    );
  }

  final AuthRepositoryErrorCode code;
  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
