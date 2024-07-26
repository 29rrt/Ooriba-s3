import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ooriba_s3/services/admin/broadcast_service.dart'; // Replace with the actual path

class BroadcastMessagePage extends StatefulWidget {
  @override
  _BroadcastMessagePageState createState() => _BroadcastMessagePageState();
}

class _BroadcastMessagePageState extends State<BroadcastMessagePage> {
  final TextEditingController _broadcastMessageController = TextEditingController();
  final BroadcastService _broadcastService = BroadcastService();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
   List<String> _locations = [];
  String? _selectedLocation;



  @override
  void initState() {
    super.initState();
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    flutterLocalNotificationsPlugin.initialize(initializationSettings);
     _loadLocations();
       _listenForBroadcastMessages();
  }

  Future<void> _loadLocations() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('Location').get();
    setState(() {
      _locations = querySnapshot.docs.map((doc) => doc.id).toList();
       _locations.insert(0, 'All Locations'); // Add the option for all locations
      if (_locations.isNotEmpty) {
        _selectedLocation = _locations[0];
      }
    });
  }

  Future<void> _sendBroadcastMessage() async {
    String message = _broadcastMessageController.text;
    String location = _selectedLocation ?? 'Unknown location';
    String broadcastMessage = location == 'All Locations' ? message : '[$location] $message';

    await FirebaseFirestore.instance.collection('BroadcastMessages').add({
      'message': broadcastMessage,
      'timestamp': FieldValue.serverTimestamp(),
      'location': location,
    });

    _broadcastMessageController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Broadcast message sent')),
    );

    

    // Send notification
    await _sendNotification(message);
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Broadcast Message'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Broadcast Message',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
             DropdownButton<String>(
              value: _selectedLocation,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedLocation = newValue;
                });
              },
              items: _locations.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            TextField(
              controller: _broadcastMessageController,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await _sendBroadcastMessage();
              },
              child: const Text('Send Message'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sent Messages',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('BroadcastMessages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var messageData = messages[index].data() as Map<String, dynamic>;
                      var timestamp = (messageData['timestamp'] as Timestamp?)?.toDate();
                      var formattedTime = timestamp != null
                          ? '${timestamp.toLocal().toString().split(' ')[0]} ${timestamp.toLocal().toString().split(' ')[1].split('.')[0]}'
                          : 'No timestamp';
                      var message = messageData['message'];

                      return ListTile(
                        title: Text(message),
                        subtitle: Text(formattedTime),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}