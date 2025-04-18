import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/disease_service.dart';
import 'login_screen.dart';
import 'community_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  XFile? _selectedImage;
  bool _isLoading = false;
  Map<String, dynamic>? _detectionResult;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = image;
        _detectionResult = null;
      });
    }
  }

  Future<void> _captureImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _selectedImage = image;
        _detectionResult = null;
      });
    }
  }

  Future<void> _detectDisease() async {
    final localizations = AppLocalizations.of(context);
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations?.pleaseSelectImage ?? 'Please select an image')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      Map<String, dynamic> result;
      
      if (kIsWeb) {
        // For web, we need to handle this differently
        final bytes = await _selectedImage!.readAsBytes();
        result = token != null 
            ? await DiseaseService.detectDiseaseWeb(bytes, token)
            : await DiseaseService.detectDiseaseAnonymousWeb(bytes);
      } else {
        // For mobile platforms
        final file = File(_selectedImage!.path);
        result = token != null
            ? await DiseaseService.detectDisease(file, token)
            : await DiseaseService.detectDiseaseAnonymousMobile(file);
      }

      if (!mounted) return;

      if (result['success']) {
        setState(() {
          _detectionResult = result['data'];
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

  Widget _buildDetectionResult() {
    final localizations = AppLocalizations.of(context);
    if (_detectionResult == null ||
        _detectionResult!['prediction'] == null ||
        _detectionResult!['probabilities'] == null) {
      return const SizedBox();
    }

    final prediction = _detectionResult!['prediction'] as String;
    final probabilities = _detectionResult!['probabilities'] as Map<String, dynamic>;

    // Sort probabilities by value in descending order
    final sortedProbabilities = probabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${localizations?.prediction ?? "Prediction"}: $prediction',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              localizations?.probabilities ?? "Probabilities",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...sortedProbabilities.map((entry) {
              final percentage = (entry.value * 100).toStringAsFixed(2);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(entry.key),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text('$percentage%'),
                    ),
                    Expanded(
                      flex: 6,
                      child: LinearProgressIndicator(
                        value: entry.value,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          entry.key == prediction ? Colors.green : Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildImageDisplay() {
    if (_selectedImage == null) {
      return const SizedBox();
    }

    if (kIsWeb) {
      // For web, we need to use a different approach
      return FutureBuilder<Uint8List>(
        future: _selectedImage!.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && 
              snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  snapshot.data!,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            );
          } else {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
        },
      );
    } else {
      // For mobile platforms
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(_selectedImage!.path),
            height: 300,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isAuthenticated;
    final username = authProvider.username;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.appTitle ?? 'Leafy'),
        actions: [
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await authProvider.logout();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  // Replace with a hardcoded string since the key doesn't exist
                  const SnackBar(content: Text('Logged out successfully')),
                );
              },
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.green,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.eco, size: 40, color: Colors.green),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isLoggedIn 
                        ? 'Hello, ${username ?? ""}!' 
                        : (localizations?.welcomeMessage ?? 'Welcome to Leafy!'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: Text(localizations?.community ?? 'Community'),
              onTap: () {
                Navigator.pop(context);
                if (isLoggedIn) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CommunityScreen()),
                  );
                } else {
                  _showLoginDialog(context);
                }
              },
            ),
            if (!isLoggedIn)
              ListTile(
                leading: const Icon(Icons.login),
                title: Text(localizations?.login ?? 'Login'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
              ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                isLoggedIn 
                    ? 'Welcome, ${username ?? ""}!' 
                    : (localizations?.welcomeMessage ?? 'Welcome to Leafy!'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                localizations?.uploadLeafImage ?? 'Upload a leaf image',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            if (_selectedImage != null) _buildImageDisplay(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: Text(localizations?.selectImage ?? 'Select Image'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _captureImage,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(localizations?.captureImage ?? 'Capture Image'),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _detectDisease,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        localizations?.detectDisease ?? 'Detect Disease',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
            if (_detectionResult != null) _buildDetectionResult(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(localizations?.joinCommunity ?? 'Join Community'),
        content: const Text(
          // Replace with a hardcoded string since the key doesn't exist
          'You need to be logged in to access the community features. Would you like to login or register now?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text(localizations?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: Text(localizations?.login ?? 'Login'),
          ),
        ],
      ),
    );
  }
}