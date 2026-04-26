import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_layout.dart';

class Step2BirthdateScreen extends ConsumerWidget {
  const Step2BirthdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final years = [
      for (
        var year = DateTime.now().year - 80;
        year <= DateTime.now().year - 14;
        year++
      )
        year,
    ];

    return OnboardingLayout(
      step: 2,
      title: '생년월일을 알려주세요',
      subtitle: '나이에 맞는 기초대사량을 계산할게요.',
      primaryLabel: '다음',
      onPrimary: () => goNext(context, 2),
      child: Row(
        children: [
          Expanded(
            child: _DateDropdown(
              label: '년',
              value: state.birthDate.year,
              values: years,
              onChanged: (year) => _update(ref, state, year: year),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _DateDropdown(
              label: '월',
              value: state.birthDate.month,
              values: [for (var month = 1; month <= 12; month++) month],
              onChanged: (month) => _update(ref, state, month: month),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _DateDropdown(
              label: '일',
              value: state.birthDate.day,
              values: [
                for (
                  var day = 1;
                  day <=
                      DateUtils.getDaysInMonth(
                        state.birthDate.year,
                        state.birthDate.month,
                      );
                  day++
                )
                  day,
              ],
              onChanged: (day) => _update(ref, state, day: day),
            ),
          ),
        ],
      ),
    );
  }

  void _update(
    WidgetRef ref,
    OnboardingState state, {
    int? year,
    int? month,
    int? day,
  }) {
    final nextYear = year ?? state.birthDate.year;
    final nextMonth = month ?? state.birthDate.month;
    final maxDay = DateUtils.getDaysInMonth(nextYear, nextMonth);
    final nextDay = (day ?? state.birthDate.day).clamp(1, maxDay);
    ref
        .read(onboardingProvider.notifier)
        .updateBirthDate(DateTime(nextYear, nextMonth, nextDay));
  }
}

class _DateDropdown extends StatelessWidget {
  const _DateDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final int value;
  final List<int> values;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: values
          .map((value) => DropdownMenuItem(value: value, child: Text('$value')))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}
