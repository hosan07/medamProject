import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_layout.dart';

class Step1NicknameScreen extends ConsumerStatefulWidget {
  const Step1NicknameScreen({super.key});

  @override
  ConsumerState<Step1NicknameScreen> createState() =>
      _Step1NicknameScreenState();
}

class _Step1NicknameScreenState extends ConsumerState<Step1NicknameScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(onboardingProvider).nickname,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nickname = ref.watch(onboardingProvider).nickname;
    final isValid = RegExp(r'^[가-힣a-zA-Z0-9]{2,10}$').hasMatch(nickname);

    return OnboardingLayout(
      step: 1,
      title: '어떻게 불러드릴까요?',
      subtitle: '2~10자의 한글, 영어, 숫자만 사용할 수 있어요.',
      primaryLabel: '다음',
      primaryEnabled: isValid,
      onPrimary: () => goNext(context, 1),
      child: TextFormField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: '예: 미담이'),
        textInputAction: TextInputAction.done,
        onChanged: ref.read(onboardingProvider.notifier).updateNickname,
      ),
    );
  }
}
