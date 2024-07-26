import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:ooriba_s3/Admin/BroadcastMessagePage.dart';
import 'package:ooriba_s3/facial/DB/DatabaseHelper.dart';
import 'package:ooriba_s3/facial/RecognitionScreen.dart';
import 'package:ooriba_s3/facial/RegistrationScreen.dart';
import 'package:ooriba_s3/leave.dart';
import 'package:ooriba_s3/services/admin/broadcast_service.dart';
import 'package:ooriba_s3/services/auth_service.dart';
import 'package:ooriba_s3/services/geo_service.dart';
import 'package:ooriba_s3/services/retrieveDataByEmail.dart'
    as retrieveDataByEmail;
import 'package:ooriba_s3/services/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ooriba_s3/services/employee_location_service.dart';

class PostLoginPage extends StatefulWidget {
  final String phoneNumber;
  final Map<String, dynamic> userDetails;

   PostLoginPage(
      {super.key, required this.phoneNumber, required this.userDetails});

  @override
  _PostLoginPageState createState() => _PostLoginPageState();
}

class _PostLoginPageState extends State<PostLoginPage> {
  bool isPresent = false;
  String? employeeId;
  String? employeeName;
  String? employeePhoneNumber;
  String? dpImageUrl;
  String? employeeType;
  DateTime? lastLoginTime;
  final UserFirestoreService firestoreService = UserFirestoreService();
  late DatabaseHelper dbHelper;
  bool isRegistered = false;
  DateTime? checkInTime;
  DateTime? checkOutTime;
  bool isLoading = true;
  bool isCheckedIn = false;
  final GeoService geoService = GeoService();
  bool isWithinRange = false;
  bool isLoadingForLocation = false;
  final EmployeeLocationService employeeLocationService =
      EmployeeLocationService();
  Timer? _autoCheckOutTimer;
  final BroadcastService _broadcastService = BroadcastService();
  String? broadcastMessage;
   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper();
    fetchEmployeeData();
    _checkIfFaceIsRegistered();
    _checkLocation();
    _loadLocalCheckInCheckOutTimes();
    _initializeNotifications();
    _listenForBroadcastMessages();
  }

   void _initializeNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _listenForBroadcastMessages() {
    FirebaseFirestore.instance
        .collection('BroadcastMessages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docChanges) {
        if (doc.type == DocumentChangeType.added) {
          var messageData = doc.doc.data() as Map<String, dynamic>;
          String message = messageData['message'];
          _sendNotification(message);
        }
      }
    });
  }

  Future<void> _sendNotification(String message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'OORIBA', 'Broadcasts',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      'New Global Communication',
      message,
      platformChannelSpecifics,
      payload: 'Broadcast Notification',
    );
  }

  @override
  void dispose() {
    _autoCheckOutTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchMessage() async {
    String? message = await _broadcastService.getCurrentBroadcastMessage();
    setState(() {
      message != null
          ? broadcastMessage = message
          : broadcastMessage = "No Message";
      isLoading = false;
    });
  }

  Future<void> _loadLocalCheckInCheckOutTimes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      checkInTime = prefs.containsKey('checkInTime')
          ? DateTime.parse(prefs.getString('checkInTime')!)
          : null;
      checkOutTime = prefs.containsKey('checkOutTime')
          ? DateTime.parse(prefs.getString('checkOutTime')!)
          : null;
    });
    print('Loaded check-in time: $checkInTime');
    print('Loaded check-out time: $checkOutTime');
  }

  Future<void> _saveLocalCheckInTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('checkInTime', time.toIso8601String());
    print('Saved check-in time: $time');
  }

  Future<void> _saveLocalCheckOutTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('checkOutTime', time.toIso8601String());
    print('Saved check-out time: $time');
  }

  Future<void> _clearLocalCheckInCheckOutTimes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('checkInTime');
    await prefs.remove('checkOutTime');
    print('Cleared local check-in and check-out times');
  }

  Future<void> fetchEmployeeData() async {
    await _fetchEmployeeDetails(widget.phoneNumber);
    await _fetchCheckInStatus(widget.phoneNumber);
    await _fetchLastLoginTime(widget.phoneNumber);
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _checkIfFaceIsRegistered() async {
    await dbHelper.init();
    final allRows = await dbHelper.queryAllRows();
    setState(() {
      isRegistered = allRows.isNotEmpty;
    });
  }

  void _checkLocation() async {
    setState(() {
      isLoading = true;
    });

    try {
      Position position = await geoService.determinePosition();
      bool withinRange = await geoService.isWithin50m(position);

      setState(() {
        isWithinRange = withinRange;
        isLoading = false;
      });

      Fluttertoast.showToast(

        msg:employeeType != "Off-site"? (isWithinRange
            ? "You are within the location"
            : "You are away from the location"):"",
      );
    } catch (e) {
      print(e);
      Fluttertoast.showToast(msg: 'Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatTime(DateTime? time) {
    if (time == null) return " ";
    // return "${time.hour}:${time.minute.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}";
    return DateFormat.jm().format(time);
  }

  Future<void> _fetchEmployeeDetails(String phoneNumber) async {
    retrieveDataByEmail.FirestoreService firestoreService =
        retrieveDataByEmail.FirestoreService();
    Map<String, dynamic>? employeeData = await firestoreService
        .getEmployeeByEmailOrPhoneNo(phoneNumber, "Regemp");

    if (employeeData != null) {
      setState(() {
        employeeId = employeeData['employeeId'];
        employeeName = employeeData['firstName'];
        employeePhoneNumber = employeeData['phoneNo'];
        dpImageUrl = employeeData['dpImageUrl'];
        employeeType = employeeData['employeeType'];
      });
    } else {
      print(
          'Employee details not found for email or Phone Number: $phoneNumber');
    }
  }

  Future<void> _fetchCheckInStatus(String phoneNumber) async {
    UserFirestoreService firestoreService = UserFirestoreService();
    DateTime today = DateTime.now();
    String todayDate = DateFormat('yyyy-MM-dd').format(today);

    try {
      DocumentSnapshot docSnapshot =
          await firestoreService.getCheckInOutData(employeeId!, todayDate);

      if (docSnapshot.exists) {
        Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
        Map<String, dynamic>? employeeData = data[employeeId];

        if (employeeData != null) {
          setState(() {
            isCheckedIn = employeeData['checkIn'] != null &&
                employeeData['checkOut'] == null;
            checkInTime = employeeData['checkIn']?.toDate();
            checkOutTime = employeeData['checkOut']?.toDate();
            isPresent = true;
          });
        }
      } else {
        print('Check-in data not found for date: $todayDate');
      }
    } catch (e) {
      print('Error fetching check-in status: $e');
    }
  }

  Future<void> _fetchLastLoginTime(String phoneNumber) async {
    try {
      DocumentSnapshot docSnapshot =
          await firestoreService.getLastLoginTime(phoneNumber);

      if (docSnapshot.exists) {
        Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
        var lastLoginTimestamp = data['lastLoginTime'];

        if (lastLoginTimestamp != null) {
          setState(() {
            lastLoginTime = (lastLoginTimestamp as Timestamp).toDate();
          });
        } else {
          print('Last login time is null for email: $phoneNumber');
          await _updateLastLoginTime(phoneNumber);
        }
      } else {
        print('Document not found for email: $phoneNumber');
        await _createAndSaveLastLoginTime(phoneNumber);
      }
    } catch (e) {
      print('Error fetching last login time: $e');
      if (e is FirebaseException && e.code == 'not-found') {
        await _createAndSaveLastLoginTime(phoneNumber);
      }
    }
  }

  Future<void> _createAndSaveLastLoginTime(String phoneNumber) async {
    DateTime now = DateTime.now();
    await firestoreService.createLastLoginTime(phoneNumber, now);
    setState(() {
      lastLoginTime = now;
    });
  }

  Future<void> _updateLastLoginTime(String phoneNumber) async {
    DateTime now = DateTime.now();
    await firestoreService.saveLastLoginTime(phoneNumber, now);
    setState(() {
      lastLoginTime = now;
    });
  }

  Future<void> _checkIn() async {
    DateTime now = DateTime.now();
    await firestoreService.addCheckInOutData(employeeId!, now, null, now);

    Position position =
        await geoService.determinePosition(); // Get current position
    await employeeLocationService.saveEmployeeLocation(
        employeeId!, position, now, 'check-in'); // Save location

    setState(() {
      isCheckedIn = true;
      checkInTime = now;
      isPresent = true;
      checkOutTime = null;
    });

    await _saveLocalCheckInTime(now);
    await _clearLocalCheckInCheckOutTimes();

    _autoCheckOutTimer = Timer(Duration(hours: 9), () {
      _checkOut();
    });
  }

  Future<void> _checkOut() async {
    DateTime now = DateTime.now();
    await firestoreService.addCheckInOutData(
        employeeId!, checkInTime!, now, now);

    Position position =
        await geoService.determinePosition(); // Get current position
    await employeeLocationService.saveEmployeeLocation(
        employeeId!, position, now, 'check-in'); // Save location

    setState(() {
      isCheckedIn = false;
      checkOutTime = now;
      isPresent = false;
    });

    await _saveLocalCheckOutTime(now);
    await _clearLocalCheckInCheckOutTimes();
  }

  Future<void> _saveLastLoginTime() async {
    DateTime now = DateTime.now();
    await firestoreService.saveLastLoginTime(widget.phoneNumber, now);
  }

  Future<String> getImageUrl(String employeeId) async {
    String imagePath = 'authImage/$employeeId.jpg';
    try {
      final ref = FirebaseStorage.instance.ref().child(imagePath);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Error fetching image for $employeeId: $e');
      return '';
    }
  }

  String formatTimeWithoutSeconds(DateTime? dateTime) {
    if (dateTime == null) {
      return 'N/a';
    }
    // return DateFormat('dd-MM-yyyy   HH:mm').format(dateTime);
    return DateFormat.yMMMMd('en_US').add_Hm().format(dateTime);
  }

  void navigateToFaceRecognitionScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              RecognitionScreen(phoneNumber: widget.phoneNumber)),
    );

    if (result == true) {
      if (isCheckedIn) {
        _checkOut();
      } else {
        _checkIn();
      }
    }
  }

//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           children: [
//             if (dpImageUrl != null)
//               CircleAvatar(
//                 backgroundImage: NetworkImage(dpImageUrl!),
//               ),
//             SizedBox(width: 8),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(employeeName != null
//                     ? 'Welcome, $employeeName-$employeeId'
//                     : "Loading"),
//                 if (lastLoginTime != null)
//                   Text(
//                     'Last login: ${formatTimeWithoutSeconds(lastLoginTime)}',
//                     style: TextStyle(fontSize: 14),
//                   ),
//               ],
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: () async {
//               await _saveLastLoginTime();
//               await AuthService().signout(context: context);
//             },
//           ),
//         ],
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Column(
//                 children: [
//                   Center(
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [

//                         ElevatedButton(
//                           onPressed: () {
//                             if (isRegistered) {
//                               if (isWithinRange) {
//                                 navigateToFaceRecognitionScreen();
//                               }
//                             } else {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) =>
//                                       const RegistrationScreen(),
//                                 ),
//                               );
//                             }
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: isRegistered
//                                 ? (isCheckedIn ? Colors.green : Colors.orange)
//                                 : null,
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 20, vertical: 15),
//                           ),
//                           child: Text(isRegistered
//                               ? (isCheckedIn ? 'Check-out' : 'Check-in')
//                               : 'Register'),
//                         ),

//                         SizedBox(width: 20),
//                         isPresent
//                             ? FutureBuilder<String>(
//                                 future: getImageUrl(employeeId!),
//                                 builder: (context, snapshot) {
//                                   if (snapshot.connectionState ==
//                                       ConnectionState.waiting) {
//                                     return const CircularProgressIndicator();
//                                   } else if (snapshot.hasError ||
//                                       !snapshot.hasData ||
//                                       snapshot.data!.isEmpty) {
//                                     return const Text('No image');
//                                   } else {
//                                     return InkWell(
//                                       onTap: () {
//                                         showDialog(
//                                           context: context,
//                                           builder: (context) => AlertDialog(
//                                             content:
//                                                 Image.network(snapshot.data!),
//                                             actions: <Widget>[
//                                               TextButton(
//                                                 child: const Text('Close'),
//                                                 onPressed: () {
//                                                   Navigator.of(context).pop();
//                                                 },
//                                               ),
//                                             ],
//                                           ),
//                                         );
//                                       },
//                                       child: Image.network(
//                                         snapshot.data!,
//                                         width: 60,
//                                         height: 60,
//                                         fit: BoxFit.fill,
//                                       ),
//                                     );
//                                   }
//                                 },
//                               )
//                             : const Icon(Icons.no_accounts, size: 60),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 20),

//                   Row(
//                     mainAxisAlignment:
//                         MainAxisAlignment.spaceEvenly, // Adjust as needed
//                     children: [
//                       Expanded(
//                         child: SizedBox(
//                           height: 70, // Adjust the height as needed
//                           child: Card(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 const Text('Last Check-in',
//                                     style:
//                                         TextStyle(fontWeight: FontWeight.bold)),
//                                 Text(formatTime(checkInTime)),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 10), // Adjust spacing between cards
//                       Expanded(
//                         child: SizedBox(
//                           height: 70, // Adjust the height as needed
//                           child: Card(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 const Text('Last Check-out',
//                                     style:
//                                         TextStyle(fontWeight: FontWeight.bold)),
//                                 Text(formatTime(checkOutTime)),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   Expanded(
//                     child: ListView(
//                       children: const [
//                         Card(
//                           child: ListTile(
//                             leading: Icon(Icons.calendar_today),
//                             title: Text('Upcoming Events'),
//                             subtitle: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text('Project Deadline: 10th July 2024'),
//                                 Text('Client Meeting: 15th July 2024'),
//                               ],
//                             ),
//                           ),
//                         ),
//                         Card(
//                           child: ListTile(
//                             leading: Icon(Icons.history),
//                             title: Text('Recent Activities'),
//                             subtitle: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text('Meeting with team at 11:00 AM'),
//                                 Text('Submitted report at 2:00 PM'),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (dpImageUrl != null)
              CircleAvatar(
                backgroundImage: NetworkImage(dpImageUrl!),
              ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employeeName != null
                        ? 'Welcome, $employeeName-$employeeId'
                        : "Loading",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                  ),
                  if (lastLoginTime != null)
                    Text(
                      'Last login: ${formatTimeWithoutSeconds(lastLoginTime)}',
                      style: TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      softWrap: false,
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _saveLastLoginTime();
              await AuthService().signout(context: context);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Dashboard'),
              onTap: () {
                // Navigator.pop(context);
                // navigateToDashboard();
              },
            ),
            ListTile(
              leading: Icon(Icons.leave_bags_at_home),
              title: Text('Apply Leave'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => LeavePage(employeeId: employeeId)),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Personal Information'),
              onTap: () {
                // Navigator.pop(context);
                // navigateToPersonalInformation();
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Logout'),
              onTap: () async {
                await AuthService().signout(context: context);
              },
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            if (isRegistered) {
                              if (employeeType == "Off-site" ||
                                  (employeeType == "On-site" &&
                                      isWithinRange)) {
                                navigateToFaceRecognitionScreen();
                              }
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const RegistrationScreen(),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isRegistered
                                ? (isWithinRange ||employeeType == "Off-site"?(isCheckedIn ? Colors.green : Colors.orange):null)
                                : null,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                          ),
                          child: Text(isRegistered
                              ? (isCheckedIn ? 'Check-out' : 'Check-in')
                              : 'Register'),
                        ),
                        SizedBox(width: 20),
                        isPresent
                            ? FutureBuilder<String>(
                                future: getImageUrl(employeeId!),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const CircularProgressIndicator();
                                  } else if (snapshot.hasError ||
                                      !snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return const Text('No image');
                                  } else {
                                    return InkWell(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            content:
                                                Image.network(snapshot.data!),
                                            actions: <Widget>[
                                              TextButton(
                                                child: const Text('Close'),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: Image.network(
                                        snapshot.data!,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.fill,
                                      ),
                                    );
                                  }
                                },
                              )
                            : const Icon(Icons.no_accounts, size: 60),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 70,
                          child: Card(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Last Check-in',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text(formatTime(checkInTime)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 70,
                          child: Card(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Last Check-out',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text(formatTime(checkOutTime)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),
                  Expanded(
                    child: ListView(
                      children: [
                        Divider(
                          color: Colors.blue,
                          thickness: 2.0,
                        ),
                        Card(
                          elevation: 5,
                          // color: Color.fromARGB(255, 222, 200, 174),
                          color: Color.fromARGB(255, 255, 255, 255),
                          child: ListTile(
                            leading: Icon(Icons.calendar_today),
                            title: Text(
                              'Upcoming Events',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Weekly Meeting at: 3 PM'),
                                Text('Holiday: 20th July 2024'),
                              ],
                            ),
                          ),
                        ),
                        Card(
                          elevation: 5,
                          // color: Color.fromARGB(255, 222, 200, 174),
                          color: Color.fromARGB(255, 255, 255, 255),

                          child: ListTile(
                            leading: Icon(Icons.message),
                            title: const Text(
                              'Global Communication',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 25),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(broadcastMessage!),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}