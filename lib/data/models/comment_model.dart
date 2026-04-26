import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  const CommentModel({
    required this.id,
    required this.uid,
    required this.nickname,
    required this.content,
    required this.parentId,
    required this.likeCount,
    required this.createdAt,
    required this.isDeleted,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'];
    return CommentModel(
      id: json['id'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '미담러',
      content: json['content'] as String? ?? '',
      parentId: json['parentId'] as String?,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.tryParse(createdAt?.toString() ?? '') ?? DateTime.now(),
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  final String id;
  final String uid;
  final String nickname;
  final String content;
  final String? parentId;
  final int likeCount;
  final DateTime createdAt;
  final bool isDeleted;

  Map<String, Object?> toJson() {
    return {
      'uid': uid,
      'nickname': nickname,
      'content': content,
      'parentId': parentId,
      'likeCount': likeCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'isDeleted': isDeleted,
    };
  }

  CommentModel copyWith({
    String? id,
    String? uid,
    String? nickname,
    String? content,
    Object? parentId = _sentinel,
    int? likeCount,
    DateTime? createdAt,
    bool? isDeleted,
  }) {
    return CommentModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      nickname: nickname ?? this.nickname,
      content: content ?? this.content,
      parentId: identical(parentId, _sentinel)
          ? this.parentId
          : parentId as String?,
      likeCount: likeCount ?? this.likeCount,
      createdAt: createdAt ?? this.createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

const Object _sentinel = Object();
