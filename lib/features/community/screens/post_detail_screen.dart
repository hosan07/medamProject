import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/models/comment_model.dart';
import '../../../data/models/post_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/community_chat_repository.dart';
import '../../../data/repositories/community_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/community_provider.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({required this.postId, super.key});

  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  String? _replyParentId;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = ref.watch(postDetailProvider(widget.postId));
    final comments = ref.watch(commentsProvider(widget.postId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글'),
        actions: [
          post.when(
            data: (data) => data == null
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: '더보기',
                    onPressed: () => _showPostMenu(data),
                    icon: const Icon(Icons.more_vert_rounded),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: post.when(
        data: (data) {
          if (data == null) {
            return const Center(child: Text('게시글을 찾을 수 없어요.'));
          }
          return Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isTablet = constraints.maxWidth >= 720;
                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 820 : 560,
                        ),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                          children: [
                            _PostHeader(post: data),
                            const SizedBox(height: 18),
                            Text(
                              data.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              data.content,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.55,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (data.imageUrls.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              _ImageCarousel(imageUrls: data.imageUrls),
                            ],
                            const SizedBox(height: 18),
                            _PostActions(post: data),
                            const Divider(height: 34),
                            Text(
                              '댓글 ${data.commentCount}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 8),
                            comments.when(
                              data: (items) => _CommentsList(
                                comments: items,
                                onReply: (comment) {
                                  setState(() => _replyParentId = comment.id);
                                  _commentController.text =
                                      '${comment.nickname}님에게 답글 ';
                                },
                              ),
                              loading: () => const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (error, _) => Text(error.toString()),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              _CommentInputBar(
                controller: _commentController,
                isReplying: _replyParentId != null,
                onCancelReply: () => setState(() => _replyParentId = null),
                onSend: () => _sendComment(data),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }

  Future<void> _sendComment(PostModel post) async {
    final user = ref.read(currentUserProvider);
    final content = _commentController.text.trim();
    if (user == null || content.isEmpty) {
      return;
    }

    final profile = await ref
        .read(firebaseFirestoreProvider)
        .doc('users/${user.uid}')
        .get();
    final nickname = profile.data()?['nickname'] as String? ??
        user.displayName ??
        user.email ??
        '미담러';
    final profileImage =
        profile.data()?['profileImage'] as String? ?? user.photoURL;

    await ref.read(communityRepositoryProvider).addComment(
          postId: post.id,
          uid: user.uid,
          nickname: nickname,
          content: content,
          parentId: _replyParentId,
          senderProfileImage: profileImage,
        );
    _commentController.clear();
    setState(() => _replyParentId = null);
  }

  void _showPostMenu(PostModel post) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report_gmailerrorred_rounded),
              title: const Text('신고하기'),
              onTap: () {
                Navigator.pop(context);
                _reportPost(post);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_rounded),
              title: const Text('차단하기'),
              onTap: () {
                Navigator.pop(context);
                _blockUser(post);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_rounded),
              title: const Text('프로필 보기'),
              onTap: () {
                Navigator.pop(context);
                context.push('/profile/${post.uid}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_rounded),
              title: const Text('친구 추가'),
              onTap: () {
                Navigator.pop(context);
                _followUser(post);
              },
            ),
            ListTile(
              leading: const Icon(Icons.mail_outline_rounded),
              title: const Text('쪽지 보내기'),
              onTap: () {
                Navigator.pop(context);
                _openChat(post);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reportPost(PostModel post) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) {
      return;
    }
    await ref.read(communityRepositoryProvider).reportPost(
          reporterUid: uid,
          targetUid: post.uid,
          postId: post.id,
          reason: '부적절한 게시글',
        );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('신고가 접수되었어요.')));
    }
  }

  Future<void> _blockUser(PostModel post) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) {
      return;
    }
    await ref.read(communityRepositoryProvider).reportPost(
          reporterUid: uid,
          targetUid: post.uid,
          postId: post.id,
          reason: '사용자 차단',
        );
    await ref
        .read(communityRepositoryProvider)
        .blockUser(uid: uid, targetUid: post.uid);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('차단하고 신고 기록을 남겼어요.')));
    }
  }

  Future<void> _followUser(PostModel post) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null || uid == post.uid) {
      return;
    }
    await ref
        .read(communityRepositoryProvider)
        .followUser(uid: uid, targetUid: post.uid);
  }

  Future<void> _openChat(PostModel post) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null || uid == post.uid) {
      return;
    }
    final chatId =
        await ref.read(communityChatRepositoryProvider).openRoom(uid, post.uid);
    if (mounted) {
      context.push('/community/chats/$chatId');
    }
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: post.profileImage == null
              ? null
              : NetworkImage(post.profileImage!),
          child:
              post.profileImage == null ? Text(_initial(post.nickname)) : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.nickname,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                '${post.category} · ${DateFormat('M월 d일 HH:mm').format(post.createdAt)}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImageCarousel extends StatelessWidget {
  const _ImageCarousel({required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: PageView.builder(
        itemCount: imageUrls.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              imageUrls[index],
              fit: BoxFit.cover,
              errorBuilder: (context, _, _) =>
                  const Center(child: Icon(Icons.image_not_supported_rounded)),
            ),
          ),
        ),
      ),
    );
  }
}

class _PostActions extends ConsumerWidget {
  const _PostActions({required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider)?.uid;
    final liked = ref.watch(postLikeStateProvider(post.id)).value ?? false;
    final scrapped = ref.watch(postScrapStateProvider(post.id)).value ?? false;

    return Row(
      children: [
        TextButton.icon(
          onPressed: uid == null
              ? null
              : () => ref
                  .read(communityRepositoryProvider)
                  .toggleLike(postId: post.id, uid: uid),
          icon: Icon(
            liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          ),
          label: Text('좋아요 ${post.likeCount}'),
        ),
        TextButton.icon(
          onPressed: uid == null
              ? null
              : () => ref
                  .read(communityRepositoryProvider)
                  .toggleScrap(postId: post.id, uid: uid),
          icon: Icon(
            scrapped ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          ),
          label: Text('스크랩 ${post.scrapCount}'),
        ),
        TextButton.icon(
          onPressed: null,
          icon: const Icon(Icons.mode_comment_outlined),
          label: Text('댓글 ${post.commentCount}'),
        ),
      ],
    );
  }
}

class _CommentsList extends StatelessWidget {
  const _CommentsList({required this.comments, required this.onReply});

  final List<CommentModel> comments;
  final ValueChanged<CommentModel> onReply;

  @override
  Widget build(BuildContext context) {
    final parents = comments.where((comment) => comment.parentId == null);
    final replies = comments.where((comment) => comment.parentId != null);

    if (comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('첫 댓글을 남겨보세요.')),
      );
    }

    return Column(
      children: [
        for (final comment in parents) ...[
          _CommentTile(comment: comment, onReply: () => onReply(comment)),
          for (final reply in replies.where(
            (item) => item.parentId == comment.id,
          ))
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: _CommentTile(
                comment: reply,
                onReply: () => onReply(comment),
              ),
            ),
        ],
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, required this.onReply});

  final CommentModel comment;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Text(_initial(comment.nickname))),
      title: Text(
        comment.nickname,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(comment.content),
      trailing: TextButton(onPressed: onReply, child: const Text('답글')),
    );
  }
}

String _initial(String value) {
  return value.trim().isEmpty ? '미' : String.fromCharCode(value.runes.first);
}

class _CommentInputBar extends StatelessWidget {
  const _CommentInputBar({
    required this.controller,
    required this.isReplying,
    required this.onCancelReply,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isReplying;
  final VoidCallback onCancelReply;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isReplying)
            Row(
              children: [
                const Expanded(child: Text('답글 작성 중')),
                TextButton(onPressed: onCancelReply, child: const Text('취소')),
              ],
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(hintText: '댓글을 입력하세요'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: onSend,
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
