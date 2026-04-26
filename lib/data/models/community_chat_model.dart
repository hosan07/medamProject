import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityChatRoom {
  const CommunityChatRoom({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastAt,
    required this.unreadCount,
  });

  factory CommunityChatRoom.fromJson(Map<String, dynamic> json) {
    final lastAt = json['lastAt'];
    return CommunityChatRoom(
      id: json['id'] as String? ?? '',
      participants:
          (json['participants'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
      lastMessage: json['lastMessage'] as String? ?? '',
      lastAt: lastAt is Timestamp
          ? lastAt.toDate()
          : DateTime.tryParse(lastAt?.toString() ?? '') ?? DateTime.now(),
      unreadCount:
          (json['unreadCount'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0),
          ) ??
          const {},
    );
  }

  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastAt;
  final Map<String, int> unreadCount;

  Map<String, Object?> toJson() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastAt': Timestamp.fromDate(lastAt),
      'unreadCount': unreadCount,
    };
  }

  CommunityChatRoom copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastAt,
    Map<String, int>? unreadCount,
  }) {
    return CommunityChatRoom(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastAt: lastAt ?? this.lastAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class CommunityChatMessage {
  const CommunityChatMessage({
    required this.id,
    required this.uid,
    required this.content,
    required this.imageUrl,
    required this.createdAt,
    required this.readBy,
  });

  factory CommunityChatMessage.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'];
    return CommunityChatMessage(
      id: json['id'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
      content: json['content'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.tryParse(createdAt?.toString() ?? '') ?? DateTime.now(),
      readBy:
          (json['readBy'] as List<dynamic>?)?.whereType<String>().toList() ??
          const [],
    );
  }

  final String id;
  final String uid;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final List<String> readBy;

  Map<String, Object?> toJson() {
    return {
      'uid': uid,
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'readBy': readBy,
    };
  }

  CommunityChatMessage copyWith({
    String? id,
    String? uid,
    String? content,
    String? imageUrl,
    DateTime? createdAt,
    List<String>? readBy,
  }) {
    return CommunityChatMessage(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      readBy: readBy ?? this.readBy,
    );
  }
}
