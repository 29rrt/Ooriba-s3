import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RejectedEmployeesPage extends StatelessWidget {
  const RejectedEmployeesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rejected Employees'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('RejectedEmp').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.requireData;
          return ListView.builder(
            itemCount: data.size,
            itemBuilder: (context, index) {
              final doc = data.docs[index];
              final firstName = doc['firstName'];
              final lastName = doc['lastName'];
              final phone = doc['phoneNo'];
              final email = doc.id; // Assuming document ID is the email
              final reason = doc['reason']; // Fetch the reason field

              return RejectedEmployeeCard(
                firstName: firstName,
                lastName: lastName,
                phone: phone,
                email: email,
                reason: reason, // Pass the reason to the card
              );
            },
          );
        },
      ),
    );
  }
}

class RejectedEmployeeCard extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String reason;

  const RejectedEmployeeCard({
    Key? key,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.reason, // Add reason parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple[100],
          child: Text(
            firstName[0],
            style: const TextStyle(color: Colors.black),
          ),
        ),
        title: Text('$firstName $lastName'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phone: $phone'),
            Text('Email: $email'),
            Text('Reason: $reason'), // Display the reason field
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            // Add your onPressed code here!
          },
          child: const Text('View More'),
        ),
      ),
    );
  }
}