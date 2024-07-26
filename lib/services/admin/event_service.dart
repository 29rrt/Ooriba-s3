import 'package:cloud_firestore/cloud_firestore.dart';

class EventService {
  final CollectionReference _eventCollection = FirebaseFirestore.instance.collection('Events');
  final CollectionReference _holidayCollection = FirebaseFirestore.instance.collection('Holidays');

  Future<Map<DateTime, List<Map<String, dynamic>>>> loadEvents() async {
    QuerySnapshot querySnapshot = await _eventCollection.get();
    Map<DateTime, List<Map<String, dynamic>>> events = {};
    for (var doc in querySnapshot.docs) {
      DateTime date = (doc['date'] as Timestamp).toDate();
      DateTime dateWithoutTime = DateTime(date.year, date.month, date.day);
      String event = doc['event'];
      if (events[dateWithoutTime] == null) {
        events[dateWithoutTime] = [];
      }
      events[dateWithoutTime]!.add({
        'id': doc.id,
        'event': event,
      });
    }
    return events;
  }

  Future<Map<DateTime, List<Map<String, dynamic>>>> loadHolidays() async {
    QuerySnapshot querySnapshot = await _holidayCollection.get();
    Map<DateTime, List<Map<String, dynamic>>> holidays = {};
    for (var doc in querySnapshot.docs) {
      DateTime date = (doc['date'] as Timestamp).toDate();
      DateTime holidayKey = DateTime(date.year, date.month, date.day);
      String holiday = doc['holiday'];
      if (holidays[holidayKey] == null) {
        holidays[holidayKey] = [];
      }
      holidays[holidayKey]!.add({
        'id': doc.id,
        'holiday': holiday,
      });
    }
    return holidays;
  }

  Future<DocumentReference> addEvent(DateTime date, String event) async {
    return await _eventCollection.add({
      'date': Timestamp.fromDate(date),
      'event': event,
    });
  }

  Future<DocumentReference> addHoliday(DateTime date, String holiday) async {
    return await _holidayCollection.add({
      'date': Timestamp.fromDate(date),
      'holiday': holiday,
    });
  }

  Future<void> deleteEvent(String eventId) async {
    await _eventCollection.doc(eventId).delete();
  }

  Future<void> deleteHoliday(String holidayId) async {
    await _holidayCollection.doc(holidayId).delete();
  }
}
