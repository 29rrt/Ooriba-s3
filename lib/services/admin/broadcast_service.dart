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
    await sendNotification(message);
  }

  Future<void> sendNotification(String message) async {
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
        'Authorization': 'MIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQC4y9+B/r1rIALO\n3MVaRWZ2UlYFaN1kv9Kj+rFgq0lbnQC2XqPk+uSLLETnsgITcKWnTJfCJCd3LtcJ\niK1/bQ2QYv7dLlqSA6WM9Rr7xQfuXz8aDUhtnhKGMSikrYZqTKfWLlqF4o/rUjGt\nXkOil0ia/YrZe6HrVV6pDm6A8RZB8kPghdIfFtmWQloovTVI0w48hyHyWyX0O6yS\nGKjZ2gjy9yByuZm2qaheNFM+6AMz5goG9aGPYdN5nuGVxrb0X2lrNG8I2IZ104fl\naCLaagDdF7QpWnw7A9o6WfXoDyx4t4FTl5KWeIzd0CleWHu+k28jSXI9PTvXJ9O1\nSuIYBzDvAgMBAAECggEACWMJwm+vLX7dxaY/PBukXcRG7FVsUY7Q41V7px5sRoQO\nIjVie+Ims88W3PIU2unw8DOazdjKTGqLr8dKkNt4QepVaeTN4vbedO+KZFmY0ony\nCZ+9GxxZcomSt/K8ji/AoseN/5kHmHt/XIAaTWsD3COe5vc5vVuDyHCcOl6Es+rF\nUL6wsmNfVzYZ1CHd1GUC/sXwz1cafBH2sFQxpI8aw8iNSqnxvkGnsOALcATUuDdL\ncF6/XkNJLWnS1s8hmLi3J30fr1xiMbSYhnLJzyke3c2jwg4zU/2I1DG/+UA9nPW+\nwMxmgykhvEN73d1faeerufAHDeugIt8lUwe6WutAeQKBgQDqrxNPhRCbY1hA9cQb\nTJWj5qoImuvqRPD9UtnMENIFa7kAvTkYLHR6sNCv8vGqlC1ByKhR6Q4DZuo1usam\nNrPGud1Od60KTpkzHKbNcLyT2n3ofnXHcX1i9ds16p9cRvWVlZbTr7EpVyBnyCqb\n+/Bsvk4awoB8LRQ9w3g0QYICTQKBgQDJlM032U7HzhCLm7v4DWaakXdQw8sQry4s\nVz9Tdf+vBhpvvsnqCA/2f87P+IFTFWCubkXy6FWMMYrlLJfpYSLDXAlx49UBuL0e\nzAmtPIrlSZ4PDiynsxS+ps5AabII2q3fPhtAlq0sgyHdoNmR/jpMyW6dihCkZ04+\nza0Lmy8GKwKBgQDfdSiL9QWlD2j/IYRDAh8R2xZX7ztm65ITg4oCNpnjs3iKbaIp\nlFqsYCO1BTx60XBuTOOIasJ/FsU3t8pihX+UX3GLv4QyZjiVZFinEQteNRLiB1ea\nOkPLsJGzut1WffJlJfRhR88GsAEZEI0RzUhWIrY34K96jWnSjYatKxrhmQKBgQCS\nKF/7pIZofNKmRw6tNho07FAUsUHlIP9biw8RVrdCkixM5YrFM39PfS/YvxgVw6RM\nFQyGqUqN0cYhkIm8338zIuJ+P3FMRERrtgk2IHWc9hmyVNav6TqbWZqmPXymytfS\ny9c6p4V8hr/hUCUwo6Jl1o9rjpWufnDPPJXBmo0n7QKBgQCTpm/tIcWhYLJG7h/4\n3yb4ulRIJfxR5UlvP2RMXNiJ3EzL72mKIt+0Xjxr3KH6ojVCxF7NCYeNfiG9bvcT\ny7klQcNDsYOxiDN9gfPXecZSvP2ouNInTemnwLGHG/jHFfPzMxmZVGjRul6H7WfF\ncDovySFPfHD7W8BPkP7eiok+tw==', // Replace with your server key from Firebase Console
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

  Future<String?> getCurrentBroadcastMessage() async {
    try {
      DocumentSnapshot doc = await _firestore.collection('CurrentBroadcast').doc('current').get();
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['message'] as String?;
      }
    } catch (e) {
      print('Error fetching broadcast message: $e');
    }
    return null;
  }
}








// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class BroadcastService {
//   final String serverKey = 'YOUR_SERVER_KEY_HERE';

//   Future<void> sendNotification(String topic, String message) async {
//     final url = Uri.parse('https://fcm.googleapis.com/fcm/send');
//     final headers = {
//       'Content-Type': 'application/json',
//       'Authorization': 'key=$serverKey',
//     };
//     final body = json.encode({
//       'to': '/topics/$topic',
//       'notification': {
//         'title': 'New Broadcast Message',
//         'body': message,
//       },
//     });

//     final response = await http.post(url, headers: headers, body: body);
//     if (response.statusCode == 200) {
//       print('Notification sent successfully');
//     } else {
//       print('Failed to send notification');
//     }
//   }
// }
