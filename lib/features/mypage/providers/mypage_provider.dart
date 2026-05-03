import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/post_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../auth/providers/auth_provider.dart';

final myPageDataProvider = FutureProvider<MyPageData>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return MyPageData.empty();
  }

  final firestore = ref.watch(firebaseFirestoreProvider);
  final profile = await _readUserProfile(firestore, user.uid);
  final posts = await _readUserPosts(firestore, user.uid);
  final followers = await _readCount(
    firestore.collection('users/${user.uid}/followers'),
    fallback: (profile.data()?['followerCount'] as num?)?.toInt() ?? 0,
  );
  final following = await _readCount(
    firestore.collection('users/${user.uid}/following'),
    fallback: (profile.data()?['followingCount'] as num?)?.toInt() ?? 0,
  );
  final albumItems = await _readAlbumItems(firestore, user.uid);

  return MyPageData.fromData(
    uid: user.uid,
    email: user.email,
    profile: profile,
    posts: posts,
    followerCount: followers,
    followingCount: following,
    albumItems: albumItems,
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

    final firestore = ref.watch(firebaseFirestoreProvider);
    final profile = await firestore.doc('users/${user.uid}').get();
    final settings = profile.data()?['settings'];
    if (settings is Map<String, dynamic>) {
      final notification = settings['notification'];
      if (notification is Map<String, dynamic>) {
        return NotificationSettings.fromJson(notification);
      }
    }

    // 기존 세션에서 저장된 하위 문서도 읽어 앱 업데이트 전 데이터를 유지합니다.
    final doc = await firestore
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
    final firestore = ref.read(firebaseFirestoreProvider);
    final batch = firestore.batch();
    final profileRef = firestore.doc('users/${user.uid}');
    final settingsRef = firestore.doc(
      'users/${user.uid}/settings/notification',
    );
    batch.set(settingsRef, settings.toJson(), SetOptions(merge: true));
    batch.set(profileRef, {
      'settings': {'notification': settings.toPlainJson()},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }
}

class MyPageData {
  const MyPageData({
    required this.uid,
    required this.nickname,
    required this.email,
    required this.profileImage,
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
      profileImage: null,
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

  factory MyPageData.fromData({
    required String uid,
    required String? email,
    required DocumentSnapshot<Map<String, dynamic>> profile,
    required List<PostModel> posts,
    required int followerCount,
    required int followingCount,
    required List<AlbumItem> albumItems,
  }) {
    final data = profile.data();

    return MyPageData(
      uid: uid,
      nickname: data?['nickname'] as String? ?? '미담러',
      email: email,
      profileImage:
          data?['profileImage'] as String? ?? data?['photoURL'] as String?,
      profileIcon: data?['profileIcon'] as String? ?? 'leaf',
      backgroundIcon: data?['backgroundIcon'] as String? ?? 'green',
      bio: data?['bio'] as String? ?? '',
      feedCount: posts.length,
      followerCount: followerCount,
      followingCount: followingCount,
      posts: posts,
      albumItems: albumItems,
    );
  }

  final String uid;
  final String nickname;
  final String? email;
  final String? profileImage;
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

  Map<String, Object?> toPlainJson() {
    return {
      'enabled': enabled,
      'vibration': vibration,
      'sound': sound,
      'comment': comment,
      'like': like,
      'follow': follow,
      'chat': chat,
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

Future<DocumentSnapshot<Map<String, dynamic>>> _readUserProfile(
  FirebaseFirestore firestore,
  String uid,
) {
  return firestore.doc('users/$uid').get();
}

Future<List<PostModel>> _readUserPosts(
  FirebaseFirestore firestore,
  String uid,
) async {
  try {
    final snapshot = await firestore
        .collection('posts')
        .where('uid', isEqualTo: uid)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .get();
    return snapshot.docs
        .map((doc) => PostModel.fromJson({'id': doc.id, ...doc.data()}))
        .toList();
  } on FirebaseException {
    // 복합 인덱스가 아직 없는 개발 환경에서도 마이페이지가 멈추지 않게 합니다.
    final snapshot = await firestore
        .collection('posts')
        .where('uid', isEqualTo: uid)
        .limit(30)
        .get();
    final posts = snapshot.docs
        .map((doc) => PostModel.fromJson({'id': doc.id, ...doc.data()}))
        .where((post) => !post.isDeleted)
        .toList();
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }
}

Future<int> _readCount(
  CollectionReference<Map<String, dynamic>> collection, {
  required int fallback,
}) async {
  try {
    final snapshot = await collection.count().get();
    return snapshot.count ?? fallback;
  } on FirebaseException {
    return fallback;
  }
}

Future<List<AlbumItem>> _readAlbumItems(
  FirebaseFirestore firestore,
  String uid,
) async {
  final bodyItems = await _readBodyPhotos(firestore, uid);
  final foodItems = await _readFoodPhotos(firestore, uid);
  final items = [
    ...bodyItems,
    ...foodItems,
  ].where((item) => item.imageUrl.trim().isNotEmpty).toList();
  items.sort((a, b) => b.date.compareTo(a.date));
  return items.take(80).toList();
}

Future<List<AlbumItem>> _readBodyPhotos(
  FirebaseFirestore firestore,
  String uid,
) async {
  final items = <AlbumItem>[];
  final queries = [
    firestore
        .collection('body_photos/$uid/photos')
        .orderBy('date', descending: true)
        .limit(60)
        .get(),
    firestore
        .collection('users/$uid/body_photos')
        .orderBy('date', descending: true)
        .limit(60)
        .get(),
  ];

  for (final query in queries) {
    try {
      final snapshot = await query;
      items.addAll(
        snapshot.docs.map(
          (doc) => AlbumItem.fromJson(type: '눈바디', data: doc.data()),
        ),
      );
    } on FirebaseException {
      // 경로가 아직 비어 있거나 권한/인덱스가 준비되지 않아도 나머지 앨범은 표시합니다.
    }
  }
  return items;
}

Future<List<AlbumItem>> _readFoodPhotos(
  FirebaseFirestore firestore,
  String uid,
) async {
  final items = <AlbumItem>[];
  QuerySnapshot<Map<String, dynamic>> days;
  try {
    days = await firestore
        .collection('food_logs/$uid/daily')
        .orderBy('updatedAt', descending: true)
        .limit(35)
        .get();
  } on FirebaseException {
    days = await firestore.collection('food_logs/$uid/daily').limit(35).get();
  }

  for (final day in days.docs) {
    try {
      final meals = await day.reference
          .collection('meals')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      items.addAll(
        meals.docs.map((doc) {
          final data = doc.data();
          return AlbumItem.fromJson(
            type: '식단',
            data: {
              ...data,
              'date':
                  data['date'] ?? data['createdAt'] ?? _dateFromDayId(day.id),
            },
          );
        }),
      );
    } on FirebaseException {
      // 한 날짜의 식단 읽기에 실패해도 다른 날짜 사진은 계속 보여줍니다.
    }
  }
  return items;
}

DateTime _dateFromDayId(String dayId) {
  try {
    return DateFormat('yyyy-MM-dd').parse(dayId);
  } on FormatException {
    return DateTime.now();
  }
}
