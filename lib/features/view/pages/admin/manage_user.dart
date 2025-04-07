import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fyp_diabetease/features/view/pages/admin/admin_MainUserpage.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({Key? key}) : super(key: key);

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Deletes a user from Firestore by their UID.
  Future<void> _deleteUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user: $e')),
      );
    }
  }

  /// Retrieves a stream of users from Firestore.
  Stream<QuerySnapshot> _getUsersStream() {
    final usersCollection = FirebaseFirestore.instance.collection('users');

    if (_searchQuery.isEmpty) {
      return usersCollection
          .where(FieldPath.documentId,
              isNotEqualTo: 'm6jsllIePZbtuuyv8t8mhk1NYA63')
          .snapshots();
    } else {
      return usersCollection
          .where('username', isGreaterThanOrEqualTo: _searchQuery)
          .where('username', isLessThanOrEqualTo: '$_searchQuery\uf8ff')
          .where(FieldPath.documentId,
              isNotEqualTo: 'm6jsllIePZbtuuyv8t8mhk1NYA63')
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Users"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by username",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },
            ),
            const SizedBox(height: 20),
            // User List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getUsersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('An error occurred while fetching users.'),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No users found.'),
                    );
                  }

                  final users = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final userId = user.id;
                      final userData = user.data() as Map<String, dynamic>?;

                      final username = userData?['username'] ?? 'No username';
                      final email = userData?['email'] ?? 'No email';
                      final avatar =
                          userData?['profileImageUrl'] ?? 'No avatar';

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            backgroundImage: avatar != 'No avatar'
                                ? NetworkImage(avatar) // Use the avatar URL
                                : null, // No image if avatar is 'No avatar'
                            child: avatar == 'No avatar'
                                ? Text(
                                    username.isNotEmpty
                                        ? username[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(color: Colors.white),
                                  )
                                : null, // No text if avatar image is present
                          ),
                          title: Text(username),
                          subtitle: Text(email),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Delete User"),
                                  content: const Text(
                                      "Are you sure you want to delete this user?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text("Delete"),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                _deleteUser(userId);
                              }
                            },
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminMainUserPage(
                                  userId: userId,
                                  username: username,
                                  avatar: avatar,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
