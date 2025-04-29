import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  
  // Helper method to ensure image URLs are complete
  String _getFullImageUrl(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return imageUrl;
    } else {
      // For relative URLs, construct the full URL
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      return '$baseUrl$imageUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isAuth;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leafy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show more options
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isLoggedIn) _buildNotLoggedInView(context),
            if (isLoggedIn) _buildLoggedInView(context, authProvider),
            
            const Divider(),
            
            _buildGrowTogetherSection(context),
            
            const Divider(),
            
            _buildFeedbackSection(context),
            
            const Divider(),
            
            _buildLanguageSection(context),
            
            const SizedBox(height: 20),
            
            _buildStoriesSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildNotLoggedInView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 50,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('Join Leafy Community'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Sign in',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Method to show profile image options
  void _showProfileImageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take a photo'),
            onTap: () {
              Navigator.of(ctx).pop();
              _uploadProfileImage(context, ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from gallery'),
            onTap: () {
              Navigator.of(ctx).pop();
              _uploadProfileImage(context, ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  // Method to upload profile image
  Future<void> _uploadProfileImage(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(
        source: source,
        maxWidth: 600,
      );

      if (pickedImage == null) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) return;

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading profile image...')),
      );

      // Prepare the request
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      // Corrected the endpoint based on backend URL configuration
      final url = Uri.parse('$baseUrl/profile/'); 
      
      // Changed method to PUT as profile update is likely idempotent
      var request = http.MultipartRequest('PUT', url);
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add the image file
      if (kIsWeb) {
        final imageBytes = await pickedImage.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'profile_image',
          imageBytes,
          filename: pickedImage.name, // Use pickedImage.name for web
          contentType: MediaType('image', 'jpeg'), // Adjust content type if needed
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'profile_image',
          pickedImage.path,
          contentType: MediaType('image', 'jpeg'), // Adjust content type if needed
        ));
      }
      
      // Send the request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        // Update the profile image in the provider
        final data = json.decode(responseData);
        if (data['profile_image'] != null) {
          authProvider.updateProfileImage(data['profile_image']);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile image: ${responseData}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${error.toString()}')),
      );
    }
  }

  Widget _buildLoggedInView(BuildContext context, AuthProvider authProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showProfileImageOptions(context),
                    child: Stack(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(45),
                            border: Border.all(color: Colors.green.shade300, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(45),
                            child: authProvider.profileImage != null
                                ? CachedNetworkImage(
                                    imageUrl: _getFullImageUrl(authProvider.profileImage!),
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    errorWidget: (context, url, error) {
                                      print('Error loading profile image: $error');
                                      return Center(
                                        child: Text(
                                          authProvider.username?[0].toUpperCase() ?? 'U',
                                          style: TextStyle(fontSize: 36, color: Colors.green.shade700),
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    },
                                  )
                                : Center(
                                    child: Text(
                                      authProvider.username?[0].toUpperCase() ?? 'U',
                                      style: TextStyle(fontSize: 36, color: Colors.green.shade700),
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if(authProvider.username != null && authProvider.username!.isNotEmpty)
                          Text(
                            authProvider.username!,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(height: 8),
                        // Only show email if available
                        if (authProvider.email != null && authProvider.email!.isNotEmpty)
                          Text(
                            authProvider.email!,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Account Settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Navigate to settings
                },
              ),
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: const Text('Sign Out'),
                onTap: () {
                  authProvider.logout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrowTogetherSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.eco,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Grow smart together!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Share Leafy and help farmers solve their plant problems.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  // Share app functionality
                },
                child: Text(
                  'Share Leafy',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.star_border,
                  color: Colors.green,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How is your experience with Leafy app?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'We\'d love to hear your thoughts and suggestions.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  // Feedback functionality
                },
                child: Text(
                  'Give Feedback',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Language Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildLanguageOption(context, 'English', const Locale('en', '')),
              const Divider(),
              _buildLanguageOption(context, 'اردو (Urdu)', const Locale('ur', '')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, String language, Locale locale) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isSelected = languageProvider.locale?.languageCode == locale.languageCode;
    
    return InkWell(
      onTap: () {
        languageProvider.setLocale(locale);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Text(
              language,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoriesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stories picked up for you',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green,
                        child: const Icon(Icons.eco, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Leafy',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Pest Control: Managing Sucking Pests',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/pests.jpg',
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 40),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
