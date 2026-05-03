import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../auth/providers/auth_provider.dart';
import 'home_provider.dart';

final recordRepositoryProvider = Provider<RecordRepository>((ref) {
  return RecordRepository(firestore: ref.watch(firebaseFirestoreProvider));
});

final dailyRecordProvider = FutureProvider.family<DailyRecordData, String>((
  ref,
  dateKey,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return DailyRecordData.empty(dateKey);
  }
  return ref.watch(recordRepositoryProvider).getDailyRecord(user.uid, dateKey);
});

final weeklyRecordProvider = FutureProvider.family<WeeklyRecordData, String>((
  ref,
  dateKey,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return const WeeklyRecordData(days: []);
  }
  return ref.watch(recordRepositoryProvider).getWeeklyRecord(user.uid, dateKey);
});

final monthlyRecordProvider = FutureProvider.family<MonthlyRecordData, String>((
  ref,
  dateKey,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return const MonthlyRecordData(days: []);
  }
  return ref
      .watch(recordRepositoryProvider)
      .getMonthlyRecord(user.uid, dateKey);
});

final calendarMonthProvider = FutureProvider.family<CalendarMonthData, String>((
  ref,
  monthKey,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return const CalendarMonthData(recordDates: {}, memoDates: {});
  }
  return ref
      .watch(recordRepositoryProvider)
      .getCalendarMonth(user.uid, monthKey);
});

class RecordRepository {
  const RecordRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Future<DailyRecordData> getDailyRecord(String uid, String dateKey) async {
    final userDoc = await _firestore.doc('users/$uid').get();
    final dailyDoc = await _firestore
        .doc('food_logs/$uid/daily/$dateKey')
        .get();
    final mealsSnapshot = await _firestore
        .collection('food_logs/$uid/daily/$dateKey/meals')
        .orderBy('createdAt', descending: false)
        .get();
    final exerciseDoc = await _firestore
        .doc('exercise_logs/$uid/daily/$dateKey')
        .get();

    final meals = mealsSnapshot.docs
        .map((doc) => HomeMealEntry.fromJson({'id': doc.id, ...doc.data()}))
        .toList();

    return DailyRecordData.fromFirestore(
      dateKey: dateKey,
      user: userDoc.data(),
      daily: dailyDoc.data(),
      meals: meals,
      exercise: exerciseDoc.data(),
    );
  }

  Future<WeeklyRecordData> getWeeklyRecord(String uid, String dateKey) async {
    final selected = _parseDateKey(dateKey);
    final start = DateTime(
      selected.year,
      selected.month,
      selected.day,
    ).subtract(const Duration(days: 6));
    final days = <DailySummaryData>[];
    for (var index = 0; index < 7; index += 1) {
      final date = start.add(Duration(days: index));
      days.add(await _getDailySummary(uid, _dateKey(date)));
    }
    return WeeklyRecordData(days: days);
  }

  Future<MonthlyRecordData> getMonthlyRecord(String uid, String dateKey) async {
    final selected = _parseDateKey(dateKey);
    final first = DateTime(selected.year, selected.month);
    final last = DateTime(selected.year, selected.month + 1, 0);
    final days = <DailySummaryData>[];
    for (var day = 1; day <= last.day; day += 1) {
      final date = DateTime(first.year, first.month, day);
      days.add(await _getDailySummary(uid, _dateKey(date)));
    }
    return MonthlyRecordData(days: days);
  }

  Future<CalendarMonthData> getCalendarMonth(
    String uid,
    String monthKey,
  ) async {
    final month = DateFormat('yyyy-MM').parse(monthKey);
    final startKey = DateFormat('yyyy-MM-dd').format(month);
    final endKey = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(month.year, month.month + 1));

    final foodSnapshot = await _firestore
        .collection('food_logs/$uid/daily')
        .where('date', isGreaterThanOrEqualTo: startKey)
        .where('date', isLessThan: endKey)
        .get();
    final memoSnapshot = await _firestore
        .collection('calendar_memos/$uid/memos')
        .where('date', isGreaterThanOrEqualTo: startKey)
        .where('date', isLessThan: endKey)
        .get();

    return CalendarMonthData(
      recordDates: {for (final doc in foodSnapshot.docs) doc.id: true},
      memoDates: {
        for (final doc in memoSnapshot.docs)
          if (doc.data()['date'] case final String date) date: true,
      },
    );
  }

  Future<void> saveMemo({
    required String uid,
    required String dateKey,
    required String category,
    required String memo,
  }) async {
    final docId = '${dateKey}_$category';
    await _firestore.doc('calendar_memos/$uid/memos/$docId').set({
      'uid': uid,
      'date': dateKey,
      'category': category,
      'memo': memo,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<DailySummaryData> _getDailySummary(String uid, String dateKey) async {
    final doc = await _firestore.doc('food_logs/$uid/daily/$dateKey').get();
    return DailySummaryData.fromFirestore(dateKey: dateKey, data: doc.data());
  }

  String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  DateTime _parseDateKey(String dateKey) {
    return DateFormat('yyyy-MM-dd').parse(dateKey);
  }
}

class DailyRecordData {
  const DailyRecordData({
    required this.dateKey,
    required this.targetCalories,
    required this.meals,
    required this.totalCalories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.waterMl,
    required this.exerciseMinutes,
    required this.exerciseType,
    required this.exerciseEntries,
  });

  factory DailyRecordData.empty(String dateKey) {
    return DailyRecordData(
      dateKey: dateKey,
      targetCalories: 1800,
      meals: const [],
      totalCalories: 0,
      carbs: 0,
      protein: 0,
      fat: 0,
      waterMl: 0,
      exerciseMinutes: 0,
      exerciseType: '기록 없음',
      exerciseEntries: const [],
    );
  }

  factory DailyRecordData.fromFirestore({
    required String dateKey,
    required Map<String, dynamic>? user,
    required Map<String, dynamic>? daily,
    required List<HomeMealEntry> meals,
    required Map<String, dynamic>? exercise,
  }) {
    final fallback = DailyRecordData.empty(dateKey);
    final entries =
        (exercise?['entries'] as List<dynamic>?)
            ?.whereType<Map<dynamic, dynamic>>()
            .map(
              (entry) =>
                  ExerciseEntry.fromJson(Map<String, dynamic>.from(entry)),
            )
            .toList() ??
        const <ExerciseEntry>[];

    return DailyRecordData(
      dateKey: dateKey,
      targetCalories:
          (user?['targetCalories'] as num?)?.toInt() ?? fallback.targetCalories,
      meals: meals,
      totalCalories:
          (daily?['consumedCalories'] as num?)?.toInt() ??
          meals.fold<int>(0, (total, meal) => total + meal.calories),
      carbs:
          (daily?['carbs'] as num?)?.toInt() ??
          meals.fold<int>(0, (total, meal) => total + meal.carbs),
      protein:
          (daily?['protein'] as num?)?.toInt() ??
          meals.fold<int>(0, (total, meal) => total + meal.protein),
      fat:
          (daily?['fat'] as num?)?.toInt() ??
          meals.fold<int>(0, (total, meal) => total + meal.fat),
      waterMl:
          (daily?['waterMl'] as num?)?.toInt() ??
          (daily?['waterIntake'] as num?)?.toInt() ??
          0,
      exerciseMinutes:
          (exercise?['totalMinutes'] as num?)?.toInt() ??
          entries.fold<int>(0, (total, entry) => total + entry.minutes),
      exerciseType: exercise?['latestExerciseType'] as String? ?? '기록 없음',
      exerciseEntries: entries,
    );
  }

  final String dateKey;
  final int targetCalories;
  final List<HomeMealEntry> meals;
  final int totalCalories;
  final int carbs;
  final int protein;
  final int fat;
  final int waterMl;
  final int exerciseMinutes;
  final String exerciseType;
  final List<ExerciseEntry> exerciseEntries;

  double get calorieRate {
    if (targetCalories <= 0) {
      return 0;
    }
    return totalCalories / targetCalories;
  }
}

class DailySummaryData {
  const DailySummaryData({
    required this.dateKey,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  factory DailySummaryData.fromFirestore({
    required String dateKey,
    required Map<String, dynamic>? data,
  }) {
    return DailySummaryData(
      dateKey: dateKey,
      calories: (data?['consumedCalories'] as num?)?.toInt() ?? 0,
      carbs: (data?['carbs'] as num?)?.toInt() ?? 0,
      protein: (data?['protein'] as num?)?.toInt() ?? 0,
      fat: (data?['fat'] as num?)?.toInt() ?? 0,
    );
  }

  final String dateKey;
  final int calories;
  final int carbs;
  final int protein;
  final int fat;
}

class WeeklyRecordData {
  const WeeklyRecordData({required this.days});

  final List<DailySummaryData> days;

  int get averageCalories => _average(days.map((day) => day.calories));
  int get averageCarbs => _average(days.map((day) => day.carbs));
  int get averageProtein => _average(days.map((day) => day.protein));
  int get averageFat => _average(days.map((day) => day.fat));
}

class MonthlyRecordData {
  const MonthlyRecordData({required this.days});

  final List<DailySummaryData> days;

  int get averageCalories => _average(days.map((day) => day.calories));

  DailySummaryData? get maxDay {
    final recorded = days.where((day) => day.calories > 0).toList();
    if (recorded.isEmpty) {
      return null;
    }
    recorded.sort((a, b) => b.calories.compareTo(a.calories));
    return recorded.first;
  }

  DailySummaryData? get minDay {
    final recorded = days.where((day) => day.calories > 0).toList();
    if (recorded.isEmpty) {
      return null;
    }
    recorded.sort((a, b) => a.calories.compareTo(b.calories));
    return recorded.first;
  }
}

class ExerciseEntry {
  const ExerciseEntry({required this.exerciseType, required this.minutes});

  factory ExerciseEntry.fromJson(Map<String, dynamic> json) {
    return ExerciseEntry(
      exerciseType: json['exerciseType'] as String? ?? '운동',
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
    );
  }

  final String exerciseType;
  final int minutes;
}

class CalendarMonthData {
  const CalendarMonthData({required this.recordDates, required this.memoDates});

  final Map<String, bool> recordDates;
  final Map<String, bool> memoDates;

  bool hasRecord(String dateKey) => recordDates[dateKey] ?? false;
  bool hasMemo(String dateKey) => memoDates[dateKey] ?? false;
}

int _average(Iterable<int> values) {
  final items = values.toList();
  if (items.isEmpty) {
    return 0;
  }
  return (items.reduce((a, b) => a + b) / items.length).round();
}
