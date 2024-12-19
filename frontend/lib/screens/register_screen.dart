import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  RegisterScreen({super.key});

  void register(BuildContext context) async {
    try {
      final authService = AuthService();
      await authService.register(
        usernameController.text,
        emailController.text,
        passwordController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration successful!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
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
              controller: emailController,
              hintText: "Email",
            ),
            const SizedBox(height: 10),
            CustomTextField(
              controller: passwordController,
              hintText: "Password",
              obscureText: true,
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: "Register",
              onPressed: () => register(context),
            ),
          ],
        ),
      ),
    );
  }
}
