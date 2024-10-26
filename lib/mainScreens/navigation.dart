
import 'package:driver_app/authentication/email_login.dart';
import 'package:driver_app/mainScreens/maps.dart';
import 'package:driver_app/mainScreens/notifications.dart';
import 'package:driver_app/mainScreens/qrcode.dart';
import 'package:driver_app/mainScreens/storage.dart';
import 'package:driver_app/mainScreens/task_display.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavigationScreen extends StatefulWidget {
  @override
  _NavigationScreenState createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> signOutAndClearPrefs(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => EmailLoginScreen()),
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          MapView(),
          TaskDisplayPage(),
          StorageBrokenItemsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [

          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Map',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt),
            label: 'Tasks',
          ),



          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Inventory',
          ),



        ],
      ),
    );
  }
}