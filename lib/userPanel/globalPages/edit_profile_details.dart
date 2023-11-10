import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileDetailsPage extends StatefulWidget {
  final DocumentReference userReference;

  EditProfileDetailsPage({required this.userReference});

  @override
  _EditProfileDetailsPageState createState() => _EditProfileDetailsPageState();
}

class _EditProfileDetailsPageState extends State<EditProfileDetailsPage> {
  late TextEditingController _nameController;
  String _profilePictureUrl = '';
  XFile? _pickedImageFile;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadCurrentUserData();
  }

  void _loadCurrentUserData() async {
    DocumentSnapshot userData = await widget.userReference.get();
    Map<String, dynamic> data = userData.data() as Map<String, dynamic>;
    _nameController.text = data['name'];
    setState(() {
      _profilePictureUrl = data['profilePicture'];
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateUserDetails() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      if (_pickedImageFile != null) {
        String imageUrl = await uploadFileAndGetUrl(_pickedImageFile!);
        _profilePictureUrl = imageUrl;
      }
      await widget.userReference.update({
        'name': _nameController.text,
        'profilePicture': _profilePictureUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User details updated successfully!'),
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pop();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update user details.'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    setState(() {
      _isUpdating = false;
    });
  }

  Future<void> _changeProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImageFile = pickedFile;
      });
    }
  }

  Future<String> uploadFileAndGetUrl(XFile file) async {
    Reference storageReference =
        FirebaseStorage.instance.ref().child('profile_pics/${file.name}');
    UploadTask uploadTask = storageReference.putFile(
      File(file.path),
      SettableMetadata(contentType: 'image/jpeg'),
    );

    await uploadTask;
    return await storageReference.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit User Details'),
      ),
      body: Padding(
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
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _pickedImageFile != null
                            ? FileImage(File(_pickedImageFile!.path))
                            : (_profilePictureUrl.isNotEmpty
                                ? NetworkImage(_profilePictureUrl)
                                : null) as ImageProvider<Object>?,
                        child: _pickedImageFile == null &&
                                _profilePictureUrl.isEmpty
                            ? const Icon(Icons.person, size: 60)
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.grey,
                        ),
                        onPressed: _changeProfilePicture,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _isUpdating
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _updateUserDetails,
                          child: const Text('Update Details'),
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
      ),
    );
  }
}
