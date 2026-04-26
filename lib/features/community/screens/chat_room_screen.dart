import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/community_chat_model.dart';
import '../../../data/repositories/community_chat_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/community_provider.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({required this.chatId, super.key});

  final String chatId;

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _controller = TextEditingController();
  final _picker = ImagePicker();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markAsRead());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider(widget.chatId));

    return Scaffold(
      appBar: AppBar(title: const Text('채팅')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 720;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isTablet ? 760 : 560),
              child: Column(
                children: [
                  Expanded(
                    child: messages.when(
                      data: (items) => ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                        itemCount: items.length,
                        itemBuilder: (context, index) =>
                            _MessageBubble(message: items[index]),
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) =>
                          Center(child: Text(error.toString())),
                    ),
                  ),
                  _ChatInputBar(
                    controller: _controller,
                    isSending: _isSending,
                    onPickImage: _pickAndSendImage,
                    onSend: _sendText,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _markAsRead() async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) {
      return;
    }
    await ref
        .read(communityChatRepositoryProvider)
        .markAsRead(chatId: widget.chatId, uid: uid);
  }

  Future<void> _sendText() async {
    await _send(content: _controller.text);
    _controller.clear();
  }

  Future<void> _pickAndSendImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return;
    }
    await _send(content: '', image: image);
  }

  Future<void> _send({required String content, XFile? image}) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null || (content.trim().isEmpty && image == null)) {
      return;
    }

    setState(() => _isSending = true);
    try {
      await ref
          .read(communityChatRepositoryProvider)
          .sendMessage(
            chatId: widget.chatId,
            uid: uid,
            content: content,
            image: image,
          );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
}

class _MessageBubble extends ConsumerWidget {
  const _MessageBubble({required this.message});

  final CommunityChatMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMine = ref.watch(currentUserProvider)?.uid == message.uid;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: isMine
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  message.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, _) =>
                      const Icon(Icons.image_not_supported_rounded),
                ),
              ),
            if (message.content.isNotEmpty) ...[
              if (message.imageUrl != null) const SizedBox(height: 8),
              Text(
                message.content,
                style: TextStyle(
                  color: isMine
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.isSending,
    required this.onPickImage,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onPickImage;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: isSending ? null : onPickImage,
            icon: const Icon(Icons.image_rounded),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(hintText: '메시지를 입력하세요'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: isSending ? null : onSend,
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
    );
  }
}
