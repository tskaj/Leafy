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
import 'login_screen.dart';
import 'package:flutter/foundation.dart';


class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<dynamic> _posts = [];
  bool _isLoading = true;

  // Helper method to ensure image URLs are complete
  String _getFullImageUrl(String? imageUrl) {
    if (imageUrl == null) return '';
    if (imageUrl.startsWith('http')) {
      return imageUrl;
    } else {
      // For relative URLs, construct the full URL
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      return '$baseUrl$imageUrl';
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  // In your _fetchPosts method, update it to use the static method:
  Future<void> _fetchPosts() async {
    print('[DEBUG] _fetchPosts: Starting fetch...'); // DEBUG
    setState(() {
      _isLoading = true;
    });
  
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      print('[DEBUG] _fetchPosts: Fetching posts with token: ${authProvider.token}'); // DEBUG
      final posts = await CommunityService.getPosts(authProvider.token);
      
      // Debug print to check what's coming back from the API
      print('[DEBUG] _fetchPosts: Fetched posts raw data: $posts'); // DEBUG
      
      // Debug print to check user data structure in each post
      // for (var post in posts) {
      //   print('Post user data: ${post['user']}');
      //   if (post['user'] is Map) {
      //     print('User profile image: ${post['user']['profile_image']}');
      //   }
      // }
      
      if (mounted) { // Check if the widget is still mounted
        print('[DEBUG] _fetchPosts: Widget is mounted. Updating state.'); // DEBUG
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
        print('[DEBUG] _fetchPosts: State updated successfully.'); // DEBUG
      } else {
        print('[DEBUG] _fetchPosts: Widget is NOT mounted. Skipping setState.'); // DEBUG
      }
    } catch (error) {
      print('[DEBUG] _fetchPosts: Error fetching posts: $error'); // DEBUG
      if (mounted) { // Check if mounted before setting state in catch block
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // And update your _loadPosts method to match:
  Future<void> _loadPosts() async {
    print('[DEBUG] _loadPosts: Starting load...'); // DEBUG
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      print('[DEBUG] _loadPosts: Loading posts with token: ${authProvider.token}'); // DEBUG
      final posts = await CommunityService.getPosts(authProvider.token);
      print('[DEBUG] _loadPosts: Loaded posts raw data: $posts'); // DEBUG
      
      if (mounted) { // Check if mounted
        print('[DEBUG] _loadPosts: Widget is mounted. Updating state.'); // DEBUG
        setState(() {
          _posts = posts;
        });
        print('[DEBUG] _loadPosts: State updated successfully.'); // DEBUG
      } else {
        print('[DEBUG] _loadPosts: Widget is NOT mounted. Skipping setState.'); // DEBUG
      }
    } catch (error) {
      print('[DEBUG] _loadPosts: Error loading posts: $error'); // DEBUG
    }
  }

  // Replace the existing _createPost method with this fixed version
  void _createPost() {
    print('[DEBUG] _createPost: Showing modal bottom sheet.'); // DEBUG
    // Show bottom sheet with create post form
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: CreatePostWidget(
          onPostCreated: (caption, image) => _handlePostCreation(caption, image, null),
        ),
      ),
    );
  }

  // Add this new method to handle post creation
  Future<void> _handlePostCreation(String caption, dynamic image, dynamic response) async {
    print('[DEBUG] _handlePostCreation: Starting post creation...'); // DEBUG
    try {
      if (!mounted) {
        print('[DEBUG] _handlePostCreation: Widget not mounted at start. Aborting.'); // DEBUG
        return;
      }
      setState(() {
        _isLoading = true;
      });
      print('[DEBUG] _handlePostCreation: Set loading state to true.'); // DEBUG
  
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) {
        print('[DEBUG] _handlePostCreation: Auth token is null. Showing error.'); // DEBUG
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication error. Please log in again.')),
        );
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }
      print('[DEBUG] _handlePostCreation: Auth token retrieved.'); // DEBUG

      // Call the service method
      Map<String, dynamic> result;
      print('[DEBUG] _handlePostCreation: Preparing to call CommunityService.createPost...'); // DEBUG
      if (kIsWeb && image is XFile) {
        print('[DEBUG] _handlePostCreation: Handling web image.'); // DEBUG
        final bytes = await image.readAsBytes();
        result = await CommunityService.createPost(caption, null, token, imageBytes: bytes);
      } else if (!kIsWeb && image is File) {
        print('[DEBUG] _handlePostCreation: Handling mobile image.'); // DEBUG
        result = await CommunityService.createPost(caption, image, token);
      } else if (image == null) {
        print('[DEBUG] _handlePostCreation: Handling post without image.'); // DEBUG
        result = await CommunityService.createPost(caption, null, token);
      } else {
        print('[DEBUG] _handlePostCreation: Invalid image type. Showing error.'); // DEBUG
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid image type.')),
        );
        if (mounted) { setState(() { _isLoading = false; }); }
        return;
      }
      print('[DEBUG] _handlePostCreation: CommunityService.createPost returned: $result'); // DEBUG

      if (!mounted) {
         print('[DEBUG] _handlePostCreation: Widget not mounted after API call. Aborting.'); // DEBUG
         return;
      }

      if (result['success']) {
        print('[DEBUG] _handlePostCreation: Post creation successful. Popping modal.'); // DEBUG
        Navigator.of(context).pop(); // Close the bottom sheet FIRST
        print('[DEBUG] _handlePostCreation: Modal popped. Showing success snackbar.'); // DEBUG
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully')),
        );
        print('[DEBUG] _handlePostCreation: Calling _fetchPosts to refresh.'); // DEBUG
        await _fetchPosts(); // Refresh the posts list AFTER closing the sheet
        print('[DEBUG] _handlePostCreation: _fetchPosts completed.'); // DEBUG
      } else {
        print('[DEBUG] _handlePostCreation: Post creation failed. Error: ${result['message']}'); // DEBUG
        // print('Error creating post: ${result['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create post: ${result['message']}')), // Show error from result
        );
        // This second snackbar seems redundant and potentially confusing
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Failed to create post: ${response?.body ?? 'Unknown error'}')),
        // );
      }
    } catch (error, stackTrace) { // Catch stack trace too
      print('[DEBUG] _handlePostCreation: Caught error: $error'); // DEBUG
      print('[DEBUG] _handlePostCreation: Stack trace: $stackTrace'); // DEBUG
      // print('Error creating post: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating post: $error')),
        );
      }
    } finally {
      print('[DEBUG] _handlePostCreation: Entering finally block.'); // DEBUG
      if (mounted) {
        print('[DEBUG] _handlePostCreation: Widget mounted in finally. Setting loading state to false.'); // DEBUG
        setState(() {
          _isLoading = false;
        });
      } else {
        print('[DEBUG] _handlePostCreation: Widget NOT mounted in finally.'); // DEBUG
      }
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

  // Add this new method to delete a comment
  Future<void> _deleteComment(int commentId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) return;

      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      // Assuming the endpoint structure for comment deletion
      final url = Uri.parse('$baseUrl/api/community/comments/$commentId/'); 
      
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Delete comment response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 204 || response.statusCode == 200) {
        // Optionally, you might want to refresh the specific post's comments
        // or just show a success message and let the user manually refresh.
        // For simplicity, just show a snackbar here.
        // You might need to pass the postId to refresh comments if needed.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment deleted')),
        );
        // Close the comments sheet after deletion
        Navigator.of(context).pop(); 
        // Refresh posts to reflect comment count change
        _loadPosts(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete comment: ${response.body}')),
        );
      }
    } catch (error) {
      print('Error deleting comment: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting comment: ${error.toString()}')),
      );
    }
  }

  // Add login prompt widget
  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Login Required',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'You need to login to access the community features and connect with other plant enthusiasts.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Login', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isAuth;
    
    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search in Community',
              prefixIcon: const Icon(Icons.search),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (value) {
              // Implement search functionality
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Notification functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // More options
            },
          ),
        ],
      ),
      body: !isLoggedIn
          ? _buildLoginPrompt()
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildFilterSection(),
                    Expanded(
                      child: _posts.isEmpty
                          ? _buildEmptyState()
                          : _buildPostsList(),
                    ),
                  ],
                ),
      floatingActionButton: isLoggedIn ? FloatingActionButton.extended(
        onPressed: _createPost,
        icon: const Icon(Icons.edit),
        label: const Text('Ask Community'),
        backgroundColor: Colors.blue,
      ) : null,
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter by',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Change filter functionality
                },
                child: Text(
                  'Change',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Zucchini', Icons.eco, Colors.green),
                const SizedBox(width: 8),
                _buildFilterChip('Wheat', Icons.grass, Colors.amber),
                const SizedBox(width: 8),
                _buildFilterChip('Sugarcane', Icons.grass, Colors.green),
                const SizedBox(width: 8),
                _buildFilterChip('Strawberry', Icons.favorite, Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.nature_people, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No posts yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createPost,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Share Your Plants'),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsList() {
    return RefreshIndicator(
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
        physics: const BouncingScrollPhysics(),
        itemCount: _posts.length,
        itemBuilder: (ctx, index) {
          final post = _posts[index];
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
    );
  }

  // Update the _buildPostCard method to better handle image display and add delete functionality
  Widget _buildPostCard(dynamic post) {
    // Get the full image URL using helper method
    String imageUrl = '';
    if (post['image'] != null) {
      imageUrl = _getFullImageUrl(post['image'].toString());
    }
    
    // Extract username and profile image from the post data
    String username = '';
    String? profileImageUrl;
    
    if (post['user'] != null) {
      if (post['user'] is Map) {
        // If user is a Map, extract username and profile_image
        username = post['user']['username'] ?? 'Unknown User';
        if (post['user']['profile_image'] != null) {
          // Use helper method to ensure URL is complete
          profileImageUrl = _getFullImageUrl(post['user']['profile_image'].toString());
          print('Profile image URL: $profileImageUrl'); // Debug print
        }
      } else if (post['user'] is String) {
        // If user is just a string (username), use that
        username = post['user'];
        // Try to get profile image from AuthProvider if this is the current user
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.username == username && authProvider.profileImage != null) {
          // Use helper method to ensure URL is complete
          profileImageUrl = _getFullImageUrl(authProvider.profileImage);
          print('Profile image from auth provider: $profileImageUrl'); // Debug print
        }
      } else {
        username = 'Unknown User';
      }
    } else {
      username = 'Unknown User';
    }
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isCurrentUserPost = authProvider.username == username;
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              // Display profile image if available
              child: profileImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: profileImageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) {
                        print('Error loading profile image: $error for URL: $profileImageUrl');
                        return Text(username.isNotEmpty ? username[0].toUpperCase() : '?');
                      },
                    ),
                  )
                : Text(username.isNotEmpty ? username[0].toUpperCase() : '?'),
            ),
            title: Text(username), // Use the extracted username
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
          // Display the image with better error handling using CachedNetworkImage
          if (imageUrl.isNotEmpty)
            Container(
              height: 300,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) {
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
                      child: Row(
                        children: [
                          Text('👍 ', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text('Like'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'love',
                      child: Row(
                        children: [
                          Text('❤️ ', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text('Love'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'laugh',
                      child: Row(
                        children: [
                          Text('😂 ', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text('Laugh'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'wow',
                      child: Row(
                        children: [
                          Text('😮 ', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text('Wow'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'sad',
                      child: Row(
                        children: [
                          Text('😢 ', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text('Sad'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'angry',
                      child: Row(
                        children: [
                          Text('😡 ', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text('Angry'),
                        ],
                      ),
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

  // Implement the _likePost method
  Future<void> _likePost(int postId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) return;
      
      final result = await CommunityService.likePost(postId, token);
      
      if (result['success']) {
        await _fetchPosts(); // Refresh posts to update like status
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    } catch (error) {
      print('Error liking post: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${error.toString()}')),
      );
    }
  }

  // Implement the _reactToPost method
  // Show comments in a bottom sheet
  // Implementation of the _showComments method
  void _showComments(dynamic post) {
    final commentController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 16,
            left: 16,
            right: 16,
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
            minHeight: MediaQuery.of(ctx).size.height * 0.5,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Comments',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Comments list
              Expanded(
                child: (post['comments'] as List? ?? []).isEmpty
                  ? Center(child: Text('No comments yet. Be the first to comment!'))
                  : ListView.builder(
                      itemCount: (post['comments'] as List).length,
                      itemBuilder: (ctx, index) {
                        final comment = (post['comments'] as List)[index];
                        return _buildCommentItem(comment, post['id']);
                      },
                    ),
              ),
              // Add comment input
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        maxLines: 3,
                        minLines: 1,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () async {
                        if (commentController.text.isEmpty) return;
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final token = authProvider.token;
                        if (token == null) return;
                        try {
                          final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
                          final url = Uri.parse('$baseUrl/api/community/posts/${post['id']}/comments/');
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
                            commentController.clear();
                            Navigator.of(context).pop();
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
  // Build a comment item widget
  Widget _buildCommentItem(dynamic comment, int postId) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isCurrentUserComment = authProvider.username == comment['user'].toString();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User avatar
          CircleAvatar(
            backgroundColor: Colors.green.shade200,
            child: Text(
              comment['user'].toString()[0].toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment['user'].toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (isCurrentUserComment)
                      IconButton(
                        icon: const Icon(Icons.delete, size: 16, color: Colors.red), // Changed icon
                        onPressed: () async { // Same onPressed logic
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Comment'),
                              content: const Text('Are you sure you want to delete this comment?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            // Call the new _deleteComment method
                            await _deleteComment(comment['id']);
                            // Note: _deleteComment already handles showing snackbars,
                            // closing the dialog (implicitly by popping), and refreshing posts.
                          }
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment['text'].toString()), // Changed 'content' to 'text'
                const SizedBox(height: 4),
                Text(
                  _formatDate(comment['created_at']),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                // Reply button
                TextButton.icon(
                  onPressed: () {
                    // Show reply dialog
                    _showReplyDialog(postId, comment['id']);
                  },
                  icon: const Icon(Icons.reply, size: 16),
                  label: const Text('Reply'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                // Display replies if any
                if (comment['replies'] != null && (comment['replies'] as List).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                    child: Column(
                      children: (comment['replies'] as List).map<Widget>((reply) {
                        return _buildCommentItem(reply, postId);
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Show reply dialog
  void _showReplyDialog(int postId, int commentId) {
    final replyController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reply to comment'),
        content: TextField(
          controller: replyController,
          decoration: const InputDecoration(
            hintText: 'Write your reply...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (replyController.text.isEmpty) return;
              
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final token = authProvider.token;
              if (token == null) return;
              
              try {
                final result = await CommunityService.addComment(
                  postId,
                  replyController.text,
                  token,
                  parentId: commentId,
                );
                
                if (result['success']) {
                  Navigator.of(ctx).pop();
                  await _fetchPosts();
                  Navigator.of(context).pop(); // Close the comments sheet
                  _showComments(_posts.firstWhere((p) => p['id'] == postId)); // Reopen with updated data
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result['message'])),
                  );
                }
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${error.toString()}')),
                );
              }
            },
            child: const Text('Reply'),
          ),
        ],
      ),
    );
  }

  // Format date for comments
  String _formatDate(dynamic dateString) {
    if (dateString == null) return '';
    
    try {
      final date = DateTime.parse(dateString.toString());
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 7) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateString.toString();
    }
  }
  
  // Add this helper method for filter chips
  Widget _buildFilterChip(String label, IconData icon, Color color) {
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      backgroundColor: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
  
// Implement the _reactToPost method
Future<void> _reactToPost(int postId, String reaction) async {
  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;
    
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
    final url = Uri.parse('$baseUrl/api/community/posts/$postId/react/');
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'reaction_type': reaction,
      }),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      await _fetchPosts(); // Refresh posts to update reactions
      HapticFeedback.lightImpact();
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
}}