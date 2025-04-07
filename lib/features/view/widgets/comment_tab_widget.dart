import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';

class CommentTabWidget extends StatefulWidget {
  final Future<List<QueryDocumentSnapshot>> Function() fetchComments;
  final TextEditingController commentController;
  final double rating;
  final Function(double) setRating;
  final Function() submitComment;

  CommentTabWidget({
    required this.fetchComments,
    required this.commentController,
    required this.rating,
    required this.setRating,
    required this.submitComment,
  });

  @override
  _CommentTabWidgetState createState() => _CommentTabWidgetState();
}

class _CommentTabWidgetState extends State<CommentTabWidget> {
  late Future<List<QueryDocumentSnapshot>> commentsFuture;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    commentsFuture = widget.fetchComments();
  }

  Future<void> _refreshComments() async {
    setState(() {
      commentsFuture = widget.fetchComments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            "Leave a review",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: 8),

          // RatingBar for setting rating
          Row(
            children: [
              RatingBar.builder(
                initialRating: widget.rating,
                minRating: 1,
                itemSize: 30,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemPadding: EdgeInsets.symmetric(horizontal: 2.0),
                itemBuilder: (context, _) =>
                    Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (rating) {
                  widget.setRating(rating); // Update rating
                },
              ),
            ],
          ),
          SizedBox(height: 8),

          TextField(
            controller: widget.commentController,
            decoration: InputDecoration(
              labelText: "Add your comment",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              filled: true,
              fillColor: Colors.grey[100],
              suffixIcon: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : IconButton(
                      icon: Icon(Icons.send, color: Colors.blueAccent),
                      onPressed: isLoading
                          ? null
                          : () async {
                              setState(() {
                                isLoading = true;
                              });
                              await widget.submitComment();
                              await _refreshComments(); // Refresh comments after submission
                              widget.commentController.clear(); // Clear input
                              widget.setRating(0.0); // Reset rating
                              setState(() {
                                isLoading = false;
                              });
                            },
                    ),
            ),
            maxLines: 3,
          ),

          SizedBox(height: 20),

          // Comments section
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshComments, // Trigger only on pull-to-refresh
              child: FutureBuilder<List<QueryDocumentSnapshot>>(
                future: commentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error loading comments"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text("No comments yet"));
                  } else {
                    var comments = snapshot.data!;
                    return ListView.builder(
                      physics: AlwaysScrollableScrollPhysics(),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        var comment =
                            comments[index].data() as Map<String, dynamic>;
                        String username = comment['username'] ?? "Anonymous";
                        String profileImageUrl = comment['profileImageUrl'] ??
                            "https://www.pngitem.com/pimgs/m/146-1468479_my-profile-icon-blank-profile-picture-circle-hd.png";

                        // Convert Timestamp to DateTime
                        Timestamp timestampObj =
                            comment['timestamp'] ?? Timestamp.now();
                        DateTime timestamp = timestampObj.toDate();

                        // Format the timestamp to a readable string
                        String formattedTimestamp =
                            DateFormat('dd/MM/yyyy').format(timestamp);

                        return Container(
                          margin: EdgeInsets.symmetric(
                              vertical: 4, horizontal: 0.5),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors
                                .blue, // Blue background color for the comment container
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile image and username in a column
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundImage:
                                        NetworkImage(profileImageUrl),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    username,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                              SizedBox(width: 12),
                              // Expanded column for the comment content, rating, and timestamp
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Comment text
                                    Text(
                                      comment['comment'],
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.white),
                                      textAlign: TextAlign.justify,
                                    ),
                                    SizedBox(height: 8),
                                    // Rating row
                                    Row(
                                      children: [
                                        Icon(Icons.star,
                                            color: Colors.amber, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          "${comment['rating']}",
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          formattedTimestamp, // Display the formatted timestamp
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.white70,
                                          ),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
