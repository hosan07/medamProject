import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/community_chat_model.dart';
import 'auth_repository.dart';
import 'food_repository.dart';

final communityChatRepositoryProvider = Provider<CommunityChatRepository>((
  ref,
) {
  return CommunityChatRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
    storageUploader: ref.watch(foodRepositoryProvider),
  );
});

class CommunityChatRepository {
  CommunityChatRepository({
    required FirebaseFirestore firestore,
    required FoodRepository storageUploader,
  }) : _firestore = firestore,
       _storageUploader = storageUploader;

  final FirebaseFirestore _firestore;
  final FoodRepository _storageUploader;

  Stream<List<CommunityChatRoom>> watchChatRooms(String uid) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    CommunityChatRoom.fromJson({'id': doc.id, ...doc.data()}),
              )
              .toList(),
        );
  }

  Stream<List<CommunityChatMessage>> watchMessages(String chatId) {
    return _firestore
        .collection('chats/$chatId/messages')
        .orderBy('createdAt', descending: true)
        .limit(80)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => CommunityChatMessage.fromJson({
                  'id': doc.id,
                  ...doc.data(),
                }),
              )
              .toList(),
        );
  }

  Future<String> openRoom(String uid, String targetUid) async {
    final participants = [uid, targetUid]..sort();
    final chatId = participants.join('_');
    await _firestore.doc('chats/$chatId').set({
      'participants': participants,
      'lastMessage': '',
      'lastAt': FieldValue.serverTimestamp(),
      'unreadCount': {uid: 0, targetUid: 0},
    }, SetOptions(merge: true));
    return chatId;
  }

  Future<void> sendMessage({
    required String chatId,
    required String uid,
    required String content,
    XFile? image,
  }) async {
    final roomRef = _firestore.doc('chats/$chatId');
    final room = await roomRef.get();
    final participants =
        (room.data()?['participants'] as List<dynamic>?)
            ?.whereType<String>()
            .toList() ??
        const <String>[];
    final others = participants.where((id) => id != uid);

    String? imageUrl;
    if (image != null) {
      imageUrl = await _storageUploader.uploadImage(
        uid: uid,
        file: File(image.path),
        folder: 'chat_images/$chatId',
      );
    }

    final trimmed = content.trim();
    final messageText = trimmed.isEmpty && imageUrl != null ? '사진' : trimmed;
    final messageRef = _firestore.collection('chats/$chatId/messages').doc();

    final updates = <String, Object?>{
      'lastMessage': messageText,
      'lastAt': FieldValue.serverTimestamp(),
      'unreadCount.$uid': 0,
    };
    for (final other in others) {
      updates['unreadCount.$other'] = FieldValue.increment(1);
    }

    final batch = _firestore.batch();
    batch.set(messageRef, {
      'uid': uid,
      'content': trimmed,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': [uid],
    });
    batch.set(roomRef, updates, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> markAsRead({required String chatId, required String uid}) async {
    final roomRef = _firestore.doc('chats/$chatId');
    await roomRef.set({'unreadCount.$uid': 0}, SetOptions(merge: true));

    final unreadMessages = await _firestore
        .collection('chats/$chatId/messages')
        .where('uid', isNotEqualTo: uid)
        .limit(30)
        .get();
    final batch = _firestore.batch();
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {
        'readBy': FieldValue.arrayUnion([uid]),
      });
    }
    await batch.commit();
  }
}
