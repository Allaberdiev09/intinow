// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intinow/authentication/user_state.dart';
import 'package:intinow/userPanel/authorizedUser/authorized_user_attending_events_list.dart';
import 'package:intinow/userPanel/authorizedUser/authorized_user_created_discussions_page.dart';
import 'package:intinow/userPanel/authorizedUser/authorized_user_index_page.dart';
import 'package:intinow/userPanel/authorizedUser/authorized_user_discussions_page.dart';
import 'package:intinow/userPanel/globalPages/user_details_profile.dart';
import 'package:intinow/userPanel/authorizedUser/your_created_events.dart';

class SideNavigationBar extends StatefulWidget {
  @override
  State<SideNavigationBar> createState() => _SideNavigationBarState();
}

class _SideNavigationBarState extends State<SideNavigationBar> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  DocumentSnapshot? userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (currentUser != null) {
      var userDocument = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser!.uid)
          .get();
      if (userDocument.exists) {
        setState(() {
          userData = userDocument;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            TextButton(
              style: TextButton.styleFrom(primary: Colors.transparent),
              onPressed: () {
                if (userData != null) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => UserDetailsProfilePage(userReference: userData!.reference),
                  ));
                }
              },
              child: UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                margin: EdgeInsets.zero,
                currentAccountPicture: CircleAvatar(
                  backgroundImage: userData != null && userData!['profilePicture'] != null
                      ? NetworkImage(userData!['profilePicture'])
                      : null,
                  child: userData != null && userData!['profilePicture'] != null
                      ? null
                      : Text(
                    userData != null ? userData!['name'][0] : 'A',
                    style: const TextStyle(fontSize: 40.0),
                  ),
                ),
                accountName: Text(
                  userData != null ? userData!['name'] : ' ',
                  style: const TextStyle(color: Colors.black),
                ),
                accountEmail: Text(
                  userData != null ? userData!['email'] : ' ',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
            _customListTile(context, Icons.dashboard, 'Dashboard'),
            _customListTile(context, Icons.access_time_filled_outlined, 'Attending Events'),
            _customListTile(context, Icons.my_library_books, 'Your Created Events'),
            _customListTile(context, Icons.question_answer_outlined, 'Ask&Answer Community'),
            _customListTile(context, Icons.my_library_books, 'Your Created Discussions'),
            _customListTile(context, Icons.logout, 'Logout Account'),
          ],
        ),
      ),
    );
  }

  Widget _customListTile(BuildContext context, IconData icon, String text) {
    return TextButton(
      style: TextButton.styleFrom(primary: Colors.transparent),
      onPressed: () {
        if (text == 'Dashboard') {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => AuthorizedUserIndexPage()));
        }
        if (text == 'Attending Events') {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => AuthorizedUserAttendingEventsPage()));
        }
        if (text == 'Your Created Events') {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => YourCreatedEventsPage()));
        }
        if (text == 'Ask&Answer Community') {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => AuthorizedUserDiscussionsPage()));
        }
        if (text == 'Your Created Discussions') {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => AuthorizedUserCreatedDiscussionsPage()));
        }
        if (text == 'Logout Account') {
          _showLogoutDialog(context);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          leading: Icon(
            icon,
            color: Colors.black,
          ),
          title: Text(
            text,
            style: const TextStyle(color: Colors.black),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text('Do you want to log out?'),
          actions: [
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => UserState()),
                      (Route<dynamic> route) => false,
                );
              },
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
          ],
        );
      },
    );
  }

}
