import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/authentication/register_user.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class UsersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Users'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No users found.'));
                }

                final users = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final userData = user.data() as Map<String, dynamic>;

                    return Dismissible(
                      key: Key(user.id), // Unique key for each item
                      background: Container(
                        color: Colors.red, // Background color when swiped
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Icon(Icons.delete, color: Colors.white),
                          ),
                        ),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) async {
                        // Remove user from Firestore
                        await FirebaseFirestore.instance.collection('users').doc(user.id).delete();

                        // Remove the user from Firebase Authentication
                        try {
                          await FirebaseAuth.instance
                              .signInWithEmailAndPassword(email: userData['email'], password: 'user_password') // Use the user's email and password
                              .then((value) {
                            value.user!.delete(); // Delete the user from Firebase Auth
                          });
                        } catch (e) {
                          // Handle any errors that occur during deletion
                          print('Error deleting user from Auth: $e');
                        }

                        // Show a snackbar to inform the user
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${userData['nickname']} removed')),
                        );
                      },
                      child: FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('clockRecords')
                            .where('userId', isEqualTo: user.id) // Match user ID
                            .where('clockIn', isGreaterThanOrEqualTo: DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          1,
                        )) // Get records from current month
                            .get(),
                        builder: (context, clockSnapshot) {
                          if (clockSnapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (clockSnapshot.hasError) {
                            return Center(child: Text('Error: ${clockSnapshot.error}'));
                          }

                          int workedDays = clockSnapshot.data?.docs.length ?? 0;
                          int totalDays = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day; // Total days in the current month

                          return Card(
                            margin: EdgeInsets.all(16.0),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userData['nickname'] ?? 'No nickname',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8.0),
                                  Text('Email: ${userData['email'] ?? 'No email'}'),
                                  Text('Phone: ${userData['phone'] ?? 'No phone'}'),
                                  Text('Address: ${userData['address'] ?? 'No address'}'),
                                  SizedBox(height: 16.0),
                                  Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularPercentIndicator(
                                          radius: 60.0,
                                          lineWidth: 8.0,
                                          percent: totalDays > 0 ? workedDays / totalDays : 0, // Prevent division by zero
                                          center: Text('$workedDays/$totalDays'),
                                          progressColor: Colors.green,
                                        ),
                                        SizedBox(height: 8.0),
                                        Text('Days Worked in ${DateTime.now().month}/${DateTime.now().year}'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to the user creation page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserRegistrationScreen()), // Replace with your actual page
                );
              },
              icon: Icon(Icons.add, size: 24), // Add icon
              label: Text('Add User'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Colors.blue, // Button color
                foregroundColor: Colors.white, // Change text color to white
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ),

        ],
      ),
    );
  }
}
