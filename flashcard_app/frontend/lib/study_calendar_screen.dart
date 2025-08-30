import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'models.dart' as model;
import 'api_service.dart';

class StudyCalendarScreen extends StatefulWidget {
  const StudyCalendarScreen({super.key});

  @override
  State<StudyCalendarScreen> createState() => _StudyCalendarScreenState();
}

class _StudyCalendarScreenState extends State<StudyCalendarScreen> {
  final ApiService apiService = ApiService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<model.StudyLog>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchStudyLogs();
  }

  Future<void> _fetchStudyLogs() async {
    try {
      final logs = await apiService.getStudyLogs();
      final events = <DateTime, List<model.StudyLog>>{};
      for (var log in logs) {
        final date = DateTime.utc(log.date.year, log.date.month, log.date.day);
        if (events[date] == null) {
          events[date] = [];
        }
        events[date]!.add(log);
      }
      setState(() {
        _events = events;
      });
    } catch (e) {
      print('Error fetching study logs: $e');
    }
  }

  List<model.StudyLog> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('学習カレンダー'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            locale: 'ja_JP',
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              }
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _fetchStudyLogs();
            },
            eventLoader: _getEventsForDay,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Center(
                    child: Text(
                      '💮',
                      style: TextStyle(fontSize: 40.0, color: Colors.amber.withOpacity(0.5)),
                    ),
                  );
                }
                return null;
              },
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: Theme.of(context).textTheme.titleLarge!,
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              defaultTextStyle: const TextStyle(color: Colors.black87),
              weekendTextStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
              outsideTextStyle: const TextStyle(color: Colors.grey),
              markersAlignment: Alignment.center,
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ValueListenableBuilder<DateTime>(
              valueListenable: ValueNotifier(_selectedDay!),
              builder: (context, value, child) {
                final events = _getEventsForDay(value);
                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final log = events[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: ListTile(
                        title: Text('学習記録: カードID ${log.cardId}'),
                        subtitle: Text('日時: ${log.date.toLocal()}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
