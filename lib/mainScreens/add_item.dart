import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddItemsScreen extends StatefulWidget {
  @override
  _AddItemsScreenState createState() => _AddItemsScreenState();
}

class _AddItemsScreenState extends State<AddItemsScreen> {
  final _formKey = GlobalKey<FormState>();
  String? status;
  DateTime? purchaseDate;
  DateTime? warrantyDate;
  String? itemId;
  String? type;

  // List of status options
  final List<String> statusOptions = ['Repair', 'Broken', 'Storage'];

  @override
  void initState() {
    super.initState();
    // Preselect 'Storage' as the default status
    status = 'Storage';
  }

  // Method to show date picker
  Future<void> _selectDate(BuildContext context, bool isPurchaseDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != (isPurchaseDate ? purchaseDate : warrantyDate)) {
      setState(() {
        if (isPurchaseDate) {
          purchaseDate = picked;
        } else {
          warrantyDate = picked;
        }
      });
    }
  }

  // Method to handle form submission
  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      // Create a new item map
      final newItem = {
        'status': status,
        'itemId': itemId,
        'type': type,
        'purchaseDate': purchaseDate != null ? Timestamp.fromDate(purchaseDate!) : null,
        'warrantyDate': warrantyDate != null ? Timestamp.fromDate(warrantyDate!) : null,
      };

      try {
        // Save to Firestore (replace 'items' with your actual collection name)
        await FirebaseFirestore.instance.collection('items').add(newItem);

        // Show a success message using SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item added successfully! Item ID: $itemId'),
            duration: Duration(seconds: 2), // Duration for the SnackBar
          ),
        );

        Navigator.pop(context); // Go back after submission
      } catch (e) {
        // Handle error here (e.g., show a dialog or snackbar)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add item: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Device'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Status Dropdown
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Status',
                  icon: Icon(Icons.store_mall_directory_rounded), // Status icon
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: status, // Preselected status
                    isExpanded: true,
                    items: statusOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        status = newValue;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 16.0),

              // Item ID Input
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'ID',
                  icon: Icon(Icons.numbers), // Item ID icon
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter item ID';
                  }
                  return null;
                },
                onSaved: (value) => itemId = value,
              ),
              SizedBox(height: 16.0),

              // Type Input
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Type',
                  icon: Icon(Icons.category), // Type icon
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter type';
                  }
                  return null;
                },
                onSaved: (value) => type = value,
              ),
              SizedBox(height: 16.0),

              // Purchase Date Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Purchase Date: ${purchaseDate != null ? DateFormat.yMd().format(purchaseDate!) : 'Not selected'}',
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.date_range), // Date icon
                    onPressed: () => _selectDate(context, true),
                  ),
                ],
              ),
              SizedBox(height: 16.0),

              // Warranty Date Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Warranty Date: ${warrantyDate != null ? DateFormat.yMd().format(warrantyDate!) : 'Not selected'}',
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.date_range), // Date icon
                    onPressed: () => _selectDate(context, false),
                  ),
                ],
              ),
              SizedBox(height: 20),

              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue, // Background color
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Optional padding
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min, // Adjusts the button to only take up necessary space
                  children: [
                    Icon(Icons.add), // Icon to display
                    SizedBox(width: 8), // Space between icon and text
                    Text('Add'), // Button text
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
