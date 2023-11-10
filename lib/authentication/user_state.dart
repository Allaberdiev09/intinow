import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intinow/authentication/login_screen.dart';
import 'package:intinow/userPanel/authorizedUser/authorized_user_index_page.dart';
import 'package:intinow/userPanel/student/student_index_page.dart';

class UserState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (userSnapshot.hasData) {
          final user = userSnapshot.data!;
          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('Users')
                .doc(user.uid)
                .get(),
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              } else if (snapshot.hasData) {
                final userData = snapshot.data!.data();
                final role = userData?['role'] as String?;

                //to check the user's role and return the appropriate widget
                if (role == 'Authorized User') {
                  return AuthorizedUserIndexPage();
                } else if (role == 'Student') {
                  return StudentIndexPage();
                } else {
                  //to handle the case where the role is not recognized
                  return Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Please Switch To Admin App!'),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                            },
                            child: Text('OK'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              } else if (snapshot.hasError) {
                return const Scaffold(
                  body: Center(
                    child: Text('An error has occurred! Please try again.'),
                  ),
                );
              } else {
                return const Scaffold(
                  body: Center(
                    child: Text('No user data found'),
                  ),
                );
              }
            },
          );
        } else {
          print('User is not logged in yet');
          return LoginScreen();
        }
      },
    );
  }
}
