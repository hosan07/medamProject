import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/auth_repository.dart';

final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(
  AuthNotifier.new,
);

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).value;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

final hasUserProfileProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return false;
  }

  return ref.watch(authRepositoryProvider).hasProfile(user.uid);
});

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  FutureOr<User?> build() {
    final repository = ref.watch(authRepositoryProvider);

    final subscription = repository.authStateChanges.listen(
      (user) {
        state = AsyncData(user);
      },
      onError: (Object error, StackTrace stackTrace) {
        state = AsyncError(error, stackTrace);
      },
    );
    ref.onDispose(subscription.cancel);

    return repository.currentUser;
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential = await ref
          .read(authRepositoryProvider)
          .signInWithGoogle();
      return credential.user;
    });
  }

  Future<void> signInWithApple() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential = await ref
          .read(authRepositoryProvider)
          .signInWithApple();
      return credential.user;
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signOut();
      return null;
    });
  }
}
