import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/community_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/mypage_provider.dart';
import '../widgets/profile_visuals.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({required this.uid, super.key});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(otherProfileProvider(uid));
    final myUid = ref.watch(currentUserProvider)?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('프로필')),
      body: profile.when(
        data: (data) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
              children: [
                const SizedBox(height: 12),
                Center(child: PresetAvatar(icon: data.profileIcon, size: 92)),
                const SizedBox(height: 14),
                Text(
                  data.nickname,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.bio.isEmpty ? '소개가 아직 없어요.' : data.bio,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                if (myUid != null && myUid != uid)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: () => ref
                            .read(communityRepositoryProvider)
                            .followUser(uid: myUid, targetUid: uid),
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('팔로우'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => ref
                            .read(communityRepositoryProvider)
                            .blockUser(uid: myUid, targetUid: uid),
                        icon: const Icon(Icons.block_rounded),
                        label: const Text('차단'),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                Text(
                  '공개 피드',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                if (data.isPrivate)
                  const Center(child: Text('비공개 계정이에요.'))
                else if (data.posts.isEmpty)
                  const Center(child: Text('아직 공개 피드가 없어요.'))
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: data.posts.length,
                    itemBuilder: (context, index) {
                      final post = data.posts[index];
                      return InkWell(
                        onTap: () =>
                            context.push('/community/posts/${post.id}'),
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
                  ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}
