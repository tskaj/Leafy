import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/auth_provider.dart';
import '../services/community_service.dart';
import '../utils/web_image_picker.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<dynamic> _posts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadPosts();
  }

  Future<void> _checkAuthAndLoadPosts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Check if user is authenticated
    if (!authProvider.isAuthenticated) {
      // If not authenticated, show login dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLoginDialog();
      });
      return;
    }
    
    // If authenticated, load posts
    _loadPosts();
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('You need to login to access the community features.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('Login'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/register');
            },
            child: const Text('Register'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/home');
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        if (!mounted) return;
        Navigator.of(context).pop();
        return;
      }

      final result = await CommunityService.getPosts(token);

      if (!mounted) return;

      if (result['success']) {
        // Check if data is a List or an Object with a 'data' field
        if (result['data'] is List) {
          setState(() {
            _posts = result['data'];
          });
        } else if (result['data'] is Map && result['data']['data'] != null) {
          setState(() {
            _posts = result['data']['data'];
          });
        } else {
          // Handle case where data is in a different format
          // For now, use dummy data
          setState(() {
            _posts = [
              {
                'id': 1,
                'user': 'Demo User',
                'caption': 'Beautiful plant collection',
                'image': 'https://via.placeholder.com/300x200?text=Plant+Image',
                'created_at': DateTime.now().toIso8601String(),
                'like_count': 5,
                'is_liked': false,
                'comments': []
              }
            ];
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    } catch (error) {
      if (!mounted) return;
      print('Error loading posts: ${error.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${error.toString()}')),
      );
      
      // Use dummy data when there's an error
      setState(() {
        _posts = [
          {
            'id': 1,
            'user': 'Demo User',
            'caption': 'Beautiful plant collection',
            'image': 'https://via.placeholder.com/300x200?text=Plant+Image',
            'created_at': DateTime.now().toIso8601String(),
            'like_count': 5,
            'is_liked': false,
            'comments': []
          }
        ];
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _createPost() async {
    final imageData = await WebImagePicker.pickImage();
    
    if (imageData == null) return;
    
    final TextEditingController captionController = TextEditingController();
    
    if (!mounted) return;
    
    // Show dialog to add caption
    final bool? shouldPost = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Post'),
        content: SingleChildScrollView( // Wrap with SingleChildScrollView
          child: Column(
            mainAxisSize: MainAxisSize.min, // Keep this
            children: [
              // Fix the image display with constrained dimensions
              Container(
                constraints: BoxConstraints(
                  maxHeight: 200,
                  maxWidth: MediaQuery.of(context).size.width * 0.6,
                ),
                child: kIsWeb
                    ? Image.memory(
                        imageData['bytes'],
                        fit: BoxFit.contain, // Use contain instead of cover
                      )
                    : Image.file(
                        File(imageData['path']),
                        fit: BoxFit.contain, // Use contain instead of cover
                      ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: captionController,
                decoration: const InputDecoration(
                  hintText: 'Add a caption...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Post'),
          ),
        ],
      ),
    );
  
    if (shouldPost != true) return;
  
    setState(() {
      _isLoading = true;
    });
  
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
  
      if (token == null) {
        if (!mounted) return;
        Navigator.of(context).pop();
        return;
      }
  
      final result = await CommunityService.createPost(
        captionController.text,
        imageData,
        token,
      );
  
      if (!mounted) return;
  
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully')),
        );
        
        // Add the new post to the posts list
        if (result['data'] != null) {
          setState(() {
            // Add the new post at the beginning of the list
            _posts.insert(0, result['data']);
          });
        } else {
          // If for some reason the data is not returned, reload all posts
          await _loadPosts();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${error.toString()}')),
      );
    }
  
    setState(() {
      _isLoading = false;
    });
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
              : RefreshIndicator(
                  onRefresh: _loadPosts,
                  child: ListView.builder(
                    itemCount: _posts.length,
                    itemBuilder: (ctx, index) {
                      final post = _posts[index];
                      return _buildPostCard(post);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPost,
        child: const Icon(Icons.add_photo_alternate),
      ),
    );
  }

  // Update the _buildPostCard method to better handle image display
  
  Widget _buildPostCard(dynamic post) {
  // Get the full image URL
  String imageUrl = '';
  if (post['image'] != null) {
    if (post['image'].toString().startsWith('http')) {
      imageUrl = post['image'].toString();
    } else {
      // For relative URLs, construct the full URL
      imageUrl = '${CommunityService.getBaseUrl()}${post['image']}';
    }
  }
  
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
                  child: Center(
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
        
        // Rest of your card implementation...
      ],
    ),
  );
}

  Future<void> _likePost(int postId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) return;

      final result = await CommunityService.likePost(postId, token);

      if (!mounted) return;

      if (result['success']) {
        // Update the post in the list
        setState(() {
          for (int i = 0; i < _posts.length; i++) {
            if (_posts[i]['id'] == postId) {
              _posts[i]['is_liked'] = result['data']['liked'];
              _posts[i]['like_count'] = result['data']['like_count'];
              break;
            }
          }
        });
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${error.toString()}')),
      );
    }
  }

  Future<void> _showComments(dynamic post) async {
    final TextEditingController commentController = TextEditingController();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        height: MediaQuery.of(ctx).size.height * 0.7,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Comments',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: post['comments'].isEmpty 
                ? const Center(child: Text('No comments yet'))
                : ListView.builder(
                    itemCount: post['comments'].length,
                    itemBuilder: (ctx, index) {
                      final comment = post['comments'][index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(comment['user'][0].toUpperCase()),
                        ),
                        title: Text(comment['user']),
                        subtitle: Text(comment['text']),
                      );
                    },
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

                      final result = await CommunityService.addComment(
                        post['id'],
                        commentController.text,
                        token,
                      );

                      if (!mounted) return;

                      if (result['success']) {
                        Navigator.of(ctx).pop();
                        _loadPosts(); // Reload posts to get updated comments
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'])),
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
    );
  }
}