import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/community_provider.dart';
import '../widgets/post_card.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCommunityCategoryProvider);
    final posts = ref.watch(communityPostsProvider);
    final uid = ref.watch(currentUserProvider)?.uid;
    final unreadCount =
        ref.watch(chatRoomsProvider).value?.fold<int>(0, (total, room) {
          return total + (uid == null ? 0 : room.unreadCount[uid] ?? 0);
        }) ??
        0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('커뮤니티'),
        actions: [
          IconButton(
            tooltip: '쪽지함',
            onPressed: () => context.push('/community/chats'),
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.mail_outline_rounded),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/community/write'),
        icon: const Icon(Icons.edit_rounded),
        label: const Text('글쓰기'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 720;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isTablet ? 980 : 560),
              child: Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final category = communityCategories[index];
                        return ChoiceChip(
                          label: Text(category),
                          selected: selected == category,
                          onSelected: (_) => ref
                              .read(selectedCommunityCategoryProvider.notifier)
                              .select(category),
                        );
                      },
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemCount: communityCategories.length,
                    ),
                  ),
                  Expanded(
                    child: posts.when(
                      data: (items) {
                        if (items.isEmpty) {
                          return const _CommunityEmpty();
                        }
                        return RefreshIndicator(
                          onRefresh: () async =>
                              ref.invalidate(communityPostsProvider),
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isTablet ? 2 : 1,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 14,
                                  mainAxisExtent: isTablet ? 390 : 370,
                                ),
                            itemCount: items.length,
                            itemBuilder: (context, index) =>
                                PostCard(post: items[index]),
                          ),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => _CommunityError(
                        message: error.toString(),
                        onRetry: () => ref.invalidate(communityPostsProvider),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CommunityEmpty extends StatelessWidget {
  const _CommunityEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('아직 게시글이 없어요', textAlign: TextAlign.center),
      ),
    );
  }
}

class _CommunityError extends StatelessWidget {
  const _CommunityError({required this.message, required this.onRetry});

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
            Text(
              '커뮤니티를 불러오지 못했어요.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
