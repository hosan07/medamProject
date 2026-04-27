import 'package:cloud_firestore/cloud_firestore.dart';

class FoodLogModel {
  const FoodLogModel({
    required this.id,
    required this.uid,
    required this.mealType,
    required this.foodName,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.imageUrl,
    required this.date,
    required this.createdAt,
  });

  factory FoodLogModel.fromJson(Map<String, dynamic> json) {
    return FoodLogModel(
      id: json['id'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
      mealType: json['mealType'] as String? ?? '',
      foodName: json['foodName'] as String? ?? '',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      carbs: (json['carbs'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toInt() ?? 0,
      fat: (json['fat'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl'] as String? ?? '',
      date: _dateFromJson(json['date']),
      createdAt: _dateFromJson(json['createdAt']),
    );
  }

  final String id;
  final String uid;
  final String mealType;
  final String foodName;
  final int calories;
  final int carbs;
  final int protein;
  final int fat;
  final String imageUrl;
  final DateTime date;
  final DateTime createdAt;

  Map<String, Object?> toJson() {
    return {
      'uid': uid,
      'mealType': mealType,
      'foodName': foodName,
      'calories': calories,
      'carbs': carbs,
      'protein': protein,
      'fat': fat,
      'imageUrl': imageUrl,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  FoodLogModel copyWith({
    String? id,
    String? uid,
    String? mealType,
    String? foodName,
    int? calories,
    int? carbs,
    int? protein,
    int? fat,
    String? imageUrl,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return FoodLogModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      mealType: mealType ?? this.mealType,
      foodName: foodName ?? this.foodName,
      calories: calories ?? this.calories,
      carbs: carbs ?? this.carbs,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      imageUrl: imageUrl ?? this.imageUrl,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

DateTime _dateFromJson(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}
