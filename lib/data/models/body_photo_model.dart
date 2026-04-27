import 'package:cloud_firestore/cloud_firestore.dart';

class BodyPhotoModel {
  const BodyPhotoModel({
    required this.id,
    required this.uid,
    required this.imageUrl,
    required this.weight,
    required this.date,
    required this.note,
  });

  factory BodyPhotoModel.fromJson(Map<String, dynamic> json) {
    final date = json['date'] ?? json['createdAt'];
    return BodyPhotoModel(
      id: json['id'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble(),
      date: date is Timestamp ? date.toDate() : DateTime.now(),
      note: json['note'] as String?,
    );
  }

  final String id;
  final String uid;
  final String imageUrl;
  final double? weight;
  final DateTime date;
  final String? note;

  Map<String, Object?> toJson() {
    return {
      'uid': uid,
      'imageUrl': imageUrl,
      'weight': weight,
      'date': Timestamp.fromDate(date),
      'note': note,
    };
  }

  BodyPhotoModel copyWith({
    String? id,
    String? uid,
    String? imageUrl,
    Object? weight = _sentinel,
    DateTime? date,
    Object? note = _sentinel,
  }) {
    return BodyPhotoModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      imageUrl: imageUrl ?? this.imageUrl,
      weight: identical(weight, _sentinel) ? this.weight : weight as double?,
      date: date ?? this.date,
      note: identical(note, _sentinel) ? this.note : note as String?,
    );
  }
}

const Object _sentinel = Object();
