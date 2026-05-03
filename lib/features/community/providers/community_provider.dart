import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/comment_model.dart';
import '../../../data/models/community_chat_model.dart';
import '../../../data/models/post_model.dart';
import '../../../data/repositories/community_chat_repository.dart';
import '../../../data/repositories/community_repository.dart';
import '../../auth/providers/auth_provider.dart';

const communityCategories = ['전체', '음식평가', '눈바디평가', '유머', '운동'];

final selectedCommunityCategoryProvider =
    NotifierProvider<SelectedCommunityCategoryNotifier, String>(
      SelectedCommunityCategoryNotifier.new,
    );

class SelectedCommunityCategoryNotifier extends Notifier<String> {
  @override
  String build() => '전체';

  void select(String category) {
    state = category;
  }
}

final communityPostsProvider = StreamProvider<List<PostModel>>((ref) {
  final category = ref.watch(selectedCommunityCategoryProvider);
  return ref.watch(communityRepositoryProvider).watchPosts(category);
});

final postDetailProvider = StreamProvider.family<PostModel?, String>((
  ref,
  postId,
) {
  return ref.watch(communityRepositoryProvider).watchPost(postId);
});

final commentsProvider = StreamProvider.family<List<CommentModel>, String>((
  ref,
  postId,
) {
  return ref.watch(communityRepositoryProvider).watchComments(postId);
});

final postLikeStateProvider = StreamProvider.family<bool, String>((
  ref,
  postId,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream<bool>.value(false);
  }
  return ref
      .watch(communityRepositoryProvider)
      .watchLikeState(postId: postId, uid: user.uid);
});

final postScrapStateProvider = StreamProvider.family<bool, String>((
  ref,
  postId,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream<bool>.value(false);
  }
  return ref
      .watch(communityRepositoryProvider)
      .watchScrapState(postId: postId, uid: user.uid);
});

final chatRoomsProvider = StreamProvider<List<CommunityChatRoom>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return const Stream.empty();
  }
  return ref.watch(communityChatRepositoryProvider).watchChatRooms(user.uid);
});

final chatMessagesProvider =
    StreamProvider.family<List<CommunityChatMessage>, String>((ref, chatId) {
      return ref.watch(communityChatRepositoryProvider).watchMessages(chatId);
    });
