import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class AcceptMailService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getEmployeeDetails(String email) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('Employee').doc(email).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      } else {
        throw Exception('No employee found with this email.');
      }
    } catch (e) {
      print('Failed to fetch employee details: $e');
      throw Exception('Failed to fetch employee details: $e');
    }
  }

  Future<void> sendAcceptanceEmail(String email) async {
    try {
      final employeeData = await getEmployeeDetails(email);

      const serviceId = 'service_7isyfqo';
      const templateId = 'template_2kg20dr';
      const userId = '_b8-qaQnQOhviU59X';
      // const apiKey =
      //     'WJJNAozmZ1JCRjpS5eyOa';

      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final response = await http.post(url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'service_id': serviceId,
            'template_id': templateId,
            'user_id': userId,
            'template_params': {
              'firstName': employeeData['firstName'],
              'lastName': employeeData['lastName'],
              'to_email': employeeData['email'],
            },
            // 'access_token': apiKey,
          }));

      if (response.statusCode != 200) {
        print('Failed to send acceptance email: ${response.body}');
        throw Exception('Failed to send acceptance email: ${response.body}');
      } else {
        print('Acceptance email sent successfully');
      }
    } catch (e) {
      print('Error in sendAcceptanceEmail: $e');
      throw Exception('Error in sendAcceptanceEmail: $e');
    }
  }
}