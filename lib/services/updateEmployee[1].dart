import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addCheckInOutData(String firstName, DateTime checkIn,
      DateTime checkOut, DateTime Ddate) async {
    try {
      String todayDate = DateFormat('yyyy-MM-dd').format(Ddate);

      // Reference to the specific document for today's date
      DocumentReference docRef = _db.collection('Dates').doc(todayDate);

      // Fetch the document to check if it exists and contains the given name
      DocumentSnapshot docSnapshot = await docRef.get();

      Map<String, dynamic> data =
          docSnapshot.exists ? docSnapshot.data() as Map<String, dynamic> : {};

      Map<String, dynamic> nameData = data[firstName] != null
          ? data[firstName] as Map<String, dynamic>
          : {};

      // Update the name data with the check-in and check-out times
      nameData['checkIn'] = checkIn;
      nameData['checkOut'] = checkOut;

      // Update the main data map with the updated name data
      data[firstName] = nameData;

      // Update the document in Firestore
      await docRef.set(data, SetOptions(merge: true));
    } catch (e) {
      print(e);
    }
  }
}