import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class DiseaseService {
  static String getBaseUrl() {
    // For web, use localhost
    if (kIsWeb) {
      return 'http://localhost:8000';  // Remove '/api' from here
    }
    // For mobile emulators, use 10.0.2.2 instead of localhost
    return 'http://10.0.2.2:8000';  // Remove '/api' from here
  }

  static Future<Map<String, dynamic>> detectDisease(File imageFile, String token) async {
    try {
      // Change the URL to match your Django URL structure
      final request = http.MultipartRequest('POST', Uri.parse('${getBaseUrl()}/predict/'));
      request.headers['Authorization'] = 'Bearer $token';
      
      // Rest of the method remains the same
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? 'Failed to detect disease',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Update all other methods similarly by changing the URL patterns
  static Future<Map<String, dynamic>> detectDiseaseWeb(Uint8List imageBytes, String token) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('${getBaseUrl()}/predict/'));
      request.headers['Authorization'] = 'Bearer $token';
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'image.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? 'Failed to detect disease',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> detectDiseaseAnonymousWeb(Uint8List imageBytes) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('${getBaseUrl()}/predict-anonymous/'));
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'image.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? 'Failed to detect disease',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> detectDiseaseAnonymousMobile(File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('${getBaseUrl()}/predict-anonymous/'));
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? 'Failed to detect disease',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> detectDiseaseAnonymous(Uint8List imageBytes) async {
    try {
      final url = Uri.parse('${getBaseUrl()}/predict-anonymous/');
      
      var request = http.MultipartRequest('POST', url);
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'image.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );
      
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var decodedResponse = json.decode(responseData);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': decodedResponse,
        };
      } else {
        return {
          'success': false,
          'message': decodedResponse['detail'] ?? 'Failed to detect disease',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'message': 'Error: ${error.toString()}',
      };
    }
  }
}