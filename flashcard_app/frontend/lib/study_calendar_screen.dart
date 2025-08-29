import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'models.dart' as model; // Added comment to force re-evaluation
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
      setState(() {
        _events = {}; // Clear previous events
        for (var log in logs) {
          final date = DateTime.utc(log.date.year, log.date.month, log.date.day);
          if (_events[date] == null) {
            _events[date] = [];
          }
          _events[date]!.add(log);
        }
      });
    } catch (e) {
      // Handle error
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
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
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
              _fetchStudyLogs(); // Fetch logs for the new month/year
            },
            eventLoader: _getEventsForDay,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: Text(
                      '💮',
                      style: TextStyle(fontSize: 16.0),
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
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              defaultTextStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              weekendTextStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
              outsideTextStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ListView.builder(
              itemCount: _getEventsForDay(_selectedDay!).length,
              itemBuilder: (context, index) {
                final log = _getEventsForDay(_selectedDay!)[index];
                return ListTile(
                  title: Text('学習ログ: ${log.date}'), // More detailed log display
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
