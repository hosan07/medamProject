import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/record_detail_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  final _memoController = TextEditingController();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  String _memoCategory = '식단';

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monthKey = DateFormat('yyyy-MM').format(_focusedDay);
    final monthData = ref.watch(calendarMonthProvider(monthKey));
    final selectedDay = _selectedDay;

    return Scaffold(
      appBar: AppBar(title: const Text('캘린더')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: monthData.when(
                data: (data) => TableCalendar<void>(
                  locale: 'ko_KR',
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2100, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  calendarFormat: CalendarFormat.month,
                  availableCalendarFormats: const {CalendarFormat.month: '월'},
                  shouldFillViewport: true,
                  daysOfWeekHeight: 22,
                  headerStyle: const HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    headerPadding: EdgeInsets.symmetric(vertical: 2),
                    leftChevronPadding: EdgeInsets.zero,
                    rightChevronPadding: EdgeInsets.zero,
                  ),
                  calendarStyle: CalendarStyle(
                    cellMargin: const EdgeInsets.all(1),
                    cellPadding: EdgeInsets.zero,
                    markerMargin: EdgeInsets.zero,
                    todayDecoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    });
                  },
                  onPageChanged: (focused) {
                    setState(() => _focusedDay = focused);
                  },
                  calendarBuilders: CalendarBuilders<void>(
                    markerBuilder: (context, day, _) {
                      final dateKey = _dateKey(day);
                      final hasRecord = data.hasRecord(dateKey);
                      final hasMemo = data.hasMemo(dateKey);
                      if (!hasRecord && !hasMemo) {
                        return null;
                      }
                      return Positioned(
                        bottom: 4,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasRecord)
                              _MarkerDot(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            if (hasRecord && hasMemo) const SizedBox(width: 3),
                            if (hasMemo)
                              Icon(
                                Icons.edit_note_rounded,
                                size: 12,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(error.toString())),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: selectedDay == null
                    ? const SizedBox(height: 48)
                    : _CalendarActions(
                        selectedDay: selectedDay,
                        onMemo: () => _showMemoSheet(selectedDay),
                        onMove: () => context.push(
                          '/daily-detail?date=${_dateKey(selectedDay)}',
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMemoSheet(DateTime day) async {
    _memoController.clear();
    _memoCategory = '식단';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.viewInsetsOf(context).bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    DateFormat('M월 d일 메모').format(day),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _memoCategory,
                    decoration: const InputDecoration(labelText: '카테고리'),
                    items: const ['식단', '운동', '몸무게', '기타']
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => _memoCategory = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _memoController,
                    maxLength: 200,
                    minLines: 4,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: '메모'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => _saveMemo(day),
                    child: const Text('저장'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveMemo(DateTime day) async {
    final user = ref.read(currentUserProvider);
    final memo = _memoController.text.trim();
    if (user == null || memo.isEmpty) {
      return;
    }
    final dateKey = _dateKey(day);
    await ref
        .read(recordRepositoryProvider)
        .saveMemo(
          uid: user.uid,
          dateKey: dateKey,
          category: _memoCategory,
          memo: memo,
        );
    ref.invalidate(calendarMonthProvider(DateFormat('yyyy-MM').format(day)));
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('메모를 저장했어요.')));
    }
  }

  String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
}

class _CalendarActions extends StatelessWidget {
  const _CalendarActions({
    required this.selectedDay,
    required this.onMemo,
    required this.onMove,
  });

  final DateTime selectedDay;
  final VoidCallback onMemo;
  final VoidCallback onMove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey(selectedDay),
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onMemo,
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('메모하기'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: onMove,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('이동하기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkerDot extends StatelessWidget {
  const _MarkerDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
