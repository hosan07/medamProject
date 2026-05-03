import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_model.dart';
import 'auth_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
    messaging: FirebaseMessaging.instance,
  );
});

class NotificationRepository {
  NotificationRepository({
    required FirebaseFirestore firestore,
    required FirebaseMessaging messaging,
  })  : _firestore = firestore,
        _messaging = messaging;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final StreamController<String> _deepLinkController =
      StreamController<String>.broadcast();
  static bool _isInitialized = false;
  static String? _pendingInitialRoute;

  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  static Stream<String> get deepLinkStream async* {
    final pendingRoute = _pendingInitialRoute;
    if (pendingRoute != null) {
      _pendingInitialRoute = null;
      yield pendingRoute;
    }
    yield* _deepLinkController.stream;
  }

  static Future<void> initializeMessaging() async {
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _deepLinkController.add(payload);
        }
      },
    );

    const channel = AndroidNotificationChannel(
      'medam_default',
      '미담 알림',
      description: '미담 앱의 댓글, 좋아요, 팔로우, 공지 알림입니다.',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final route = _routeFromMessage(message);
      if (route != null) {
        _deepLinkController.add(route);
      }
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    final initialRoute =
        initialMessage == null ? null : _routeFromMessage(initialMessage);
    if (initialRoute != null) {
      _pendingInitialRoute = initialRoute;
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || token.isEmpty) {
        return;
      }
      await FirebaseFirestore.instance.doc('users/$uid').set({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    await saveRemoteMessageToFirestore(message);
  }

  static Future<void> saveRemoteMessageToFirestore(
    RemoteMessage message,
  ) async {
    final uid = message.data['recipientUid'] as String? ??
        message.data['uid'] as String? ??
        FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return;
    }

    final notificationId = message.data['notificationId'] as String?;
    final notificationCollection = FirebaseFirestore.instance.collection(
      'notifications/$uid/items',
    );
    final notificationRef = notificationId == null || notificationId.isEmpty
        ? notificationCollection.doc()
        : notificationCollection.doc(notificationId);
    final type = MedamNotificationType.fromJson(
      message.data['type'] as String?,
    );
    final title = message.notification?.title ??
        message.data['title'] as String? ??
        type.label;
    final body =
        message.notification?.body ?? message.data['body'] as String? ?? title;

    await notificationRef.set({
      'id': notificationRef.id,
      'type': type.name,
      'title': title,
      'body': body,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'targetId': message.data['targetId'] as String? ?? '',
      'senderUid': message.data['senderUid'] as String? ?? '',
      'senderNickname': message.data['senderNickname'] as String? ?? '미담',
      'senderProfileImage': message.data['senderProfileImage'] as String?,
    }, SetOptions(merge: true));
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await saveRemoteMessageToFirestore(message);

    final title =
        message.notification?.title ?? message.data['title'] as String? ?? '미담';
    final body = message.notification?.body ?? message.data['body'] as String?;
    final route = _routeFromMessage(message);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'medam_default',
        '미담 알림',
        channelDescription: '미담 앱의 댓글, 좋아요, 팔로우, 공지 알림입니다.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: details,
      payload: route,
    );
  }

  static String? _routeFromMessage(RemoteMessage message) {
    final data = message.data;
    final type = MedamNotificationType.fromJson(data['type'] as String?);
    final targetId = data['targetId'] as String? ?? '';
    final senderUid = data['senderUid'] as String? ?? '';

    return switch (type) {
      MedamNotificationType.comment ||
      MedamNotificationType.like when targetId.isNotEmpty =>
        '/community/posts/$targetId',
      MedamNotificationType.follow when senderUid.isNotEmpty =>
        '/profile/$senderUid',
      MedamNotificationType.notice => '/notification',
      _ => null,
    };
  }

  Stream<List<NotificationModel>> watchNotifications({
    required String uid,
    MedamNotificationType? type,
  }) {
    return _firestore
        .collection('notifications/$uid/items')
        .orderBy('createdAt', descending: true)
        .limit(80)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map(
            (doc) => NotificationModel.fromJson({'id': doc.id, ...doc.data()}),
          )
          .where((item) => type == null || item.type == type)
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Stream<bool> watchHasUnread(String uid) {
    return _firestore
        .collection('notifications/$uid/items')
        .where('isRead', isEqualTo: false)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  Future<void> markAllAsRead(String uid) async {
    final snapshot = await _firestore
        .collection('notifications/$uid/items')
        .where('isRead', isEqualTo: false)
        .limit(100)
        .get();
    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification({
    required String uid,
    required String notificationId,
  }) {
    return _firestore.doc('notifications/$uid/items/$notificationId').delete();
  }

  Future<void> requestPermissionAndSaveFcmToken(String uid) async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await saveFcmTokenIfAllowed(uid);
  }

  Future<void> saveFcmTokenIfAllowed(String uid) async {
    final settings = await readSettings(uid);
    if (!settings.receiveAll) {
      await deleteFcmToken(uid);
      return;
    }

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      return;
    }
    await _firestore.doc('users/$uid').set({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  Future<void> deleteFcmToken(String uid) async {
    await _messaging.deleteToken();
    await _firestore.doc('users/$uid').set({
      'fcmToken': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> createNotificationIfAllowed({
    required String recipientUid,
    required MedamNotificationType type,
    required String targetId,
    required String senderUid,
    required String senderNickname,
    String? title,
    String? body,
    String? senderProfileImage,
  }) async {
    if (recipientUid == senderUid) {
      return;
    }
    final settings = await readSettings(recipientUid);
    if (!settings.allows(type)) {
      return;
    }

    final notificationRef =
        _firestore.collection('notifications/$recipientUid/items').doc();
    await notificationRef.set({
      'id': notificationRef.id,
      'type': type.name,
      'title': title ?? _defaultTitle(type),
      'body': body ?? _defaultBody(type, senderNickname),
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'targetId': targetId,
      'senderUid': senderUid,
      'senderNickname': senderNickname,
      'senderProfileImage': senderProfileImage,
    });

    // TODO: Cloud Functions에서 수신자 fcmToken으로 실제 FCM 푸시 발송하기.
  }

  Future<NotificationSettingsData> readSettings(String uid) async {
    final doc = await _firestore.doc('users/$uid/settings/notification').get();
    if (doc.exists) {
      return NotificationSettingsData.fromJson(doc.data());
    }

    final profile = await _firestore.doc('users/$uid').get();
    final settings = profile.data()?['settings'];
    if (settings is Map<String, dynamic>) {
      final notification = settings['notification'];
      if (notification is Map<String, dynamic>) {
        return NotificationSettingsData.fromJson(notification);
      }
    }
    return const NotificationSettingsData();
  }

  String _defaultTitle(MedamNotificationType type) {
    return type.label;
  }

  String _defaultBody(MedamNotificationType type, String senderNickname) {
    return switch (type) {
      MedamNotificationType.comment => '$senderNickname님이 내 게시글에 댓글을 달았어요',
      MedamNotificationType.like => '$senderNickname님이 내 게시글을 좋아해요',
      MedamNotificationType.follow => '$senderNickname님이 팔로우하기 시작했어요',
      MedamNotificationType.notice => '새로운 공지가 도착했어요',
    };
  }
}

class NotificationSettingsData {
  const NotificationSettingsData({
    this.receiveAll = true,
    this.vibration = true,
    this.sound = true,
    this.comment = true,
    this.like = true,
    this.follow = true,
    this.chat = true,
  });

  factory NotificationSettingsData.fromJson(Map<String, dynamic>? json) {
    return NotificationSettingsData(
      receiveAll:
          json?['receiveAll'] as bool? ?? json?['enabled'] as bool? ?? true,
      vibration: json?['vibration'] as bool? ?? true,
      sound: json?['sound'] as bool? ?? true,
      comment: json?['comment'] as bool? ?? true,
      like: json?['like'] as bool? ?? true,
      follow: json?['follow'] as bool? ?? true,
      chat: json?['chat'] as bool? ?? true,
    );
  }

  final bool receiveAll;
  final bool vibration;
  final bool sound;
  final bool comment;
  final bool like;
  final bool follow;
  final bool chat;

  bool allows(MedamNotificationType type) {
    if (!receiveAll) {
      return false;
    }
    return switch (type) {
      MedamNotificationType.comment => comment,
      MedamNotificationType.like => like,
      MedamNotificationType.follow => follow,
      MedamNotificationType.notice => true,
    };
  }
}
