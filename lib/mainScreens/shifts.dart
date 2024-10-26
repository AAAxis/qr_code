import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClockInOutApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clock In/Out App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ClockInOutPage(),
    );
  }
}

class ClockInOutPage extends StatefulWidget {
  @override
  _ClockInOutPageState createState() => _ClockInOutPageState();
}

class _ClockInOutPageState extends State<ClockInOutPage> {
  List<Map<String, String>> clockRecords = [];
  bool isClockedIn = false;

  @override
  void initState() {
    super.initState();
    fetchClockRecords();
    loadClockState(); // Load clock state when the app starts
  }

  Future<void> loadClockState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? clockedInState = prefs.getBool('isClockedIn');

    setState(() {
      isClockedIn = clockedInState ?? false; // Default to false if no state is saved
    });
  }

  Future<void> fetchClockRecords() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      try {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('clockRecords')
            .where('userId', isEqualTo: userId)
            .get();

        List<Map<String, String>> records = [];
        for (var doc in snapshot.docs) {
          Timestamp clockInTimestamp = doc['clockIn'];
          Timestamp clockOutTimestamp = doc['clockOut'];

          records.add({
            'id': doc.id,
            'userId': doc['userId'],
            'clockIn': clockInTimestamp.toDate().toString(),
            'clockOut': clockOutTimestamp.toDate().toString(),
          });
        }

        records.sort((a, b) =>
            DateTime.parse(b['clockIn']!).compareTo(DateTime.parse(a['clockIn']!)));

        setState(() {
          clockRecords = records;
        });
      } catch (e) {
        print("Error fetching records: $e");
      }
    }
  }

  void clockIn() async {
    setState(() {
      isClockedIn = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isClockedIn', true);
  }

  Future<void> clockOut() async {
    setState(() {
      isClockedIn = false;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isClockedIn', false);

    final clockInTime = Timestamp.now();
    final clockOutTime = Timestamp.now();
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      final clockRecord = {
        'userId': userId,
        'clockIn': clockInTime,
        'clockOut': clockOutTime,
      };

      try {
        await FirebaseFirestore.instance.collection('clockRecords').add(clockRecord);
        fetchClockRecords();
      } catch (e) {
        print("Error saving record: $e");
      }
    }
  }

  Future<void> deleteRecord(String id) async {
    try {
      await FirebaseFirestore.instance.collection('clockRecords').doc(id).delete();
      fetchClockRecords();
    } catch (e) {
      print("Error deleting record: $e");
    }
  }

  String formatDateTime(String dateTime) {
    final DateTime dt = DateTime.parse(dateTime);
    return DateFormat.yMMMd().add_jm().format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Shifts'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: isClockedIn ? clockOut : clockIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: isClockedIn ? Colors.red : Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isClockedIn ? 'Clock Out' : 'Clock In',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Clock Records',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: clockRecords.length,
                itemBuilder: (context, index) {
                  final record = clockRecords[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 4,
                    child: ListTile(
                      title: Text(
                        'Clock In: ${formatDateTime(record['clockIn']!)}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        'Clock Out: ${formatDateTime(record['clockOut']!)}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Delete Record'),
                              content: Text('Are you sure you want to delete this record?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    deleteRecord(record['id']!);
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('Yes'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('No'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
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
