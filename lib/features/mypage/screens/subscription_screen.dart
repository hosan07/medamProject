import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/ads/ad_manager.dart';
import '../providers/monetization_provider.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);
    final credits = ref.watch(creditProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('구독 및 크레딧')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: subscription.when(
            data: (plan) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                _PlanHeader(plan: plan, credits: credits.value ?? 0),
                const SizedBox(height: 16),
                const _BenefitTable(),
                const SizedBox(height: 16),
                if (!plan.isSubscribed)
                  FilledButton.icon(
                    onPressed: () => ref
                        .read(subscriptionProvider.notifier)
                        .startStubSubscription(),
                    icon: const Icon(Icons.workspace_premium_rounded),
                    label: const Text('구독하기'),
                  )
                else
                  FilledButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('구독 중'),
                  ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => ref
                      .read(subscriptionProvider.notifier)
                      .restoreStubSubscription(),
                  icon: const Icon(Icons.restore_rounded),
                  label: const Text('구독 복원하기'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: plan.isSubscribed
                      ? null
                      : () => _watchAdAndEarnCredits(context, ref),
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  label: const Text('광고 보고 크레딧 받기'),
                ),
                const SizedBox(height: 18),
                Text(
                  '인앱 결제는 StoreKit/BillingClient 연결 단계에서 실제 상품과 영수증 검증으로 교체됩니다.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text(error.toString())),
          ),
        ),
      ),
    );
  }

  Future<void> _watchAdAndEarnCredits(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final shown = await AdManager.instance.showInterstitialAd();
    await ref.read(creditProvider.notifier).earnCredits(shown ? 3 : 1);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(shown ? '크레딧 3개를 받았어요.' : '크레딧 1개를 받았어요.')),
    );
  }
}

class _PlanHeader extends StatelessWidget {
  const _PlanHeader({required this.plan, required this.credits});

  final SubscriptionState plan;
  final int credits;

  @override
  Widget build(BuildContext context) {
    final renewsAt = plan.renewsAt;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Badge(
                  backgroundColor: plan.isSubscribed
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                  label: Text(plan.isSubscribed ? '구독 중' : '무료'),
                ),
                const Spacer(),
                Text(
                  '크레딧 $credits',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              plan.isSubscribed ? '미담 플러스' : '무료 플랜',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              renewsAt == null
                  ? '광고 시청으로 크레딧을 충전할 수 있어요.'
                  : '${DateFormat('yyyy.MM.dd').format(renewsAt)}까지 혜택이 유지돼요.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitTable extends StatelessWidget {
  const _BenefitTable();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: const [
            _BenefitRow(title: '광고', free: '노출', paid: '제거'),
            Divider(height: 22),
            _BenefitRow(title: '크레딧 충전', free: '광고 시청', paid: '매월 30일치'),
            Divider(height: 22),
            _BenefitRow(title: 'AI 코치', free: '기본', paid: '우선 사용'),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.title,
    required this.free,
    required this.paid,
  });

  final String title;
  final String free;
  final String paid;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        Expanded(child: Text(free, textAlign: TextAlign.center)),
        Expanded(
          child: Text(
            paid,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
