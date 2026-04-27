import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/home_provider.dart';

class ExerciseAddScreen extends ConsumerStatefulWidget {
  const ExerciseAddScreen({super.key});

  @override
  ConsumerState<ExerciseAddScreen> createState() => _ExerciseAddScreenState();
}

class _ExerciseAddScreenState extends ConsumerState<ExerciseAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _typeController = TextEditingController();
  final _minutesController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _typeController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('운동 추가')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '오늘의 운동',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _typeController,
                          decoration: const InputDecoration(
                            labelText: '운동 종류',
                            hintText: '예: 걷기, 헬스, 요가',
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? '운동 종류를 입력해 주세요.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _minutesController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: '시간(분)'),
                          validator: (value) {
                            final minutes = int.tryParse(value?.trim() ?? '');
                            if (minutes == null || minutes <= 0) {
                              return '1분 이상 입력해 주세요.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: _isSaving ? null : _save,
                          child: _isSaving
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('저장하기'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref
          .read(homeRepositoryProvider)
          .addExercise(
            uid: user.uid,
            exerciseType: _typeController.text.trim(),
            minutes: int.parse(_minutesController.text.trim()),
          );
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
