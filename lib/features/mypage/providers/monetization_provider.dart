import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../auth/providers/auth_provider.dart';

final creditProvider = AsyncNotifierProvider<CreditNotifier, int>(
  CreditNotifier.new,
);

final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionNotifier, SubscriptionState>(
      SubscriptionNotifier.new,
    );

final isSubscribedProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionProvider).value?.isSubscribed ?? false;
});

class CreditNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return 0;
    }

    final snapshot = await ref
        .watch(firebaseFirestoreProvider)
        .doc('users/${user.uid}/wallet/credits')
        .get();
    return (snapshot.data()?['currentCredits'] as num?)?.toInt() ?? 0;
  }

  Future<void> earnCredits(int amount) async {
    if (amount <= 0) {
      return;
    }
    await _changeCredits(amount);
  }

  Future<bool> spendCredits(int amount) async {
    if (amount <= 0) {
      return true;
    }

    final current = state.value ?? 0;
    if (current < amount) {
      return false;
    }
    await _changeCredits(-amount);
    return true;
  }

  Future<void> _changeCredits(int delta) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      return;
    }

    final next = ((state.value ?? 0) + delta).clamp(0, 999999);
    state = AsyncData(next);

    await ref
        .read(firebaseFirestoreProvider)
        .doc('users/${user.uid}/wallet/credits')
        .set({
          'currentCredits': next,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }
}

class SubscriptionNotifier extends AsyncNotifier<SubscriptionState> {
  @override
  Future<SubscriptionState> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return SubscriptionState.free();
    }

    final snapshot = await ref
        .watch(firebaseFirestoreProvider)
        .doc('users/${user.uid}/subscription/main')
        .get();
    return SubscriptionState.fromJson(snapshot.data());
  }

  Future<void> startStubSubscription() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      return;
    }

    // TODO: StoreKit/BillingClient 인앱결제 완료 콜백에서 이 상태를 갱신합니다.
    final next = SubscriptionState(
      planName: '구독 중',
      isActive: true,
      renewsAt: DateTime.now().add(const Duration(days: 30)),
    );
    state = AsyncData(next);

    final firestore = ref.read(firebaseFirestoreProvider);
    final batch = firestore.batch();
    batch.set(
      firestore.doc('users/${user.uid}/subscription/main'),
      {...next.toJson(), 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
    batch.set(firestore.doc('users/${user.uid}/wallet/credits'), {
      'currentCredits': FieldValue.increment(30),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
    ref.invalidate(creditProvider);
  }

  Future<void> restoreStubSubscription() async {
    await startStubSubscription();
  }
}

class SubscriptionState {
  const SubscriptionState({
    required this.planName,
    required this.isActive,
    required this.renewsAt,
  });

  factory SubscriptionState.free() {
    return const SubscriptionState(
      planName: '무료',
      isActive: false,
      renewsAt: null,
    );
  }

  factory SubscriptionState.fromJson(Map<String, dynamic>? json) {
    final renewsAt = json?['renewsAt'];
    return SubscriptionState(
      planName: json?['planName'] as String? ?? '무료',
      isActive: json?['isActive'] as bool? ?? false,
      renewsAt: renewsAt is Timestamp ? renewsAt.toDate() : null,
    );
  }

  final String planName;
  final bool isActive;
  final DateTime? renewsAt;

  bool get isSubscribed {
    if (!isActive) {
      return false;
    }
    final end = renewsAt;
    return end == null || end.isAfter(DateTime.now());
  }

  Map<String, Object?> toJson() {
    return {
      'planName': planName,
      'isActive': isActive,
      'renewsAt': renewsAt == null ? null : Timestamp.fromDate(renewsAt!),
    };
  }
}
