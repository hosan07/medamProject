import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/medam_placeholder.dart';
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
      appBar: AppBar(
        title: const Text('마이페이지'),
        actions: [
          IconButton(
            tooltip: '앱 설정',
            onPressed: () => context.push('/app-settings'),
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
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
                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        loading: () => const MedamListPlaceholder(itemCount: 3),
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
                  child: PresetAvatar(
                    icon: data.profileIcon,
                    imageUrl: data.profileImage,
                    size: 86,
                  ),
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
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) => _PresetPicker(
        title: '프로필 아이콘',
        labels: profileIconLabels,
        onSelected: (value) async {
          await ref.read(firebaseFirestoreProvider).doc('users/$uid').set({
            'profileIcon': value,
            'profileImage': FieldValue.delete(),
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
      useRootNavigator: true,
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
      useRootNavigator: true,
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
      return const Center(child: Text('아직 게시글이 없어요'));
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
      return const Center(child: Text('아직 사진이 없어요'));
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
