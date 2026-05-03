import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/auth_repository.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/camera/screens/body_camera_screen.dart';
import '../features/camera/screens/camera_menu_screen.dart';
import '../features/camera/screens/food_camera_screen.dart';
import '../features/chat/screens/ai_chat_screen.dart';
import '../features/community/screens/chat_list_screen.dart';
import '../features/community/screens/chat_room_screen.dart';
import '../features/community/screens/community_screen.dart';
import '../features/community/screens/post_detail_screen.dart';
import '../features/community/screens/post_write_screen.dart';
import '../features/home/screens/daily_detail_screen.dart';
import '../features/home/screens/exercise_add_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home/widgets/main_scaffold.dart';
import '../features/mypage/screens/app_settings_screen.dart';
import '../features/mypage/screens/mypage_screen.dart';
import '../features/mypage/screens/notification_settings_screen.dart';
import '../features/mypage/screens/profile_screen.dart';
import '../features/mypage/screens/settings_screen.dart';
import '../features/mypage/screens/simple_mypage_route_screen.dart';
import '../features/mypage/screens/subscription_screen.dart';
import '../features/onboarding/screens/step10_water.dart';
import '../features/onboarding/screens/step11_exercise.dart';
import '../features/onboarding/screens/step12_ai_coach.dart';
import '../features/onboarding/screens/step13_plan_loading.dart';
import '../features/onboarding/screens/step14_plan_result.dart';
import '../features/onboarding/screens/step15_diet_type.dart';
import '../features/onboarding/screens/step16_complete.dart';
import '../features/onboarding/screens/step1_nickname.dart';
import '../features/onboarding/screens/step2_birthdate.dart';
import '../features/onboarding/screens/step3_gender.dart';
import '../features/onboarding/screens/step4_height.dart';
import '../features/onboarding/screens/step5_goal.dart';
import '../features/onboarding/screens/step6_goal_reason.dart';
import '../features/onboarding/screens/step7_tried_before.dart';
import '../features/onboarding/screens/step8_weight.dart';
import '../features/onboarding/screens/step9_activity.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authRepositoryProvider).authStateChanges,
    ),
    redirect: (context, state) async {
      final path = state.uri.path;
      final isSplash = path == '/splash';
      final isLogin = path == '/login';
      final isOnboarding = path.startsWith('/onboarding');

      if (isSplash || authState.isLoading) {
        return null;
      }

      final user = authState.value;
      if (user == null) {
        return isLogin ? null : '/login';
      }

      final hasProfile = await ref.read(hasUserProfileProvider.future);
      if (!hasProfile) {
        return isOnboarding ? null : '/onboarding';
      }

      if (isLogin || isOnboarding) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        name: MedamRouteName.splash,
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        name: MedamRouteName.login,
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        name: MedamRouteName.onboarding,
        path: '/onboarding',
        redirect: (context, state) => '/onboarding/1',
      ),
      GoRoute(
        name: MedamRouteName.onboardingStep,
        path: '/onboarding/:step',
        builder: (context, state) {
          final step = int.tryParse(state.pathParameters['step'] ?? '1') ?? 1;
          return switch (step) {
            1 => const Step1NicknameScreen(),
            2 => const Step2BirthdateScreen(),
            3 => const Step3GenderScreen(),
            4 => const Step4HeightScreen(),
            5 => const Step5GoalScreen(),
            6 => const Step6GoalReasonScreen(),
            7 => const Step7TriedBeforeScreen(),
            8 => const Step8WeightScreen(),
            9 => const Step9ActivityScreen(),
            10 => const Step10WaterScreen(),
            11 => const Step11ExerciseScreen(),
            12 => const Step12AiCoachScreen(),
            13 => const Step13PlanLoadingScreen(),
            14 => const Step14PlanResultScreen(),
            15 => const Step15DietTypeScreen(),
            16 => const Step16CompleteScreen(),
            _ => const Step1NicknameScreen(),
          };
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: MedamRouteName.home,
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: MedamRouteName.aiChat,
                path: '/ai-chat',
                builder: (context, state) => const AIChatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: MedamRouteName.camera,
                path: '/camera',
                builder: (context, state) => const CameraMenuScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: MedamRouteName.community,
                path: '/community',
                builder: (context, state) => const CommunityScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: MedamRouteName.mypage,
                path: '/mypage',
                builder: (context, state) => const MyPageScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/community/write',
        builder: (context, state) => const PostWriteScreen(),
      ),
      GoRoute(
        path: '/community/posts/:postId',
        builder: (context, state) {
          final postId = state.pathParameters['postId'] ?? '';
          return PostDetailScreen(postId: postId);
        },
      ),
      GoRoute(
        path: '/community/chats',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/community/chats/:chatId',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId'] ?? '';
          return ChatRoomScreen(chatId: chatId);
        },
      ),
      GoRoute(
        name: MedamRouteName.settings,
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        name: MedamRouteName.appSettings,
        path: '/app-settings',
        builder: (context, state) => const AppSettingsScreen(),
      ),
      GoRoute(
        path: '/notification-settings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/notices',
        builder: (context, state) =>
            const SimpleMyPageRouteScreen(title: '공지사항'),
      ),
      GoRoute(
        path: '/blocked-users',
        builder: (context, state) =>
            const SimpleMyPageRouteScreen(title: '차단 유저 관리'),
      ),
      GoRoute(
        path: '/follow-requests',
        builder: (context, state) =>
            const SimpleMyPageRouteScreen(title: '팔로우 요청 관리'),
      ),
      GoRoute(
        path: '/release-notes',
        builder: (context, state) =>
            const SimpleMyPageRouteScreen(title: '업데이트 내역'),
      ),
      GoRoute(
        path: '/terms-security',
        builder: (context, state) =>
            const SimpleMyPageRouteScreen(title: '약관 및 보안'),
      ),
      GoRoute(
        name: MedamRouteName.calendar,
        path: '/calendar',
        builder: (context, state) => const MedamRouteScreen(title: '캘린더'),
      ),
      GoRoute(
        name: MedamRouteName.notification,
        path: '/notification',
        builder: (context, state) => const MedamRouteScreen(title: '알림'),
      ),
      GoRoute(
        name: MedamRouteName.profile,
        path: '/profile/:uid',
        builder: (context, state) {
          final uid = state.pathParameters['uid'] ?? '';
          return ProfileScreen(uid: uid);
        },
      ),
      GoRoute(
        path: '/daily-detail',
        builder: (context, state) => const DailyDetailScreen(),
      ),
      GoRoute(
        path: '/body-album',
        builder: (context, state) => const BodyCameraScreen(autoCapture: false),
      ),
      GoRoute(
        path: '/camera/body',
        builder: (context, state) => const BodyCameraScreen(),
      ),
      GoRoute(
        path: '/camera/food',
        builder: (context, state) => const FoodCameraScreen(),
      ),
      GoRoute(
        path: '/exercise',
        builder: (context, state) => const ExerciseAddScreen(),
      ),
      GoRoute(
        path: '/exercise-detail',
        builder: (context, state) => const MedamRouteScreen(title: '운동 상세'),
      ),
    ],
  );
});

class MedamRouteName {
  const MedamRouteName._();

  static const splash = 'splash';
  static const login = 'login';
  static const onboarding = 'onboarding';
  static const onboardingStep = 'onboarding_step';
  static const home = 'home';
  static const aiChat = 'ai_chat';
  static const camera = 'camera';
  static const community = 'community';
  static const mypage = 'mypage';
  static const appSettings = 'app_settings';
  static const settings = 'settings';
  static const calendar = 'calendar';
  static const notification = 'notification';
  static const profile = 'profile';
}

class MedamRouteScreen extends StatelessWidget {
  const MedamRouteScreen({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '미담',
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle ?? '$title 화면',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
