import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class UpcomingEventsPage extends StatefulWidget {
  @override
  _UpcomingEventsPageState createState() => _UpcomingEventsPageState();
}

class _UpcomingEventsPageState extends State<UpcomingEventsPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('Events').get();
    setState(() {
      _events = {};
      for (var doc in querySnapshot.docs) {
        DateTime date = (doc['date'] as Timestamp).toDate();
        String event = doc['event'];
        if (_events[date] == null) {
          _events[date] = [];
        }
        _events[date]!.add({
          'id': doc.id,
          'event': event,
        });
      }
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  Future<void> _addEvent(String event) async {
    if (_selectedDay != null) {
      DocumentReference docRef = await FirebaseFirestore.instance.collection('Events').add({
        'date': Timestamp.fromDate(_selectedDay!),
        'event': event,
      });
      setState(() {
        if (_events[_selectedDay!] == null) {
          _events[_selectedDay!] = [];
        }
        _events[_selectedDay!]!.add({
          'id': docRef.id,
          'event': event,
        });
      });
    }
  }

  Future<void> _deleteEvent(String eventId, DateTime date) async {
    await FirebaseFirestore.instance.collection('Events').doc(eventId).delete();
    setState(() {
      _events[date]!.removeWhere((event) => event['id'] == eventId);
      if (_events[date]!.isEmpty) {
        _events.remove(date);
      }
    });
  }

  void _showAddEventDialog() {
    final TextEditingController _eventController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Event'),
          content: TextField(
            controller: _eventController,
            decoration: const InputDecoration(labelText: 'Event'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _addEvent(_eventController.text);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Events'),
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
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay; // update `_focusedDay` here as well
              });
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
            },
            eventLoader: _getEventsForDay,
          ),
          const SizedBox(height: 8.0),
          ElevatedButton(
            onPressed: _showAddEventDialog,
            child: const Text('Add Event'),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ListView(
              children: _getEventsForDay(_selectedDay ?? _focusedDay)
                  .map((event) => ListTile(
                        title: Text(event['event']),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteEvent(event['id'], _selectedDay ?? _focusedDay),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
