import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'auth_repository.dart';

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return FoodRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
});

class FoodRepository {
  const FoodRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  }) : _firestore = firestore,
       _storage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Future<String> uploadImage({
    required String uid,
    required File file,
    required String folder,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref('users/$uid/$folder/$timestamp.jpg');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<void> saveFood({
    required String uid,
    required String mealType,
    required FoodData foodData,
    required String imageUrl,
  }) async {
    final now = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(now);
    final foodRef = _firestore.collection('users/$uid/food_logs').doc();
    final dailyRef = _firestore.doc('users/$uid/daily_logs/$dateKey');

    final batch = _firestore.batch();
    batch.set(foodRef, {
      ...foodData.toJson(),
      'uid': uid,
      'mealType': mealType,
      'imageUrl': imageUrl,
      'date': Timestamp.fromDate(DateTime(now.year, now.month, now.day)),
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(dailyRef, {
      'consumedCalories': FieldValue.increment(foodData.calories),
      'carbs': FieldValue.increment(foodData.carbs),
      'protein': FieldValue.increment(foodData.protein),
      'fat': FieldValue.increment(foodData.fat),
      'mealCounts.$mealType': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> getTodayFoods({
    required String uid,
    required DateTime date,
  }) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final snapshot = await _firestore
        .collection('users/$uid/food_logs')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> getFoodAlbum(String uid) async {
    final snapshot = await _firestore
        .collection('users/$uid/food_logs')
        .orderBy('createdAt', descending: true)
        .limit(60)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> saveBodyPhoto({
    required String uid,
    required String imageUrl,
    double? weight,
    String? note,
  }) async {
    final now = DateTime.now();
    await _firestore.collection('users/$uid/body_photos').add({
      'uid': uid,
      'imageUrl': imageUrl,
      'weight': weight,
      'note': note,
      'date': Timestamp.fromDate(now),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<BodyPhotoEntry>> watchBodyPhotos(String uid) {
    return _firestore
        .collection('users/$uid/body_photos')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BodyPhotoEntry.fromJson(doc.data()))
              .toList(),
        );
  }
}

class FoodData {
  const FoodData({
    required this.foodName,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  final String foodName;
  final int calories;
  final int carbs;
  final int protein;
  final int fat;

  FoodData copyWith({
    String? foodName,
    int? calories,
    int? carbs,
    int? protein,
    int? fat,
  }) {
    return FoodData(
      foodName: foodName ?? this.foodName,
      calories: calories ?? this.calories,
      carbs: carbs ?? this.carbs,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'foodName': foodName,
      'calories': calories,
      'carbs': carbs,
      'protein': protein,
      'fat': fat,
    };
  }
}

class BodyPhotoEntry {
  const BodyPhotoEntry({
    required this.imageUrl,
    required this.date,
    this.weight,
    this.note,
  });

  factory BodyPhotoEntry.fromJson(Map<String, dynamic> json) {
    return BodyPhotoEntry(
      imageUrl: json['imageUrl'] as String? ?? '',
      date:
          (json['date'] as Timestamp?)?.toDate() ??
          (json['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      weight: (json['weight'] as num?)?.toDouble(),
      note: json['note'] as String?,
    );
  }

  final String imageUrl;
  final DateTime date;
  final double? weight;
  final String? note;
}
