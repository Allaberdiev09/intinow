import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OwnEventDetailsPage extends StatefulWidget {
  final Map<String, dynamic> eventData;
  final DocumentReference eventReference;

  OwnEventDetailsPage({required this.eventData, required this.eventReference});
  @override
  _OwnEventDetailsPageState createState() => _OwnEventDetailsPageState(eventData, eventReference);
}

class _OwnEventDetailsPageState extends State<OwnEventDetailsPage> {
  final Map<String, dynamic> eventData;
  final DocumentReference eventReference;

  late List<dynamic> attendeesList;
  late List<Map<String, dynamic>> attendeesDetails;

  _OwnEventDetailsPageState(this.eventData, this.eventReference);

  int attendeesNumber = 0;

  @override
  void initState() {
    super.initState();
    attendeesList = widget.eventData['attendeesList'] ?? [];
    attendeesDetails = [];
    attendeesNumber = widget.eventData['attendeesNumber'] ?? attendeesList.length;
    fetchAttendeesDetails();
  }

  Future<void> fetchAttendeesDetails() async {
    for (var uid in attendeesList) {
      var userDoc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();
      if (userDoc.data() != null) {
        Map<String, dynamic> attendeeDetails = userDoc.data()!;
        attendeeDetails['uid'] = uid;

        setState(() {
          attendeesDetails.add(attendeeDetails);
        });
      }
    }
  }

  Future<void> removeAttendee(String uid) async {
    setState(() {
      attendeesList.remove(uid);
      attendeesNumber--;
    });

    await widget.eventReference.update({
      'attendeesList': attendeesList,
      'attendeesNumber': attendeesNumber,
    });

    setState(() {
      attendeesDetails.removeWhere((detail) => detail['uid'] == uid);
    });
    Navigator.pop(context);
  }

  Future<void> deleteEvent() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Event?'),
          content: const Text('Are you sure you want to delete this event?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(context).pop();
                Navigator.pop(context);
                await eventReference.delete();
              },
            ),
          ],
        );
      },
    );
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
            if (eventData['endDate'] != null)
              Text(
                'End Date: ${eventData['endDate']}',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            const SizedBox(height: 30),
            InkWell(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => AttendeesScreen(
                    attendees: attendeesDetails,
                    onRemoveAttendee: (uid) => removeAttendee(uid),
                  ),
                ));
              },
              child: Text(
                '$attendeesNumber Attending',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 10),
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
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: deleteEvent,
        child: const Icon(Icons.delete),
      ),
    );
  }
}

class AttendeesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> attendees;
  final Future<void> Function(String uid) onRemoveAttendee;

  AttendeesScreen({required this.attendees, required this.onRemoveAttendee});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendees'),
      ),
      body: ListView.builder(
        itemCount: attendees.length,
        itemBuilder: (context, index) {
          final attendee = attendees[index];
          return ListTile(
            title: Text(attendee['name'] ?? 'No Name'),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline_outlined),
              onPressed: () async {
                if (attendee['uid'] != null) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Remove Attendee?'),
                        content: const Text('Are you sure you want to remove this attendee?'),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: const Text('Remove'),
                            onPressed: () {
                              Navigator.of(context).pop();
                              onRemoveAttendee(attendee['uid']);
                            },
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Error: Attendee UID is null."),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
