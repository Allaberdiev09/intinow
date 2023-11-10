import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intinow/userPanel/authorizedUser/services/faculties.dart';
import 'dart:io';
import 'dart:math';
import 'package:intl/intl.dart';

class CreateEventPage extends StatefulWidget {
  @override
  _CreateEventPageState createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  bool _isLoading = false;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String? titleError;
  String? descriptionError;

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  String visibility = "Public";
  String selectedFaculty = "";
  File? _eventImage;
  List<String> selectedFaculties = [];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool showEndDateTimePicker = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildImageSelectionWidget(),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: TextFormField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Event Title',
                  border: const OutlineInputBorder(),
                  errorText: titleError,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 15.0),
              child: _buildDateTimePickers(),
            ),
            const SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 15.0),
              child: TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: const OutlineInputBorder(),
                  errorText: descriptionError,
                ),
                maxLines: 5,
              ),
            ),
            const SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 15.0),
              child: _buildVisibilityAndFacultySelection(),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: () async {
                    final User? currentUser = _auth.currentUser;
                    if (currentUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Please sign in to create an event.'),
                        duration: Duration(seconds: 3),
                      ));
                      return;
                    }

                    setState(() {
                      titleError = null;
                      descriptionError = null;
                    });

                    //to validate and check if the event title and description are not empty
                    if (titleController.text.isEmpty) {
                      setState(() {
                        titleError = 'Event title is required';
                      });
                      return;
                    }

                    if (descriptionController.text.isEmpty) {
                      setState(() {
                        descriptionError = 'Event description is required';
                      });
                      return;
                    }
                    setState(() {
                      _isLoading = true;
                    });
                    await _createEvent(currentUser);
                  },
                  child: const Text('Create Event'),
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(365, 50),
                    textStyle: const TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  final String imagePlaceholder = 'assets/images/eventImagePlaceholder.png';

  @override
  Widget _buildImageSelectionWidget() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 200,
          child: _eventImage == null
              ? Image.asset(
            imagePlaceholder,
            fit: BoxFit.cover,
          )
              : Image.file(_eventImage!, fit: BoxFit.cover),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: Row(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.white.withOpacity(0.5),
                  onPrimary: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                onPressed: _pickImage,
                child: const Text("Upload Image"),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.white.withOpacity(0.5),
                  onPrimary: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                onPressed: _takePicture,
                child: const Icon(Icons.camera_alt),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _takePicture() async {
    final pickedImage = await _imagePicker.pickImage(source: ImageSource.camera);
    if (pickedImage != null) {
      setState(() {
        _eventImage = File(pickedImage.path);
      });
    }
  }

  void _pickImage() async {
    final pickedImage = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _eventImage = File(pickedImage.path);
      });
    }
  }

  Widget _buildDateTimePickers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Start Date and Time:'),
        const SizedBox(height: 15.0),
        DateTimePicker(
          initialDate: startDate,
          onSelected: (date) {
            setState(() {
              startDate = date;
              //to automatically update the end date and time when the start date and time change
              if (endDate.isBefore(startDate)) {
                endDate = startDate;
              }
            });
          },
        ),
        const SizedBox(height: 10.0),
        if (showEndDateTimePicker)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('End Date and Time:'),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        showEndDateTimePicker = false;
                      });
                    },
                  ),
                ],
              ),
              DateTimePicker(
                initialDate: endDate,
                onSelected: (date) {
                  setState(() {
                    endDate = date;
                  });
                },
              ),
            ],
          )
        else
          ElevatedButton(
            onPressed: () {
              setState(() {
                showEndDateTimePicker = true;
              });
            },
            child: const Text('Add End Date and Time'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVisibilityAndFacultySelection() {
    return InkWell(
      onTap: _showVisibilityBottomSheet,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Event Privacy (visibility) : ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  visibility,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 3),
                Icon(_getVisibilityIcon(), color: Colors.black54),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getVisibilityIcon() {
    switch (visibility) {
      case 'Public':
        return Icons.public;
      case 'Faculties':
        return Icons.group;
      default:
        return Icons.public;
    }
  }

  void _showVisibilityBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.public),
            title: const Text('Public'),
            subtitle: const Text('Anyone on Inti Now'),
            onTap: () {
              setState(() {
                visibility = 'Public';
                selectedFaculties.clear();
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Faculties'),
            subtitle: const Text('Choose Faculties'),
            onTap: () {
              setState(() {
                visibility = 'Faculties';
              });
              _showFacultiesSelectionSheet();
            },
          ),
        ],
      ),
    );
  }


  void _showFacultiesSelectionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Column(
            children: [
              const ListTile(
                title: Text(
                  'Faculties',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: Faculties.getFaculties().length,
                  itemBuilder: (context, index) {
                    final faculty = Faculties.getFaculties()[index];
                    return CheckboxListTile(
                      title: Text(faculty),
                      value: selectedFaculties.contains(faculty),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedFaculties.add(faculty);
                          } else {
                            selectedFaculties.remove(faculty);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: selectedFaculties.isNotEmpty
                    ? () {
                  Navigator.pop(context);
                }
                    : null,
                child: const Text('Done'),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith(
                        (states) {
                      if (states.contains(MaterialState.disabled)) {
                        return Colors.grey;
                      }
                      return null;
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<String> _generateUniqueEventId() async {
    String eventId;
    final firestore = FirebaseFirestore.instance;

    while (true) {
      eventId = (Random().nextInt(1000000000)).toString().padLeft(9, '0');
      final eventDoc = await firestore.collection('Events').doc(eventId).get();
      if (!eventDoc.exists) {
        return eventId;
      }
    }
  }

  Future<void> _createEvent(User currentUser) async {
    try {
      final String eventId = await _generateUniqueEventId();
      final DateTime now = DateTime.now();
      String imageUrl = 'https://firebasestorage.googleapis.com/v0/b/intinow.appspot.com/o/placeholders%2FeventImagePlaceholder.png?alt=media&token=e59ec9ec-15b9-4350-b8fe-4b885d8765ea'; // Initialize imageUrl to an empty string

      if (_eventImage != null) {
        final String imageFileName = 'event_image_${now.microsecondsSinceEpoch}.jpg';
        final Reference storageReference = _storage.ref().child('event_images/$imageFileName');
        await storageReference.putFile(_eventImage!); // Upload the image to Firebase Storage
        imageUrl = await storageReference.getDownloadURL(); // Get the downloadable URL
      }

      final DocumentReference eventDocRef = _firestore.collection('Events').doc(eventId);
      final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm');

      final Map<String, dynamic> eventData = {
        'createdBy': currentUser.uid,
        'title': titleController.text,
        'description': descriptionController.text,
        'startDate': dateFormat.format(startDate),
        'visibility': visibility,
        'createdDateTime': dateFormat.format(now),
        'imageReferenceURL': imageUrl,
        'attendeesNumber': 0,
        'attendeesList': [],
      };

      if (showEndDateTimePicker) {
        eventData['endDate'] = dateFormat.format(endDate);
      }
      if (visibility == 'Faculties') {
        eventData['selectedFaculties'] = selectedFaculties;
      }
      await eventDocRef.set(eventData);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Event created successfully'),
        duration: Duration(seconds: 2),
      ));
      Navigator.pop(context);
    } catch (e) {
      print('Error creating event: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error creating event. Please try again.'),
        duration: Duration(seconds: 2),
      ));
    }
  }

}

class DateTimePicker extends StatelessWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onSelected;

  DateTimePicker({
    required this.initialDate,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('MMM dd, yyyy  HH:mm a');
    String formattedDate = dateFormat.format(initialDate);

    return InkWell(
      onTap: () async {
        final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime.now(),
          lastDate: DateTime(2101),
        );

        if (pickedDate != null) {
          final TimeOfDay? pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(initialDate),
          );

          if (pickedTime != null) {
            final DateTime selectedDateTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
            onSelected(selectedDateTime);
          }
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ),
        child: Row(
          children: <Widget>[
            Text(formattedDate),
          ],
        ),
      ),
    );
  }
}