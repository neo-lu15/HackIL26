import 'package:flutter/material.dart';

import '../../../core/models/event_model.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());

  final List<EventModel> _events = [
    EventModel(
      id: 'e1',
      title: 'Client Meeting',
      start: DateTime.now().add(const Duration(hours: 2)),
      end: DateTime.now().add(const Duration(hours: 3)),
      gcalLocations: ['Zoom'],
    ),
    EventModel(
      id: 'e2',
      title: 'Deep Work Block',
      start: DateTime.now().add(const Duration(days: 1, hours: 1)),
      end: DateTime.now().add(const Duration(days: 1, hours: 3)),
      gcalLocations: ['Desk'],
    ),
    EventModel(
      id: 'e3',
      title: 'Design Sync',
      start: DateTime.now().add(const Duration(days: 3, hours: 4)),
      end: DateTime.now().add(const Duration(days: 3, hours: 5)),
      gcalLocations: ['Room 2B'],
    ),
  ];

  List<EventModel> _eventsForDay(DateTime day) {
    final normalized = DateUtils.dateOnly(day);
    final list = _events
        .where((event) => DateUtils.isSameDay(event.start, normalized))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return list;
  }

  int _eventCountForDay(DateTime day) => _eventsForDay(day).length;

  List<DateTime> _visibleDays(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    // Monday = 1, Sunday = 7, shift to 0-based with Monday first.
    final leadingEmpty = (firstDayOfMonth.weekday + 6) % 7;
    final totalUsedCells = leadingEmpty + daysInMonth;
    final totalCells = ((totalUsedCells + 6) ~/ 7) * 7;

    final firstVisibleDay =
        firstDayOfMonth.subtract(Duration(days: leadingEmpty));

    return [
      for (int i = 0; i < totalCells; i++)
        firstVisibleDay.add(Duration(days: i)),
    ];
  }

  Future<void> _addEventDialog() async {
    final titleController = TextEditingController();
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);
    String location = '';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Event'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Location'),
                      onChanged: (value) => location = value,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: startTime,
                              );
                              if (picked != null) {
                                setDialogState(() => startTime = picked);
                              }
                            },
                            child: Text('Start ${startTime.format(context)}'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: endTime,
                              );
                              if (picked != null) {
                                setDialogState(() => endTime = picked);
                              }
                            },
                            child: Text('End ${endTime.format(context)}'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;
    if (titleController.text.trim().isEmpty) return;

    final start = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      startTime.hour,
      startTime.minute,
    );
    final end = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      endTime.hour,
      endTime.minute,
    );

    setState(() {
      _events.add(
        EventModel(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: titleController.text.trim(),
          start: start,
          end: end.isAfter(start) ? end : start.add(const Duration(hours: 1)),
          gcalLocations: location.trim().isEmpty ? [] : [location.trim()],
        ),
      );
    });
  }

  void _deleteEvent(String id) {
    setState(() {
      _events.removeWhere((event) => event.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Calendar', style: theme.textTheme.headlineMedium),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _focusedMonth =
                          DateTime(DateTime.now().year, DateTime.now().month);
                      _selectedDate = DateUtils.dateOnly(DateTime.now());
                    });
                  },
                  icon: const Icon(Icons.today_outlined),
                  label: const Text('Today'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _addEventDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Create'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Google Calendar style month view with a selected-day agenda.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 1100;

                  if (wide) {
                    return Row(
                      children: [
                        Expanded(flex: 3, child: _monthCard()),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: _agendaCard()),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Expanded(flex: 3, child: _monthCard()),
                      const SizedBox(height: 12),
                      Expanded(flex: 2, child: _agendaCard()),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthCard() {
    final days = _visibleDays(_focusedMonth);
    final monthLabel =
        '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _focusedMonth =
                          DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                    });
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      monthLabel,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _focusedMonth =
                          DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                    });
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: const [
                _WeekLabel('Mon'),
                _WeekLabel('Tue'),
                _WeekLabel('Wed'),
                _WeekLabel('Thu'),
                _WeekLabel('Fri'),
                _WeekLabel('Sat'),
                _WeekLabel('Sun'),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: days.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.18,
                ),
                itemBuilder: (context, index) {
                  final day = days[index];
                  final inMonth = day.month == _focusedMonth.month;
                  final selected = DateUtils.isSameDay(day, _selectedDate);
                  final today = DateUtils.isSameDay(day, DateTime.now());
                  final count = _eventCountForDay(day);

                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setState(() {
                        _selectedDate = DateUtils.dateOnly(day);
                        _focusedMonth = DateTime(day.year, day.month);
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.all(2.5),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: selected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Colors.transparent,
                        border: Border.all(
                          color: today
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              color: inMonth
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          if (count > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$count event${count == 1 ? '' : 's'}',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _agendaCard() {
    final selectedEvents = _eventsForDay(_selectedDate);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formattedDate(_selectedDate),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              '${selectedEvents.length} scheduled item${selectedEvents.length == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: selectedEvents.isEmpty
                  ? const Center(
                      child:
                          Text('No events on this day. Create one to start.'),
                    )
                  : ListView.separated(
                      itemCount: selectedEvents.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final event = selectedEvents[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_timeLabel(event.start)} - ${_timeLabel(event.end)}'
                                      '${event.gcalLocations.isNotEmpty ? ' · ${event.gcalLocations.first}' : ''}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Delete event',
                                onPressed: () => _deleteEvent(event.id),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formattedDate(DateTime value) {
    return '${_monthName(value.month)} ${value.day}, ${value.year}';
  }

  String _timeLabel(DateTime value) {
    final hour = value.hour == 0
        ? 12
        : value.hour > 12
            ? value.hour - 12
            : value.hour;
    final period = value.hour >= 12 ? 'PM' : 'AM';
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
  }
}

class _WeekLabel extends StatelessWidget {
  const _WeekLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
