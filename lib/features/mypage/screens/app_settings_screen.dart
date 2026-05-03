import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/mypage_provider.dart';

class AppSettingsScreen extends ConsumerWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(myPageDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('앱 설정')),
      body: data.when(
        data: (profile) => LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 720;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isTablet ? 720 : 560),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? 28 : 18,
                    12,
                    isTablet ? 28 : 18,
                    120,
                  ),
                  children: [
                    _SettingsSection(
                      children: [
                        _MenuTile(
                          icon: Icons.mail_outline_rounded,
                          title: '쪽지함',
                          onTap: () => context.push('/community/chats'),
                        ),
                        _MenuTile(
                          icon: Icons.notifications_active_outlined,
                          title: '알림 설정',
                          onTap: () => context.push('/notification-settings'),
                        ),
                        _MenuTile(
                          icon: Icons.workspace_premium_outlined,
                          title: '구독 및 크레딧',
                          onTap: () => context.push('/subscription'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SettingsSection(
                      children: [
                        _MenuTile(
                          icon: Icons.campaign_outlined,
                          title: '공지사항',
                          onTap: () => context.push('/notices'),
                        ),
                        _MenuTile(
                          icon: Icons.dark_mode_outlined,
                          title: '테마 설정',
                          onTap: () => context.push('/settings'),
                        ),
                        _MenuTile(
                          icon: Icons.description_outlined,
                          title: '오픈소스 라이선스',
                          onTap: () => showLicensePage(
                            context: context,
                            applicationName: '미담',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SettingsSection(
                      children: [
                        _MenuTile(
                          icon: Icons.block_outlined,
                          title: '차단 유저 관리',
                          onTap: () => context.push('/blocked-users'),
                        ),
                        _MenuTile(
                          icon: Icons.person_add_alt_outlined,
                          title: '팔로우 요청 관리',
                          onTap: () => context.push('/follow-requests'),
                        ),
                        _MenuTile(
                          icon: Icons.lock_outline_rounded,
                          title: '계정 공개 범위',
                          onTap: () => _showPrivacySheet(context, ref, profile),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SettingsSection(
                      children: [
                        _MenuTile(
                          icon: Icons.widgets_outlined,
                          title: '위젯 추가하기',
                          onTap: () => _showWidgetGuide(context),
                        ),
                        _MenuTile(
                          icon: Icons.ios_share_rounded,
                          title: '친구 초대하기',
                          onTap: () => SharePlus.instance.share(
                            ShareParams(text: '미담에서 오늘의 건강 기록을 같이 시작해요.'),
                          ),
                        ),
                        _MenuTile(
                          icon: Icons.history_rounded,
                          title: '업데이트 내역',
                          onTap: () => context.push('/release-notes'),
                        ),
                        _MenuTile(
                          icon: Icons.verified_user_outlined,
                          title: '약관 및 보안',
                          onTap: () => context.push('/terms-security'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SettingsSection(
                      children: [
                        _MenuTile(
                          icon: Icons.logout_rounded,
                          title: '로그아웃',
                          danger: true,
                          onTap: () => _confirmSignOut(context, ref),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }

  void _showPrivacySheet(BuildContext context, WidgetRef ref, MyPageData data) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('공개'),
                onTap: () => _setPrivacy(context, ref, data.uid, false),
              ),
              ListTile(
                title: const Text('비공개'),
                onTap: () => _setPrivacy(context, ref, data.uid, true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setPrivacy(
    BuildContext context,
    WidgetRef ref,
    String uid,
    bool isPrivate,
  ) async {
    await ref.read(firebaseFirestoreProvider).doc('users/$uid').set({
      'isPrivate': isPrivate,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    ref.invalidate(myPageDataProvider);
    if (context.mounted) Navigator.pop(context);
  }

  void _showWidgetGuide(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Text('홈 화면 위젯은 다음 단계에서 딥링크와 함께 연결할 예정이에요.'),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('현재 계정에서 로그아웃할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).signOut();
      if (context.mounted) context.go('/login');
    }
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(children: children),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? Theme.of(context).colorScheme.error : null;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }
}
