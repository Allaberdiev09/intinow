import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventDetailsPage extends StatefulWidget {
  final Map<String, dynamic> eventData;
  final DocumentReference eventReference;

  EventDetailsPage({required this.eventData, required this.eventReference});

  @override
  _EventDetailsPageState createState() => _EventDetailsPageState(eventData, eventReference);
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  final Map<String, dynamic> eventData;
  final DocumentReference eventReference;
  bool isAttending = false;

  _EventDetailsPageState(this.eventData, this.eventReference);

  @override
  void initState() {
    super.initState();
    checkIfUserIsAttending();
  }

  void checkIfUserIsAttending() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userUid = currentUser.uid;
      final attendeesList = eventData['attendeesList'] as List?;
      if (attendeesList != null && attendeesList.contains(userUid)) {
        setState(() {
          isAttending = true;
        });
      }
    }
  }

  void toggleAttendance() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userUid = currentUser.uid;
      final attendeesList = eventData['attendeesList'] as List? ?? [];

      if (isAttending) {
        attendeesList.remove(userUid);
        await eventReference.update({
          'attendeesNumber': FieldValue.increment(-1),
          'attendeesList': attendeesList,
        });
      } else {
        attendeesList.add(userUid);
        await eventReference.update({
          'attendeesNumber': FieldValue.increment(1),
          'attendeesList': attendeesList,
        });
      }
      setState(() {
        isAttending = !isAttending;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                // Display event title
                Text(
                  eventData['title'] ?? 'Event Title',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Display event image
            Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: NetworkImage(eventData['imageReferenceURL'] ?? ''),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Display start date
            Text(
              'Start Date: ${eventData['startDate'] ?? 'No start date provided'}',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            // Display end date if it exists
            if (eventData['endDate'] != null)
              Text(
                'End Date: ${eventData['endDate']}',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            const SizedBox(height: 10),
            // Display attendees number
            Text(
              '${eventData['attendeesNumber']} Attending',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            // Display event description
            const Text(
              'Description:',
              style: TextStyle(
                fontSize: 22,
                color: Colors.blueGrey,
              ),
            ),
            Text(
              eventData['description'] ?? 'No description available.',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: toggleAttendance,
              child: Text(isAttending ? 'Leave' : 'Attend'),
            ),
          ],
        ),
      ),
    );
  }
}
