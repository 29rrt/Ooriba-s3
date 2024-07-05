//EmailJS
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import 'services/auth_service.dart';
import 'services/firestore_service.dart';

class EmployeeCheckInPage extends StatefulWidget {
  final String empname;
  final String empemail;

  const EmployeeCheckInPage(
      {super.key, required this.empname, required this.empemail});

  @override
  // ignore: library_private_types_in_public_api
  _EmployeeCheckInPageState createState() => _EmployeeCheckInPageState();
}

class CheckInOutRecord {
  final DateTime date;
  bool isCheckedIn;
  DateTime? checkInTime;
  DateTime? checkOutTime;

  CheckInOutRecord(
      {required this.date,
      this.isCheckedIn = false,
      this.checkInTime,
      this.checkOutTime});
}

class _EmployeeCheckInPageState extends State<EmployeeCheckInPage> {
  late DateTime dataDate;
  late List<CheckInOutRecord> checkInOutRecords;
  late String _email;

  @override
  void initState() {
    super.initState();
    _email = widget.empemail;
    checkInOutRecords = _generateCheckInOutRecords();
  }

  List<CheckInOutRecord> _generateCheckInOutRecords() {
    // Generate records for the last 7 days
    List<CheckInOutRecord> records = [];
    DateTime now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      DateTime date = now.subtract(Duration(days: i));
      // Dummy logic to alternate check-in and check-out for demonstration
      bool isCheckedIn = i.isOdd;
      DateTime? checkInTime = isCheckedIn ? date.add(Duration(hours: 9)) : null;
      DateTime? checkOutTime =
          isCheckedIn ? null : date.add(Duration(hours: 18));

      records.add(CheckInOutRecord(
          date: date,
          isCheckedIn: isCheckedIn,
          checkInTime: checkInTime,
          checkOutTime: checkOutTime));
    }
    return records;
  }

  void _toggleCheckInOut(int index) async {
    final FirestoreService _firestoreService = FirestoreService();
    void _addData() async {
      if (widget.empname.isNotEmpty) {
        setState(() {});

        await _firestoreService.addCheckInOutData(
            widget.empemail,
            checkInOutRecords[index].checkInTime!,
            checkInOutRecords[index].checkOutTime!,
            dataDate);

        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data added successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter a first name')),
        );
      }
    }

    setState(() {
      DateTime now = DateTime.now();
      checkInOutRecords[index].isCheckedIn =
          !checkInOutRecords[index].isCheckedIn;
      dataDate = now.subtract(Duration(days: index));
      if (checkInOutRecords[index].isCheckedIn) {
        checkInOutRecords[index].checkInTime = DateTime.now();
        checkInOutRecords[index].checkOutTime = null;

        _sendCheckInEmail(widget.empname, widget.empemail,
            checkInOutRecords[index].checkInTime!);
      } else {
        checkInOutRecords[index].checkOutTime = DateTime.now();
        _addData();
        _sendCheckOutEmail(widget.empname, widget.empemail,
            checkInOutRecords[index].checkOutTime!);
      }
    });
    //update into database
  }

  //email thing by emailJS
  Future<void> _sendCheckInEmail(
      String empname, String empemail, DateTime checkInTime) async {
    const serviceId = 'service_qe69w28';
    const templateId = 'template_1owmygk';
    const userId = 'lMYaM2NpLYjm2qSWI';
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final response = await http.post(
      url,
      headers: {
        'origin': 'http:localhost',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'empname': empname,
          'empemail': empemail,
          'check_in_time': checkInTime.toIso8601String(),
        }
      }),
    );

    if (response.statusCode == 200) {
      if (kDebugMode) {
        print('Check-in email sent successfully');
      }
    } else {
      if (kDebugMode) {
        print('Failed to send check-in email: ${response.body}');
      }
    }
  }

  Future<void> _sendCheckOutEmail(
      String empname, String empemail, DateTime checkOutTime) async {
    const serviceId = 'service_qe69w28';
    const templateId = 'template_drhybtc';
    const userId = 'lMYaM2NpLYjm2qSWI';
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'empemail': empemail,
          'empname': empname,
          'check_out_time': checkOutTime.toIso8601String(),
        }
      }),
    );

    if (response.statusCode == 200) {
      if (kDebugMode) {
        print('Check-out email sent successfully');
      }
    } else {
      if (kDebugMode) {
        print('Failed to send check-out email: ${response.body}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${_email}'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signout(context: context);
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: checkInOutRecords.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
                'Date: ${checkInOutRecords[index].date.toLocal().toString().split(' ')[0]}'),
            subtitle: checkInOutRecords[index].isCheckedIn
                ? Text('Checked in at: ${checkInOutRecords[index].checkInTime}')
                : Text(
                    'Checked out at: ${checkInOutRecords[index].checkOutTime}'),
            trailing: ElevatedButton(
              onPressed: () => _toggleCheckInOut(index),
              style: ElevatedButton.styleFrom(
                backgroundColor: checkInOutRecords[index].isCheckedIn
                    ? Colors.green
                    : Colors.red,
              ),
              child: checkInOutRecords[index].isCheckedIn
                  ? const Text('Check Out')
                  : const Text('Check In'),
            ),
          );
        },
      ),
    );
  }
}