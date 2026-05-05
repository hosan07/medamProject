import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../data/models/chat_message_model.dart';
import '../providers/ai_chat_provider.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(aiChatProfileProvider);
    final messages = ref.watch(aiChatProvider);

    return Scaffold(
      appBar: AppBar(
        title: profile.when(
          data: (data) => Row(
            children: [
              _CoachAvatar(name: data.aiCoachName, size: 38),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.aiCoachName),
                  Text(
                    '미담 AI 코치',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          loading: () => const Text('AI 코치'),
          error: (_, _) => const Text('AI 코치'),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 720;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isTablet ? 820 : 560),
                child: Column(
                  children: [
                    profile.when(
                      data: (data) => _PersonalSettingsBar(profile: data),
                      loading: () => const _SettingsSkeleton(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                    Expanded(
                      child: messages.when(
                        data: (items) => _MessageList(
                          messages: items,
                          isTablet: isTablet,
                          onQuickReply: _sendQuickReply,
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, _) => _ChatError(
                          message: error.toString(),
                          onRetry: () => ref.invalidate(aiChatProvider),
                        ),
                      ),
                    ),
                    _InputBar(
                      controller: _controller,
                      focusNode: _focusNode,
                      isSending: _isSending,
                      onAttach: () => context.push('/camera/food'),
                      onSend: () => _sendMessage(_controller.text),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _sendQuickReply(String text) async {
    _controller.text = text;
    await _sendMessage(text);
  }

  Future<void> _sendMessage(String text) async {
    if (_isSending || text.trim().isEmpty) {
      return;
    }

    setState(() => _isSending = true);
    _controller.clear();
    _focusNode.unfocus();

    try {
      await ref.read(aiChatProvider.notifier).sendMessage(text);
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
}

class _PersonalSettingsBar extends StatelessWidget {
  const _PersonalSettingsBar({required this.profile});

  final AIChatProfile profile;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _InfoChip(
            icon: Icons.flag_rounded,
            label: profile.goal,
            onTap: () => _showPersonalSettingsSheet(context, profile),
          ),
          const SizedBox(width: 8),
          _InfoChip(
            icon: Icons.local_fire_department_rounded,
            label: '${profile.targetCalories}kcal',
            onTap: () => _showPersonalSettingsSheet(context, profile),
          ),
          const SizedBox(width: 8),
          _InfoChip(
            icon: Icons.tune_rounded,
            label: '개인 맞춤 설정',
            onTap: () => _showPersonalSettingsSheet(context, profile),
          ),
        ],
      ),
    );
  }

  void _showPersonalSettingsSheet(BuildContext context, AIChatProfile profile) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '개인 맞춤 설정',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                _SettingSummaryRow(label: '목표', value: profile.goal),
                _SettingSummaryRow(
                  label: '목표 칼로리',
                  value: '${profile.targetCalories}kcal',
                ),
                _SettingSummaryRow(label: 'AI 코치', value: profile.aiCoachName),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('확인'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SettingSummaryRow extends StatelessWidget {
  const _SettingSummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }
}

class _SettingsSkeleton extends StatelessWidget {
  const _SettingsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 56);
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.isTablet,
    required this.onQuickReply,
  });

  final List<ChatMessage> messages;
  final bool isTablet;
  final ValueChanged<String> onQuickReply;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: true,
      padding: EdgeInsets.fromLTRB(20, 8, 20, isTablet ? 22 : 14),
      itemCount: messages.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _QuickReplies(onSelected: onQuickReply);
        }

        final message = messages[index - 1];
        return _MessageBubble(message: message);
      },
    );
  }
}

class _QuickReplies extends StatelessWidget {
  const _QuickReplies({required this.onSelected});

  final ValueChanged<String> onSelected;

  static const suggestions = ['오늘 뭐 먹었어', '칼로리 알려줘', '오늘 운동 추천', '내 목표 확인'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final suggestion in suggestions)
            ActionChip(
              label: Text(suggestion),
              onPressed: () => onSelected(suggestion),
              side: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.7),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatMessageRole.user;
    final bubbleColor = isUser
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.surface;
    final textColor =
        isUser ? Colors.white : Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const _CoachAvatar(name: 'AI', size: 32),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(22),
                    topRight: const Radius.circular(22),
                    bottomLeft: Radius.circular(isUser ? 22 : 6),
                    bottomRight: Radius.circular(isUser ? 6 : 22),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.onAttach,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final VoidCallback onAttach;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 98),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton.filledTonal(
              tooltip: '사진 첨부',
              onPressed: isSending ? null : onAttach,
              icon: const Icon(Icons.add_photo_alternate_rounded),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: '오늘 뭘 먹었는지 알려줘요 :)',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: '전송',
              onPressed: isSending ? null : onSend,
              style: IconButton.styleFrom(
                backgroundColor: medamPrimaryColor,
                foregroundColor: Colors.white,
                fixedSize: const Size(48, 48),
              ),
              icon: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachAvatar extends StatelessWidget {
  const _CoachAvatar({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Text(
        name.isEmpty ? 'AI' : String.fromCharCode(name.runes.first),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ChatError extends StatelessWidget {
  const _ChatError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              '대화를 불러오지 못했어요.',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
