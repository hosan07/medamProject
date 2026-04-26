import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/auth_repository.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/splash_screen.dart';

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
          final step = state.pathParameters['step'] ?? '1';
          return MedamRouteScreen(title: '온보딩 $step단계');
        },
      ),
      GoRoute(
        name: MedamRouteName.home,
        path: '/home',
        builder: (context, state) => const MedamRouteScreen(title: '홈'),
      ),
      GoRoute(
        name: MedamRouteName.aiChat,
        path: '/ai-chat',
        builder: (context, state) => const MedamRouteScreen(title: 'AI봇'),
      ),
      GoRoute(
        name: MedamRouteName.camera,
        path: '/camera',
        builder: (context, state) => const MedamRouteScreen(title: '카메라'),
      ),
      GoRoute(
        name: MedamRouteName.community,
        path: '/community',
        builder: (context, state) => const MedamRouteScreen(title: '커뮤니티'),
      ),
      GoRoute(
        name: MedamRouteName.mypage,
        path: '/mypage',
        builder: (context, state) => const MedamRouteScreen(title: '마이페이지'),
      ),
      GoRoute(
        name: MedamRouteName.settings,
        path: '/settings',
        builder: (context, state) => const MedamRouteScreen(title: '설정'),
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
          return MedamRouteScreen(title: '프로필', subtitle: uid);
        },
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
