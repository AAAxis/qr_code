import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class EditMarksScreen extends StatefulWidget {
  @override
  _EditMarksScreenState createState() => _EditMarksScreenState();
}

class _EditMarksScreenState extends State<EditMarksScreen> {
  final List<DocumentSnapshot> _marks = [];
  final List<DocumentSnapshot> _filteredMarks = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMarks();
    _searchController.addListener(_filterMarks);
  }

  Future<void> _fetchMarks() async {
    try {
      // Fetch all marks from Firestore
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('markers')
          .get();

      setState(() {
        _marks.addAll(querySnapshot.docs);
        _filteredMarks.addAll(_marks); // Initialize filtered marks with all marks
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching marks: $e");
    }
  }

  void _filterMarks() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredMarks.clear();

      // Filter marks based on the search query
      if (query.isEmpty) {
        _filteredMarks.addAll(_marks); // Show all marks if the search query is empty
      } else {
        _filteredMarks.addAll(
          _marks.where((mark) {
            // Check if the address or technician name contains the search query
            return (mark['address']?.toLowerCase().contains(query) ?? false);
          }),
        );
      }
    });
  }

  void _deleteMark(String markId, String itemId) async {
    try {
      // Delete the mark from the markers collection
      await FirebaseFirestore.instance.collection('markers').doc(markId).delete();

      // Find the item by itemId in the items collection
      QuerySnapshot itemSnapshot = await FirebaseFirestore.instance
          .collection('items')
          .where('itemId', isEqualTo: itemId)
          .get();

      if (itemSnapshot.docs.isNotEmpty) {
        // Assuming itemId is unique and we want to update the first found document
        String foundItemId = itemSnapshot.docs.first.id;

        // Update the status of the found item in the items collection
        await FirebaseFirestore.instance.collection('items').doc(foundItemId).update({
          'status': 'Storage', // Change the status to 'storage'
        });

        print("Item status updated successfully.");
      } else {
        print("No item found with the specified itemId.");
      }

      setState(() {
        _marks.removeWhere((mark) => mark.id == markId);
        _filteredMarks.removeWhere((mark) => mark.id == markId); // Update filtered marks as well
      });
      print("Marker deleted successfully.");
    } catch (e) {
      print("Error deleting marker or updating item: $e");
    }
  }

  void _openMap(double latitude, double longitude) async {
    final String url = 'https://www.google.com/maps?q=$latitude,$longitude';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _showMarkDetails(DocumentSnapshot mark) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Mark Details"),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text("Address: ${mark['address'] ?? 'N/A'}"),
                // Make Latitude and Longitude clickable
                if (mark['location'] != null)
                  Text.rich(
                    TextSpan(
                      text: "Location: ",
                      children: [
                        TextSpan(
                          text: '${mark['location'].latitude}° N, ${mark['location'].longitude}° W',
                          style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              _openMap(
                                mark['location'].latitude,
                                mark['location'].longitude,
                              );
                            },
                        ),
                      ],
                    ),
                  )
                else
                  Text("Location: N/A"),
                Text("Assigned Date: ${mark['date'] ?? 'N/A'}"),
                Text("ID: ${mark['itemId'] ?? 'N/A'}"),
                Text("Technician: ${mark['technician'] ?? 'N/A'}"),
                Text("Ticket: ${mark['ticket'] ?? 'N/A'}"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Close"),
            ),
            TextButton(
              onPressed: () {
                _deleteMark(mark.id, mark['itemId']); // Pass both markId and itemId to delete method
                Navigator.of(context).pop(); // Close the dialog after deletion
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
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
        title: Text("Marks List"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by address',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredMarks.isEmpty
                ? Center(child: Text("No marks found.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))
                : ListView.builder(
              itemCount: _filteredMarks.length,
              itemBuilder: (context, index) {
                DocumentSnapshot mark = _filteredMarks[index];
                return ListTile(
                  leading: Icon(
                    Icons.push_pin_rounded, // Point icon for the leading position
                    color: Colors.black, // Set the color to red or any color you prefer
                  ),
                  title:  Text("${mark['ticket'] ?? 'No Ticket'}"),

                subtitle: Text(
                    "${mark['address']}, Date ${mark['date']}", // Add ID to the subtitle
                  ),
                  onTap: () => _showMarkDetails(mark),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose(); // Dispose the controller when not needed
    super.dispose();
  }
}
