import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/exercise_log_model.dart';
import 'auth_repository.dart';

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepository(firestore: ref.watch(firebaseFirestoreProvider));
});

class ExerciseRepository {
  const ExerciseRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Stream<List<ExerciseLogModel>> watchLogs(String uid, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _firestore
        .collection('users/$uid/exercise_logs')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    ExerciseLogModel.fromJson({'id': doc.id, ...doc.data()}),
              )
              .toList(),
        );
  }

  Future<void> addExerciseLog(ExerciseLogModel log) async {
    final now = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(log.date);
    final logRef = _firestore
        .collection('users/${log.uid}/exercise_logs')
        .doc();
    final dailyRef = _firestore.doc('users/${log.uid}/daily_logs/$dateKey');

    final batch = _firestore.batch();
    batch.set(logRef, {
      ...log.copyWith(id: logRef.id, createdAt: now).toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(dailyRef, {
      'exerciseMinutes': FieldValue.increment(log.minutes),
      'exerciseCalories': FieldValue.increment(log.caloriesBurned),
      'exerciseType': log.exerciseType,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> deleteExerciseLog({
    required String uid,
    required String logId,
    required DateTime date,
  }) async {
    final logRef = _firestore.doc('users/$uid/exercise_logs/$logId');
    final snapshot = await logRef.get();
    final data = snapshot.data();
    if (data == null) {
      return;
    }

    final log = ExerciseLogModel.fromJson({'id': logId, ...data});
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final dailyRef = _firestore.doc('users/$uid/daily_logs/$dateKey');
    final batch = _firestore.batch();
    batch.delete(logRef);
    batch.set(dailyRef, {
      'exerciseMinutes': FieldValue.increment(-log.minutes),
      'exerciseCalories': FieldValue.increment(-log.caloriesBurned),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }
}
