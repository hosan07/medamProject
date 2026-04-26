import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/community_provider.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(chatRoomsProvider);
    final uid = ref.watch(currentUserProvider)?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('쪽지함')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 720;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isTablet ? 720 : 560),
              child: rooms.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(child: Text('아직 대화가 없어요.'));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemBuilder: (context, index) {
                      final room = items[index];
                      final partner = room.participants.firstWhere(
                        (id) => id != uid,
                        orElse: () => '알 수 없음',
                      );
                      final unread = uid == null
                          ? 0
                          : room.unreadCount[uid] ?? 0;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        tileColor: Theme.of(context).colorScheme.surface,
                        leading: CircleAvatar(child: Text(_initial(partner))),
                        title: Text(
                          partner,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: Text(
                          room.lastMessage.isEmpty
                              ? '대화를 시작해보세요'
                              : room.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('HH:mm').format(room.lastAt),
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (unread > 0) ...[
                              const SizedBox(height: 6),
                              Badge(label: Text('$unread')),
                            ],
                          ],
                        ),
                        onTap: () =>
                            context.push('/community/chats/${room.id}'),
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemCount: items.length,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(error.toString())),
              ),
            ),
          );
        },
      ),
    );
  }
}

String _initial(String value) {
  return value.trim().isEmpty
      ? '?'
      : String.fromCharCode(value.runes.first).toUpperCase();
}
