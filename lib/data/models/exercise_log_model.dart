import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseLogModel {
  const ExerciseLogModel({
    required this.id,
    required this.uid,
    required this.exerciseType,
    required this.minutes,
    required this.caloriesBurned,
    required this.date,
    required this.createdAt,
    required this.note,
  });

  factory ExerciseLogModel.fromJson(Map<String, dynamic> json) {
    return ExerciseLogModel(
      id: json['id'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
      exerciseType: json['exerciseType'] as String? ?? '',
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
      caloriesBurned: (json['caloriesBurned'] as num?)?.toInt() ?? 0,
      date: _dateFromJson(json['date']),
      createdAt: _dateFromJson(json['createdAt']),
      note: json['note'] as String?,
    );
  }

  final String id;
  final String uid;
  final String exerciseType;
  final int minutes;
  final int caloriesBurned;
  final DateTime date;
  final DateTime createdAt;
  final String? note;

  Map<String, Object?> toJson() {
    return {
      'uid': uid,
      'exerciseType': exerciseType,
      'minutes': minutes,
      'caloriesBurned': caloriesBurned,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'note': note,
    };
  }

  ExerciseLogModel copyWith({
    String? id,
    String? uid,
    String? exerciseType,
    int? minutes,
    int? caloriesBurned,
    DateTime? date,
    DateTime? createdAt,
    Object? note = _sentinel,
  }) {
    return ExerciseLogModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      exerciseType: exerciseType ?? this.exerciseType,
      minutes: minutes ?? this.minutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      note: identical(note, _sentinel) ? this.note : note as String?,
    );
  }
}

DateTime _dateFromJson(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}

const Object _sentinel = Object();
