import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/onboarding_layout.dart';

class Step13PlanLoadingScreen extends StatefulWidget {
  const Step13PlanLoadingScreen({super.key});

  @override
  State<Step13PlanLoadingScreen> createState() =>
      _Step13PlanLoadingScreenState();
}

class _Step13PlanLoadingScreenState extends State<Step13PlanLoadingScreen> {
  double _progress = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 90), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _progress = (_progress + 0.03).clamp(0, 1);
      });
      if (_progress >= 1) {
        timer.cancel();
        if (mounted) {
          context.go('/onboarding/14');
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'step 13 of $onboardingTotalSteps',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: const LinearProgressIndicator(
                      minHeight: 8,
                      value: 13 / onboardingTotalSteps,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '계획을 만들고 있어요...',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 28),
                  LinearProgressIndicator(value: _progress, minHeight: 10),
                  const SizedBox(height: 16),
                  Text(
                    '${(_progress * 100).round()}%',
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => context.go('/onboarding/12'),
                    child: const Text('이전'),
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
