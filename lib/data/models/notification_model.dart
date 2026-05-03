import 'package:cloud_firestore/cloud_firestore.dart';

enum MedamNotificationType {
  comment,
  like,
  follow,
  notice;

  static MedamNotificationType fromJson(String? value) {
    return MedamNotificationType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => MedamNotificationType.notice,
    );
  }

  String get label {
    return switch (this) {
      MedamNotificationType.comment => '댓글',
      MedamNotificationType.like => '좋아요',
      MedamNotificationType.follow => '팔로우',
      MedamNotificationType.notice => '공지',
    };
  }
}

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    required this.targetId,
    required this.senderUid,
    required this.senderNickname,
    required this.senderProfileImage,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'];
    return NotificationModel(
      id: json['id'] as String? ?? '',
      type: MedamNotificationType.fromJson(json['type'] as String?),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.tryParse(createdAt?.toString() ?? '') ?? DateTime.now(),
      targetId: json['targetId'] as String? ?? '',
      senderUid: json['senderUid'] as String? ?? '',
      senderNickname: json['senderNickname'] as String? ?? '미담',
      senderProfileImage: json['senderProfileImage'] as String?,
    );
  }

  final String id;
  final MedamNotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final String targetId;
  final String senderUid;
  final String senderNickname;
  final String? senderProfileImage;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'body': body,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'targetId': targetId,
      'senderUid': senderUid,
      'senderNickname': senderNickname,
      'senderProfileImage': senderProfileImage,
    };
  }
}
