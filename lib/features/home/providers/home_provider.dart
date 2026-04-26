import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../auth/providers/auth_provider.dart';

final todayHomeDataProvider = FutureProvider<TodayHomeData>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return TodayHomeData.empty();
  }

  final firestore = ref.watch(firebaseFirestoreProvider);
  final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

  final profileFuture = firestore.doc('users/${user.uid}/profile/main').get();
  final logFuture = firestore
      .doc('users/${user.uid}/daily_logs/$dateKey')
      .get();
  final bodyPhotosFuture = firestore
      .collection('users/${user.uid}/body_photos')
      .orderBy('date', descending: true)
      .limit(3)
      .get();

  final results = await Future.wait([
    profileFuture,
    logFuture,
    bodyPhotosFuture,
  ]);

  final profile = results[0] as DocumentSnapshot<Map<String, dynamic>>;
  final log = results[1] as DocumentSnapshot<Map<String, dynamic>>;
  final bodyPhotos = results[2] as QuerySnapshot<Map<String, dynamic>>;

  return TodayHomeData.fromFirestore(
    profile: profile.data(),
    log: log.data(),
    bodyPhotos: bodyPhotos.docs.map((doc) => doc.data()).toList(),
  );
});

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
    required Map<String, dynamic>? profile,
    required Map<String, dynamic>? log,
    required List<Map<String, dynamic>> bodyPhotos,
  }) {
    final fallback = TodayHomeData.empty();
    final currentWeight = (profile?['currentWeight'] as num?)?.toDouble() ?? 65;
    final heightCm = (profile?['height'] as num?)?.toDouble() ?? 170;
    final heightM = heightCm / 100;
    final bmi = heightM == 0
        ? fallback.bmi
        : currentWeight / (heightM * heightM);

    return TodayHomeData(
      targetCalories:
          (profile?['targetCalories'] as num?)?.toInt() ??
          (log?['targetCalories'] as num?)?.toInt() ??
          fallback.targetCalories,
      consumedCalories:
          (log?['consumedCalories'] as num?)?.toInt() ??
          fallback.consumedCalories,
      carbs: (log?['carbs'] as num?)?.toInt() ?? fallback.carbs,
      protein: (log?['protein'] as num?)?.toInt() ?? fallback.protein,
      fat: (log?['fat'] as num?)?.toInt() ?? fallback.fat,
      carbsTarget:
          (log?['carbsTarget'] as num?)?.toInt() ?? fallback.carbsTarget,
      proteinTarget:
          (log?['proteinTarget'] as num?)?.toInt() ?? fallback.proteinTarget,
      fatTarget: (log?['fatTarget'] as num?)?.toInt() ?? fallback.fatTarget,
      mealCounts: {
        for (final label in fallback.mealCounts.keys)
          label:
              ((log?['mealCounts'] as Map<String, dynamic>?)?[label] as num?)
                  ?.toInt() ??
              0,
      },
      bmi: bmi,
      weightChange:
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
          (log?['exerciseMinutes'] as num?)?.toInt() ??
          fallback.exerciseMinutes,
      exerciseType: (log?['exerciseType'] as String?) ?? fallback.exerciseType,
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
