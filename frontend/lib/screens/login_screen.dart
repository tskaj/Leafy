import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../services/auth_service.dart';
import 'upload_image_screen.dart'; // Import the new screen

class LoginScreen extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginScreen({super.key});

  void login(BuildContext context) async {
    try {
      final authService = AuthService();
      final token = await authService.login(
        usernameController.text,
        passwordController.text,
      );

      // Navigate to the next screen upon successful login
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UploadImageScreen(token: token)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomTextField(
              controller: usernameController,
              hintText: "Username",
            ),
            const SizedBox(height: 10),
            CustomTextField(
              controller: passwordController,
              hintText: "Password",
              obscureText: true,
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: "Login",
              onPressed: () => login(context),
            ),
          ],
        ),
      ),
    );
  }
}
