import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class DiscussionDetailsPage extends StatelessWidget {
  final Map<dynamic, dynamic> discussion;
  final String discussionId;

  DiscussionDetailsPage({Key? key, required this.discussion, required this.discussionId}) : super(key: key);

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
    return Scaffold(
      appBar: AppBar(
        title: Text(discussion['title'] ?? 'Discussion Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<Map<String, dynamic>?>(
              future: getUserData(discussion['createdBy']),
              builder: (context, AsyncSnapshot<Map<String, dynamic>?> snapshot) {
                if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                  var userData = snapshot.data!;
                  return ListTile(
                    leading: userData['profilePicture'] != null
                        ? CircleAvatar(
                      backgroundImage: NetworkImage(userData['profilePicture']),
                    )
                        : const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(userData['name'] ?? 'Unknown'),
                  );
                } else if (snapshot.hasError) {
                  return const Text('Error loading user data');
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                discussion['title'] ?? 'No Title',
                style: Theme.of(context).textTheme.headline5,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                discussion['body'] ?? 'No content available',
              ),
            ),
            const Divider(),
            ReplySection(
              discussionId: discussionId,
              createdBy: discussion['createdBy'],
            ),
          ],
        ),
      ),
    );
  }
}

class ReplySection extends StatefulWidget {
  final String discussionId;
  final String createdBy;

  ReplySection({Key? key, required this.discussionId, required this.createdBy}) : super(key: key);

  @override
  _ReplySectionState createState() => _ReplySectionState();
}

class _ReplySectionState extends State<ReplySection> {
  TextEditingController _replyController = TextEditingController();
  bool _isSendingReply = false;
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

  void sendReply(String replyText) async {
    if (replyText.trim().isEmpty) return;

    setState(() {
      _isSendingReply = true;
    });

    final DatabaseReference discussionRef =
    FirebaseDatabase.instance.ref().child('Discussions/${widget.discussionId}/replies');

    final FirebaseAuth auth = FirebaseAuth.instance;
    final String userId = auth.currentUser!.uid;

    try {
      await discussionRef.push().set({
        'text': replyText,
        'userId': userId,
        'timestamp': ServerValue.timestamp,
      });

      _replyController.clear();
    } catch (e) {

    }

    setState(() {
      _isSendingReply = false;
    });
  }

  void deleteReply(String replyKey) async {
    final DatabaseReference replyRef =
    FirebaseDatabase.instance.ref().child('Discussions/${widget.discussionId}/replies/$replyKey');
    await replyRef.remove();
  }

  @override
  Widget build(BuildContext context) {
    final DatabaseReference repliesRef =
    FirebaseDatabase.instance.ref().child('Discussions/${widget.discussionId}/replies');
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _replyController,
            decoration: InputDecoration(
              hintText: 'Write a reply...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: _isSendingReply ? null : () => sendReply(_replyController.text),
              ),
            ),
          ),
        ),
        StreamBuilder(
          stream: repliesRef.onValue,
          builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
            if (snapshot.hasData && !snapshot.hasError && snapshot.data!.snapshot.value != null) {
              Map<dynamic, dynamic> repliesMap = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
              List<dynamic> replies = repliesMap.entries.map((e) => e.value).toList();
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: replies.length,
                itemBuilder: (context, index) {
                  var reply = replies[index];
                  var replyKey = repliesMap.entries.elementAt(index).key;
                  return FutureBuilder<Map<String, dynamic>?>(
                    future: getUserData(reply['userId']),
                    builder: (context, AsyncSnapshot<Map<String, dynamic>?> userSnapshot) {
                      if (userSnapshot.connectionState == ConnectionState.done) {
                        var userData = userSnapshot.data;
                        var currentUser = FirebaseAuth.instance.currentUser;

                        bool canDelete = currentUser?.uid == reply['userId'] || currentUser?.uid == widget.createdBy;

                        return ListTile(
                          leading: userData?['profilePicture'] != null
                              ? CircleAvatar(
                            backgroundImage: NetworkImage(userData!['profilePicture']),
                          )
                              : const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(reply['text'] ?? 'No Reply'),
                          subtitle: Text(userData?['name'] ?? 'Unknown'),
                          trailing: canDelete ? IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => deleteReply(replyKey),
                          ) : null,
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
              return const Center(child: Text('Error loading replies'));
            } else {
              return const Center(child: Text('No replies yet'));
            }
          },
        ),
      ],
    );
  }
}
