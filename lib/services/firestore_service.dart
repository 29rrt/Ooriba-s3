import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addCheckInOutData(String email, DateTime checkIn, DateTime checkOut, DateTime date) async {
    await _db.collection('attendance').doc(email + '_' + DateFormat('yyyy-MM-dd').format(date)).set({
      'email': email,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'checkIn': checkIn,
      'checkOut': checkOut,
    }, SetOptions(merge: true));
  }

  Future<Map<String, Map<String, String>>> getDataByDate(String date) async {
    Map<String, Map<String, String>> data = {};

    QuerySnapshot snapshot = await _db
        .collection('attendance')
        .where('date', isEqualTo: date)
        .get();

    for (var doc in snapshot.docs) {
      data[doc['email']] = {
        'checkIn': (doc['checkIn'] as Timestamp).toDate().toIso8601String(),
        'checkOut': (doc['checkOut'] as Timestamp).toDate().toIso8601String(),
      };
    }

    return data;
  }
}
