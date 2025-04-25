import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/language_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/language_selection_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'screens/register_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => LanguageProvider()),
        ChangeNotifierProvider(create: (ctx) => AuthProvider()),
        // Add other providers here
      ],
      child: Consumer<LanguageProvider>(
        builder: (ctx, languageProvider, _) {
          return MaterialApp(
            title: 'Leafy',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
              useMaterial3: true,
              fontFamily: 'Roboto',
            ),
            // Localization setup
            locale: languageProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''), // English
              Locale('ur', ''), // Urdu
            ],
            // Define initial route
            initialRoute: '/',
            // Add routes map here
            routes: {
              '/': (ctx) => Consumer<AuthProvider>(
                builder: (ctx, authProvider, _) {
                  // Check if user is authenticated
                  if (authProvider.isAuth) {
                    return const HomeScreen();
                  } else {
                    // Show language selection screen first time, then auth screen
                    return FutureBuilder(
                      future: authProvider.tryAutoLogin(),
                      builder: (ctx, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Scaffold(
                            body: Center(child: CircularProgressIndicator()),
                          );
                        } else {
                          // If first time or language not selected, show language selection
                          return const LanguageSelectionScreen();
                        }
                      },
                    );
                  }
                },
              ),
              '/login': (ctx) => const AuthScreen(),
              '/register': (ctx) => const RegisterScreen(),
              '/home': (ctx) => const HomeScreen(),
            },
          );
        },
      ),
    );
  }
}
