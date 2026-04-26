import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CameraMenuScreen extends StatelessWidget {
  const CameraMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('카메라')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 560;
                  final cards = [
                    _CameraMenuCard(
                      title: '눈바디 사진 찍기',
                      description: '나의 변화를 기록해요',
                      icon: Icons.accessibility_new_rounded,
                      onTap: () => context.push('/camera/body'),
                    ),
                    _CameraMenuCard(
                      title: '음식 칼로리 계산',
                      description: '찍으면 칼로리가 계산돼요',
                      icon: Icons.restaurant_rounded,
                      onTap: () => context.push('/camera/food'),
                    ),
                  ];

                  return isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: cards[0]),
                            const SizedBox(width: 14),
                            Expanded(child: cards[1]),
                          ],
                        )
                      : Column(
                          children: [
                            cards[0],
                            const SizedBox(height: 14),
                            cards[1],
                          ],
                        );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraMenuCard extends StatelessWidget {
  const _CameraMenuCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: 190,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 30,
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
