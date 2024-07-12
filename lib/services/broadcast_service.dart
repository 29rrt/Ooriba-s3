//get the original code form git without firebase messaging .


import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

class BroadcastService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> sendBroadcastMessage(String message) async {
    // Send broadcast message to Firestore
    await _firestore.collection('BroadcastMessages').add({
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('CurrentBroadcast').doc('current').set({
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Send notification to all users
    await sendNotificationToUsers(message);
  }

  Future<void> sendNotificationToUsers(String message) async {
    // Assuming you have a topic "all_users" to which all users are subscribed
    const String topic = 'all_users';

    final tokenResponse = await _firestore.collection('FCMTokens').get();
    List<String> tokens = tokenResponse.docs.map((doc) => doc.data()['token'] as String).toList();

    // Subscribe all users to the topic (optional, if not already subscribed)
    await _firebaseMessaging.subscribeToTopic(topic);

    // Construct the notification payload
    var notification = {
      'title': 'Broadcast Message',
      'body': message,
      'topic': topic,
    };

    // Send notification using FCM server API
    var httpResponse = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=BFjEScs2uoDCURSUfj4pOqbCak-Vq-x8HvKiAJFgSITabjcV5TcQfaLADm5n4w8S5I4gMC8NlL-Cu7mEqywkAH0', // Replace with your server key from Firebase Console
      },
      body: jsonEncode(<String, dynamic>{
        'notification': notification,
        'to': '/topics/$topic',
      }),
    );

    if (httpResponse.statusCode == 200) {
      print('Notification sent successfully');
    } else {
      print('Failed to send notification. Error: ${httpResponse.reasonPhrase}');
    }
  }

  editBroadcastMessage(String id, String newMessage) {}

  deleteBroadcastMessage(String id) {}

  // Other methods like editBroadcastMessage, deleteBroadcastMessage, etc.
}
