import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/models/post_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/mypage_provider.dart';
import '../widgets/profile_visuals.dart';

class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(myPageDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('마이페이지')),
      body: data.when(
        data: (profile) => LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 720;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isTablet ? 980 : 560),
                child: DefaultTabController(
                  length: 2,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _ProfileHeader(data: profile)),
                      const SliverToBoxAdapter(
                        child: TabBar(
                          tabs: [
                            Tab(text: '피드'),
                            Tab(text: '앨범'),
                          ],
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: isTablet ? 360 : 300,
                          child: TabBarView(
                            children: [
                              _FeedGrid(posts: profile.posts),
                              _AlbumGrid(items: profile.albumItems),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(child: _MenuList(data: profile)),
                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  ),
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
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({required this.data});

  final MyPageData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showBackgroundPicker(context, ref),
            child: Container(
              height: 132,
              decoration: BoxDecoration(
                gradient: profileBackgroundGradient(data.backgroundIcon),
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -36),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _showAvatarPicker(context, ref),
                  child: PresetAvatar(icon: data.profileIcon, size: 86),
                ),
                const SizedBox(height: 8),
                Text(
                  data.nickname,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (data.bio.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    data.bio,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Stat(label: '피드', value: data.feedCount),
                    _Stat(label: '팔로워', value: data.followerCount),
                    _Stat(label: '팔로잉', value: data.followingCount),
                  ],
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => _showEditProfileSheet(context, ref, data),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('프로필 수정'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAvatarPicker(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _PresetPicker(
        title: '프로필 아이콘',
        labels: profileIconLabels,
        onSelected: (value) async {
          await ref.read(firebaseFirestoreProvider).doc('users/$uid').set({
            'profileIcon': value,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          ref.invalidate(myPageDataProvider);
        },
      ),
    );
  }

  Future<void> _showBackgroundPicker(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _PresetPicker(
        title: '배경 이미지',
        labels: backgroundLabels,
        onSelected: (value) async {
          await ref.read(firebaseFirestoreProvider).doc('users/$uid').set({
            'backgroundIcon': value,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          ref.invalidate(myPageDataProvider);
        },
      ),
    );
  }

  Future<void> _showEditProfileSheet(
    BuildContext context,
    WidgetRef ref,
    MyPageData data,
  ) async {
    final nicknameController = TextEditingController(text: data.nickname);
    final bioController = TextEditingController(text: data.bio);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nicknameController,
              decoration: const InputDecoration(labelText: '닉네임'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bioController,
              maxLength: 60,
              decoration: const InputDecoration(labelText: '소개'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                await ref
                    .read(firebaseFirestoreProvider)
                    .doc('users/${data.uid}')
                    .set({
                      'nickname': nicknameController.text.trim(),
                      'bio': bioController.text.trim(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));
                ref.invalidate(myPageDataProvider);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
    nicknameController.dispose();
    bioController.dispose();
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetPicker extends StatelessWidget {
  const _PresetPicker({
    required this.title,
    required this.labels,
    required this.onSelected,
  });

  final String title;
  final Map<String, String> labels;
  final Future<void> Function(String value) onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final entry in labels.entries)
                  ActionChip(
                    label: Text(entry.value),
                    onPressed: () async {
                      await onSelected(entry.key);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedGrid extends StatelessWidget {
  const _FeedGrid({required this.posts});

  final List<PostModel> posts;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const Center(child: Text('아직 작성한 피드가 없어요.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return InkWell(
          onTap: () => context.push('/community/posts/${post.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              post.title,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}

class _AlbumGrid extends StatelessWidget {
  const _AlbumGrid({required this.items});

  final List<AlbumItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('아직 앨범 사진이 없어요.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, _, _) => ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: const Icon(Icons.image_rounded),
                ),
              ),
              Positioned(left: 6, top: 6, child: Badge(label: Text(item.type))),
            ],
          ),
        );
      },
    );
  }
}

class _MenuList extends ConsumerWidget {
  const _MenuList({required this.data});

  final MyPageData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      child: Column(
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
            onTap: () =>
                showLicensePage(context: context, applicationName: '미담'),
          ),
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
            onTap: () => _showPrivacySheet(context, ref, data),
          ),
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
          _MenuTile(
            icon: Icons.logout_rounded,
            title: '로그아웃',
            danger: true,
            onTap: () => _confirmSignOut(context, ref),
          ),
        ],
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
