// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:ooriba_s3/services/retrieveDataByEmployeeId.dart';
// import 'services/leave_service.dart';
// import 'apply_leave.dart'; // Import the ApplyLeavePage

// class LeaveApprovalPage extends StatefulWidget {
//   @override
//   _LeaveApprovalPageState createState() => _LeaveApprovalPageState();
// }

// class _LeaveApprovalPageState extends State<LeaveApprovalPage> {
//   final LeaveService _leaveService = LeaveService();
//   final TextEditingController _searchController = TextEditingController();
//   bool isLoading = false;
//   bool hasError = false;
//   List<Map<String, dynamic>> leaveRequests = [];

//   @override
//   void initState() {
//     super.initState();
//     fetchAllLeaveRequests();
//   }

//   void fetchAllLeaveRequests() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//     try {
//       List<Map<String, dynamic>> requests =
//           await _leaveService.fetchAllLeaveRequests();
//       setState(() {
//         leaveRequests = requests;
//       });
//     } catch (e) {
//       setState(() {
//         hasError = true;
//       });
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   String formatDate(Timestamp timestamp) {
//     DateTime dateTime = timestamp.toDate();
//     return '${_getOrdinal(dateTime.day)} ${DateFormat('MMMM yyyy').format(dateTime)}';
//   }

//   String _getOrdinal(int day) {
//     if (day % 10 == 1 && day != 11) {
//       return '${day}st';
//     } else if (day % 10 == 2 && day != 12) {
//       return '${day}nd';
//     } else if (day % 10 == 3 && day != 13) {
//       return '${day}rd';
//     } else {
//       return '${day}th';
//     }
//   }

//   Future<Map<String, dynamic>> getEmployeeDetails(String employeeId) async {
//     final FirestoreService firestoreService = FirestoreService();
//     Map<String, dynamic>? employeeData =
//         await firestoreService.getEmployeeById(employeeId);
//     if (employeeData != null) {
//       return employeeData;
//     } else {
//       return {'employeeId': employeeId, 'name': 'Unknown'};
//     }
//   }

//   Future<void> fetchLeaveRequestsByEmployeeId(String employeeId) async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//     try {
//       List<Map<String, dynamic>> requests =
//           await _leaveService.fetchLeaveRequestsByEmployeeId(employeeId);
//       setState(() {
//         leaveRequests = requests;
//       });
//     } catch (e) {
//       setState(() {
//         hasError = true;
//       });
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   Widget buildLeaveRequestItem(Map<String, dynamic> leaveDetails) {
//     String employeeId = leaveDetails['employeeId'] ?? 'Unknown';
//     String leaveType = leaveDetails['leaveType'] ?? 'Unknown';
//     String fromDate = leaveDetails['fromDate'] != null
//         ? formatDate(leaveDetails['fromDate'] as Timestamp)
//         : 'N/A';
//     String toDate = leaveDetails['toDate'] != null
//         ? formatDate(leaveDetails['toDate'] as Timestamp)
//         : 'N/A';
//     double numberOfDays = leaveDetails['numberOfDays'] ?? 0.0;
//     String leaveReason = leaveDetails['leaveReason'] ?? 'No reason provided';

//     return FutureBuilder<Map<String, dynamic>>(
//       future: getEmployeeDetails(employeeId),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(child: CircularProgressIndicator());
//         } else if (snapshot.hasError) {
//           return Text('Error fetching employee details');
//         } else if (!snapshot.hasData || snapshot.data == null) {
//           return Text('Employee data not found');
//         } else {
//           Map<String, dynamic> employeeData = snapshot.data!;
//           String employeeName =
//               '${employeeData['firstName']} ${employeeData['lastName']}';
//           String employeeRole = employeeData['role'] ?? 'Role not specified';
//           String employeeDepartment =
//               employeeData['department'] ?? 'Department not specified';
//           String employeeDp =
//               employeeData['dpImageUrl'] ?? 'https://via.placeholder.com/150';

//           return Container(
//             width: 300,
//             child: Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         CircleAvatar(
//                           backgroundImage: NetworkImage(employeeDp),
//                           radius: 25.0,
//                         ),
//                         SizedBox(width: 8.0),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(employeeName,
//                                   style: TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 14.0)),
//                               Text('$employeeId',
//                                   style: TextStyle(fontSize: 12.0)),
//                               Text(employeeRole,
//                                   style: TextStyle(fontSize: 12.0)),
//                             ],
//                           ),
//                         ),
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text('$leaveType',
//                                 style: TextStyle(fontSize: 12.0)),
//                             Text('$numberOfDays Days',
//                                 style: TextStyle(fontSize: 12.0)),
//                           ],
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 8.0),
//                     Text('$leaveReason',
//                         style: TextStyle(
//                             fontWeight: FontWeight.bold, fontSize: 12.0)),
//                     Text('$fromDate - $toDate',
//                         style: TextStyle(fontSize: 12.0)),
//                     SizedBox(height: 8.0),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.end,
//                       children: [
//                         ElevatedButton(
//                           onPressed: () async {
//                             String fromDateStr = DateFormat('yyyy-MM-dd')
//                                 .format((leaveDetails['fromDate'] as Timestamp)
//                                     .toDate());
//                             await _leaveService.updateLeaveStatus(
//                                 employeeId: employeeId,
//                                 fromDateStr: fromDateStr,
//                                 isApproved: true);
//                             fetchAllLeaveRequests();
//                           },
//                           child:
//                               Text('Approve', style: TextStyle(fontSize: 12.0)),
//                           style: ElevatedButton.styleFrom(
//                             padding: EdgeInsets.symmetric(
//                                 horizontal: 8.0, vertical: 4.0),
//                             backgroundColor: Colors.green,
//                           ),
//                         ),
//                         SizedBox(width: 8.0),
//                         ElevatedButton(
//                           onPressed: () async {
//                             String fromDateStr = DateFormat('yyyy-MM-dd')
//                                 .format((leaveDetails['fromDate'] as Timestamp)
//                                     .toDate());
//                             await _leaveService.updateLeaveStatus(
//                                 employeeId: employeeId,
//                                 fromDateStr: fromDateStr,
//                                 isApproved: false);
//                             fetchAllLeaveRequests();
//                           },
//                           child: Text('Deny', style: TextStyle(fontSize: 12.0)),
//                           style: ElevatedButton.styleFrom(
//                             padding: EdgeInsets.symmetric(
//                                 horizontal: 8.0, vertical: 4.0),
//                             backgroundColor: Colors.red,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         }
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Leave Requests'),
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : hasError
//               ? Center(child: Text('Error fetching leave requests'))
//               : Column(
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.all(8.0),
//                       child: TextField(
//                         controller: _searchController,
//                         decoration: InputDecoration(
//                           labelText: 'Search by Employee ID',
//                           suffixIcon: IconButton(
//                             icon: Icon(Icons.search),
//                             onPressed: () {
//                               String employeeId = _searchController.text.trim();
//                               fetchLeaveRequestsByEmployeeId(employeeId);
//                             },
//                           ),
//                         ),
//                       ),
//                     ),
//                     Expanded(
//                       child: ListView.builder(
//                         itemCount: leaveRequests.length,
//                         itemBuilder: (context, index) {
//                           Map<String, dynamic> leaveDetails =
//                               leaveRequests[index];
//                           return buildLeaveRequestItem(leaveDetails);
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => ApplyLeavePage()),
//           );
//         },
//         child: Icon(Icons.add),
//       ),
//     );
//   }
// }




























// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:ooriba/services/retrieveDataByEmployeeId.dart';
// import 'services/leave_service.dart';

// class LeaveApprovalPage extends StatefulWidget {
//   @override
//   _LeaveApprovalPageState createState() => _LeaveApprovalPageState();
// }

// class _LeaveApprovalPageState extends State<LeaveApprovalPage> {
//   final LeaveService _leaveService = LeaveService();
//   final TextEditingController _searchController = TextEditingController();
//   bool isLoading = false;
//   bool hasError = false;
//   List<Map<String, dynamic>> leaveRequests = [];

//   @override
//   void initState() {
//     super.initState();
//     fetchAllLeaveRequests();
//   }

//   void fetchAllLeaveRequests() async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//     try {
//       List<Map<String, dynamic>> requests =
//           await _leaveService.fetchAllLeaveRequests();
//       setState(() {
//         leaveRequests = requests;
//       });
//     } catch (e) {
//       setState(() {
//         hasError = true;
//       });
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   String formatDate(Timestamp timestamp) {
//     DateTime dateTime = timestamp.toDate();
//     return '${_getOrdinal(dateTime.day)} ${DateFormat('MMMM yyyy').format(dateTime)}';
//   }

//   String _getOrdinal(int day) {
//     if (day % 10 == 1 && day != 11) {
//       return '${day}st';
//     } else if (day % 10 == 2 && day != 12) {
//       return '${day}nd';
//     } else if (day % 10 == 3 && day != 13) {
//       return '${day}rd';
//     } else {
//       return '${day}th';
//     }
//   }

//   Future<Map<String, dynamic>> getEmployeeDetails(String employeeId) async {
//     final FirestoreService firestoreService = FirestoreService();
//     Map<String, dynamic>? employeeData =
//         await firestoreService.getEmployeeById(employeeId);
//     if (employeeData != null) {
//       return employeeData;
//     } else {
//       return {'employeeId': employeeId, 'name': 'Unknown'};
//     }
//   }

//   Future<void> fetchLeaveRequestsByEmployeeId(String employeeId) async {
//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });
//     try {
//       List<Map<String, dynamic>> requests =
//           await _leaveService.fetchLeaveRequestsByEmployeeId(employeeId);
//       setState(() {
//         leaveRequests = requests;
//       });
//     } catch (e) {
//       setState(() {
//         hasError = true;
//       });
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   Widget buildLeaveRequestItem(Map<String, dynamic> leaveDetails) {
//     String employeeId = leaveDetails['employeeId'] ?? 'Unknown';
//     String leaveType = leaveDetails['leaveType'] ?? 'Unknown';
//     String fromDate = leaveDetails['fromDate'] != null
//         ? formatDate(leaveDetails['fromDate'] as Timestamp)
//         : 'N/A';
//     String toDate = leaveDetails['toDate'] != null
//         ? formatDate(leaveDetails['toDate'] as Timestamp)
//         : 'N/A';
//     double numberOfDays = leaveDetails['numberOfDays'] ?? 0.0;
//     String leaveReason = leaveDetails['leaveReason'] ?? 'No reason provided';

//     return FutureBuilder<Map<String, dynamic>>(
//       future: getEmployeeDetails(employeeId),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(child: CircularProgressIndicator());
//         } else if (snapshot.hasError) {
//           return Text('Error fetching employee details');
//         } else if (!snapshot.hasData || snapshot.data == null) {
//           return Text('Employee data not found');
//         } else {
//           Map<String, dynamic> employeeData = snapshot.data!;
//           String employeeName =
//               '${employeeData['firstName']} ${employeeData['lastName']}';
//           String employeeRole = employeeData['role'] ?? 'Role not specified';
//           String employeeDepartment =
//               employeeData['department'] ?? 'Department not specified';
//           String employeeDp =
//               employeeData['dpImageUrl'] ?? 'https://via.placeholder.com/150';

//           return Container(
//             width: 300,
//             child: Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         CircleAvatar(
//                           backgroundImage: NetworkImage(employeeDp),
//                           radius: 25.0,
//                         ),
//                         SizedBox(width: 8.0),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(employeeName,
//                                   style: TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 14.0)),
//                               Text('$employeeId',
//                                   style: TextStyle(fontSize: 12.0)),
//                               Text(employeeRole,
//                                   style: TextStyle(fontSize: 12.0)),
//                             ],
//                           ),
//                         ),
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text('$leaveType',
//                                 style: TextStyle(fontSize: 12.0)),
//                             Text('$numberOfDays Days',
//                                 style: TextStyle(fontSize: 12.0)),
//                           ],
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 8.0),
//                     Text('$leaveReason',
//                         style: TextStyle(
//                             fontWeight: FontWeight.bold, fontSize: 12.0)),
//                     Text('$fromDate - $toDate',
//                         style: TextStyle(fontSize: 12.0)),
//                     SizedBox(height: 8.0),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.end,
//                       children: [
//                         ElevatedButton(
//                           onPressed: () async {
//                             String fromDateStr = DateFormat('yyyy-MM-dd')
//                                 .format((leaveDetails['fromDate'] as Timestamp)
//                                     .toDate());
//                             await _leaveService.updateLeaveStatus(
//                                 employeeId: employeeId,
//                                 fromDateStr: fromDateStr,
//                                 isApproved: true);
//                             fetchAllLeaveRequests();
//                           },
//                           child:
//                               Text('Approve', style: TextStyle(fontSize: 12.0)),
//                           style: ElevatedButton.styleFrom(
//                             padding: EdgeInsets.symmetric(
//                                 horizontal: 8.0, vertical: 4.0),
//                             backgroundColor: Colors.green,
//                           ),
//                         ),
//                         SizedBox(width: 8.0),
//                         ElevatedButton(
//                           onPressed: () async {
//                             String fromDateStr = DateFormat('yyyy-MM-dd')
//                                 .format((leaveDetails['fromDate'] as Timestamp)
//                                     .toDate());
//                             await _leaveService.updateLeaveStatus(
//                                 employeeId: employeeId,
//                                 fromDateStr: fromDateStr,
//                                 isApproved: false);
//                             fetchAllLeaveRequests();
//                           },
//                           child: Text('Deny', style: TextStyle(fontSize: 12.0)),
//                           style: ElevatedButton.styleFrom(
//                             padding: EdgeInsets.symmetric(
//                                 horizontal: 8.0, vertical: 4.0),
//                             backgroundColor: Colors.red,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         }
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Leave Approval'),
//         bottom: PreferredSize(
//           preferredSize: Size.fromHeight(56.0),
//           child: Padding(
//             padding: EdgeInsets.all(8.0),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: 'Enter Employee ID',
//                 suffixIcon: IconButton(
//                   icon: Icon(Icons.search),
//                   onPressed: () {
//                     fetchLeaveRequestsByEmployeeId(_searchController.text);
//                   },
//                 ),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8.0),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : hasError
//               ? Center(
//                   child: Text(
//                       'Failed to fetch leave requests. Please try again later.',
//                       style: TextStyle(color: Colors.red)))
//               : ListView.builder(
//                   itemCount: leaveRequests.length,
//                   itemBuilder: (context, index) {
//                     return buildLeaveRequestItem(leaveRequests[index]);
//                   },
//                 ),
//     );
//   }
// }

// void main() => runApp(MaterialApp(
//       home: LeaveApprovalPage(),
//     ));

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ooriba_s3/services/retrieveDataByEmployeeId.dart';
import '../services/leave_service.dart';
import '../apply_leave.dart'; // Import the ApplyLeavePage

class LeaveApprovalPage extends StatefulWidget {
  @override
  _LeaveApprovalPageState createState() => _LeaveApprovalPageState();
}

class _LeaveApprovalPageState extends State<LeaveApprovalPage> {
  final LeaveService _leaveService = LeaveService();
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = false;
  bool hasError = false;
  List<Map<String, dynamic>> leaveRequests = [];

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
      List<Map<String, dynamic>> requests =
          await _leaveService.fetchAllLeaveRequests();
      setState(() {
        leaveRequests = requests;
      });
    } catch (e) {
      setState(() {
        hasError = true;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatDate(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return '${_getOrdinal(dateTime.day)} ${DateFormat('MMMM yyyy').format(dateTime)}';
  }

  String _getOrdinal(int day) {
    if (day % 10 == 1 && day != 11) {
      return '${day}st';
    } else if (day % 10 == 2 && day != 12) {
      return '${day}nd';
    } else if (day % 10 == 3 && day != 13) {
      return '${day}rd';
    } else {
      return '${day}th';
    }
  }

  Future<Map<String, dynamic>> getEmployeeDetails(String employeeId) async {
    final FirestoreService firestoreService = FirestoreService();
    Map<String, dynamic>? employeeData =
        await firestoreService.getEmployeeById(employeeId);
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
      List<Map<String, dynamic>> requests =
          await _leaveService.fetchLeaveRequestsByEmployeeId(employeeId);
      setState(() {
        leaveRequests = requests;
      });
    } catch (e) {
      setState(() {
        hasError = true;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildLeaveRequestItem(Map<String, dynamic> leaveDetails) {
    String employeeId = leaveDetails['employeeId'] ?? 'Unknown';
    String leaveType = leaveDetails['leaveType'] ?? 'Unknown';
    String fromDate = leaveDetails['fromDate'] != null
        ? formatDate(leaveDetails['fromDate'] as Timestamp)
        : 'N/A';
    String toDate = leaveDetails['toDate'] != null
        ? formatDate(leaveDetails['toDate'] as Timestamp)
        : 'N/A';
    double numberOfDays = leaveDetails['numberOfDays'] ?? 0.0;
    String leaveReason = leaveDetails['leaveReason'] ?? 'No reason provided';

    return FutureBuilder<Map<String, dynamic>>(
      future: getEmployeeDetails(employeeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error fetching employee details');
        } else if (!snapshot.hasData || snapshot.data == null) {
          return Text('Employee data not found');
        } else {
          Map<String, dynamic> employeeData = snapshot.data!;
          String employeeName =
              '${employeeData['firstName']} ${employeeData['lastName']}';
          String employeeRole = employeeData['role'] ?? 'Role not specified';
          String employeeDepartment =
              employeeData['department'] ?? 'Department not specified';
          String employeeDp =
              employeeData['dpImageUrl'] ?? 'https://via.placeholder.com/150';

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
                        CircleAvatar(
                          backgroundImage: NetworkImage(employeeDp),
                          radius: 25.0,
                        ),
                        SizedBox(width: 8.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(employeeName,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.0)),
                              Text('$employeeId',
                                  style: TextStyle(fontSize: 12.0)),
                              Text(employeeRole,
                                  style: TextStyle(fontSize: 12.0)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$leaveType',
                                style: TextStyle(fontSize: 12.0)),
                            Text('$numberOfDays Days',
                                style: TextStyle(fontSize: 12.0)),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 8.0),
                    Text('$leaveReason',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12.0)),
                    Text('$fromDate - $toDate',
                        style: TextStyle(fontSize: 12.0)),
                    SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            String fromDateStr = DateFormat('yyyy-MM-dd')
                                .format((leaveDetails['fromDate'] as Timestamp)
                                    .toDate());
                            await _leaveService.updateLeaveStatus(
                                employeeId: employeeId,
                                fromDateStr: fromDateStr,
                                isApproved: true);
                            fetchAllLeaveRequests();
                          },
                          child:
                              Text('Approve', style: TextStyle(fontSize: 12.0)),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 4.0),
                            backgroundColor: Colors.green,
                          ),
                        ),
                        SizedBox(width: 8.0),
                        ElevatedButton(
                          onPressed: () async {
                            String fromDateStr = DateFormat('yyyy-MM-dd')
                                .format((leaveDetails['fromDate'] as Timestamp)
                                    .toDate());
                            await _leaveService.updateLeaveStatus(
                                employeeId: employeeId,
                                fromDateStr: fromDateStr,
                                isApproved: false);
                            fetchAllLeaveRequests();
                          },
                          child: Text('Deny', style: TextStyle(fontSize: 12.0)),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 4.0),
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
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
        title: Text('Leave Requests'),
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
                        itemCount: leaveRequests.length,
                        itemBuilder: (context, index) {
                          Map<String, dynamic> leaveDetails =
                              leaveRequests[index];
                          return buildLeaveRequestItem(leaveDetails);
                        },
                      ),
                    ),

                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ApplyLeavePage()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}