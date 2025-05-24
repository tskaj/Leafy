import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/language_provider.dart';
import 'main_navigation_screen.dart';
import 'dart:ui';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Decorative top element - more compact
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Circular background with blur effect
                          Container(
                            height: screenSize.height * 0.22,
                            width: screenSize.height * 0.22,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green.withOpacity(0.1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.05),
                                    blurRadius: 30,
                                    spreadRadius: 10,
                                  )
                                ]),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.transparent,
                                ),
                              ),
                            ),
                          ),
                          // Animation - smaller size
                          SizedBox(
                            height: screenSize.height * 0.24,
                            width: screenSize.width * 0.65,
                            child: Lottie.asset(
                              'assets/animations/plant_animation.json',
                              fit: BoxFit.contain,
                              repeat: true,
                              animate: true,
                              errorBuilder: (context, error, stackTrace) {
                                print('Lottie error: $error');
                                return Container(
                                  child: const Center(
                                    child: Icon(
                                      Icons.local_florist,
                                      size: 70,
                                      color: Colors.green,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Welcome text with gradient text
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Colors.green.shade600, Colors.green.shade800],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        'Welcome to Leafy',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              blurRadius: 8.0,
                              color: Colors.green.withOpacity(0.3),
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Subtitle with custom styling - smaller
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      child: const Text(
                        'Please select your preferred language',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Language buttons container - side by side
                    Row(
                      children: [
                        // English button
                        Expanded(
                          child: _buildLanguageButton(
                            context,
                            'English',
                            const Locale('en', ''),
                            Icons.language,
                          )
                              .animate()
                              .fadeIn(duration: 600.ms, delay: 300.ms)
                              .slideY(
                                  begin: 0.2,
                                  end: 0,
                                  duration: 600.ms,
                                  curve: Curves.easeOutQuad),
                        ),

                        const SizedBox(width: 12),

                        // Urdu button
                        Expanded(
                          child: _buildLanguageButton(
                            context,
                            'اردو',
                            const Locale('ur', ''),
                            Icons.language,
                          )
                              .animate()
                              .fadeIn(duration: 600.ms, delay: 500.ms)
                              .slideY(
                                  begin: 0.2,
                                  end: 0,
                                  duration: 600.ms,
                                  curve: Curves.easeOutQuad),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;

        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(isHovered ? 0.25 : 0.15),
                  spreadRadius: isHovered ? 1 : 0,
                  blurRadius: isHovered ? 15 : 8,
                  offset: Offset(0, isHovered ? 5 : 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                splashColor: Colors.white.withOpacity(0.1),
                highlightColor: Colors.white.withOpacity(0.05),
                onTap: () async {
                  // Set the selected language
                  await languageProvider.setLocale(locale);

                  // Navigate to main navigation screen
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (ctx) => const MainNavigationScreen()),
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        isHovered
                            ? Colors.green.shade400
                            : Colors.green.shade500,
                        isHovered
                            ? Colors.green.shade600
                            : Colors.green.shade700,
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(isHovered ? 0.3 : 0.2),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              Colors.white.withOpacity(isHovered ? 0.3 : 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        language,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
