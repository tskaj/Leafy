import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../providers/language_provider.dart';
import 'home_screen.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(  // Add this to fix overflow
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo or animation - fixed path
                // Replace this:
                Lottie.asset(
                  'assets/animations/plant_animation.json',
                  height: 200,
                  repeat: true,
                ),
                
                // With this (no change in path, just adding error handling):
                Lottie.asset(
                  'assets/animations/plant_animation.json',
                  height: 200,
                  repeat: true,
                  errorBuilder: (context, error, stackTrace) {
                    print('Lottie error: $error');
                    return Container(
                      height: 200,
                      color: Colors.green.withOpacity(0.2),
                      child: const Center(
                        child: Icon(
                          Icons.local_florist,
                          size: 80,
                          color: Colors.green,
                        ),
                      ),
                    );
                  },
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          // Set the selected language
          await Provider.of<LanguageProvider>(context, listen: false)
              .setLocale(locale);
          
          // Navigate to home screen
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (ctx) => const HomeScreen()),
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