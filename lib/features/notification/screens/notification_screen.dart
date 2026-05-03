import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/notification_provider.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  bool _didMarkRead = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didMarkRead) {
      return;
    }
    _didMarkRead = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _markAllAsRead());
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedNotificationCategoryProvider);
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('알림')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final category = notificationCategories[index];
                    return ChoiceChip(
                      label: Text(category),
                      selected: selected == category,
                      onSelected: (_) => ref
                          .read(selectedNotificationCategoryProvider.notifier)
                          .select(category),
                    );
                  },
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemCount: notificationCategories.length,
                ),
              ),
              Expanded(
                child: notifications.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const Center(child: Text('아직 알림이 없어요.'));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Dismissible(
                          key: ValueKey(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.delete_rounded,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (_) => _delete(item),
                          child: _NotificationTile(
                            notification: item,
                            onTap: () => _openNotification(item),
                          ),
                        );
                      },
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemCount: items.length,
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text(error.toString())),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markAllAsRead() async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) {
      return;
    }
    await ref.read(notificationRepositoryProvider).markAllAsRead(uid);
  }

  Future<void> _delete(NotificationModel notification) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) {
      return;
    }
    await ref.read(notificationRepositoryProvider).deleteNotification(
          uid: uid,
          notificationId: notification.id,
        );
  }

  void _openNotification(NotificationModel notification) {
    switch (notification.type) {
      case MedamNotificationType.comment:
      case MedamNotificationType.like:
        if (notification.targetId.isNotEmpty) {
          context.push('/community/posts/${notification.targetId}');
        }
      case MedamNotificationType.follow:
        if (notification.senderUid.isNotEmpty) {
          context.push('/profile/${notification.senderUid}');
        }
      case MedamNotificationType.notice:
        _showNotice(notification);
    }
  }

  void _showNotice(NotificationModel notification) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Text(notification.body),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final profileImage = notification.senderProfileImage;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      tileColor: notification.isRead
          ? Theme.of(context).colorScheme.surface
          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      leading: CircleAvatar(
        backgroundImage: profileImage == null || profileImage.isEmpty
            ? null
            : NetworkImage(profileImage),
        child: profileImage == null || profileImage.isEmpty
            ? Text(_initial(notification.senderNickname))
            : null,
      ),
      title: Text(
        notification.senderNickname,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        notification.body.isEmpty ? notification.title : notification.body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        _relativeTime(notification.createdAt),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _initial(String value) {
  return value.trim().isEmpty ? '미' : String.fromCharCode(value.runes.first);
}

String _relativeTime(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) {
    return '방금 전';
  }
  if (diff.inHours < 1) {
    return '${diff.inMinutes}분 전';
  }
  if (diff.inDays < 1) {
    return '${diff.inHours}시간 전';
  }
  return '${diff.inDays}일 전';
}
