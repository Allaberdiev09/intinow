import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intinow/userPanel/globalPages/event_details_page.dart';
import 'package:intinow/userPanel/student/services/side_navigation_bar_student.dart';

class StudentAttendingEventsPage extends StatefulWidget {
  @override
  _StudentAttendingEventsPageState createState() => _StudentAttendingEventsPageState();
}

class _StudentAttendingEventsPageState extends State<StudentAttendingEventsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _allEvents = [];
  List<DocumentSnapshot> _displayedEvents = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchEvents(String query) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final events = _allEvents.where((doc) {
          final eventTitle = doc['title'].toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return eventTitle.contains(searchLower);
        }).toList();

        setState(() {
          _displayedEvents = events;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text(
          'Attending Events',
          style: TextStyle(fontSize: 20),
        ),
      ),
      drawer: SideNavigationBarStudent(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(child: _buildAttendingEventList()),
          ],
        ),
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
              onChanged: _searchEvents,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: 'Search events',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                  child: const Icon(Icons.close),
                  onTap: () {
                    _searchController.clear();
                    _searchEvents('');
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

  Widget _buildAttendingEventList() {
    final currentUser = _auth.currentUser;
    final userUid = currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('Events')
          .where('attendeesList', arrayContains: userUid)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> eventsSnapshot) {
        if (eventsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (eventsSnapshot.hasError) {
          return Center(child: Text('Error: ${eventsSnapshot.error}'));
        }
        if (!eventsSnapshot.hasData) {
          return const Center(child: Text('No events found'));
        }
        _allEvents = eventsSnapshot.data!.docs;
        _displayedEvents = _searchController.text.isEmpty
            ? _allEvents
            : _allEvents.where((doc) {
          final eventTitle = doc['title'].toString().toLowerCase();
          final searchLower = _searchController.text.toLowerCase();
          return eventTitle.contains(searchLower);
        }).toList();

        //to filter for valid start dates
        _displayedEvents = _displayedEvents.where((doc) {
          final startDate = doc['startDate'] as String?;
          if (startDate == null) {
            return false;
          }
          final eventDate = DateTime.parse(startDate);
          return eventDate.isAfter(DateTime.now()) || eventDate.isAtSameMomentAs(DateTime.now());
        }).toList();

        return _buildEventList(_displayedEvents);
      },
    );
  }


  Widget _buildEventList(List<DocumentSnapshot> events) {
    if (events.isEmpty) {
      return const Center(child: Text('No matching events found'));
    }
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (BuildContext context, int index) {
        DocumentSnapshot event = events[index];
        Map<String, dynamic>? eventData = event.data() as Map<String, dynamic>?;
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
                  Text(
                    eventData!['title'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Start Date: ${eventData['startDate'] ?? 'Not specified'}',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
