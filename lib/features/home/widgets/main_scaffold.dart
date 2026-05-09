import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final isCameraTab = navigationShell.currentIndex == 2;

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: AnimatedSlide(
        offset: isCameraTab ? const Offset(0, 1.4) : Offset.zero,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: IgnorePointer(
          ignoring: isCameraTab,
          child: SafeArea(
            minimum: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _NavItem(
                        icon: Icons.home_rounded,
                        label: '홈',
                        selected: navigationShell.currentIndex == 0,
                        onTap: () => _goBranch(0),
                      ),
                      _NavItem(
                        icon: Icons.chat_bubble_rounded,
                        label: 'AI봇',
                        selected: navigationShell.currentIndex == 1,
                        onTap: () => _goBranch(1),
                      ),
                      _NavItem(
                        icon: Icons.camera_alt_rounded,
                        label: '카메라',
                        selected: navigationShell.currentIndex == 2,
                        onTap: () => _goBranch(2),
                      ),
                      _NavItem(
                        icon: Icons.people_rounded,
                        label: '커뮤니티',
                        selected: navigationShell.currentIndex == 3,
                        onTap: () => _goBranch(3),
                      ),
                      _NavItem(
                        icon: Icons.person_rounded,
                        label: '마이페이지',
                        selected: navigationShell.currentIndex == 4,
                        onTap: () => _goBranch(4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 52,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    height: 1.0,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
