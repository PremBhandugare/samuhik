import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:samuhik/Screens/addDona.dart';
import 'package:samuhik/Screens/manageReq.dart';

class DrawerScreen extends StatefulWidget {
  @override
  _DrawerScreenState createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen> {
  String fullName = 'Loading...';
  String email = '';
  String role = '';
  String emailID = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        
        final instituteDoc = await FirebaseFirestore.instance
            .collection('institutes')
            .doc(user.uid)
            .get();

        if (instituteDoc.exists) {
          final data = instituteDoc.data() as Map<String, dynamic>;
          setState(() {
            fullName = data['instituteName'] ?? 'No Name';
            email = data['email'] ?? 'No Email';
            role = 'institute';
            emailID = user.uid;
          });
        } else {
          
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (userDoc.exists) {
            final data = userDoc.data() as Map<String, dynamic>;
            setState(() {
              fullName = data['fullName'] ?? 'No Name';
              email = data['email'] ?? 'No Email';
              role = 'user';
            });
          } else {
            setState(() {
              fullName = 'No User Data';
              role = 'unknown';
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        fullName = 'Error loading data';
        role = 'unknown';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          _buildUserHeader(),
          _buildCommonMenuItems(),
          if (role == 'user')
            _buildUserMenuItems()
          else if (role == 'institute')
            _buildInstituteMenuItems(),
          _buildSettingsAndLogout(),
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    return UserAccountsDrawerHeader(
      accountName: Text(
        fullName,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      accountEmail: Text(
        email,
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        child: Text(
          fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 40.0,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        
      ),
    );
  }

  Widget _buildCommonMenuItems() {
    return ListTile(
      leading: Icon(Icons.home),
      title: Text('Home'),
      onTap: () {
        
        Navigator.pop(context);
      },
    );
  }

  Widget _buildUserMenuItems() {
    return ListTile(
      leading: Icon(Icons.add_shopping_cart),
      title: Text('My Contributions'),
      onTap: () {
        
           // Navigator.of(context).push(MaterialPageRoute(builder:(ctx)=>MyContributions(userId: emailID)));
        
        
      },
    );
  }

  Widget _buildInstituteMenuItems() {
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.add_business),
          title: Text('Raise a Request'),
          onTap: () {
            
            Navigator.of(context).push(MaterialPageRoute(builder:(ctx)=>AddRequestScreen()));
            
           
          },
        ),
        ListTile(
          leading: Icon(Icons.inventory),
          title: Text('Manage Requests'),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder:(ctx)=>ManageDon(CurrUserID: emailID)));
          },
        ),
      ],
    );
  }

  Widget _buildSettingsAndLogout() {
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.settings),
          title: Text('Settings'),
          onTap: () {
           
            Navigator.pop(context);
           
          },
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.logout, color: Colors.red),
          title: Text('Logout', style: TextStyle(color: Colors.red)),
          onTap: () => _showLogoutDialog(),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pop();
                
              },
            ),
          ],
        );
      },
    );
  }
}