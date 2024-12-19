import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/custom_button.dart';
import 'dart:io';
import '../services/auth_service.dart'; // Import auth_service.dart

class UploadImageScreen extends StatefulWidget {
  final String token; // Token from login

  const UploadImageScreen({required this.token, super.key});

  @override
  _UploadImageScreenState createState() => _UploadImageScreenState();
}

class _UploadImageScreenState extends State<UploadImageScreen> {
  XFile? _image;

  void pickImage() async {
    final ImagePicker picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _image = pickedImage;
      });
    }
  }

  void uploadImage() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image first")),
      );
      return;
    }

    try {
      final authService = AuthService();
      final prediction = await authService.uploadImage(widget.token, File(_image!.path));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Prediction: $prediction")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Image")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickImage,
              child: const Text("Select Image"),
            ),
            if (_image != null) ...[
              const SizedBox(height: 20),
              Image.file(
                File(_image!.path),
                height: 200,
              ),
            ],
            const SizedBox(height: 20),
            CustomButton(
              text: "Upload",
              onPressed: uploadImage,
            ),
          ],
        ),
      ),
    );
  }
}
