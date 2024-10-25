import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class Item {
  String id;
  String status;
  String type;
  String name;
  DateTime purchaseDate; // Existing property
  DateTime warrantyDate; // New property

  Item({
    required this.id,
    required this.status,
    required this.type,
    required this.purchaseDate,
    required this.name,
    required this.warrantyDate, // Initialize new property
  });

  // Format date as a string for display
  String get formattedPurchaseDate => DateFormat('yyyy-MM-dd').format(purchaseDate);
  String get formattedWarrantyDate => DateFormat('yyyy-MM-dd').format(warrantyDate); // Format warranty date
}


class ItemsUnderRepairScreen extends StatefulWidget {
  @override
  _ItemsUnderRepairScreenState createState() => _ItemsUnderRepairScreenState();
}

class _ItemsUnderRepairScreenState extends State<ItemsUnderRepairScreen> {
  List<Item> itemsUnderRepair = [];
  List<Item> filteredItems = [];
  final List<String> availableStatuses = [ 'Storage', 'Broken', 'Repair'];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchItems(); // Fetch items from Firestore when screen initializes
  }

  Future<void> fetchItems() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('items').get();

    setState(() {
      itemsUnderRepair = snapshot.docs
          .where((doc) => doc['status'] == 'Repair')
          .map((doc) => Item(
        id: doc.id,
        status: doc['status'],
        type: doc['type'],
        purchaseDate: (doc['purchaseDate'] as Timestamp).toDate(), // Convert Timestamp to DateTime
        name: doc['itemId'], // Item name
        warrantyDate: (doc['warrantyDate'] as Timestamp).toDate(), // Convert warranty date
      ))
          .toList();
      filteredItems = itemsUnderRepair;
    });
  }

  // Method to update item details in Firestore
  void _updateItemDetails(Item item) async {
    await FirebaseFirestore.instance.collection('items').doc(item.id).update({
      'status': item.status,
      'type': item.type,
      'purchaseDate': Timestamp.fromDate(item.purchaseDate), // Convert DateTime back to Timestamp
      'itemId': item.name,
    });
    setState(() {
      fetchItems(); // Reload items after update
    });
  }

  void _editItemDetails(Item item) {
    final _nameController = TextEditingController(text: item.name);
    final _typeController = TextEditingController(text: item.type);
    final _purchaseDateController = TextEditingController(text: item.formattedPurchaseDate);
    final _warrantyDateController = TextEditingController(text: item.formattedWarrantyDate); // New controller

    String selectedStatus = item.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Edit Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.label),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _typeController,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _purchaseDateController,
                  decoration: InputDecoration(
                    labelText: 'Purchase Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: item.purchaseDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      _purchaseDateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                      item.purchaseDate = pickedDate; // Update item date
                    }
                  },
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _warrantyDateController, // Warranty date field
                  decoration: InputDecoration(
                    labelText: 'Warranty Date',
                    prefixIcon: Icon(Icons.calendar_today), // Icon for Warranty Date field
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: item.warrantyDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      _warrantyDateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                      item.warrantyDate = pickedDate; // Update item warranty date
                    }
                  },
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  items: availableStatuses.map((String status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedStatus = newValue!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.settings),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    item.name = _nameController.text;
                    item.type = _typeController.text;
                    item.status = selectedStatus;

                    _updateItemDetails(item); // Save updated details to Firestore
                    Navigator.of(context).pop(); // Close the bottom sheet
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Save'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


// Method to delete an item from Firestore
  void _deleteItem(String itemId) async {
    try {
      // Delete the document from Firestore using the item ID
      await FirebaseFirestore.instance.collection('items').doc(itemId).delete();

      // Update the list of items in the UI after deletion
      setState(() {
        itemsUnderRepair.removeWhere((item) => item.id == itemId);
        filteredItems = itemsUnderRepair;
      });

      // Show a success message after deletion
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item deleted successfully')));
    } catch (e) {
      // Show an error message if something goes wrong
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete item: $e')));
    }
  }

  // Widget to display the list of items under repair
  Widget _buildItemList(List<Item> items) {
    final displayedItems = items.take(4).toList(); // Limit the displayed items to a maximum of 4

    return ListView.builder(
      itemCount: displayedItems.length,
      itemBuilder: (context, index) {
        final item = displayedItems[index];
        return Dismissible(
          key: Key(item.id),
          background: Container(color: Colors.red, child: Icon(Icons.delete, color: Colors.white)),
          onDismissed: (direction) {
            _deleteItem(item.id);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item deleted')));
          },
          child: ListTile(
            leading: Icon(Icons.build), // Custom icon for Repair status
            title: Text('ID: ${item.name}'),
            subtitle: Text('Status: ${item.status}, Type: ${item.type},  Purchase Date: ${item.formattedPurchaseDate}'),
            onTap: () => _editItemDetails(item), // Open bottom sheet for editing
          ),
        );
      },
    );
  }

  // Method to filter items based on search query
  void _filterItems(String query) {
    setState(() {
      searchQuery = query;
      filteredItems = itemsUnderRepair.where((item) {
        return item.id.toLowerCase().contains(query.toLowerCase()) ||
            item.type.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Under Repair'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by ID',
                border: OutlineInputBorder(),
              ),
              onChanged: _filterItems, // Update filter on text change
            ),
          ),
        ),
      ),
      body: _buildItemList(filteredItems), // Display list of filtered items
    );
  }
}
