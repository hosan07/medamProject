import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import 'auth_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(firestore: ref.watch(firebaseFirestoreProvider));
});

class UserRepository {
  const UserRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Stream<UserModel?> watchUser(String uid) {
    return _firestore.doc('users/$uid').snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return null;
      }
      return UserModel.fromJson({'uid': uid, ...data});
    });
  }

  Future<UserModel?> getUser(String uid) async {
    final snapshot = await _firestore.doc('users/$uid').get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    return UserModel.fromJson({'uid': uid, ...data});
  }

  Future<void> updateUser(UserModel user) async {
    await _firestore.doc('users/${user.uid}').set({
      ...user.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateProfileFields({
    required String uid,
    String? nickname,
    String? profileIcon,
    String? backgroundIcon,
    String? bio,
    bool? isPrivate,
  }) async {
    final updates = <String, Object?>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (nickname != null) updates['nickname'] = nickname;
    if (profileIcon != null) updates['profileIcon'] = profileIcon;
    if (backgroundIcon != null) updates['backgroundIcon'] = backgroundIcon;
    if (bio != null) updates['bio'] = bio;
    if (isPrivate != null) updates['isPrivate'] = isPrivate;

    await _firestore.doc('users/$uid').set(updates, SetOptions(merge: true));
  }
}
