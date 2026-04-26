import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/chat_message_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../auth/providers/auth_provider.dart';

final aiChatProfileProvider = FutureProvider<AIChatProfile>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return AIChatProfile.guest();
  }

  final firestore = ref.watch(firebaseFirestoreProvider);
  final profile = await firestore.doc('users/${user.uid}/profile/main').get();
  final rootUser = await firestore.doc('users/${user.uid}').get();

  return AIChatProfile.fromJson({...?rootUser.data(), ...?profile.data()});
});

final aiChatProvider = AsyncNotifierProvider<AIChatNotifier, List<ChatMessage>>(
  AIChatNotifier.new,
);

class AIChatNotifier extends AsyncNotifier<List<ChatMessage>> {
  @override
  Future<List<ChatMessage>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const [];
    }

    final firestore = ref.watch(firebaseFirestoreProvider);
    final snapshot = await firestore
        .collection('users/${user.uid}/ai_chat_history')
        .orderBy('timestamp', descending: true)
        .limit(80)
        .get();

    final messages = snapshot.docs
        .map((doc) => ChatMessage.fromJson({'id': doc.id, ...doc.data()}))
        .toList();

    if (messages.isNotEmpty) {
      return messages;
    }

    final profile = await ref.watch(aiChatProfileProvider.future);
    final greeting = ChatMessage(
      id: _newId(),
      role: ChatMessageRole.assistant,
      content:
          '안녕하세요! ${profile.nickname}님, 오늘 하루는 어떠셨나요?\n오늘 드신 것들을 알려주시면 칼로리 계산을 도와드릴게요 :)',
      timestamp: DateTime.now(),
    );
    await _saveMessage(user.uid, greeting);
    return [greeting];
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) {
      return;
    }

    final previous = state.value ?? const <ChatMessage>[];
    final userMessage = ChatMessage(
      id: _newId(),
      role: ChatMessageRole.user,
      content: trimmed,
      timestamp: DateTime.now(),
    );

    state = AsyncData([userMessage, ...previous]);
    await _saveMessage(user.uid, userMessage);

    final profile = await ref.read(aiChatProfileProvider.future);
    final assistantMessage = await _callAI(text: trimmed, profile: profile);

    state = AsyncData([assistantMessage, userMessage, ...previous]);
    await _saveMessage(user.uid, assistantMessage);
  }

  Future<void> _saveMessage(String uid, ChatMessage message) async {
    final firestore = ref.read(firebaseFirestoreProvider);
    await firestore
        .doc('users/$uid/ai_chat_history/${message.id}')
        .set(message.toJson());
  }

  Future<ChatMessage> _callAI({
    required String text,
    required AIChatProfile profile,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 850));

    // TODO: OpenAI 또는 Anthropic API 연결 시 이 함수에서 프로필, 최근 대화,
    // 오늘 식단 로그를 함께 보내 개인화된 응답을 생성합니다.
    final lower = text.toLowerCase();
    final response = switch (lower) {
      final value when value.contains('운동') =>
        '${profile.nickname}님 목표가 ${profile.goal}라면 오늘은 30분 정도의 빠른 걷기와 가벼운 근력 운동을 추천해요. 무리하기보다 꾸준히 이어지는 강도가 좋아요.',
      final value when value.contains('목표') =>
        '현재 목표는 ${profile.goal}, 하루 권장 칼로리는 약 ${profile.targetCalories}kcal예요. 오늘 기록을 기준으로 남은 칼로리와 탄단지를 같이 맞춰볼게요.',
      final value when value.contains('칼로리') =>
        '음식 이름이나 사진을 알려주시면 칼로리를 추정해드릴게요. 가능하면 양도 같이 적어주세요. 예: 현미밥 반 공기, 닭가슴살 100g',
      final value when value.contains('먹') =>
        '좋아요. 오늘 드신 음식을 하나씩 알려주세요. 음식명, 대략적인 양, 조리 방식이 있으면 더 정확하게 계산할 수 있어요.',
      _ =>
        '${profile.aiCoachName}가 같이 볼게요. 오늘 컨디션, 먹은 음식, 운동 여부 중 하나만 편하게 말해주시면 다음 행동을 짧게 정리해드릴게요.',
    };

    return ChatMessage(
      id: _newId(),
      role: ChatMessageRole.assistant,
      content: response,
      timestamp: DateTime.now(),
    );
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}

class AIChatProfile {
  const AIChatProfile({
    required this.nickname,
    required this.goal,
    required this.targetCalories,
    required this.aiCoach,
  });

  factory AIChatProfile.guest() {
    return const AIChatProfile(
      nickname: '회원',
      goal: '건강 관리',
      targetCalories: 1800,
      aiCoach: '다온',
    );
  }

  factory AIChatProfile.fromJson(Map<String, dynamic> json) {
    return AIChatProfile(
      nickname: (json['nickname'] as String?)?.trim().isNotEmpty == true
          ? json['nickname'] as String
          : '회원',
      goal: json['goal'] as String? ?? '건강 관리',
      targetCalories: (json['targetCalories'] as num?)?.toInt() ?? 1800,
      aiCoach: json['aiCoach'] as String? ?? '다온',
    );
  }

  final String nickname;
  final String goal;
  final int targetCalories;
  final String aiCoach;

  String get aiCoachName => aiCoach.split(' ').first;
}
