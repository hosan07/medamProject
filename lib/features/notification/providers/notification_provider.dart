import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../auth/providers/auth_provider.dart';

const notificationCategories = ['전체', '댓글', '좋아요', '팔로우', '공지'];

final selectedNotificationCategoryProvider =
    NotifierProvider<SelectedNotificationCategoryNotifier, String>(
  SelectedNotificationCategoryNotifier.new,
);

class SelectedNotificationCategoryNotifier extends Notifier<String> {
  @override
  String build() => '전체';

  void select(String category) {
    state = category;
  }
}

final notificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(const <NotificationModel>[]);
  }
  final category = ref.watch(selectedNotificationCategoryProvider);
  return ref.watch(notificationRepositoryProvider).watchNotifications(
        uid: user.uid,
        type: _typeFromCategory(category),
      );
});

final hasUnreadNotificationsProvider = StreamProvider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(false);
  }
  return ref.watch(notificationRepositoryProvider).watchHasUnread(user.uid);
});

final notificationDeepLinkProvider = StreamProvider<String>((ref) {
  return NotificationRepository.deepLinkStream;
});

MedamNotificationType? _typeFromCategory(String category) {
  return switch (category) {
    '댓글' => MedamNotificationType.comment,
    '좋아요' => MedamNotificationType.like,
    '팔로우' => MedamNotificationType.follow,
    '공지' => MedamNotificationType.notice,
    _ => null,
  };
}
