import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ooriba_s3/services/retrieveDataByEmployeeId.dart';

class ProvideattendancePage extends StatefulWidget {
  @override
  _ProvideattendancePageState createState() => _ProvideattendancePageState();
}

class _ProvideattendancePageState extends State<ProvideattendancePage> {
  final FirestoreService retrieveAllEmployee = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = false;
  bool hasError = false;
  List<Map<String, dynamic>> allEmployees = [];
  Map<String, Map<String, dynamic>> checkInOutData = {};

  @override
  void initState() {
    super.initState();
    fetchAllLeaveRequests();
  }

  void fetchAllLeaveRequests() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      List<Map<String, dynamic>> employees =
          await retrieveAllEmployee.getAllEmployees();
      for (var employee in employees) {
        String employeeId = employee['employeeId'] ?? '';
        Map<String, dynamic> data = await retrieveAllEmployee
            .getCheckInOutDataByEmployeeId(employeeId, DateTime.now());
        checkInOutData[employeeId] = data;
      }
      setState(() {
        allEmployees = employees;
      });
    } catch (e) {
      print('Error fetching leave requests: $e');
      setState(() {
        hasError = true;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> getEmployeeDetails(String employeeId) async {
    Map<String, dynamic>? employeeData =
        await retrieveAllEmployee.getEmployeeById(employeeId);
    if (employeeData != null) {
      return employeeData;
    } else {
      return {'employeeId': employeeId, 'name': 'Unknown'};
    }
  }

  Future<void> fetchLeaveRequestsByEmployeeId(String employeeId) async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      Map<String, dynamic>? employeeData =
          await retrieveAllEmployee.getEmployeeById(employeeId);
      if (employeeData != null) {
        Map<String, dynamic> data = await retrieveAllEmployee
            .getCheckInOutDataByEmployeeId(employeeId, DateTime.now());
        setState(() {
          allEmployees = [employeeData];
          checkInOutData[employeeId] = data;
        });
      } else {
        setState(() {
          allEmployees = [];
        });
      }
    } catch (e) {
      print('Error fetching leave requests by employee ID: $e');
      setState(() {
        hasError = true;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> toggleCheckInCheckOut(String employeeId) async {
    DateTime now = DateTime.now();
    await retrieveAllEmployee.toggleCheckInCheckOut(employeeId, now);
    setState(() {
      fetchAllLeaveRequests();
    });
  }

  Widget buildLeaveRequestItem(Map<String, dynamic> employeeDetails) {
    String employeeId = employeeDetails['employeeId'] ?? 'Unknown';
    Map<String, dynamic> data = checkInOutData[employeeId] ?? {};

    String checkInTime = data['checkIn'] != null
        ? DateFormat('hh:mm a').format(data['checkIn'] as DateTime)
        : '';
    String checkOutTime = data['checkOut'] != null
        ? DateFormat('hh:mm a').format(data['checkOut'] as DateTime)
        : '';
    bool isCheckedIn = data['checkIn'] != null && data['checkOut'] == null;

    return FutureBuilder<Map<String, dynamic>>(
      future: getEmployeeDetails(employeeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          print(
              'Error fetching employee details for ID $employeeId: ${snapshot.error}');
          return Text('Error fetching employee details');
        } else if (!snapshot.hasData || snapshot.data == null) {
          print('No data found for employee ID $employeeId');
          return Text('Employee data not found');
        } else {
          Map<String, dynamic> employeeData = snapshot.data!;
          String first=employeeData['firstName']??'null';
          String last=employeeData['lastName']??'null';
          String employeeName =
              '${(first)[0].toUpperCase()}${first.substring(1).toLowerCase()} ${(last)[0].toUpperCase()}${last.substring(1).toLowerCase()}';
          String employeeRole = employeeData['role'] ?? 'Role not specified';
          String employeeDp = employeeData['dpImageUrl'] ?? "null";
return Container(
  width: 300,
  child: Card(
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              employeeDp != "null"
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(employeeDp),
                      radius: 25.0,
                    )
                  : CircleAvatar(
                      backgroundImage: null,
                      radius: 25.0,
                    ),
              SizedBox(width: 8.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(employeeName,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14.0)),
                    Text('$employeeId', style: TextStyle(fontSize: 12.0)),
                    Text(employeeRole, style: TextStyle(fontSize: 12.0)),
                  ],
                ),
              ),
              SizedBox(width: 8.0),
              Align(
                
                child: ElevatedButton(
                  onPressed: () async {
                    await toggleCheckInCheckOut(employeeId);
                  },
                  child: Text(
                    isCheckedIn ? 'Check Out' : 'Check In ',
                    style: TextStyle(fontSize: 12.0),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    backgroundColor: isCheckedIn
                        ? const Color.fromARGB(255, 107, 241, 112)
                        : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.0),
          Text('Check-In: $checkInTime'),
          Text('Check-Out: $checkOutTime'),
        ],
      ),
    ),
  ),
);

        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Provide Attendance'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : hasError
              ? Center(child: Text('Error fetching leave requests'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search by Employee ID',
                          suffixIcon: IconButton(
                            icon: Icon(Icons.search),
                            onPressed: () {
                              String employeeId = _searchController.text.trim();
                              fetchLeaveRequestsByEmployeeId(employeeId);
                            },
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: allEmployees.length,
                        itemBuilder: (context, index) {
                          Map<String, dynamic> employeeDetails =
                              allEmployees[index];
                          return buildLeaveRequestItem(employeeDetails);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
