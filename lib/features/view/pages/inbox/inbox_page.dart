import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fyp_diabetease/firebase/firebase_service.dart';
import 'package:fyp_diabetease/features/view/pages/inbox/chatdetail_page.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({Key? key}) : super(key: key);

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> chats = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  Future<void> _fetchChats() async {
    try {
      List<Map<String, dynamic>> fetchedChats =
          await _firebaseService.getInboxChats();

      if (mounted) {
        setState(() {
          // Filter out duplicate chats by chatId
          chats = [];
          for (var chat in fetchedChats) {
            if (!chats.any(
                (existingChat) => existingChat['chatId'] == chat['chatId'])) {
              if (chat['lastMessageTime'] is Timestamp) {
                chat['lastMessageTime'] =
                    _firebaseService.formatTimestamp(chat['lastMessageTime']);
              } else {
                chat['lastMessageTime'] = 'Not Available';
              }
              chats.add(chat);
            }
          }
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching chats: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshChats() async {
    await _fetchChats(); // Fetch the chats again
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Messages'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshChats, // Trigger refresh on pull down
              child: chats.isEmpty
                  ? const Center(child: Text('No messages yet'))
                  : ListView.builder(
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(
                                chat['profileImageUrl'] ?? 'default_image_url'),
                          ),
                          title: Text(
                            chat['name'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            chat['lastMessage'] ?? 'No message',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: Text(
                            chat['lastMessageTime'],
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                          onTap: () {
                            // Navigate to ChatDetailPage
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatDetailPage(
                                  chatId: chat['chatId'],
                                  name: chat['name'],
                                  profileImageUrl: chat['profileImageUrl'],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
    );
  }
}
