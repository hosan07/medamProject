import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/medam_logo.dart';
import '../providers/auth_provider.dart';
import '../providers/remote_config_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({this.enableAutoNavigation = true, super.key});

  final bool enableAutoNavigation;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    if (widget.enableAutoNavigation) {
      unawaited(_routeAfterSplash());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _routeAfterSplash() async {
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    if (!mounted) {
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) {
      context.go('/login');
      return;
    }

    final hasProfile = await ref.read(hasUserProfileProvider.future);
    if (!mounted) {
      return;
    }

    context.go(hasProfile ? '/home' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final showAd = ref.watch(
      splashAdVisibleProvider.select((state) => state.value ?? false),
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: Column(
                children: [
                  const Spacer(),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const MedamLogo(size: 86),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '찍어서 담는 나의 오늘',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: showAd
                        ? const _SplashAdBanner()
                        : const SizedBox(height: 76),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashAdBanner extends StatelessWidget {
  const _SplashAdBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('splash_ad_banner'),
      width: double.infinity,
      height: 76,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Text(
        '광고',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
