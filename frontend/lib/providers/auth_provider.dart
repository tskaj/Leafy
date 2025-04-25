import 'dart:convert';
import 'dart:async'; // Add this import for Timer
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/disease_service.dart';  // Add this import
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _refreshToken;
  String? _userId;
  String? _username;
  String? _email;
  DateTime? _expiryDate;
  Timer? _authTimer;

  bool get isAuth {
    return token != null;
  }

  String? get token {
    if (_expiryDate != null && 
        _expiryDate!.isAfter(DateTime.now()) && 
        _token != null) {
      return _token;
    }
    return null;
  }

  String? get username {
    return _username;
  }

  String? get email {
    return _email;
  }

  // Add this method to get the auth header
  // Add this getter to your AuthProvider class if it doesn't exist
  Map<String, String> get authHeaders {
    return {
      'Authorization': 'Bearer $_token',
      'Content-Type': 'application/json',
    };
  }

  Future<void> _saveAuthData(String token, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = json.encode({
      'token': token,
      'refreshToken': refreshToken,
      'expiryDate': DateTime.now()
          .add(const Duration(minutes: 60))
          .toIso8601String(),
    });
    prefs.setString('userData', userData);
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return false;
    }

    final extractedUserData =
        json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
    final expiryDate = DateTime.parse(extractedUserData['expiryDate']);

    if (expiryDate.isBefore(DateTime.now())) {
      // Try to refresh token
      final refreshSuccess = _refreshToken != null 
          ? await refreshAuthToken(extractedUserData['refreshToken'])
          : false;
      if (!refreshSuccess) {
        return false;
      }
    }

    _token = extractedUserData['token'];
    _refreshToken = extractedUserData['refreshToken'];
    _expiryDate = expiryDate;
    
    // Decode JWT to get user info
    Map<String, dynamic> decodedToken = JwtDecoder.decode(_token!);
    _userId = decodedToken['user_id'].toString();
    _username = decodedToken['username'];
    
    notifyListeners();
    return true;
  }

  Future<bool> refreshAuthToken(String refreshToken) async {
    try {
      // Use the DiseaseService.getBaseUrl() method for consistency
      final url = Uri.parse('${DiseaseService.getBaseUrl()}/token/refresh/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _token = responseData['access'];
        _expiryDate = DateTime.now().add(const Duration(minutes: 60));
        notifyListeners();
        return true;
      }
      return false;
    } catch (error) {
      return false;
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      // Use the DiseaseService.getBaseUrl() method for consistency
      final url = Uri.parse('${DiseaseService.getBaseUrl()}/login/');
      
      print('Attempting to login with URL: ${url.toString()}');
      
      // Add more detailed error handling and debugging
      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({
            'username': username,
            'password': password,
          }),
        );

        print('Login response status: ${response.statusCode}');
        print('Login response body: ${response.body}');

        final responseData = json.decode(response.body);

        if (response.statusCode == 200) {
          _token = responseData['access'];
          _refreshToken = responseData['refresh'];
          _expiryDate = DateTime.now().add(const Duration(minutes: 60));
          
          // Decode JWT to get user info
          Map<String, dynamic> decodedToken = JwtDecoder.decode(_token!);
          _userId = decodedToken['user_id'].toString();
          _username = decodedToken['username'];
          
          _saveAuthData(_token!, _refreshToken!);
          notifyListeners();
          return {'success': true};
        } else {
          return {
            'success': false,
            'message': responseData['detail'] ?? 'Authentication failed',
          };
        }
      } catch (innerError) {
        print('Inner login error: ${innerError.toString()}');
        return {
          'success': false,
          'message': 'Network error: ${innerError.toString()}',
        };
      }
    } catch (error) {
      print('Outer login error: ${error.toString()}');
      return {
        'success': false,
        'message': 'Could not authenticate you. Error: ${error.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> signup(String username, String email, String password) async {
    try {
      // Use the DiseaseService.getBaseUrl() method for consistency
      final url = Uri.parse('${DiseaseService.getBaseUrl()}/register/');
      
      print('Attempting to signup with URL: ${url.toString()}');
      
      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({
            'username': username,
            'email': email,
            'password': password,
          }),
        );

        print('Signup response status: ${response.statusCode}');
        print('Signup response body: ${response.body}');

        final responseData = json.decode(response.body);

        if (response.statusCode == 201) {
          return {'success': true};
        } else {
          return {
            'success': false,
            'message': responseData.toString(),
          };
        }
      } catch (innerError) {
        print('Inner signup error: ${innerError.toString()}');
        return {
          'success': false,
          'message': 'Network error: ${innerError.toString()}',
        };
      }
    } catch (error) {
      print('Outer signup error: ${error.toString()}');
      return {
        'success': false,
        'message': 'Could not register you. Error: ${error.toString()}',
      };
    }
  }

  // Update the register method to accept email as a parameter
  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    try {
      final result = await AuthService.register(username, email, password);
      
      if (result['success']) {
        _token = result['token'];
        _username = username;
        _expiryDate = DateTime.now().add(const Duration(days: 30));
        
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('token', _token!);
        prefs.setString('username', _username!);
        prefs.setString('expiryDate', _expiryDate!.toIso8601String());
        
        notifyListeners();
      }
      
      return result;
    } catch (error) {
      return {
        'success': false,
        'message': 'Failed to register: ${error.toString()}',
      };
    }
  }

  Future<void> logout() async {
    _token = null;
    _refreshToken = null;
    _userId = null;
    _expiryDate = null;
    _username = null;
    
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
    notifyListeners();
  }
}