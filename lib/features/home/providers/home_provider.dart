import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../auth/providers/auth_provider.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(firestore: ref.watch(firebaseFirestoreProvider));
});

final todayHomeDataProvider = StreamProvider<TodayHomeData>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(TodayHomeData.empty());
  }

  return ref.watch(homeRepositoryProvider).watchTodayHomeData(user.uid);
});

final todayMealsProvider = StreamProvider<List<HomeMealEntry>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return const Stream.empty();
  }

  return ref.watch(homeRepositoryProvider).watchTodayMeals(user.uid);
});

class HomeRepository {
  const HomeRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Stream<TodayHomeData> watchTodayHomeData(String uid) {
    final dateKey = _dateKey(DateTime.now());
    final controller = StreamController<TodayHomeData>();

    Map<String, dynamic>? userData;
    Map<String, dynamic>? profileData;
    Map<String, dynamic>? foodDailyData;
    Map<String, dynamic>? exerciseDailyData;
    List<Map<String, dynamic>> bodyPhotos = const [];

    void emit() {
      if (!controller.isClosed) {
        controller.add(
          TodayHomeData.fromFirestore(
            user: userData,
            profile: profileData,
            foodDaily: foodDailyData,
            exerciseDaily: exerciseDailyData,
            bodyPhotos: bodyPhotos,
          ),
        );
      }
    }

    final subscriptions = <StreamSubscription<dynamic>>[
      _firestore.doc('users/$uid').snapshots().listen((snapshot) {
        userData = snapshot.data();
        emit();
      }),
      _firestore.doc('users/$uid/profile/main').snapshots().listen((snapshot) {
        profileData = snapshot.data();
        emit();
      }),
      _firestore.doc('food_logs/$uid/daily/$dateKey').snapshots().listen((
        snapshot,
      ) {
        foodDailyData = snapshot.data();
        emit();
      }),
      _firestore.doc('exercise_logs/$uid/daily/$dateKey').snapshots().listen((
        snapshot,
      ) {
        exerciseDailyData = snapshot.data();
        emit();
      }),
      _firestore
          .collection('users/$uid/body_photos')
          .orderBy('date', descending: true)
          .limit(3)
          .snapshots()
          .listen((snapshot) {
            bodyPhotos = snapshot.docs.map((doc) => doc.data()).toList();
            emit();
          }),
    ];

    controller.onCancel = () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };

    return controller.stream;
  }

  Stream<List<HomeMealEntry>> watchTodayMeals(String uid) {
    final dateKey = _dateKey(DateTime.now());
    return _firestore
        .collection('food_logs/$uid/daily/$dateKey/meals')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => HomeMealEntry.fromJson({'id': doc.id, ...doc.data()}),
              )
              .toList(),
        );
  }

  Future<String> addMeal({
    required String uid,
    required String mealType,
    required String foodName,
    required int calories,
    required int carbs,
    required int protein,
    required int fat,
    String? imageUrl,
  }) async {
    final now = DateTime.now();
    final dateKey = _dateKey(now);
    final dailyRef = _firestore.doc('food_logs/$uid/daily/$dateKey');
    final mealRef = dailyRef.collection('meals').doc();

    final batch = _firestore.batch();
    batch.set(mealRef, {
      'uid': uid,
      'mealType': mealType,
      'foodName': foodName,
      'calories': calories,
      'carbs': carbs,
      'protein': protein,
      'fat': fat,
      'imageUrl': imageUrl,
      'date': Timestamp.fromDate(DateTime(now.year, now.month, now.day)),
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(dailyRef, {
      'uid': uid,
      'date': dateKey,
      'consumedCalories': FieldValue.increment(calories),
      'carbs': FieldValue.increment(carbs),
      'protein': FieldValue.increment(protein),
      'fat': FieldValue.increment(fat),
      'mealCounts.$mealType': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
    return mealRef.id;
  }

  Future<void> addExercise({
    required String uid,
    required String exerciseType,
    required int minutes,
  }) async {
    final now = DateTime.now();
    final dateKey = _dateKey(now);
    final dailyRef = _firestore.doc('exercise_logs/$uid/daily/$dateKey');

    await dailyRef.set({
      'uid': uid,
      'date': dateKey,
      'totalMinutes': FieldValue.increment(minutes),
      'latestExerciseType': exerciseType,
      'entries': FieldValue.arrayUnion([
        {
          'exerciseType': exerciseType,
          'minutes': minutes,
          'createdAt': Timestamp.fromDate(now),
        },
      ]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
}

class TodayHomeData {
  const TodayHomeData({
    required this.targetCalories,
    required this.consumedCalories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.carbsTarget,
    required this.proteinTarget,
    required this.fatTarget,
    required this.mealCounts,
    required this.bmi,
    required this.weightChange,
    required this.bodyPhotoUrls,
    required this.exerciseMinutes,
    required this.exerciseType,
  });

  factory TodayHomeData.empty() {
    return const TodayHomeData(
      targetCalories: 1800,
      consumedCalories: 0,
      carbs: 0,
      protein: 0,
      fat: 0,
      carbsTarget: 220,
      proteinTarget: 100,
      fatTarget: 50,
      mealCounts: {'아침': 0, '점심': 0, '저녁': 0, '간식': 0, '물': 0, '영양제': 0},
      bmi: 22.0,
      weightChange: [65, 64.7, 64.4, 64.2, 63.9, 63.8, 63.5],
      bodyPhotoUrls: [],
      exerciseMinutes: 0,
      exerciseType: '기록 없음',
    );
  }

  factory TodayHomeData.fromFirestore({
    required Map<String, dynamic>? user,
    required Map<String, dynamic>? profile,
    required Map<String, dynamic>? foodDaily,
    required Map<String, dynamic>? exerciseDaily,
    required List<Map<String, dynamic>> bodyPhotos,
  }) {
    final fallback = TodayHomeData.empty();
    final currentWeight =
        (user?['currentWeight'] as num?)?.toDouble() ??
        (profile?['currentWeight'] as num?)?.toDouble() ??
        65;
    final heightCm =
        (user?['height'] as num?)?.toDouble() ??
        (profile?['height'] as num?)?.toDouble() ??
        170;
    final heightM = heightCm / 100;
    final bmi = heightM == 0
        ? fallback.bmi
        : currentWeight / (heightM * heightM);

    return TodayHomeData(
      targetCalories:
          (user?['targetCalories'] as num?)?.toInt() ??
          (profile?['targetCalories'] as num?)?.toInt() ??
          fallback.targetCalories,
      consumedCalories:
          (foodDaily?['consumedCalories'] as num?)?.toInt() ??
          fallback.consumedCalories,
      carbs: (foodDaily?['carbs'] as num?)?.toInt() ?? fallback.carbs,
      protein: (foodDaily?['protein'] as num?)?.toInt() ?? fallback.protein,
      fat: (foodDaily?['fat'] as num?)?.toInt() ?? fallback.fat,
      carbsTarget: fallback.carbsTarget,
      proteinTarget: fallback.proteinTarget,
      fatTarget: fallback.fatTarget,
      mealCounts: {
        for (final label in fallback.mealCounts.keys)
          label:
              ((foodDaily?['mealCounts'] as Map<String, dynamic>?)?[label]
                      as num?)
                  ?.toInt() ??
              0,
      },
      bmi: bmi,
      weightChange:
          (user?['weightHistory'] as List<dynamic>?)
              ?.whereType<num>()
              .map((value) => value.toDouble())
              .toList() ??
          (profile?['weightHistory'] as List<dynamic>?)
              ?.whereType<num>()
              .map((value) => value.toDouble())
              .toList() ??
          fallback.weightChange,
      bodyPhotoUrls: bodyPhotos
          .map((photo) => photo['imageUrl'])
          .whereType<String>()
          .toList(),
      exerciseMinutes:
          (exerciseDaily?['totalMinutes'] as num?)?.toInt() ??
          fallback.exerciseMinutes,
      exerciseType:
          (exerciseDaily?['latestExerciseType'] as String?) ??
          fallback.exerciseType,
    );
  }

  final int targetCalories;
  final int consumedCalories;
  final int carbs;
  final int protein;
  final int fat;
  final int carbsTarget;
  final int proteinTarget;
  final int fatTarget;
  final Map<String, int> mealCounts;
  final double bmi;
  final List<double> weightChange;
  final List<String> bodyPhotoUrls;
  final int exerciseMinutes;
  final String exerciseType;

  double get calorieProgress {
    if (targetCalories <= 0) {
      return 0;
    }
    return (consumedCalories / targetCalories).clamp(0, 1);
  }
}

class HomeMealEntry {
  const HomeMealEntry({
    required this.id,
    required this.mealType,
    required this.foodName,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.createdAt,
  });

  factory HomeMealEntry.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'];
    return HomeMealEntry(
      id: json['id'] as String? ?? '',
      mealType: json['mealType'] as String? ?? '',
      foodName: json['foodName'] as String? ?? '',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      carbs: (json['carbs'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toInt() ?? 0,
      fat: (json['fat'] as num?)?.toInt() ?? 0,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    );
  }

  final String id;
  final String mealType;
  final String foodName;
  final int calories;
  final int carbs;
  final int protein;
  final int fat;
  final DateTime createdAt;
}
