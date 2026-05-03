import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/comment_model.dart';
import '../models/notification_model.dart';
import '../models/post_model.dart';
import 'auth_repository.dart';
import 'food_repository.dart';
import 'notification_repository.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
    storageUploader: ref.watch(foodRepositoryProvider),
    notificationRepository: ref.watch(notificationRepositoryProvider),
  );
});

class CommunityRepository {
  CommunityRepository({
    required FirebaseFirestore firestore,
    required FoodRepository storageUploader,
    required NotificationRepository notificationRepository,
  })  : _firestore = firestore,
        _storageUploader = storageUploader,
        _notificationRepository = notificationRepository;

  final FirebaseFirestore _firestore;
  final FoodRepository _storageUploader;
  final NotificationRepository _notificationRepository;

  Stream<List<PostModel>> watchPosts(String category, {int limit = 30}) {
    // 복합 인덱스 없이도 개발/초기 운영 환경에서 목록이 뜨도록 서버 쿼리는 단순화합니다.
    // 삭제/차단/카테고리 필터는 앱에서 적용합니다.
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(category == '전체' ? limit : limit * 3)
        .snapshots()
        .map((snapshot) {
      final posts = snapshot.docs
          .map((doc) => PostModel.fromJson({'id': doc.id, ...doc.data()}))
          .where((post) => !post.isDeleted && !post.isBlocked)
          .where((post) => category == '전체' || post.category == category)
          .toList();
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts.take(limit).toList();
    });
  }

  Stream<PostModel?> watchPost(String postId) {
    return _firestore.doc('posts/$postId').snapshots().map((doc) {
      final data = doc.data();
      if (data == null) {
        return null;
      }
      return PostModel.fromJson({'id': doc.id, ...data});
    });
  }

  Stream<List<CommentModel>> watchComments(String postId) {
    return _firestore
        .collection('posts/$postId/comments')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => CommentModel.fromJson({'id': doc.id, ...doc.data()}),
          )
          .where((comment) => !comment.isDeleted)
          .toList();
    });
  }

  Stream<bool> watchLikeState({required String postId, required String uid}) {
    return _firestore
        .doc('posts/$postId/likes/$uid')
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<bool> watchScrapState({required String postId, required String uid}) {
    return _firestore
        .doc('posts/$postId/scraps/$uid')
        .snapshots()
        .map((doc) => doc.exists);
  }

  Future<String> createPost({
    required String uid,
    required String nickname,
    required String? profileImage,
    required String category,
    required String title,
    required String content,
    required List<XFile> images,
  }) async {
    final postRef = _firestore.collection('posts').doc();
    final imageUrls = <String>[];

    for (final image in images.take(5)) {
      imageUrls.add(
        await _storageUploader.uploadImage(
          uid: uid,
          file: File(image.path),
          folder: 'community_posts/${postRef.id}',
        ),
      );
    }

    await postRef.set({
      'uid': uid,
      'nickname': nickname,
      'profileImage': profileImage,
      'category': category,
      'title': title,
      'content': content,
      'imageUrls': imageUrls,
      'likeCount': 0,
      'commentCount': 0,
      'scrapCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'isBlocked': false,
      'isDeleted': false,
    });

    return postRef.id;
  }

  Future<void> addComment({
    required String postId,
    required String uid,
    required String nickname,
    required String content,
    String? parentId,
    String? senderProfileImage,
  }) async {
    final commentRef = _firestore.collection('posts/$postId/comments').doc();
    final postRef = _firestore.doc('posts/$postId');
    final post = await postRef.get();
    final postOwnerUid = post.data()?['uid'] as String?;

    final batch = _firestore.batch();
    batch.set(commentRef, {
      'uid': uid,
      'nickname': nickname,
      'profileImage': senderProfileImage,
      'content': content,
      'parentId': parentId,
      'likeCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'isDeleted': false,
    });
    batch.update(postRef, {'commentCount': FieldValue.increment(1)});
    await batch.commit();

    if (postOwnerUid != null) {
      await _notificationRepository.createNotificationIfAllowed(
        recipientUid: postOwnerUid,
        type: MedamNotificationType.comment,
        targetId: postId,
        senderUid: uid,
        senderNickname: nickname,
        senderProfileImage: senderProfileImage,
      );
    }
  }

  Future<void> toggleLike({required String postId, required String uid}) async {
    final likeRef = _firestore.doc('posts/$postId/likes/$uid');
    final postRef = _firestore.doc('posts/$postId');
    final didLike = await _toggleCounter(
      markerRef: likeRef,
      targetRef: postRef,
      countField: 'likeCount',
    );
    if (!didLike) {
      return;
    }

    final post = await postRef.get();
    final postOwnerUid = post.data()?['uid'] as String?;
    if (postOwnerUid == null) {
      return;
    }

    final sender = await _readSenderProfile(uid);
    await _notificationRepository.createNotificationIfAllowed(
      recipientUid: postOwnerUid,
      type: MedamNotificationType.like,
      targetId: postId,
      senderUid: uid,
      senderNickname: sender.nickname,
      senderProfileImage: sender.profileImage,
    );
  }

  Future<void> toggleScrap({
    required String postId,
    required String uid,
  }) async {
    final scrapRef = _firestore.doc('posts/$postId/scraps/$uid');
    final postRef = _firestore.doc('posts/$postId');
    await _toggleCounter(
      markerRef: scrapRef,
      targetRef: postRef,
      countField: 'scrapCount',
    );
  }

  Future<void> reportPost({
    required String reporterUid,
    required String targetUid,
    required String postId,
    required String reason,
  }) async {
    await _firestore.collection('reports').add({
      'reporterUid': reporterUid,
      'targetUid': targetUid,
      'postId': postId,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> blockUser({
    required String uid,
    required String targetUid,
  }) async {
    await _firestore.doc('users/$uid/blocked/$targetUid').set({
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> followUser({
    required String uid,
    required String targetUid,
  }) async {
    final followingRef = _firestore.doc('users/$uid/following/$targetUid');
    final alreadyFollowing = await followingRef.get();
    if (alreadyFollowing.exists) {
      return;
    }

    final batch = _firestore.batch();
    batch.set(followingRef, {
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(_firestore.doc('users/$targetUid/followers/$uid'), {
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();

    final sender = await _readSenderProfile(uid);
    await _notificationRepository.createNotificationIfAllowed(
      recipientUid: targetUid,
      type: MedamNotificationType.follow,
      targetId: uid,
      senderUid: uid,
      senderNickname: sender.nickname,
      senderProfileImage: sender.profileImage,
    );
  }

  Future<bool> _toggleCounter({
    required DocumentReference<Map<String, dynamic>> markerRef,
    required DocumentReference<Map<String, dynamic>> targetRef,
    required String countField,
  }) async {
    return _firestore.runTransaction<bool>((transaction) async {
      final marker = await transaction.get(markerRef);
      if (marker.exists) {
        transaction.delete(markerRef);
        transaction.update(targetRef, {countField: FieldValue.increment(-1)});
        return false;
      } else {
        transaction.set(markerRef, {'createdAt': FieldValue.serverTimestamp()});
        transaction.update(targetRef, {countField: FieldValue.increment(1)});
        return true;
      }
    });
  }

  Future<_SenderProfile> _readSenderProfile(String uid) async {
    final profile = await _firestore.doc('users/$uid').get();
    final data = profile.data();
    return _SenderProfile(
      nickname: data?['nickname'] as String? ?? '미담러',
      profileImage:
          data?['profileImage'] as String? ?? data?['photoURL'] as String?,
    );
  }
}

class _SenderProfile {
  const _SenderProfile({required this.nickname, required this.profileImage});

  final String nickname;
  final String? profileImage;
}
