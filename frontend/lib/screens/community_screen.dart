import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/community_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  bool _isLoading = false;
  List<dynamic> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
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
        setState(() {
          _posts = result['data'];
        });
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

  Future<void> _createPost() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    final TextEditingController captionController = TextEditingController();

    if (!mounted) return;

    // Show dialog to add caption
    final bool? shouldPost = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(
              File(image.path),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: captionController,
              decoration: InputDecoration(
                hintText: 'Add a caption...',
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppLocalizations.of(context)!.post),
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
        captionController.text,  // First parameter should be the caption (String)
        File(image.path),        // Second parameter should be the image (File)
        token,                   // Third parameter is the token
      );

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully')),
        );
        _loadPosts(); // Reload posts
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
        title: Text(AppLocalizations.of(context)!.community),
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
                      Text(
                        AppLocalizations.of(context)!.noPostsYet,
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _createPost,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: Text(AppLocalizations.of(context)!.shareYourPlants),
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

  Widget _buildPostCard(dynamic post) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              child: Text(post['user'][0].toUpperCase()),
            ),
            title: Text(post['user']),
            subtitle: Text(
              DateTime.parse(post['created_at']).toLocal().toString().split('.')[0],
            ),
          ),
          Image.network(
            post['image'],
            height: 300,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.error, size: 50),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(post['caption']),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    post['is_liked'] ? Icons.favorite : Icons.favorite_border,
                    color: post['is_liked'] ? Colors.red : null,
                  ),
                  onPressed: () => _likePost(post['id']),
                ),
                Text('${post['like_count']}'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment),
                  onPressed: () => _showComments(post),
                ),
                Text('${post['comments'].length}'),
              ],
            ),
          ),
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
                ? Center(child: Text('No comments yet'))
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