import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getEmployees() {
    return _db.collection('Employee').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add document ID to the data
        return data;
      }).toList();
    });
  }

  Future<void> saveEmployeeData(String email, Map<String, dynamic> data) async {
    try {
      await _db
          .collection('Employee')
          .doc(email)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      print('Error saving employee data: $e');
      throw e; // Re-throw the error to handle it in the UI
    }
  }

  Future<Map<String, dynamic>?> searchEmployee({required String email}) async {
    try {
      DocumentSnapshot doc = await _db.collection('Employee').doc(email).get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('Error fetching employee data: $e');
      throw e; // Re-throw the error to handle it in the UI
    }
  }

  addCheckInOutData(String empemail, DateTime dateTime, DateTime dateTime2, DateTime dataDate) {}
}