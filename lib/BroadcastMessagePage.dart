import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'services/broadcast_service.dart'; // Replace with the actual path

class BroadcastMessagePage extends StatefulWidget {
  @override
  _BroadcastMessagePageState createState() => _BroadcastMessagePageState();
}

class _BroadcastMessagePageState extends State<BroadcastMessagePage> {
  final TextEditingController _broadcastMessageController = TextEditingController();
  final BroadcastService _broadcastService = BroadcastService();

  Future<void> _sendBroadcastMessage() async {
    String message = _broadcastMessageController.text;
    await _broadcastService.sendBroadcastMessage(message);

    _broadcastMessageController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Broadcast message sent')),
    );
  }

  Future<void> _editBroadcastMessage(String id, String newMessage) async {
    await _broadcastService.editBroadcastMessage(id, newMessage);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Broadcast message updated')),
    );
  }

  Future<void> _deleteBroadcastMessage(String id) async {
    await _broadcastService.deleteBroadcastMessage(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Broadcast message deleted')),
    );
  }

  void _showEditDialog(String id, String currentMessage) {
    TextEditingController _editController = TextEditingController(text: currentMessage);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Broadcast Message'),
          content: TextField(
            controller: _editController,
            decoration: const InputDecoration(labelText: 'Message'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () async {
                await _editBroadcastMessage(id, _editController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Broadcast Message'),
          content: const Text('Are you sure you want to delete this message?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Delete'),
              onPressed: () async {
                await _deleteBroadcastMessage(id);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _showEditDialog(messages[index].id, message);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                _showDeleteConfirmationDialog(messages[index].id);
                              },
                            ),
                          ],
                        ),
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
