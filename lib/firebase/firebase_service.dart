import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'package:intl/intl.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<User?> signUpWithEmailAndPassword(
      String email,
      String password,
      String username,
      DateTime dateOfBirth,
      String height,
      String weight,
      String gender,
      String diabetesType) async {
    try {
      // Check if the username already exists
      QuerySnapshot existingUsers = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      print('Existing users count: ${existingUsers.docs.length}');

      if (existingUsers.docs.isNotEmpty) {
        print("Username already exists: $username");
        throw Exception("Username already exists. Please choose another one.");
      }

      // Proceed with user creation if username is unique
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      User? user = credential.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'username': username,
          'email': email,
          'dateOfBirth': dateOfBirth,
          'height': height,
          'weight': weight,
          'gender': gender,
          'diabetesType': diabetesType,
          'followingUser': [], // Initialize empty list for following users
          'followedByUser': [], // Initialize empty list for followed by users
        });
      }

      return user;
    } catch (e) {
      print("Sign up error: $e");
      throw Exception("Error during sign-up: $e");
    }
  }

  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      // Detailed error handling for FirebaseAuthException
      switch (e.code) {
        case 'user-not-found':
          throw 'No user found for that email.';
        case 'wrong-password':
          throw 'Wrong password provided.';
        case 'invalid-email':
          throw 'The email address is badly formatted.';
        case 'user-disabled':
          throw 'This user account has been disabled.';
        default:
          throw 'Login error. Please enter valid credentials.';
      }
    } catch (e) {
      // Generic error handling
      throw 'An error occurred: $e';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageReference = _storage.ref().child('recipes/$fileName');
      UploadTask uploadTask = storageReference.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Image upload error: $e");
      throw Exception("Image upload error: $e");
    }
  }

  Future<void> uploadRecipe(
      {required String recipeName,
      required String description,
      required String ingredients,
      required String instructions,
      required String imageUrl,
      required double calories,
      required double fat,
      required double sugar,
      required double protein,
      required double glycemicIndex,
      required double carbohydrateContent,
      required double fiberContent,
      required double sodiumContent,
      required double addedSugars,
      required double riskLevel,
      required List<String> tags,
      required int prepTime,
      required int cookTime,
      required int serving,
      required String advice}) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("User not logged in");
      }

      // Fetch the username from the 'users' collection
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(currentUser.uid).get();
      String username = userSnapshot['username'] ??
          'Anonymous'; // Default to 'Anonymous' if no username

      await _firestore.collection('recipes').add({
        'recipeName': recipeName,
        'description': description,
        'ingredients': ingredients,
        'instructions': instructions,
        'imageUrl': imageUrl,
        'userId': currentUser.uid,
        'username': username,
        'createdAt': Timestamp.now(),
        'calories': calories,
        'fat': fat,
        'sugar': sugar,
        'protein': protein,
        'glycemicIndex': glycemicIndex,
        'carbohydrateContent': carbohydrateContent,
        'fiberContent': fiberContent,
        'sodiumContent': sodiumContent,
        'addedSugars': addedSugars,
        'riskLevel': riskLevel,
        'tags': tags,
        'averageRating': 0.0,
        'prepTime': prepTime.toString(), // Add preparation time
        'cookTime': cookTime.toString(), // Add cooking time
        'serving': serving.toString(),
        'advice': advice
      });
    } catch (e) {
      print("Error saving recipe: $e");
      throw Exception("Error saving recipe: $e");
    }
  }

  Future<void> followUser(String targetUserId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("User not logged in");
      }

      DocumentReference currentUserDoc =
          _firestore.collection('users').doc(currentUser.uid);
      DocumentReference targetUserDoc =
          _firestore.collection('users').doc(targetUserId);

      // Ensure the current user document exists and contains the fields
      await currentUserDoc.set({
        'followingUser': FieldValue.arrayUnion([]), // Initialize if missing
        'followedByUser': FieldValue.arrayUnion([]), // Initialize if missing
      }, SetOptions(merge: true));

      // Ensure the target user document exists and contains the fields
      await targetUserDoc.set({
        'followingUser': FieldValue.arrayUnion([]), // Initialize if missing
        'followedByUser': FieldValue.arrayUnion([]), // Initialize if missing
      }, SetOptions(merge: true));

      // Add the target user to the current user's following list
      await currentUserDoc.update({
        'followingUser': FieldValue.arrayUnion([targetUserId]),
      });

      // Add the current user to the target user's followedBy list
      await targetUserDoc.update({
        'followedByUser': FieldValue.arrayUnion([currentUser.uid]),
      });
    } catch (e) {
      print("Error following user: $e");
      throw Exception("Error following user: $e");
    }
  }

  Future<void> unfollowUser(String targetUserId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("User not logged in");
      }

      DocumentReference currentUserDoc =
          _firestore.collection('users').doc(currentUser.uid);
      DocumentReference targetUserDoc =
          _firestore.collection('users').doc(targetUserId);

      // Remove the target user ID from the current user's following list
      await currentUserDoc.update({
        'followingUser': FieldValue.arrayRemove([targetUserId]),
      });

      // Remove the current user ID from the target user's followedBy list
      await targetUserDoc.update({
        'followedByUser': FieldValue.arrayRemove([currentUser.uid]),
      });
    } catch (e) {
      print("Error unfollowing user: $e");
      throw Exception("Error unfollowing user: $e");
    }
  }

  // Get the count of users the current user is following
  Future<int> getFollowingCount() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("User not logged in");
      }

      // Retrieve the current user's document from Firestore
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(currentUser.uid).get();

      // Get the 'followingUser' field, which is an array of the user IDs the current user is following
      List<dynamic> followingList = userSnapshot['followingUser'] ?? [];

      return followingList
          .length; // Return the length of the list (i.e., following count)
    } catch (e) {
      print("Error fetching following count: $e");
      throw Exception("Error fetching following count: $e");
    }
  }

// Get the count of users following the current user
  Future<int> getFollowersCount() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("User not logged in");
      }

      // Retrieve the current user's document from Firestore
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(currentUser.uid).get();

      // Get the 'followedByUser' field, which is an array of the user IDs following the current user
      List<dynamic> followersList = userSnapshot['followedByUser'] ?? [];

      return followersList
          .length; // Return the length of the list (i.e., followers count)
    } catch (e) {
      print("Error fetching followers count: $e");
      throw Exception("Error fetching followers count: $e");
    }
  }

  Future<void> addComment(String recipeId, String comment, int rating) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("User not logged in");
      }

      // Retrieve the username from the 'users' collection
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(currentUser.uid).get();
      String username = userSnapshot['username'] ??
          'Anonymous'; // Fallback to 'Anonymous' if username not found

      // Add the comment along with the username and rating
      await _firestore.collection('comments').add({
        'recipeId': recipeId,
        'comment': comment,
        'rating': rating,
        'username': username,
        'profileImageUrl': userSnapshot['profileImageUrl'],
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error adding comment: $e");
      throw Exception("Error adding comment: $e");
    }
  }

  Future<Map<String, dynamic>?> fetchUserDetails(String userId) async {
    try {
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(userId).get();
      return userSnapshot.exists
          ? userSnapshot.data() as Map<String, dynamic>
          : null;
    } catch (e) {
      print('Error fetching user details: $e');
      return null;
    }
  }

  // Fetch list of recipes uploaded by followed users
  Future<List<Map<String, dynamic>>> fetchFollowedUsersRecipes(
      List<String> followedUserIds) async {
    try {
      QuerySnapshot recipesSnapshot = await _firestore
          .collection('recipes')
          .where('uploadedBy', whereIn: followedUserIds)
          .get();
      return recipesSnapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Error fetching recipes: $e');
      return [];
    }
  }

  // Fetch current user's followed users
  Future<List<String>> fetchFollowedUsers(String userId) async {
    try {
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(userId).get();
      return (userSnapshot.data() as Map<String, dynamic>)['following'] ?? [];
    } catch (e) {
      print('Error fetching followed users: $e');
      return [];
    }
  }

  Future<List<QueryDocumentSnapshot>> getComments(String recipeId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('comments')
          .where('recipeId', isEqualTo: recipeId)
          .orderBy('timestamp', descending: true)
          .get();
      return querySnapshot.docs;
    } catch (e) {
      print("Error fetching comments: $e");
      throw Exception("Error fetching comments: $e");
    }
  }

  Future<void> toggleBookmark(String recipeId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print("No user is currently logged in.");
        return;
      }

      DocumentReference userDoc =
          _firestore.collection('users').doc(currentUser.uid);
      DocumentSnapshot userSnapshot = await userDoc.get();

      if (!userSnapshot.exists) {
        await userDoc.set({'savedRecipes': []});
        print("Created user document for: ${currentUser.uid}");
      }

      Map<String, dynamic>? data = userSnapshot.data() as Map<String, dynamic>?;
      List<dynamic> savedRecipes = data?['savedRecipes'] ?? [];

      if (savedRecipes.contains(recipeId)) {
        savedRecipes.remove(recipeId);
        print("Removed $recipeId from savedRecipes.");
      } else {
        savedRecipes.add(recipeId);
        print("Added $recipeId to savedRecipes.");
      }

      await userDoc
          .set({'savedRecipes': savedRecipes}, SetOptions(merge: true));
      print("Updated savedRecipes for ${currentUser.uid}: $savedRecipes");
    } catch (e) {
      print("Error toggling bookmark for user ${_auth.currentUser?.uid}: $e");
      throw Exception("Error toggling bookmark: $e");
    }
  }

  Future<List<QueryDocumentSnapshot>> getBookmarkedRecipes() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      List<dynamic> savedRecipes = userDoc['savedRecipes'] ?? [];

      if (savedRecipes.isEmpty) return [];

      QuerySnapshot recipeSnapshot = await _firestore
          .collection('recipes')
          .where(FieldPath.documentId, whereIn: savedRecipes)
          .get();

      return recipeSnapshot.docs;
    } catch (e) {
      print("Error fetching bookmarked recipes: $e");
      throw Exception("Error fetching bookmarked recipes: $e");
    }
  }

  Future<bool> isRecipeBookmarked(String recipeId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      List<dynamic> savedRecipes = userDoc['savedRecipes'] ?? [];
      return savedRecipes.contains(recipeId);
    } catch (e) {
      print("Error checking if recipe is bookmarked: $e");
      throw Exception("Error checking bookmark status: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getFollowingUsers() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("User not logged in");
      }

      // Retrieve the current user's document from Firestore
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userSnapshot.exists) {
        throw Exception("Current user document does not exist");
      }

      // Safely retrieve the followingUser field, defaulting to an empty list if not found
      List<dynamic> followingUserIds = userSnapshot['followingUser'] ?? [];

      List<Map<String, dynamic>> followingUsers = [];

      for (var userId in followingUserIds) {
        // Retrieve each followed user's document
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(userId).get();

        // Check if the document exists and contains data
        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          // Print the retrieved user data for debugging
          print("Retrieved user data: $userData");

          // Ensure 'name' field exists, fallback to 'Unknown' if not
          userData['name'] = userData['name'] ?? 'Unknown';
          followingUsers.add(userData);
        } else {
          print("User document for $userId does not exist or has no data.");
        }
      }

      return followingUsers;
    } catch (e) {
      print("Error fetching following users: $e");
      throw Exception("Error fetching following users: $e");
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      // Assume you have a 'chats' collection in Firestore
      await _firestore.collection('chats').doc(chatId).delete();
      print('Chat with ID $chatId deleted successfully.');
    } catch (e) {
      print("Error deleting chat: $e");
      throw Exception('Failed to delete chat');
    }
  }

  // Fetch the average rating of a recipe
  Future<double> fetchAverageRating(String recipeId) async {
    try {
      // Query ratings collection and filter by recipeId
      QuerySnapshot ratingsSnapshot = await _firestore
          .collection('ratings')
          .where('recipeId', isEqualTo: recipeId)
          .get();

      if (ratingsSnapshot.docs.isEmpty) {
        return 0.0; // Return 0 if no ratings are found
      }

      // Calculate the total rating sum
      double totalRating = 0.0;
      for (var doc in ratingsSnapshot.docs) {
        totalRating += (doc['rating'] as double); // Make sure to cast correctly
      }

      // Return the average
      return totalRating / ratingsSnapshot.docs.length;
    } catch (e) {
      print("Error fetching average rating: $e");
      throw Exception("Error fetching average rating: $e");
    }
  }

  Future<void> updateRecipeAverageRating(String recipeId) async {
    try {
      double averageRating = await fetchAverageRating(recipeId);
      await _firestore.collection('recipes').doc(recipeId).update({
        'averageRating': averageRating,
      });
    } catch (e) {
      print("Error updating average rating: $e");
      throw Exception("Error updating average rating: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getInboxChats() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("User not logged in");

      // Query for chats where the current user is a participant
      final chatQuery = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUser.uid)
          .orderBy('lastMessageTime', descending: true)
          .get();

      List<Map<String, dynamic>> chats = [];

      for (var doc in chatQuery.docs) {
        final chatData = doc.data() as Map<String, dynamic>;

        // Extract participant IDs and fetch their details (username, profileImageUrl)
        List<String> participantIds =
            List<String>.from(chatData['participants']);
        participantIds.remove(currentUser.uid); // Remove the current user's ID

        if (participantIds.isNotEmpty) {
          final targetUserId =
              participantIds[0]; // Assuming only one other participant

          // Fetch target user's details (username and profile image)
          DocumentSnapshot targetUserDoc =
              await _firestore.collection('users').doc(targetUserId).get();
          final targetUserData = targetUserDoc.data() as Map<String, dynamic>;
          final targetUsername = targetUserData['username'] ?? 'Unknown';
          final targetProfileImageUrl = targetUserData['profileImageUrl'] ?? '';

          chats.add({
            'chatId': doc.id,
            'name': targetUsername,
            'profileImageUrl': targetProfileImageUrl,
            'lastMessage': chatData['lastMessage'] ?? '',
            'lastMessageTime': chatData['lastMessageTime'] ?? 'Not Available',
          });
        }
      }

      return chats;
    } catch (e) {
      print("Error fetching inbox chats: $e");
      return [];
    }
  }

  String formatTimestamp(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    final now = DateTime.now();
    if (dateTime.day == now.day &&
        dateTime.month == now.month &&
        dateTime.year == now.year) {
      return DateFormat('hh:mm a').format(dateTime); // e.g., "10:30 AM"
    } else if (dateTime.year == now.year) {
      return DateFormat('MMM d').format(dateTime); // e.g., "Nov 19"
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime); // e.g., "Nov 19, 2024"
    }
  }

  Stream<List<Map<String, dynamic>>> getChatMessages(String chatId) {
    try {
      return _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'messageId': doc.id,
            'message': data['message'],
            'senderId': data['senderId'],
            'timestamp': data['timestamp'],
            'isCurrentUser': data['senderId'] == _auth.currentUser?.uid,
          };
        }).toList();
      });
    } catch (e) {
      print("Error fetching messages: $e");
      return const Stream.empty();
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String message,
  }) async {
    try {
      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw Exception("User not logged in");
      }

      // Add the message to the messages subcollection
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'message': message,
        'senderId': currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update the lastMessage and lastMessageTime fields in the chat document
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': message,
        'lastMessageTime':
            FieldValue.serverTimestamp(), // Set the last message time
      });
    } catch (e) {
      print("Error sending message: $e");
      throw Exception("Error sending message: $e");
    }
  }

  Future<String> getOrCreateChat({required String targetUserId}) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("User not logged in");
      }

      // Check if a chat already exists between the two users
      final chatQuery = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUser.uid)
          .get();

      for (var doc in chatQuery.docs) {
        final participants = doc['participants'] as List<dynamic>;
        if (participants.contains(targetUserId)) {
          return doc.id; // Return the existing chatId
        }
      }

      // If no chat exists, create a new chat
      final chatDoc = await _firestore.collection('chats').add({
        'participants': [currentUser.uid, targetUserId],
        'createdAt': FieldValue.serverTimestamp(),
      });

      return chatDoc.id; // Return the new chatId
    } catch (e) {
      print("Error getting or creating chat: $e");
      throw Exception("Error getting or creating chat: $e");
    }
  }

  Future<List<String>> _fetchFollowingUserIds(String currentUserId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      if (userDoc.exists) {
        List<String> followingUserIds =
            List<String>.from(userDoc['followingUser'] ?? []);
        return followingUserIds;
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching following users: $e");
      return [];
    }
  }
}
