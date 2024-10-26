import 'dart:io';
import 'package:driver_app/mainScreens/create_task.dart';
import 'package:driver_app/mainScreens/drawer.dart';
import 'package:driver_app/mainScreens/edit_task.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class TaskDisplayPage extends StatefulWidget {
  @override
  _TaskDisplayPageState createState() => _TaskDisplayPageState();
}

class _TaskDisplayPageState extends State<TaskDisplayPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tasks'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'New'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      drawer: CustomDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          TaskListView(status: 'New'),
          TaskListView(status: 'Completed'),
        ],
      ),

    );
  }
}

class TaskListView extends StatefulWidget {
  final String status;

  TaskListView({required this.status});

  @override
  _TaskListViewState createState() => _TaskListViewState();
}
class _TaskListViewState extends State<TaskListView> {
  String searchQuery = '';
  double uploadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              labelText: 'Search Tasks',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tasks')
                .where('status', isEqualTo: widget.status)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No tasks found.'));
              }

              final tasks = snapshot.data!.docs
                  .where((task) =>
                  task['name'].toLowerCase().contains(searchQuery))
                  .toList();

              return ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final date = (task['created_at'] as Timestamp).toDate();
                  final formattedDate =
                      '${date.day}/${date.month}/${date.year}';

                  IconData icon;
                  switch (task['status']) {
                    case 'New':
                      icon = Icons.fiber_new;
                      break;
                    case 'Completed':
                      icon = Icons.check_circle;
                      break;
                    default:
                      icon = Icons.task;
                  }

                  return Dismissible(
                    key: Key(task.id), // Unique key for each task
                    background: Container(
                      color: Colors.green,
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Icon(Icons.phone, color: Colors.white),
                    ),
                    direction: DismissDirection.startToEnd,
                    onDismissed: (direction) {
                      // Launch the call
                      _makePhoneCall(task['phone']);
                    },
                    child: ListTile(
                      leading: Icon(icon),
                      title: Text(task['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(task['address']),
                          Text(formattedDate),
                        ],
                      ),
                      onTap: () => _showBottomSheet(context, task),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunch(launchUri.toString())) {
      await launch(launchUri.toString());
    } else {
      throw 'Could not launch $launchUri';
    }
  }



  void _showBottomSheet(BuildContext context, QueryDocumentSnapshot task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                task['name'],
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 10),
              _displayUploadedDocuments(task),
              SizedBox(height: 10),
              // Upload Document Button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextButton(
                  onPressed: () => _uploadDocumentAndAddToCollection(task),
                  child: Text('Upload Document'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.secondary, // Use secondary color for the text
                    textStyle: TextStyle(
                      fontWeight: FontWeight.bold, // Make the text bold if desired
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0), // Add padding for a button-like feel
                    // You can add more style properties if needed, like background color, etc.
                  ),
                ),
              ),


              // Mark as Completed / Mark as New
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextButton(
                  onPressed: () {
                    _updateTaskStatus(task.id, task['status'] == 'New' ? 'Completed' : 'New');
                    Navigator.of(context).pop();
                  },
                  child: Text(task['status'] == 'New' ? 'Mark as Completed' : 'Mark as New'),
                ),
              ),

              // Edit Task
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditTaskPage(
                          taskId: task.id,
                          currentName: task['name'],
                          currentAddress: task['address'],
                          currentPhone: task['phone'] ?? '',
                          currentEmail: task['email'] ?? '',
                          currentDescription: task['description'] ?? '',
                          createdAt: task['created_at'],
                        ),
                      ),
                    );
                  },
                  child: Text('Edit Task'),
                ),
              ),



              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
              ),

              // Cancel Button
            ],
          ),
        );
      },
    );
  }

  Widget _displayUploadedDocuments(QueryDocumentSnapshot task) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('documents')
          .where('docId', isEqualTo: task.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }
        if (snapshot.data!.docs.isEmpty) {
          return Text('No documents uploaded.');
        }

        return ListView(
          shrinkWrap: true,
          children: snapshot.data!.docs.map((doc) {
            return Dismissible(
              key: Key(doc.id), // Unique key for each document
              direction: DismissDirection.endToStart, // Swipe from right to left
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Icon(Icons.delete, color: Colors.white), // Delete icon
              ),
              onDismissed: (direction) {
                // Call the function to delete the document
                _deleteDocument(doc.id);
                // Show a snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Document deleted')),
                );
              },
              child: ListTile(
                title: Text('Document ID: ${doc.id}'),
                trailing: IconButton(
                  icon: Icon(Icons.open_in_new),
                  onPressed: () async {
                    final url = doc['documentUrl'];
                    if (await canLaunch(url)) {
                      await launch(url);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not open document.')),
                      );
                    }
                  },
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

// Function to delete the document
  void _deleteDocument(String docId) {
    FirebaseFirestore.instance.collection('documents').doc(docId).delete().then((_) {
      print('Document deleted: $docId');
    }).catchError((error) {
      print('Failed to delete document: $error');
    });
  }

  void _uploadDocumentAndAddToCollection(QueryDocumentSnapshot task) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.isNotEmpty) {
      String filePath = result.files.single.path!;
      String fileName = result.files.single.name;

      try {
        Reference ref = FirebaseStorage.instance.ref('task_documents/$fileName');
        UploadTask uploadTask = ref.putFile(File(filePath));

        uploadTask.snapshotEvents.listen((event) {
          setState(() {
            uploadProgress =
                event.bytesTransferred.toDouble() / event.totalBytes.toDouble();
          });
        });

        String downloadUrl = await (await uploadTask).ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('documents').add({
          'taskName': task['name'],
          'date': (task['created_at'] as Timestamp).toDate(),
          'phone': task['phone'] ?? 'N/A',
          'docId': task.id,
          'documentUrl': downloadUrl,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document uploaded successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading document: $e')),
        );
      }
    }
  }

  void _updateTaskStatus(String taskId, String newStatus) {
    FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'status': newStatus,
    }).then((_) {
      print('Task updated to $newStatus');
    }).catchError((error) {
      print('Failed to update task: $error');
    });
  }
}
