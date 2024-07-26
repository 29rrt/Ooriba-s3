import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/leave_service.dart'; // Adjust the import according to your project structure

class LeaveReportPage extends StatefulWidget {
  @override
  _LeaveReportPageState createState() => _LeaveReportPageState();
}

class _LeaveReportPageState extends State<LeaveReportPage> {
  final LeaveService _leaveService = LeaveService();
  Map<String, dynamic>? leaveCount;

  @override
  void initState() {
    super.initState();
    fetchLeaveCount();
  }

  Future<void> fetchLeaveCount() async {
    try {
      String employeeId = 'employee123'; // Use the actual employeeId
      Map<String, dynamic>? countData =
          await _leaveService.fetchLeaveCount(employeeId);
      setState(() {
        leaveCount = countData;
      });
    } catch (e) {
      print('Error fetching leave count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leave Report'),
      ),
      body: leaveCount != null
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Leave Count:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text('Employee ID: ${leaveCount!['employeeId']}'),
                  Text('From Date: ${leaveCount!['fromDate']}'),
                  Text('Count: ${leaveCount!['count']}'),
                ],
              ),
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}