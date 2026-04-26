import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatMessageRole {
  user,
  assistant;

  static ChatMessageRole fromJson(String? value) {
    return ChatMessageRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => ChatMessageRole.assistant,
    );
  }
}

enum ChatMessageType {
  text,
  quickReply,
  foodCard;

  static ChatMessageType fromJson(String? value) {
    return ChatMessageType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ChatMessageType.text,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.messageType = ChatMessageType.text,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final timestamp = json['timestamp'];

    return ChatMessage(
      id: json['id'] as String? ?? '',
      role: ChatMessageRole.fromJson(json['role'] as String?),
      content: json['content'] as String? ?? '',
      timestamp: timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.tryParse(timestamp?.toString() ?? '') ?? DateTime.now(),
      messageType: ChatMessageType.fromJson(json['messageType'] as String?),
    );
  }

  final String id;
  final ChatMessageRole role;
  final String content;
  final DateTime timestamp;
  final ChatMessageType messageType;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'role': role.name,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'messageType': messageType.name,
    };
  }

  ChatMessage copyWith({
    String? id,
    ChatMessageRole? role,
    String? content,
    DateTime? timestamp,
    ChatMessageType? messageType,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      messageType: messageType ?? this.messageType,
    );
  }
}
