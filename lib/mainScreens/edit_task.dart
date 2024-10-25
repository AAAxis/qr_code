import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditTaskPage extends StatefulWidget {
  final String taskId;
  final String currentName;
  final String currentPhone;
  final String currentEmail;
  final String currentDescription;
  final Timestamp createdAt;
  final String currentAddress;

  EditTaskPage({
    required this.taskId,
    required this.currentName,
    required this.currentPhone,
    required this.currentEmail,
    required this.currentDescription,
    required this.createdAt,
    required this.currentAddress,
  });

  @override
  _EditTaskPageState createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName;
    _phoneController.text = widget.currentPhone;
    _emailController.text = widget.currentEmail;
    _descriptionController.text = widget.currentDescription;
    _addressController.text = widget.currentAddress;
  }

  void _updateTask() {
    FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).update({
      'name': _nameController.text,
      'phone': _phoneController.text,
      'email': _emailController.text,
      'description': _descriptionController.text,
      'address': _addressController.text,
      'created_at': widget.createdAt,
    }).then((_) {
      Navigator.pop(context);
    }).catchError((error) {
      print('Failed to update task: $error');
    });
  }

  void _deleteTask() {
    FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).delete().then((_) {
      Navigator.pop(context); // Go back after deletion
    }).catchError((error) {
      print('Failed to delete task: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(widget.createdAt.toDate());

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Task', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        color: Colors.grey[100],
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              Text(
                'Created At: $formattedDate',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 26),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Task Name',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.task, color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.phone, color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.email, color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.location_on, color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.black),
                  prefixIcon: Icon(Icons.description, color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _updateTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text('Save', style: TextStyle(fontSize: 16)),
                  ),
                  ElevatedButton(
                    onPressed: _deleteTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent, // Set delete button color to red
                      foregroundColor: Colors.white, // Set text color to white
                      padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0), // Rounded corners
                      ),
                    ),
                    child: Text('Delete', style: TextStyle(fontSize: 16)),
                  ),

                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
