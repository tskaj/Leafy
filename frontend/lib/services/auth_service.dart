import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/disease_service.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // Notice the URL change from /api/login/ to /login/
      final response = await http.post(
        Uri.parse('${DiseaseService.getBaseUrl()}/login/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Login failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }
  
  // Add other auth methods here (register, logout, etc.)
}