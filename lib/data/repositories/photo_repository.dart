import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'auth_repository.dart';
import 'food_repository.dart';

final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  return PhotoRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
});

class PhotoRepository {
  const PhotoRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  }) : _firestore = firestore,
       _storage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> _itemsRef(String uid) {
    return _firestore.collection('photos/$uid/items');
  }

  Future<String> addLocalPhoto({
    required String uid,
    required String localPath,
    required String type,
    String mediaType = 'image',
    String category = 'all',
    String? foodName,
    int? calories,
    DateTime? date,
  }) async {
    final doc = _itemsRef(uid).doc();
    final capturedAt = date ?? DateTime.now();
    await doc.set({
      'uid': uid,
      'localPath': localPath,
      'type': type,
      'mediaType': mediaType,
      'category': category,
      // ignore: use_null_aware_elements
      if (foodName != null) 'foodName': foodName,
      // ignore: use_null_aware_elements
      if (calories != null) 'calories': calories,
      'isBackedUp': false,
      'remoteUrl': null,
      'date': Timestamp.fromDate(capturedAt),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Stream<List<PhotoAlbumItem>> watchMonthPhotos({
    required String uid,
    required DateTime month,
    String type = 'all',
  }) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    Query<Map<String, dynamic>> query = _itemsRef(uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true);
    if (type != 'all') {
      query = query.where('type', isEqualTo: type);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => PhotoAlbumItem.fromJson(doc.id, doc.data()))
          .toList(),
    );
  }

  Future<List<PhotoAlbumItem>> readRecentBodyPhotos({
    required String uid,
    int limit = 3,
  }) async {
    final snapshot = await _itemsRef(uid)
        .where('type', isEqualTo: 'body')
        .orderBy('date', descending: true)
        .limit(limit * 3)
        .get();
    return snapshot.docs
        .map((doc) => PhotoAlbumItem.fromJson(doc.id, doc.data()))
        .where((item) => item.localPath.trim().isNotEmpty)
        .where((item) => File(item.localPath).existsSync())
        .take(limit)
        .toList();
  }

  Future<String> backupPhoto({
    required String uid,
    required PhotoAlbumItem item,
  }) async {
    final file = File(item.localPath);
    if (!file.existsSync()) {
      throw const PhotoRepositoryException('갤러리 원본을 찾을 수 없어요.');
    }

    final extension = item.mediaType == 'video' ? 'mp4' : 'jpg';
    final contentType = item.mediaType == 'video' ? 'video/mp4' : 'image/jpeg';
    final ref = _storage.ref('photos/$uid/${item.type}/${item.id}.$extension');
    await ref.putFile(file, SettableMetadata(contentType: contentType));
    final url = await ref.getDownloadURL();
    await _itemsRef(uid).doc(item.id).set({
      'isBackedUp': true,
      'remoteUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return url;
  }

  Future<void> deletePhoto({
    required String uid,
    required PhotoAlbumItem item,
  }) async {
    if (item.isBackedUp && item.remoteUrl.trim().isNotEmpty) {
      try {
        await _storage.refFromURL(item.remoteUrl).delete();
      } on Object {
        // Storage 파일이 이미 없더라도 앱 기록 삭제는 계속 진행합니다.
      }
    }
    await _itemsRef(uid).doc(item.id).delete();
  }

  Future<void> deletePhotoDocument({
    required String uid,
    required String photoId,
  }) {
    return _itemsRef(uid).doc(photoId).delete();
  }
}

class PhotoAlbumItem {
  const PhotoAlbumItem({
    required this.id,
    required this.uid,
    required this.localPath,
    required this.type,
    required this.mediaType,
    required this.category,
    required this.isBackedUp,
    required this.remoteUrl,
    required this.date,
    this.foodName,
    this.calories,
  });

  factory PhotoAlbumItem.fromJson(String id, Map<String, dynamic> json) {
    final dateValue = json['date'] ?? json['createdAt'];
    return PhotoAlbumItem(
      id: id,
      uid: json['uid'] as String? ?? '',
      localPath: json['localPath'] as String? ?? '',
      type: json['type'] as String? ?? 'body',
      mediaType: json['mediaType'] as String? ?? 'image',
      category: json['category'] as String? ?? 'all',
      foodName: json['foodName'] as String?,
      calories: (json['calories'] as num?)?.toInt(),
      isBackedUp: json['isBackedUp'] as bool? ?? false,
      remoteUrl: json['remoteUrl'] as String? ?? '',
      date: dateValue is Timestamp ? dateValue.toDate() : DateTime.now(),
    );
  }

  final String id;
  final String uid;
  final String localPath;
  final String type;
  final String mediaType;
  final String category;
  final String? foodName;
  final int? calories;
  final bool isBackedUp;
  final String remoteUrl;
  final DateTime date;

  String get typeLabel => type == 'food' ? '음식' : '눈바디';

  String get categoryLabel {
    return switch (category) {
      'front' => '앞모습',
      'side' => '옆모습',
      _ => typeLabel,
    };
  }

  bool get isVideo => mediaType == 'video';

  String get monthKey => DateFormat('yyyy-MM').format(date);
}

class PhotoRepositoryException implements Exception {
  const PhotoRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
