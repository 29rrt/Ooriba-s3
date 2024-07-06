import 'package:cloud_firestore/cloud_firestore.dart';

class DateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, Map<String, String>>> getDataByDate(String date) async {
    try {
      DocumentSnapshot snapshot =
          await _firestore.collection('Dates').doc(date).get();

      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        return data.map((email, value) {
          Map<String, dynamic> emailData = value as Map<String, dynamic>;
          Timestamp checkInTimestamp = emailData['checkIn'];
          Timestamp checkOutTimestamp = emailData['checkOut'];
          DateTime checkIn = checkInTimestamp.toDate();
          DateTime checkOut = checkOutTimestamp.toDate();

          return MapEntry(email, {
            'checkIn':
                checkIn.toString(), // Convert to desired format if necessary
            'checkOut': checkOut.toString(),
          });
        });
      } else {
        print('Document does not exist for the given date: $date');
        return {};
      }
    } catch (e) {
      print('Error retrieving data: $e');
      return {};
    }
  }
}
