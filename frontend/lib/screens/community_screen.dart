import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http_parser/http_parser.dart'; // Make sure this import is present
import '../providers/auth_provider.dart';
import '../services/community_service.dart';
import '../utils/web_image_picker.dart';
import '../utils/constants.dart';
import '../widgets/create_post_widget.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<dynamic> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  // In your _fetchPosts method, update it to use the static method:
  Future<void> _fetchPosts() async {
    setState(() {
      _isLoading = true;
    });
  
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final posts = await CommunityService.getPosts(authProvider.token);
      
      // Debug print to check what's coming back from the API
      print('Fetched posts: $posts');
      
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (error) {
      print('Error fetching posts: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // And update your _loadPosts method to match:
  Future<void> _loadPosts() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final posts = await CommunityService.getPosts(authProvider.token);
      
      setState(() {
        _posts = posts;
      });
    } catch (error) {
      print('Error loading posts: $error');
    }
  }

  // Replace the existing _createPost method with this fixed version
  void _createPost() {
    // Show bottom sheet with create post form
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: CreatePostWidget(
          onPostCreated: _handlePostCreation,
        ),
      ),
    );
  }

  // Add this new method to handle post creation
  Future<void> _handlePostCreation(String caption, dynamic image) async {
    try {
      setState(() {
        _isLoading = true;
      });
  
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) return;
      
      // Fix the URL - use a hardcoded value if the env variable is null
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      final url = Uri.parse('$baseUrl/api/community/posts/');
      
      print('Attempting to create post at URL: $url');
      
      // Create multipart request
      var request = http.MultipartRequest('POST', url);
      
      // Add auth headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });
      
      // Add text fields
      request.fields['caption'] = caption;
      
      // Add image if available
      if (image != null) {
        if (kIsWeb) {
          // For web, handle XFile
          final bytes = await image.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              'image',
              bytes,
              filename: 'image.jpg',
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        } else {
          // For mobile platforms
          request.files.add(await http.MultipartFile.fromPath(
            'image',
            image.path,
          ));
        }
      }
      
      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      print('Post creation response: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Post created successfully
        await _fetchPosts(); // Refresh the posts list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully')),
        );
      } else {
        print('Failed to create post: ${response.statusCode}');
        print('Response body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create post: ${response.body}')),
        );
      }
    } catch (error) {
      print('Error creating post: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating post: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add this method to delete a post
  Future<void> _deletePost(int postId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) return;

      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      final response = await http.delete(
        Uri.parse('$baseUrl/api/community/posts/$postId/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      print('Delete post response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 204 || response.statusCode == 200) {
        setState(() {
          _posts.removeWhere((p) => p['id'] == postId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete post: ${response.body}')),
        );
      }
    } catch (error) {
      print('Error deleting post: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${error.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'), // Replace AppLocalizations with hardcoded text
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.nature_people, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No posts yet', // Replace AppLocalizations with hardcoded text
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _createPost,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Share Your Plants'), // Replace AppLocalizations with hardcoded text
                      ),
                    ],
                  ),
                )
              : // Replace the existing RefreshIndicator with this improved version
              RefreshIndicator(
                onRefresh: () async {
                  // Show a snackbar to indicate refresh is happening
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refreshing...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  
                  // Add haptic feedback
                  HapticFeedback.mediumImpact();
                  
                  // Perform the refresh
                  await _loadPosts();
                  
                  // Show success message
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Feed updated!'),
                        duration: Duration(seconds: 1),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(), // Better scrolling feel
                  itemCount: _posts.length,
                  itemBuilder: (ctx, index) {
                    final post = _posts[index];
                    // Apply staggered animations to each item
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: _buildPostCard(post),
                        ),
                      ),
                    );
                  },
                ),
              ),

      floatingActionButton: FloatingActionButton(
        onPressed: _createPost,
        child: const Icon(Icons.add_photo_alternate),
      ),
    );
  }

  // Update the _buildPostCard method to better handle image display and add delete functionality
  Widget _buildPostCard(dynamic post) {
    // Get the full image URL
    String imageUrl = '';
    if (post['image'] != null) {
      if (post['image'].toString().startsWith('http')) {
        imageUrl = post['image'].toString();
      } else {
        // For relative URLs, construct the full URL
        final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
        imageUrl = '$baseUrl${post['image']}';
      }
    }
    
    // Extract username from the post data
    String username = '';
    if (post['user'] != null) {
      if (post['user'] is Map) {
        username = post['user']['username'] ?? 'Unknown User';
      } else if (post['user'] is String) {
        username = post['user'];
      } else {
        username = 'Unknown User';
      }
    } else {
      username = 'Unknown User';
    }
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isCurrentUserPost = authProvider.username == post['user'].toString();
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              child: Text(post['user'].toString()[0].toUpperCase()),
            ),
            title: Text(post['user'].toString()),
            subtitle: Text(
              DateTime.tryParse(post['created_at'].toString()) != null
                  ? DateTime.parse(post['created_at'].toString()).toString().substring(0, 16)
                  : post['created_at'].toString(),
            ),
            trailing: isCurrentUserPost
                ? IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Post'),
                          content: const Text('Are you sure you want to delete this post?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _deletePost(post['id']);
                      }
                    },
                  )
                : null,
          ),
          if (post['caption'] != null && post['caption'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(post['caption'].toString()),
            ),
          // Display the image with better error handling
          if (imageUrl.isNotEmpty)
            Container(
              height: 300,
              width: double.infinity,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / 
                            loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading image: $error');
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 50),
                          SizedBox(height: 8),
                          Text('Image not available'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          
          // Add interaction buttons (like, comment, react)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Like button
                TextButton.icon(
                  icon: Icon(
                    post['is_liked'] == true ? Icons.favorite : Icons.favorite_border,
                    color: post['is_liked'] == true ? Colors.red : null,
                  ),
                  label: Text('${post['like_count'] ?? 0}'),
                  onPressed: () => _likePost(post['id']),
                ),
                
                // Comment button
                TextButton.icon(
                  onPressed: () => _showComments(post),
                  icon: const Icon(Icons.comment),
                  label: Text('${(post['comments'] as List?)?.length ?? 0}'),
                ),
                
                // React button (emoji)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.emoji_emotions),
                  onSelected: (String reaction) {
                    _reactToPost(post['id'], reaction);
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'like',
                      child: Text('👍 Like'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'love',
                      child: Text('❤️ Love'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'laugh',
                      child: Text('😂 Laugh'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'wow',
                      child: Text('😮 Wow'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'sad',
                      child: Text('😢 Sad'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'angry',
                      child: Text('😡 Angry'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Display comment count if there are comments
          if ((post['comments'] as List?)?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
              child: GestureDetector(
                onTap: () => _showComments(post),
                child: Text(
                  'View all ${(post['comments'] as List).length} comments',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Implement the _reactToPost method
  Future<void> _reactToPost(int postId, String reaction) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) return;
  
      final url = Uri.parse('${dotenv.env['API_BASE_URL']}/api/community/posts/$postId/react/');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'reaction': reaction}),
      );
  
      print('React post response: ${response.statusCode}');
      print('Response body: ${response.body}');
  
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh posts to show updated reactions
        await _loadPosts(); // Change from _fetchPosts to _loadPosts
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reacted with $reaction')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to react to post: ${response.body}')),
        );
      }
    } catch (error) {
      print('Error reacting to post: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${error.toString()}')),
      );
    }
  }

  // Complete the _showComments method
  Future<void> _showComments(dynamic post) async {
    final TextEditingController commentController = TextEditingController();
    int? replyToCommentId;
    String replyToUsername = '';

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          height: MediaQuery.of(ctx).size.height * 0.7,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Comments',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: post['comments'] == null || (post['comments'] as List).isEmpty 
                  ? const Center(child: Text('No comments yet'))
                  : ListView.builder(
                      itemCount: (post['comments'] as List).length,
                      itemBuilder: (ctx, index) {
                        final comment = post['comments'][index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                child: Text(comment['user']['username'].toString()[0].toUpperCase()),
                              ),
                              title: Text(comment['user']['username']),
                              subtitle: Text(comment['content']),
                              trailing: TextButton(
                                child: const Text('Reply'),
                                onPressed: () {
                                  setState(() {
                                    replyToCommentId = comment['id'];
                                    replyToUsername = comment['user']['username'];
                                    commentController.text = '@$replyToUsername ';
                                  });
                                },
                              ),
                            ),
                            // Show replies if any
                            if (comment['replies'] != null && (comment['replies'] as List).isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 40.0),
                                child: Column(
                                  children: [
                                    for (var reply in comment['replies'])
                                      ListTile(
                                        leading: CircleAvatar(
                                          radius: 12,
                                          child: Text(reply['user']['username'].toString()[0].toUpperCase()),
                                        ),
                                        title: Text(reply['user']['username'], 
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        subtitle: Text(reply['content'],
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            const Divider(),
                          ],
                        );
                      },
                    ),
              ),
              // Show who we're replying to
              if (replyToCommentId != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Row(
                    children: [
                      Text('Replying to: $replyToUsername', 
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          setState(() {
                            replyToCommentId = null;
                            replyToUsername = '';
                            commentController.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () async {
                        if (commentController.text.trim().isEmpty) return;

                        final authProvider = Provider.of<AuthProvider>(
                          context, 
                          listen: false
                        );
                        final token = authProvider.token;
                        if (token == null) return;

                        try {
                          final url = replyToCommentId == null
                            ? Uri.parse('${dotenv.env['API_BASE_URL']}/api/community/posts/${post['id']}/comments/')
                            : Uri.parse('${dotenv.env['API_BASE_URL']}/api/community/comments/$replyToCommentId/replies/');
                          
                          final response = await http.post(
                            url,
                            headers: {
                              'Authorization': 'Bearer $token',
                              'Content-Type': 'application/json',
                            },
                            body: jsonEncode({
                              'content': commentController.text,
                            }),
                          );

                          if (response.statusCode == 201) {
                            // Comment added successfully
                            commentController.clear();
                            
                            // Close the bottom sheet
                            Navigator.of(context).pop();
                            
                            // Refresh posts to show the new comment
                            _fetchPosts();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to add comment: ${response.body}')),
                            );
                          }
                        } catch (error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${error.toString()}')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // Implement the _likePost method
  Future<void> _likePost(int postId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) return;
  
      final url = Uri.parse('${dotenv.env['API_BASE_URL']}/api/community/posts/$postId/like/');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
  
      print('Like post response: ${response.statusCode}');
      print('Response body: ${response.body}');
  
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh posts to show updated like status
        await _loadPosts(); // Use _loadPosts instead of _fetchPosts
        
        // Add haptic feedback for better UX
        HapticFeedback.lightImpact();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to like post: ${response.body}')),
        );
      }
    } catch (error) {
      print('Error liking post: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${error.toString()}')),
      );
    }
  }
}

  