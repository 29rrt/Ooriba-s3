import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'services/firestore_service.dart';

class DatePickerButton extends StatefulWidget {
  @override
  _DatePickerButtonState createState() => _DatePickerButtonState();
}

class _DatePickerButtonState extends State<DatePickerButton> {
  DateTime? _selectedDate;
  Map<String, Map<String, String>> _data = {};

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchData(DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  void _fetchData(String date) async {
    FirestoreService service = FirestoreService();
    print("Fetching data for date: $date"); // Debug statement
    Map<String, Map<String, String>> data = await service.getDataByDate(date);
    print("Data fetched: $data"); // Debug statement

    setState(() {
      _data = data;
    });

    for (var entry in data.entries) {
      if (entry.value['checkIn'] != null) {
        _sendCheckInEmail(entry.key, entry.value['checkIn']!);
      }
      if (entry.value['checkOut'] != null) {
        _sendCheckOutEmail(entry.key, entry.value['checkOut']!);
      }
    }
  }

  Future<void> _sendCheckInEmail(String email, String checkInTime) async {
    const serviceId = 'service_qe69w28';
    const templateId = 'template_1owmygk';
    const userId = 'lMYaM2NpLYjm2qSWI';
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'empemail': email,
          'check_in_time': checkInTime,
        },
      }),
    );

    if (response.statusCode == 200) {
      print('Check-in email sent successfully for $email at $checkInTime!'); // Debug statement
    } else {
      print('Failed to send check-in email for $email: ${response.body}'); // Debug statement
    }
  }

  Future<void> _sendCheckOutEmail(String email, String checkOutTime) async {
    const serviceId = 'service_qe69w28';
    const templateId = 'template_ikcen39';
    const userId = 'lMYaM2NpLYjm2qSWI';
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'empemail': email,
          'check_out_time': checkOutTime,
        },
      }),
    );

    if (response.statusCode == 200) {
      print('Check-out email sent successfully for $email at $checkOutTime!'); // Debug statement
    } else {
      print('Failed to send check-out email for $email: ${response.body}'); // Debug statement
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Page'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => _selectDate(context),
            child: Text('Select date'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _data.length,
              itemBuilder: (context, index) {
                String email = _data.keys.elementAt(index);
                Map<String, String> emailData = _data[email]!;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(email),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('Check-in: ${emailData['checkIn']}')),
                            Expanded(child: Text('Check-out: ${emailData['checkOut']}')),
                          ],
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Status: ',
                                style: TextStyle(color: Colors.black),
                              ),
                              TextSpan(
                                text: emailData['checkOut'] != null ? 'present' : 'absent',
                                style: TextStyle(color: emailData['checkOut'] != null ? Colors.green : Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
