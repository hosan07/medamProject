import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/medam_placeholder.dart';
import '../providers/mypage_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('알림 설정')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: settings.when(
            data: (data) => ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _SwitchTile(
                  title: '알림 받기',
                  value: data.enabled,
                  onChanged: (value) =>
                      _save(ref, data.copyWith(enabled: value)),
                ),
                _SwitchTile(
                  title: '진동',
                  value: data.vibration,
                  enabled: data.receiveAll,
                  onChanged: (value) =>
                      _save(ref, data.copyWith(vibration: value)),
                ),
                _SwitchTile(
                  title: '소리',
                  value: data.sound,
                  enabled: data.receiveAll,
                  onChanged: (value) => _save(ref, data.copyWith(sound: value)),
                ),
                const SizedBox(height: 12),
                _SwitchTile(
                  title: '댓글알림',
                  value: data.comment,
                  enabled: data.receiveAll,
                  onChanged: (value) =>
                      _save(ref, data.copyWith(comment: value)),
                ),
                _SwitchTile(
                  title: '좋아요알림',
                  value: data.like,
                  enabled: data.receiveAll,
                  onChanged: (value) => _save(ref, data.copyWith(like: value)),
                ),
                _SwitchTile(
                  title: '팔로우알림',
                  value: data.follow,
                  enabled: data.receiveAll,
                  onChanged: (value) =>
                      _save(ref, data.copyWith(follow: value)),
                ),
                _SwitchTile(
                  title: '채팅알림',
                  value: data.chat,
                  enabled: data.receiveAll,
                  onChanged: (value) => _save(ref, data.copyWith(chat: value)),
                ),
              ],
            ),
            loading: () => const MedamListPlaceholder(itemCount: 4),
            error: (error, _) => Center(child: Text(error.toString())),
          ),
        ),
      ),
    );
  }

  void _save(WidgetRef ref, NotificationSettings settings) {
    ref.read(notificationSettingsProvider.notifier).save(settings);
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        value: value,
        onChanged: enabled ? onChanged : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
