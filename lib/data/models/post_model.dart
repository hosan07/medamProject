import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  const PostModel({
    required this.id,
    required this.uid,
    required this.nickname,
    required this.profileImage,
    required this.category,
    required this.title,
    required this.content,
    required this.imageUrls,
    required this.likeCount,
    required this.commentCount,
    required this.scrapCount,
    required this.createdAt,
    required this.isBlocked,
    required this.isDeleted,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '미담러',
      profileImage: json['profileImage'] as String?,
      category: json['category'] as String? ?? '전체',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      imageUrls:
          (json['imageUrls'] as List<dynamic>?)?.whereType<String>().toList() ??
          const [],
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      scrapCount: (json['scrapCount'] as num?)?.toInt() ?? 0,
      createdAt: _dateFromJson(json['createdAt']),
      isBlocked: json['isBlocked'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  final String id;
  final String uid;
  final String nickname;
  final String? profileImage;
  final String category;
  final String title;
  final String content;
  final List<String> imageUrls;
  final int likeCount;
  final int commentCount;
  final int scrapCount;
  final DateTime createdAt;
  final bool isBlocked;
  final bool isDeleted;

  Map<String, Object?> toJson() {
    return {
      'uid': uid,
      'nickname': nickname,
      'profileImage': profileImage,
      'category': category,
      'title': title,
      'content': content,
      'imageUrls': imageUrls,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'scrapCount': scrapCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'isBlocked': isBlocked,
      'isDeleted': isDeleted,
    };
  }

  PostModel copyWith({
    String? id,
    String? uid,
    String? nickname,
    String? profileImage,
    String? category,
    String? title,
    String? content,
    List<String>? imageUrls,
    int? likeCount,
    int? commentCount,
    int? scrapCount,
    DateTime? createdAt,
    bool? isBlocked,
    bool? isDeleted,
  }) {
    return PostModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      nickname: nickname ?? this.nickname,
      profileImage: profileImage ?? this.profileImage,
      category: category ?? this.category,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      scrapCount: scrapCount ?? this.scrapCount,
      createdAt: createdAt ?? this.createdAt,
      isBlocked: isBlocked ?? this.isBlocked,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

DateTime _dateFromJson(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}
