import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:samuhik/Screens/homeScr.dart';
import 'package:samuhik/Screens/login.dart';
import 'package:samuhik/Screens/manageReq.dart';
import 'package:samuhik/Screens/map.dart';
import 'package:samuhik/Screens/seeDonations.dart';
import 'package:samuhik/Screens/drawScr.dart';
import 'package:samuhik/widgets/bottomnav.dart';

class TabScr extends StatefulWidget {
  @override
  State<TabScr> createState() => _TabScrState();
}

class _TabScrState extends State<TabScr> {
  User? userid = FirebaseAuth.instance.currentUser;
  int currInd = 1;
  bool isInstitute = false;

  @override
  void initState() {
    super.initState();
    checkUserType();
    setupmessgs();
  }

  Future<void> checkUserType() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('institutes')
          .doc(user.uid)
          .get();
      setState(() {
        isInstitute = userDoc.exists;
      });
    }
  }

  void setupmessgs() async {
    final fpm = FirebaseMessaging.instance;
    await fpm.requestPermission();
    final token = await fpm.getToken();
    fpm.subscribeToTopic('chat');
    print(token);
  }

  void selTab(int index) {
    setState(() {
      currInd = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    String actText = 'Financial Literacy';
    Widget actScr = HomeScr();

    switch (currInd) {
      case 0:
        actScr = MapScr();
        actText = 'Maps';
        break;
      case 1:
        actScr = HomeScr();
        actText = 'Home';
        break;
      case 2:
        if (isInstitute) {
          actScr = ManageDon(CurrUserID: userid!.uid);
        } else {
          actScr = Seedonations();
        }
        actText = 'Activity';
        break;
    }

    return WillPopScope(
      onWillPop: () async {
        if (currInd != 1) {
          setState(() {
            currInd = 1;
          });
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          title: Text(
            actText,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold
            ),
          ),
          actions: [
            StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
            
                if (snapshot.hasData) {
                  return TextButton(
                    onPressed: () async {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirm Logout'),
                            content: const Text('Are you sure you want to logout?'),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: const Text('Yes'),
                                onPressed: () async {
                                  await FirebaseAuth.instance.signOut();
                                  Navigator.of(context).pop();
                                  setState(() {
                                    isInstitute = false;
                                    currInd = 1;
                                  });
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text(
                      'Signout',
                      style: TextStyle(color: Colors.white),
                    )
                  );
                }
            
                return TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      ModalBottomSheetRoute(
                        builder: (ctx) {
                          return const LoginScr();
                        },
                        isScrollControlled: false
                      )
                    );
                  },
                  child: const Text(
                    'Signin',
                    style: TextStyle(color: Colors.white),
                  )
                );
              },
            ),
          ],
        ),
        drawer: Drawer(
          child: DrawerScreen()
        ),
        body: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 64),
              child: actScr
              ),
            Positioned(
              
              bottom: 3,
              left: 25,
              right: 25,
              child: BottomNavBar(
                currentIndex: currInd,
                onTap: selTab,
              ),
            ),
          ],
        ),
      ),
    );
  }
}