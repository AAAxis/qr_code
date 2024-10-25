import 'package:driver_app/mainScreens/edit_marks.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

class MapView extends StatefulWidget {
  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  late GoogleMapController _controller;
  Set<Marker> _markers = {};
  List<Map<String, String>> _itemList = [];
  List<Map<String, String>> _filteredItems = [];
  LatLng? _tappedPoint;
  String _address = "Address not set";
  List<String> _technicianNames = []; // To hold the list of technician names
  String? _selectedTechnician; // To hold the currently selected technician
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _technicianController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isBottomSheetOpen = false; // Track if the bottom sheet is open

  @override
  void initState() {
    super.initState();
    _fetchMarkers();
    _fetchAllTechnicians();
    _fetchItems(); // Fetch items from Firestore
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now()); // Set current date
  }



// Add a variable to store the marker ID
  MarkerId? _currentMarkerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
            },
            onTap: (LatLng point) async {
              _tappedPoint = point;
              _address = await _fetchAddress(point);
              _addressController.text = _address; // Set address in the controller

              // Add a marker to the set and store its ID
              _currentMarkerId = MarkerId(point.toString());
              _markers.add(Marker(
                markerId: _currentMarkerId!,
                position: point,
                infoWindow: InfoWindow(title: _address),
              ));

              // Update the UI
              setState(() {});

              // Show the initial bottom sheet
              _showBottomSheet();
            },
            markers: _markers,
            initialCameraPosition: CameraPosition(
              target: LatLng(37.4276, -122.1697), // Example coordinates
              zoom: 10,
            ),
          ),
          Positioned(
            top: 50, // Adjust this value to position the text vertically
            left: 0,
            right: 0,
            child: Text(
              "Tap anywhere to add a Mark",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18, // Adjust font size as needed
                fontWeight: FontWeight.bold,
                color: Colors.black, // Change text color if needed
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => EditMarksScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min, // Make the Row take minimum width
                  children: [
                    Icon(Icons.list, size: 20), // Add your desired icon here
                    SizedBox(width: 8), // Add some space between the icon and the text
                    Text("List view"),
                  ],
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
  Future<String> _fetchAddress(LatLng point) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(point.latitude, point.longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return "${placemark.street}, ${placemark.locality}, ${placemark.country}";
      } else {
        return "No address available";
      }
    } catch (e) {
      print("Error getting address: $e");
      return "Address not found";
    }
  }

  void _fetchItems() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('items')
        .where('status', isNotEqualTo: 'Client') // Exclude items with status 'Assigned'
        .get();

    setState(() {
      _itemList = querySnapshot.docs.map((doc) {
        return {
          'itemId': doc['itemId'] as String,
          'type': doc['type'] as String,
        };
      }).toList();
      _filteredItems = _itemList; // Initialize filtered items
    });
  }


  void _showBottomSheet() {
    // Check if a bottom sheet is already open
    if (_isBottomSheetOpen) return; // Do not open a new one if it's already open

    _isBottomSheetOpen = true; // Set the flag to true

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          height: 500,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by Device...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () {
                      FocusScope.of(context).unfocus(); // Close the keyboard
                      _submitSearch(_searchController.text); // Submit search on button press
                    },
                  ),
                ),
                onChanged: (value) {
                  _filterItems(value); // Update filtered items as the user types
                },
              ),
              SizedBox(height: 10),
              Expanded(
                child: _filteredItems.isEmpty
                    ? Center(child: Text("No items found", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)))
                    : ListView.builder(
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    return ListTile(
                      leading: Icon(Icons.device_hub), // Replace with your desired icon
                      title: Text(item['itemId']!),
                      subtitle: Text('Type: ${item['type']}'),
                      onTap: () {
                        _selectItem(item['itemId']!, item['type']!); // Close this sheet and show item details
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      _isBottomSheetOpen = false; // Reset the flag when the bottom sheet is closed

      // Remove the marker if the bottom sheet is dismissed
      if (_currentMarkerId != null) {
        _markers.removeWhere((marker) => marker.markerId == _currentMarkerId);
        _currentMarkerId = null; // Reset the marker ID
        setState(() {}); // Update the UI to reflect the marker removal
      }
    });
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = query.isEmpty
          ? _itemList // Show all items if query is empty
          : _itemList.where((item) => item['itemId']!.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  void _submitSearch(String query) {
    _filterItems(query); // Update filtered items based on the search query
  }

  void _selectItem(String itemId, String type) async {
    Navigator.of(context).pop(); // Close the current bottom sheet
   // Fetch the technician name before showing details
    _showItemDetailSheet(itemId, type); // Open the new bottom sheet for item details
  }

  void _fetchMarkers() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('markers').get();

    Set<Marker> markers = {}; // Create a new set of markers
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final itemId = data['itemId'] as String;
      final location = data['location'] as GeoPoint;

      markers.add(Marker(
        markerId: MarkerId(itemId), // Unique identifier for each marker
        position: LatLng(location.latitude, location.longitude),
        infoWindow: InfoWindow(title: itemId, snippet: data['address']),
        icon: BitmapDescriptor.defaultMarker, // You can customize the marker icon here
      ));
    }

    setState(() {
      _markers = markers; // Update the state with the fetched markers
    });
  }


// Add a controller for the ticket number
  final TextEditingController _ticketController = TextEditingController();

  Future<void> _fetchAllTechnicians() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('users').get();
      List<String> technicianNames = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final nickname = data['nickname'] as String?;
        if (nickname != null) {
          technicianNames.add(nickname);
        }
      }

      setState(() {
        _technicianNames = technicianNames; // Update the state with fetched technician names
      });
    } catch (e) {
      print("Error fetching technicians: $e");
    }
  }

  void _showItemDetailSheet(String itemId, String type) async {
    // Fetch the ticket numbers as a list of strings
    List<String> ticketNumbers = await _fetchTicketNumbers();
    String? selectedTicketNumber;

    // Initialize the technician names if not done already
    await _fetchAllTechnicians(); // Ensure this method populates _technicianNames

    // Clear previous values
    _ticketController.text = "";
    _technicianController.text = ""; // Clear technician controller as well
    _selectedTechnician = null; // Reset selected technician

    if (_isBottomSheetOpen) return;
    _isBottomSheetOpen = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Device ID: $itemId", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              // Address Field
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  hintText: 'Address',
                  prefixIcon: Icon(Icons.location_on, color: Colors.black),
                  suffixIcon: _addressController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.black),
                    onPressed: () {
                      setState(() {
                        _addressController.clear(); // Clear the text field
                      });
                    },
                  )
                      : null, // Show clear icon only when there is text
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
              ),
              SizedBox(height: 10),
              // Dropdown for Ticket Number
              DropdownButtonFormField<String>(
                value: selectedTicketNumber,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedTicketNumber = newValue;
                    _ticketController.text = newValue ?? '';
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Select Task',
                  prefixIcon: Icon(Icons.confirmation_number, color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                items: ticketNumbers.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 10),
              // Dropdown for Technician
              DropdownButtonFormField<String>(
                value: _selectedTechnician,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTechnician = newValue; // Update selected technician
                    _technicianController.text = newValue ?? ''; // Update TextField controller
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Select Technician',
                  prefixIcon: Icon(Icons.person, color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                items: _technicianNames.map<DropdownMenuItem<String>>((String name) {
                  return DropdownMenuItem<String>(
                    value: name,
                    child: Text(name),
                  );
                }).toList(),
              ),
              SizedBox(height: 10),
              // Date Field
              GestureDetector(
                onTap: () async {
                  // Show date picker when tapped
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _dateController.text = "${pickedDate.toLocal()}".split(' ')[0]; // Format date to "yyyy-mm-dd"
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      hintText: 'Select Date',
                      prefixIcon: Icon(Icons.calendar_today, color: Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      // Validate inputs
                      if (_addressController.text.isEmpty ||
                          _selectedTechnician == null ||
                          _dateController.text.isEmpty ||
                          selectedTicketNumber == null) {
                        // Show an alert dialog if any required field is empty
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Incomplete Information"),
                              content: Text("Please fill in all fields (Address, Technician, Date, Task)."),
                              actions: [
                                TextButton(
                                  child: Text("OK"),
                                  onPressed: () {
                                    Navigator.of(context).pop(); // Close the dialog
                                  },
                                ),
                              ],
                            );
                          },
                        );
                        return; // Exit the function if any field is empty
                      }

                      // If all fields are filled, proceed to submit data
                      _onSubmit(itemId);
                    },
                    child: Text("Submit"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      _isBottomSheetOpen = false; // Reset the flag when the bottom sheet is closed
    });
  }


// Function to fetch all open ticket numbers
  Future<List<String>> _fetchTicketNumbers() async {
    try {
      // Reference to the Firestore collection
      CollectionReference tasksCollection = FirebaseFirestore.instance.collection('tasks');

      // Querying the collection to find open tasks
      QuerySnapshot querySnapshot = await tasksCollection
          .where('status', isEqualTo: 'New') // Adjust this field name as needed
          .get();

      // Create a list to hold the ticket numbers
      List<String> ticketNumbers = [];

      // Iterate through the documents and add the ticket number to the list
      for (var doc in querySnapshot.docs) {
        // Assuming 'ticketNumber' is the field name for ticket numbers
        ticketNumbers.add(doc['name']); // Replace with the correct field name
      }

      return ticketNumbers; // Return the list of ticket numbers
    } catch (e) {
      print("Error fetching ticket numbers: $e");
      return []; // Return an empty list on error
    }
  }

  Future<void> _onSubmit(String itemId) async {
    // Prepare the marker data to be saved
    final markerData = {
      'itemId': itemId,
      'address': _addressController.text,
      'ticket': _ticketController.text,
      'technician': _technicianController.text,
      'date': _dateController.text,
      'location': GeoPoint(_tappedPoint!.latitude, _tappedPoint!.longitude),
    };

    try {
      // Save marker data in the 'markers' collection
      await FirebaseFirestore.instance.collection('markers').add(markerData);
      print("Marker saved successfully.");

      // Now, fetch the document ID based on itemId
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('items')
          .where('itemId', isEqualTo: itemId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Get the document ID
        String docId = querySnapshot.docs.first.id; // Get the ID of the first matched document

        // Update the status of the item using the document ID
        await FirebaseFirestore.instance.collection('items').doc(docId).update({
          'status': 'Client', // Update the status to 'Assigned'
        });
        print("Item status updated successfully.");
        _fetchItems();
        _fetchMarkers();
      } else {
        print("No item found with itemId: $itemId");
      }

      // Close the detail sheet after submission
      Navigator.of(context).pop();
    } catch (e) {
      print("Error saving marker or updating item: $e");
    }
  }

}
