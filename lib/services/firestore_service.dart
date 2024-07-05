import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getDataByDate(String date) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _db.collection('Dates').doc(date).get();

      if (snapshot.exists) {
        return snapshot.data() ?? {};
      } else {
        return {};
      }
    } catch (e) {
      print('Error fetching data: $e');
      return {};
    }
  }

  addCheckInOutData(String empemail, DateTime dateTime, DateTime dateTime2, DateTime dataDate) {}
}