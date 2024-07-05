// firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getEmployeeByEmail(String email) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('Employee')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data() as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<Map<String, dynamic>?> searchEmployee({required String email}) async {
    if (email.isNotEmpty) {
      final employeeData = await getEmployeeByEmail(email);
      return employeeData;
    }
    return null;
  }
  //  final FirestoreService firestore_Service = FirestoreService();
  //  Map<String, dynamic>? employeeData = await firestore_Service.searchEmployee(email: email)
  // String firstName = employeeData != null ? employeeData['firstName'] ?? '' : '';
}