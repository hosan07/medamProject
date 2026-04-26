import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/auth_repository.dart';

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
      OnboardingNotifier.new,
    );

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => OnboardingState.initial();

  void updateNickname(String value) {
    state = state.copyWith(nickname: value.trim());
  }

  void updateBirthDate(DateTime value) {
    state = state.copyWith(birthDate: value);
  }

  void updateGender(String value) {
    state = state.copyWith(gender: value);
  }

  void updateHeight(int value) {
    state = state.copyWith(height: value);
  }

  void updateGoal(String value) {
    state = state.copyWith(goal: value, goalReason: null);
  }

  void updateGoalReason(String value) {
    state = state.copyWith(goalReason: value);
  }

  void updateTriedBefore(String value) {
    state = state.copyWith(triedBefore: value);
  }

  void updateCurrentWeight(double value) {
    state = state.copyWith(currentWeight: value);
  }

  void updateTargetWeight(double value) {
    state = state.copyWith(targetWeight: value);
  }

  void updateActivityLevel(String value) {
    state = state.copyWith(activityLevel: value);
  }

  void updateWaterIntake(String value) {
    state = state.copyWith(waterIntake: value);
  }

  void toggleExerciseType(String value) {
    final next = [...state.exerciseTypes];
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    state = state.copyWith(exerciseTypes: next);
  }

  void skipExerciseTypes() {
    state = state.copyWith(exerciseTypes: const []);
  }

  void updateAiCoach(String value) {
    state = state.copyWith(aiCoach: value);
  }

  void updateRecommendedDiet(String value) {
    state = state.copyWith(recommendedDiet: value);
  }

  Future<void> saveProfile(String uid) async {
    final firestore = ref.read(firebaseFirestoreProvider);
    final data = state.toJson()
      ..addAll({
        'uid': uid,
        'bmr': state.bmr,
        'tdee': state.tdee,
        'targetCalories': state.targetCalories,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

    final batch = firestore.batch();
    batch.set(firestore.doc('users/$uid/profile/main'), data);
    batch.set(firestore.doc('users/$uid'), {
      'nickname': state.nickname,
      'goal': state.goal,
      'targetWeight': state.targetWeight,
      'currentWeight': state.currentWeight,
      'aiCoach': state.aiCoach,
      'dietType': state.recommendedDiet,
      'profileCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }
}

class OnboardingState {
  const OnboardingState({
    required this.nickname,
    required this.birthDate,
    required this.gender,
    required this.height,
    required this.goal,
    required this.goalReason,
    required this.triedBefore,
    required this.currentWeight,
    required this.targetWeight,
    required this.activityLevel,
    required this.waterIntake,
    required this.exerciseTypes,
    required this.aiCoach,
    required this.recommendedDiet,
  });

  factory OnboardingState.initial() {
    return OnboardingState(
      nickname: '',
      birthDate: DateTime(DateTime.now().year - 25, 1, 1),
      gender: null,
      height: 170,
      goal: null,
      goalReason: null,
      triedBefore: null,
      currentWeight: 65,
      targetWeight: 60,
      activityLevel: null,
      waterIntake: null,
      exerciseTypes: const [],
      aiCoach: null,
      recommendedDiet: null,
    );
  }

  final String nickname;
  final DateTime birthDate;
  final String? gender;
  final int height;
  final String? goal;
  final String? goalReason;
  final String? triedBefore;
  final double currentWeight;
  final double targetWeight;
  final String? activityLevel;
  final String? waterIntake;
  final List<String> exerciseTypes;
  final String? aiCoach;
  final String? recommendedDiet;

  int get age {
    final now = DateTime.now();
    var value = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      value -= 1;
    }
    return value.clamp(1, 120);
  }

  int get bmr {
    final base = 10 * currentWeight + 6.25 * height - 5 * age;
    final result = gender == '남성' ? base + 5 : base - 161;
    return result.round();
  }

  int get tdee {
    final multiplier = switch (activityLevel) {
      '매우 적음' => 1.2,
      '적음' => 1.375,
      '보통' => 1.55,
      '많음' => 1.725,
      '매우 많음' => 1.9,
      _ => 1.375,
    };
    return (bmr * multiplier).round();
  }

  int get targetCalories {
    final adjustment = switch (goal) {
      '감량' => -400,
      '증량' => 300,
      '근육량 증가' => 200,
      '체지방률 감소' => -250,
      _ => 0,
    };
    return (tdee + adjustment).clamp(1200, 4200);
  }

  OnboardingState copyWith({
    String? nickname,
    DateTime? birthDate,
    Object? gender = _sentinel,
    int? height,
    Object? goal = _sentinel,
    Object? goalReason = _sentinel,
    Object? triedBefore = _sentinel,
    double? currentWeight,
    double? targetWeight,
    Object? activityLevel = _sentinel,
    Object? waterIntake = _sentinel,
    List<String>? exerciseTypes,
    Object? aiCoach = _sentinel,
    Object? recommendedDiet = _sentinel,
  }) {
    return OnboardingState(
      nickname: nickname ?? this.nickname,
      birthDate: birthDate ?? this.birthDate,
      gender: identical(gender, _sentinel) ? this.gender : gender as String?,
      height: height ?? this.height,
      goal: identical(goal, _sentinel) ? this.goal : goal as String?,
      goalReason: identical(goalReason, _sentinel)
          ? this.goalReason
          : goalReason as String?,
      triedBefore: identical(triedBefore, _sentinel)
          ? this.triedBefore
          : triedBefore as String?,
      currentWeight: currentWeight ?? this.currentWeight,
      targetWeight: targetWeight ?? this.targetWeight,
      activityLevel: identical(activityLevel, _sentinel)
          ? this.activityLevel
          : activityLevel as String?,
      waterIntake: identical(waterIntake, _sentinel)
          ? this.waterIntake
          : waterIntake as String?,
      exerciseTypes: exerciseTypes ?? this.exerciseTypes,
      aiCoach: identical(aiCoach, _sentinel)
          ? this.aiCoach
          : aiCoach as String?,
      recommendedDiet: identical(recommendedDiet, _sentinel)
          ? this.recommendedDiet
          : recommendedDiet as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'nickname': nickname,
      'birthDate': Timestamp.fromDate(birthDate),
      'gender': gender,
      'height': height,
      'goal': goal,
      'goalReason': goalReason,
      'triedBefore': triedBefore,
      'currentWeight': currentWeight,
      'targetWeight': targetWeight,
      'activityLevel': activityLevel,
      'waterIntake': waterIntake,
      'exerciseTypes': exerciseTypes,
      'aiCoach': aiCoach,
      'recommendedDiet': recommendedDiet,
    };
  }
}

const Object _sentinel = Object();
