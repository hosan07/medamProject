import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  const UserModel({
    required this.uid,
    required this.nickname,
    required this.email,
    required this.profileIcon,
    required this.backgroundIcon,
    required this.bio,
    required this.isPrivate,
    required this.createdAt,
    required this.goal,
    required this.targetWeight,
    required this.currentWeight,
    required this.aiCoach,
    required this.dietType,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '미담러',
      email: json['email'] as String?,
      profileIcon: json['profileIcon'] as String? ?? 'leaf',
      backgroundIcon: json['backgroundIcon'] as String? ?? 'green',
      bio: json['bio'] as String? ?? '',
      isPrivate: json['isPrivate'] as bool? ?? false,
      createdAt: _dateFromJson(json['createdAt']),
      goal: json['goal'] as String?,
      targetWeight: (json['targetWeight'] as num?)?.toDouble(),
      currentWeight: (json['currentWeight'] as num?)?.toDouble(),
      aiCoach: json['aiCoach'] as String?,
      dietType: json['dietType'] as String?,
    );
  }

  final String uid;
  final String nickname;
  final String? email;
  final String profileIcon;
  final String backgroundIcon;
  final String bio;
  final bool isPrivate;
  final DateTime createdAt;
  final String? goal;
  final double? targetWeight;
  final double? currentWeight;
  final String? aiCoach;
  final String? dietType;

  Map<String, Object?> toJson() {
    return {
      'uid': uid,
      'nickname': nickname,
      'email': email,
      'profileIcon': profileIcon,
      'backgroundIcon': backgroundIcon,
      'bio': bio,
      'isPrivate': isPrivate,
      'createdAt': Timestamp.fromDate(createdAt),
      'goal': goal,
      'targetWeight': targetWeight,
      'currentWeight': currentWeight,
      'aiCoach': aiCoach,
      'dietType': dietType,
    };
  }

  UserModel copyWith({
    String? uid,
    String? nickname,
    Object? email = _sentinel,
    String? profileIcon,
    String? backgroundIcon,
    String? bio,
    bool? isPrivate,
    DateTime? createdAt,
    Object? goal = _sentinel,
    Object? targetWeight = _sentinel,
    Object? currentWeight = _sentinel,
    Object? aiCoach = _sentinel,
    Object? dietType = _sentinel,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      nickname: nickname ?? this.nickname,
      email: identical(email, _sentinel) ? this.email : email as String?,
      profileIcon: profileIcon ?? this.profileIcon,
      backgroundIcon: backgroundIcon ?? this.backgroundIcon,
      bio: bio ?? this.bio,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt ?? this.createdAt,
      goal: identical(goal, _sentinel) ? this.goal : goal as String?,
      targetWeight: identical(targetWeight, _sentinel)
          ? this.targetWeight
          : targetWeight as double?,
      currentWeight: identical(currentWeight, _sentinel)
          ? this.currentWeight
          : currentWeight as double?,
      aiCoach: identical(aiCoach, _sentinel)
          ? this.aiCoach
          : aiCoach as String?,
      dietType: identical(dietType, _sentinel)
          ? this.dietType
          : dietType as String?,
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
