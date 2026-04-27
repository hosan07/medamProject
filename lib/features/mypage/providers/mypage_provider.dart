import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/post_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../auth/providers/auth_provider.dart';

final myPageDataProvider = FutureProvider<MyPageData>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return MyPageData.empty();
  }

  final firestore = ref.watch(firebaseFirestoreProvider);
  final profileFuture = firestore.doc('users/${user.uid}').get();
  final feedFuture = firestore
      .collection('posts')
      .where('uid', isEqualTo: user.uid)
      .where('isDeleted', isEqualTo: false)
      .orderBy('createdAt', descending: true)
      .limit(30)
      .get();
  final followersFuture = firestore
      .collection('users/${user.uid}/followers')
      .count()
      .get();
  final followingFuture = firestore
      .collection('users/${user.uid}/following')
      .count()
      .get();
  final bodyFuture = firestore
      .collection('users/${user.uid}/body_photos')
      .orderBy('date', descending: true)
      .limit(40)
      .get();
  final foodFuture = firestore
      .collection('users/${user.uid}/food_logs')
      .orderBy('createdAt', descending: true)
      .limit(40)
      .get();

  final results = await Future.wait([
    profileFuture,
    feedFuture,
    followersFuture,
    followingFuture,
    bodyFuture,
    foodFuture,
  ]);

  return MyPageData.fromSnapshots(
    uid: user.uid,
    email: user.email,
    profile: results[0] as DocumentSnapshot<Map<String, dynamic>>,
    posts: results[1] as QuerySnapshot<Map<String, dynamic>>,
    followers: results[2] as AggregateQuerySnapshot,
    following: results[3] as AggregateQuerySnapshot,
    bodyPhotos: results[4] as QuerySnapshot<Map<String, dynamic>>,
    foodPhotos: results[5] as QuerySnapshot<Map<String, dynamic>>,
  );
});

final otherProfileProvider = FutureProvider.family<PublicProfileData, String>((
  ref,
  uid,
) async {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final profileFuture = firestore.doc('users/$uid').get();
  final feedFuture = firestore
      .collection('posts')
      .where('uid', isEqualTo: uid)
      .where('isDeleted', isEqualTo: false)
      .orderBy('createdAt', descending: true)
      .limit(30)
      .get();

  final results = await Future.wait([profileFuture, feedFuture]);
  return PublicProfileData.fromSnapshots(
    uid: uid,
    profile: results[0] as DocumentSnapshot<Map<String, dynamic>>,
    posts: results[1] as QuerySnapshot<Map<String, dynamic>>,
  );
});

final notificationSettingsProvider =
    AsyncNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
      NotificationSettingsNotifier.new,
    );

class NotificationSettingsNotifier extends AsyncNotifier<NotificationSettings> {
  @override
  Future<NotificationSettings> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const NotificationSettings();
    }

    final doc = await ref
        .watch(firebaseFirestoreProvider)
        .doc('users/${user.uid}/settings/notification')
        .get();
    return NotificationSettings.fromJson(doc.data());
  }

  Future<void> save(NotificationSettings settings) async {
    state = AsyncData(settings);
    final user = ref.read(currentUserProvider);
    if (user == null) {
      return;
    }
    await ref
        .read(firebaseFirestoreProvider)
        .doc('users/${user.uid}/settings/notification')
        .set(settings.toJson(), SetOptions(merge: true));
  }
}

class MyPageData {
  const MyPageData({
    required this.uid,
    required this.nickname,
    required this.email,
    required this.profileIcon,
    required this.backgroundIcon,
    required this.bio,
    required this.feedCount,
    required this.followerCount,
    required this.followingCount,
    required this.posts,
    required this.albumItems,
  });

  factory MyPageData.empty() {
    return const MyPageData(
      uid: '',
      nickname: '미담러',
      email: null,
      profileIcon: 'leaf',
      backgroundIcon: 'green',
      bio: '',
      feedCount: 0,
      followerCount: 0,
      followingCount: 0,
      posts: [],
      albumItems: [],
    );
  }

  factory MyPageData.fromSnapshots({
    required String uid,
    required String? email,
    required DocumentSnapshot<Map<String, dynamic>> profile,
    required QuerySnapshot<Map<String, dynamic>> posts,
    required AggregateQuerySnapshot followers,
    required AggregateQuerySnapshot following,
    required QuerySnapshot<Map<String, dynamic>> bodyPhotos,
    required QuerySnapshot<Map<String, dynamic>> foodPhotos,
  }) {
    final data = profile.data();
    final feed = posts.docs
        .map((doc) => PostModel.fromJson({'id': doc.id, ...doc.data()}))
        .toList();
    final album = [
      ...bodyPhotos.docs.map(
        (doc) => AlbumItem.fromJson(type: '눈바디', data: doc.data()),
      ),
      ...foodPhotos.docs.map(
        (doc) => AlbumItem.fromJson(type: '식단', data: doc.data()),
      ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return MyPageData(
      uid: uid,
      nickname: data?['nickname'] as String? ?? '미담러',
      email: email,
      profileIcon: data?['profileIcon'] as String? ?? 'leaf',
      backgroundIcon: data?['backgroundIcon'] as String? ?? 'green',
      bio: data?['bio'] as String? ?? '',
      feedCount: feed.length,
      followerCount: followers.count ?? 0,
      followingCount: following.count ?? 0,
      posts: feed,
      albumItems: album,
    );
  }

  final String uid;
  final String nickname;
  final String? email;
  final String profileIcon;
  final String backgroundIcon;
  final String bio;
  final int feedCount;
  final int followerCount;
  final int followingCount;
  final List<PostModel> posts;
  final List<AlbumItem> albumItems;
}

class PublicProfileData {
  const PublicProfileData({
    required this.uid,
    required this.nickname,
    required this.bio,
    required this.profileIcon,
    required this.isPrivate,
    required this.posts,
  });

  factory PublicProfileData.fromSnapshots({
    required String uid,
    required DocumentSnapshot<Map<String, dynamic>> profile,
    required QuerySnapshot<Map<String, dynamic>> posts,
  }) {
    final data = profile.data();
    return PublicProfileData(
      uid: uid,
      nickname: data?['nickname'] as String? ?? '미담러',
      bio: data?['bio'] as String? ?? '',
      profileIcon: data?['profileIcon'] as String? ?? 'leaf',
      isPrivate: data?['isPrivate'] as bool? ?? false,
      posts: posts.docs
          .map((doc) => PostModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList(),
    );
  }

  final String uid;
  final String nickname;
  final String bio;
  final String profileIcon;
  final bool isPrivate;
  final List<PostModel> posts;
}

class AlbumItem {
  const AlbumItem({
    required this.type,
    required this.imageUrl,
    required this.date,
  });

  factory AlbumItem.fromJson({
    required String type,
    required Map<String, dynamic> data,
  }) {
    final dateValue = data['date'] ?? data['createdAt'];
    return AlbumItem(
      type: type,
      imageUrl: data['imageUrl'] as String? ?? '',
      date: dateValue is Timestamp ? dateValue.toDate() : DateTime.now(),
    );
  }

  final String type;
  final String imageUrl;
  final DateTime date;
}

class NotificationSettings {
  const NotificationSettings({
    this.enabled = true,
    this.vibration = true,
    this.sound = true,
    this.comment = true,
    this.like = true,
    this.follow = true,
    this.chat = true,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic>? json) {
    return NotificationSettings(
      enabled: json?['enabled'] as bool? ?? true,
      vibration: json?['vibration'] as bool? ?? true,
      sound: json?['sound'] as bool? ?? true,
      comment: json?['comment'] as bool? ?? true,
      like: json?['like'] as bool? ?? true,
      follow: json?['follow'] as bool? ?? true,
      chat: json?['chat'] as bool? ?? true,
    );
  }

  final bool enabled;
  final bool vibration;
  final bool sound;
  final bool comment;
  final bool like;
  final bool follow;
  final bool chat;

  Map<String, Object?> toJson() {
    return {
      'enabled': enabled,
      'vibration': vibration,
      'sound': sound,
      'comment': comment,
      'like': like,
      'follow': follow,
      'chat': chat,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  NotificationSettings copyWith({
    bool? enabled,
    bool? vibration,
    bool? sound,
    bool? comment,
    bool? like,
    bool? follow,
    bool? chat,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      vibration: vibration ?? this.vibration,
      sound: sound ?? this.sound,
      comment: comment ?? this.comment,
      like: like ?? this.like,
      follow: follow ?? this.follow,
      chat: chat ?? this.chat,
    );
  }
}
