import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intinow/userPanel/globalPages/edit_profile_details.dart';

class UserDetailsProfilePage extends StatelessWidget {
  final DocumentReference userReference;

  UserDetailsProfilePage({required this.userReference});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: userReference.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User not found.'));
          }
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String userName = userData['name'];
          String userRole = userData['role'];
          String userEmail = userData['email'];
          String userProfilePicture = userData['profilePicture'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  margin: const EdgeInsets.only(top: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade400,
                        offset: const Offset(0, 0),
                        blurRadius: 10.0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: NetworkImage(userProfilePicture),
                        backgroundColor:
                        Colors.black,
                      ),
                      const SizedBox(height: 20.0),
                      Text(
                        userName,
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 10.0),
                      Text(
                        userRole,
                        style: TextStyle(
                            fontSize: 20, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 5.0),
                      Text(
                        userEmail,
                        style: TextStyle(
                            fontSize: 18, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 20.0),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EditProfileDetailsPage(userReference: userReference),
                            ),
                          );
                        },
                        child: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          fixedSize: const Size(365, 50),
                          textStyle: const TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
