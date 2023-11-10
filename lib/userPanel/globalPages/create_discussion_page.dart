import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateDiscussionsPage extends StatefulWidget {
  @override
  _CreateDiscussionsPageState createState() => _CreateDiscussionsPageState();
}

class _CreateDiscussionsPageState extends State<CreateDiscussionsPage> {
  TextEditingController _titleController = TextEditingController();
  TextEditingController _bodyController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final DatabaseReference _discussionsRef =
      FirebaseDatabase.instance.reference().child('Discussions');

  Future<void> _createDiscussion() async {
    if (_formKey.currentState!.validate()) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final discussionId = _discussionsRef.push().key;
      final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
      final formattedDateTime = dateFormat.format(DateTime.now());
      setState(() {
        _isLoading = true;
      });
      try {
        final discussion = {
          'title': _titleController.text,
          'body': _bodyController.text,
          'createdBy': uid,
          'createdDateTime': formattedDateTime,
          'replies': [],
        };
        await _discussionsRef.child(discussionId!).set(discussion);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Discussion created successfully!'),
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create the discussion'),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Create Discussion')),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(13.0),
            child: Card(
              elevation: 10.0,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value!.trim().isEmpty
                            ? 'Title cannot be empty'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _bodyController,
                        decoration: const InputDecoration(
                          labelText: 'Body',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 22,
                        validator: (value) => value!.trim().isEmpty
                            ? 'Body cannot be empty'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _createDiscussion,
                        child: Text(
                            _isLoading ? 'Creating...' : 'Create Discussion'),
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
              ),
            ),
          ),
        ));
  }
}
