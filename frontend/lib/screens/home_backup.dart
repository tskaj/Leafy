import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../services/disease_service.dart';
import 'new_login_screen.dart';
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
  String _selectedCrop = 'tomato';
  List<String> _availableCrops = ['tomato'];
  bool _loadingCrops = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableCrops();
  }

  Future<void> _loadAvailableCrops() async {
    setState(() {
      _loadingCrops = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      final crops = await DiseaseService.getAvailableCrops(token);
      
      setState(() {
        _availableCrops = crops;
        _loadingCrops = false;
      });
    } catch (e) {
      setState(() {
        _loadingCrops = false;
      });
    }
  }
  void _navigateToLogin() {
    // Ensure context is still valid before navigating
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (ctx) => const NewLoginScreen()), // Now this should be found
      );
    }
  }
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final isValidLeafImage = await _validateLeafImage(image);
      if (isValidLeafImage) {
        setState(() {
          _selectedImage = image;
          _detectionResult = null;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)?.pleaseSelectLeafImage ?? 'Please select a leaf image')),
          );
        }
      }
    }
  }

  Future<void> _captureImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      final isValidLeafImage = await _validateLeafImage(image);
      if (isValidLeafImage) {
        setState(() {
          _selectedImage = image;
          _detectionResult = null;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)?.pleaseSelectLeafImage ?? 'Please select a leaf image')),
          );
        }
      }
    }
  }
  
  Future<bool> _validateLeafImage(XFile image) async {
    // Basic validation based on file extension
    final validExtensions = ['jpg', 'jpeg', 'png'];
    
    // Handle both regular file paths and blob URLs
    String fileExtension;
    if (kIsWeb && image.path.startsWith('blob:')) {
      // For web, we can't rely on the path for extension
      // Instead, check the name property or use a default
      final fileName = image.name?.toLowerCase() ?? '';
      fileExtension = fileName.contains('.')
          ? fileName.split('.').last
          : 'jpg'; // Default to jpg if no extension found
      print('Web image detected, using name for extension: $fileExtension');
    } else {
      // For mobile platforms, use the path
      fileExtension = image.path.split('.').last.toLowerCase();
    }
    
    if (!validExtensions.contains(fileExtension)) {
      print('Invalid file extension: $fileExtension');
      return false;
    }
    
    // Size validation
    try {
      final fileBytes = await image.readAsBytes();
      final fileSizeInMB = fileBytes.length / (1024 * 1024);
      if (fileSizeInMB > 10) { // Limit to 10MB
        print('File too large: ${fileSizeInMB.toStringAsFixed(2)} MB');
        return false;
      }
    } catch (e) {
      print('Error checking file size: $e');
      // Continue with validation if size check fails
    }
    
    // Use the same validation approach for both web and mobile
    try {
      final result = await DiseaseService.validateLeafImage(image);
      
      if (result['success']) {
        // Check if it's a leaf with sufficient confidence
        final isLeaf = result['isLeaf'] as bool;
        final confidence = result['confidence'] as double;
        
        // Set a reasonable confidence threshold
        final confidenceThreshold = 0.6; // 60% confidence threshold
        
        print('Leaf validation result: isLeaf=$isLeaf, confidence=$confidence');
        return isLeaf && confidence >= confidenceThreshold;
      } else {
        // If API call failed, show the error but don't accept the image
        print('Leaf validation API error: ${result['message']}');
        // Don't default to accepting non-leaf images
        return false;
      }
    } catch (e) {
      // If there's an exception, don't accept the image
      print('Error during leaf validation: $e');
      return false;
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
            ? await DiseaseService.detectDiseaseWeb(bytes, token, cropType: _selectedCrop)
            : await DiseaseService.detectDiseaseAnonymousWeb(bytes, cropType: _selectedCrop);
      } else {
        // For mobile platforms
        final file = File(_selectedImage!.path);
        result = token != null
            ? await DiseaseService.detectDisease(file, token, cropType: _selectedCrop)
            : await DiseaseService.detectDiseaseAnonymousMobile(file, cropType: _selectedCrop);
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

  Widget _buildCropSelector() {
    return _loadingCrops
        ? const Center(child: CircularProgressIndicator())
        : Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Crop Type:',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _availableCrops.length,
                    itemBuilder: (context, index) {
                      final crop = _availableCrops[index];
                      final isSelected = crop == _selectedCrop;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCrop = crop;
                            _detectionResult = null;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 12),
                          width: 100,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.green.shade100 : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Colors.green : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.eco,
                                color: isSelected ? Colors.green : Colors.grey,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                crop.capitalize(),
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.green : Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
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

    // Determine if the prediction is healthy or diseased
    final bool isHealthy = prediction.toLowerCase().contains('healthy');
    final Color accentColor = isHealthy ? Colors.green : Colors.orange;
    final IconData statusIcon = isHealthy ? Icons.check_circle : Icons.warning_rounded;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 1,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.green.shade50,
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with prediction result
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accentColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(statusIcon, color: accentColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations?.prediction ?? "Prediction",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              prediction,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Probabilities section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bar_chart_rounded, color: Colors.grey[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            localizations?.probabilities ?? "Probabilities",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...sortedProbabilities.map((entry) {
                        final percentage = (entry.value * 100).toStringAsFixed(1);
                        final isTopPrediction = entry.key == prediction;
                        final double percentageValue = double.parse(percentage);
                        
                        // Determine color based on prediction and percentage
                        Color barColor;
                        if (isTopPrediction) {
                          barColor = isHealthy ? Colors.green.shade500 : Colors.orange.shade500;
                        } else {
                          // Gradient from blue to grey based on percentage
                          barColor = percentageValue > 20 ? Colors.blue.shade400 : Colors.grey.shade400;
                        }
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isTopPrediction ? FontWeight.bold : FontWeight.w500,
                                        color: isTopPrediction ? Colors.green.shade800 : Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: barColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: barColor.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      '$percentage%',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: barColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Stack(
                                children: [
                                  // Background track
                                  Container(
                                    height: 10,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  // Progress bar with animated gradient
                                  FractionallySizedBox(
                                    widthFactor: entry.value,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 800),
                                      height: 10,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            barColor,
                                            barColor.withOpacity(0.7),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: isTopPrediction ? [
                                          BoxShadow(
                                            color: barColor.withOpacity(0.4),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ] : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageDisplay() {
    if (_selectedImage == null) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            if (kIsWeb)
              // For web platforms
              FutureBuilder<Uint8List>(
                future: _selectedImage!.readAsBytes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done && 
                      snapshot.hasData) {
                    return Image.memory(
                      snapshot.data!,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    );
                  } else {
                    return Container(
                      height: 300,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }
                },
              )
            else
              // For mobile platforms
              Image.file(
                File(_selectedImage!.path),
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            
            // Overlay gradient for better text visibility if needed
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'Selected Image',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // In the build method of your HomeScreen class, update the AppBar:
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isLoggedIn = authProvider.isAuth;
    // Remove the duplicate declaration
    final username = authProvider.username;
    final localizations = AppLocalizations.of(context);
  
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.green.shade50,
        foregroundColor: Colors.green.shade800,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.eco, color: Colors.green),
            ),
            const SizedBox(width: 12),
            Text(
              localizations?.appTitle ?? 'Leafy',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          // Language selection button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.language, color: Colors.green),
              tooltip: 'Change Language',
              onPressed: () {
                _showLanguageDialog(context, languageProvider);
              },
            ),
          ),
          if (isLoggedIn)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.logout, color: Colors.green),
                onPressed: () async {
                  await authProvider.logout();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logged out successfully')),
                  );
                },
              ),
            ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green.shade400,
                    Colors.green.shade700,
                  ],
                ),
              ),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.eco, size: 40, color: Colors.green),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isLoggedIn 
                        ? 'Hello, ${username ?? ""}!' 
                        : (localizations?.welcomeMessage ?? 'Welcome to Leafy!'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLoggedIn 
                        ? 'Glad to see you again!' 
                        : 'Sign in to access all features',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.home_rounded,
                    title: 'Home',
                    isSelected: true,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.people_rounded,
                    title: localizations?.community ?? 'Community',
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
                    _buildDrawerItem(
                      icon: Icons.login_rounded,
                      title: localizations?.login ?? 'Login',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NewLoginScreen()),
                        );
                      },
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    'Leafy v1.0.0',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with welcome message and title
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoggedIn 
                        ? 'Welcome, ${username ?? ""}!' 
                        : (localizations?.welcomeMessage ?? 'Welcome to Leafy!'),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations?.detectDisease ?? 'Identify Crop Diseases',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    localizations?.uploadLeafImage ?? 'Upload a leaf image to detect diseases and get instant results',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Crop selector
            _buildCropSelector(),
            
            // Image display
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _selectedImage != null 
                  ? _buildImageDisplay() 
                  : Container(
                      margin: const EdgeInsets.all(16),
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              localizations?.selectImage ?? 'Select an image to analyze',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            
            // Image selection buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: Text(localizations?.selectImage ?? 'Gallery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green.shade700,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _captureImage,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(localizations?.captureImage ?? 'Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green.shade700,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Detect disease button
            Container(
              margin: const EdgeInsets.all(16.0),
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _detectDisease,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Text(
                        localizations?.detectDisease ?? 'Analyze Image',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            
            // Detection result
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _detectionResult != null ? _buildDetectionResult() : const SizedBox(),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, LanguageProvider languageProvider) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.language, color: Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)?.appTitle ?? 'Select Language',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildLanguageOption(
                title: 'English',
                locale: const Locale('en'),
                isSelected: languageProvider.locale == const Locale('en'),
                onTap: () {
                  languageProvider.setLocale(const Locale('en'));
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 8),
              _buildLanguageOption(
                title: 'اردو',
                locale: const Locale('ur'),
                isSelected: languageProvider.locale == const Locale('ur'),
                onTap: () {
                  languageProvider.setLocale(const Locale('ur'));
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                ),
                child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLanguageOption({
    required String title,
    required Locale locale,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.green.shade800 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.green : Colors.grey.shade700,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.green : Colors.grey.shade800,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.people, color: Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      localizations?.joinCommunity ?? 'Join Community',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                // Replace with a hardcoded string since the key doesn't exist
                'You need to be logged in to access the community features. Would you like to login or register now?',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NewLoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: Text(localizations?.login ?? 'Login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on AppLocalizations? {
  get pleaseSelectLeafImage => null;
}

// Add this extension method for string capitalization
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}