import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../providers/language_provider.dart';
import 'home_screen.dart';
import 'main_navigation_screen.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Single large animation
                Container(
                  height: screenSize.height * 0.4, // 40% of screen height
                  width: screenSize.width,
                  child: Lottie.asset(
                    'assets/animations/plant_animation.json',
                    fit: BoxFit.contain,
                    repeat: true,
                    animate: true,
                    errorBuilder: (context, error, stackTrace) {
                      print('Lottie error: $error');
                      return Container(
                        color: Colors.green.withOpacity(0.2),
                        child: const Center(
                          child: Icon(
                            Icons.local_florist,
                            size: 100,
                            color: Colors.green,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 40),
                
                const Text(
                  'Welcome to Leafy',
                  style: TextStyle(
                    fontSize: 28, 
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                const Text(
                  'Please select your preferred language',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // English button
                _buildLanguageButton(
                  context,
                  'English',
                  const Locale('en', ''),
                  Icons.language,
                ),
                
                const SizedBox(height: 16),
                
                // Urdu button
                _buildLanguageButton(
                  context,
                  'اردو (Urdu)',
                  const Locale('ur', ''),
                  Icons.language,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageButton(
    BuildContext context, 
    String language, 
    Locale locale,
    IconData icon,
  ) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          // Set the selected language
          await languageProvider.setLocale(locale);
          
          // Navigate to main navigation screen
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (ctx) => const MainNavigationScreen()),
            );
          }
        },
        icon: Icon(icon),
        label: Text(
          language,
          style: const TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}