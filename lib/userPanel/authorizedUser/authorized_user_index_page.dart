import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intinow/userPanel/authorizedUser/create_event_page.dart';
import 'package:intinow/userPanel/globalPages/event_details_page.dart';
import 'package:intinow/userPanel/authorizedUser/services/side_navigation_bar.dart';

class AuthorizedUserIndexPage extends StatefulWidget {
  @override
  _AuthorizedUserIndexPageState createState() => _AuthorizedUserIndexPageState();
}

class _AuthorizedUserIndexPageState extends State<AuthorizedUserIndexPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  Future<DocumentSnapshot> _getUserDetails(String uid) async {
    DocumentSnapshot userDoc =
    await _firestore.collection('Admin').doc(uid).get();
    if (userDoc.exists) return userDoc;
    return await _firestore.collection('Users').doc(uid).get();
  }

  Future<List<dynamic>> _getUserFaculties() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc =
      await _firestore.collection('Users').doc(currentUser.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['faculties'] ?? [];
      }
    }
    return [];
  }

  bool _isEventValid(Map<String, dynamic> eventData) {
    final String? startDate = eventData['startDate'] as String?;
    final String? endDate = eventData['endDate'] as String?;
    if (startDate != null) {
      final DateTime startDateTime = DateTime.parse(startDate);
      if (endDate != null) {
        final DateTime endDateTime = DateTime.parse(endDate);
        final DateTime now = DateTime.now();
        return startDateTime.isAfter(now) && endDateTime.isAfter(now);
      } else {
        final DateTime now = DateTime.now();
        return startDateTime.isAfter(now);
      }
    }
    return false;
  }


  bool _eventMatchesUserFaculties(
      Map<String, dynamic> eventData, List<dynamic> userFaculties) {
    if (eventData['visibility'] == 'Public') {
      return true;
    } else if (eventData['visibility'] == 'Faculties') {
      List<dynamic> eventFaculties = eventData['selectedFaculties'] ?? [];
      return eventFaculties.any((faculty) => userFaculties.contains(faculty));
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text(
          'Home Page',
          style: TextStyle(fontSize: 20),
        ),
      ),
      drawer: SideNavigationBar(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(child: _buildEventList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => CreateEventPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 2.0),
                hintText: 'Search events',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                  child: const Icon(Icons.close),
                  onTap: () {
                    _searchController.clear();
                    _searchTerm = '';
                    setState(() {});
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchTerm = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventList() {
    return FutureBuilder<List<dynamic>>(
      future: _getUserFaculties(),
      builder: (context, AsyncSnapshot<List<dynamic>> facultiesSnapshot) {
        if (facultiesSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (facultiesSnapshot.hasError) {
          return Center(child: Text('Error: ${facultiesSnapshot.error}'));
        }
        List<dynamic> userFaculties = facultiesSnapshot.data ?? [];

        return StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('Events').snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            List<DocumentSnapshot> filteredEvents = snapshot.data?.docs
                .where((DocumentSnapshot document) {
              Map<String, dynamic>? eventData =
              document.data() as Map<String, dynamic>?;

              //to check if the event is valid and matches user faculties
              bool isValidEvent = _eventMatchesUserFaculties(eventData!, userFaculties) &&
                  _isEventValid(eventData!);

              //to check if the createdBy field is not equal to the current user's UID
              bool createdByCurrentUser = eventData!['createdBy'] == _auth.currentUser?.uid;

              //to only include events that are valid and not created by the current user
              return isValidEvent && !createdByCurrentUser;
            }).toList() ??
                [];

            if (_searchTerm.isNotEmpty) {
              filteredEvents = filteredEvents.where((DocumentSnapshot document) {
                Map<String, dynamic>? eventData = document.data() as Map<String, dynamic>?;
                String title = eventData?['title'] ?? '';
                return title.toLowerCase().contains(_searchTerm.toLowerCase());
              }).toList();
            }

            return ListView.builder(
              itemCount: filteredEvents.length,
              itemBuilder: (BuildContext context, int index) {
                DocumentSnapshot event = filteredEvents[index];
                Map<String, dynamic>? eventData =
                event.data() as Map<String, dynamic>?;

                return FutureBuilder<DocumentSnapshot>(
                  future: _getUserDetails(eventData!['createdBy']),
                  builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(title: Text('Loading data...'));
                    }
                    if (userSnapshot.hasError) {
                      return ListTile(title: Text('Error: ${userSnapshot.error}'));
                    }
                    if (userSnapshot.data == null) {
                      return const ListTile(title: Text('User not found'));
                    }

                    String startDate = eventData!['startDate'] ?? '';
                    String endDate = eventData['endDate'] ?? '';
                    int attendeesNumber = eventData['attendeesNumber'] ?? 0;

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EventDetailsPage(
                              eventData: eventData,
                              eventReference: event.reference,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 2.0,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 3,
                                blurRadius: 5,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: NetworkImage(
                                        userSnapshot.data!['profilePicture'] ?? ''),
                                    radius: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(userSnapshot.data!['name'],
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                height: 250,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: NetworkImage(
                                        eventData!['imageReferenceURL'] ?? ''),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                eventData!['title'],
                                style: TextStyle(
                                  fontSize:
                                  18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Start Date: $startDate',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[
                                  600],
                                ),
                              ),
                              if (endDate
                                  .isNotEmpty)
                                Text(
                                  'End Date: $endDate',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[
                                    600],
                                  ),
                                ),
                              Text(
                                '$attendeesNumber Attending',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors
                                      .green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}