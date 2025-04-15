import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/main.dart';
import 'package:frontend/providers/auth_provider.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (ctx) => AuthProvider(),
        child: const MyApp(),
      ),
    );

    // Verify that the login screen appears
    expect(find.text('Login'), findsOneWidget);
  });
}
