import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:io';

class AuthService {
  final String baseUrl = "http://127.0.0.1:8000/api/";

  Future<String> login(String username, String password) async {
    final response = await http.post(
      Uri.parse("${baseUrl}users/login/"),
      body: json.encode({"username": username, "password": password}),
      headers: {
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["access"]; // Return the access token
    } else {
      throw Exception("Failed to login: ${response.body}");
    }
  }

  Future<void> register(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse("${baseUrl}users/register/"),
      body: json.encode({
        "username": username,
        "email": email,
        "password": password,
      }),
      headers: {
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode != 201) {
      throw Exception("Failed to register: ${response.body}");
    }
  }

  Future<String> uploadImage(String token, File image) async {
    final url = Uri.parse("${baseUrl}predict-image/");

    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('image', image.path,
          contentType: MediaType('image', 'jpeg')));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final data = json.decode(responseBody);
      return data['prediction'];
    } else {
      throw Exception("Failed to upload image: ${response.reasonPhrase}");
    }
  }
}
