import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intinow/userPanel/globalPages/create_discussion_page.dart';
import 'package:intinow/userPanel/globalPages/discussion_details_page.dart';
import 'package:intinow/userPanel/student/services/side_navigation_bar_student.dart';

class StudentDiscussionsPage extends StatefulWidget {
  @override
  State<StudentDiscussionsPage> createState() => _StudentDiscussionsPageState();
}

class _StudentDiscussionsPageState extends State<StudentDiscussionsPage> {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text(
          'Discussions',
          style: TextStyle(fontSize: 20),
        ),
      ),
      drawer: SideNavigationBarStudent(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: DiscussionListWidget(searchQuery: _searchQuery, currentUser: _currentUser),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => CreateDiscussionsPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: TextField(
              controller: _searchController,
              textAlignVertical: TextAlignVertical.center,
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 2.0),
                hintText: 'Search discussions',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = "";
                    });
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}


class DiscussionListWidget extends StatelessWidget {
  final String searchQuery;
  final User? currentUser;

  DiscussionListWidget({required this.searchQuery, required this.currentUser});
  bool isCreatedByCurrentUser(String createdBy) {
    return currentUser != null && currentUser?.uid == createdBy;
  }
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    DocumentSnapshot userSnapshot =
    await FirebaseFirestore.instance.collection('Users').doc(userId).get();
    if (userSnapshot.exists && userSnapshot.data() != null) {
      return userSnapshot.data() as Map<String, dynamic>;
    } else {
      DocumentSnapshot adminSnapshot =
      await FirebaseFirestore.instance.collection('Admin').doc(userId).get();
      if (adminSnapshot.exists && adminSnapshot.data() != null) {
        return adminSnapshot.data() as Map<String, dynamic>;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final DatabaseReference discussionsRef =
    FirebaseDatabase.instance.ref().child('Discussions');
    return StreamBuilder(
      stream: discussionsRef.onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.hasData &&
            !snapshot.hasError &&
            snapshot.data!.snapshot.value != null) {
          Map<dynamic, dynamic> discussionsMap =
          Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
          List<dynamic> discussions = discussionsMap.entries
              .map((e) => e.value)
              .toList();
          discussions = discussions.where((discussion) {
            final title = discussion['title'] ?? '';
            final createdBy = discussion['createdBy'] ?? '';
            return !isCreatedByCurrentUser(createdBy) && title.toLowerCase().contains(searchQuery.toLowerCase());
          }).toList();
          return ListView.builder(
            itemCount: discussions.length,
            itemBuilder: (context, index) {
              var discussion = discussions[index];
              return FutureBuilder<Map<String, dynamic>?>(
                future: getUserData(discussion['createdBy']),
                builder: (context, AsyncSnapshot<Map<String, dynamic>?> userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.done) {
                    var userData = userSnapshot.data;
                    return InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => DiscussionDetailsPage(
                              discussion: discussion,
                              discussionId: discussionsMap.keys.elementAt(index),
                            ),
                          ),
                        );
                      },
                      child: Card(
                        child: ListTile(
                          leading: userData?['profilePicture'] != null
                              ? CircleAvatar(
                            backgroundImage: NetworkImage(userData!['profilePicture']),
                          )
                              : const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(discussion['title'] ?? 'No Title'),
                          subtitle: Text('by ${userData?['name'] ?? 'Unknown'}'),
                        ),
                      ),
                    );
                  } else if (userSnapshot.hasError) {
                    return const Text('Error loading user data');
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              );
            },
          );
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading discussions'));
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
