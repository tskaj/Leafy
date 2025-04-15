import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async'; // Add this import for TimeoutException
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DiseaseService {
  // Get the appropriate base URL based on platform
  static String getBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      // For Android emulator
      return 'http://10.0.2.2:8000';
    } else {
      // For iOS simulator or other platforms
      return 'http://localhost:8000';
    }
  }

  static Future<Map<String, dynamic>> detectDisease(
      File imageFile, String token) async {
    try {
      final baseUrl = getBaseUrl();
      final url = Uri.parse('$baseUrl/api/users/predict/');
      
      // Create multipart request
      var request = http.MultipartRequest('POST', url);
      
      // Add authorization header
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });
      
      // Add file to request
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ));
      
      // Set timeout for the request
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Connection timed out. Please check your network or server status.');
        },
      );
      
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to detect disease. Status: ${response.statusCode}, Body: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> detectDiseaseWeb(Uint8List imageBytes, String token) async {
      try {
        final baseUrl = getBaseUrl();
        final url = Uri.parse('$baseUrl/api/users/predict/');
        
        // Create a multipart request
        var request = http.MultipartRequest('POST', url);
        
        // Add the authorization header
        request.headers['Authorization'] = 'Bearer $token';
        
        // Add the file
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: 'image.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
        
        // Send the request with timeout
        var response = await request.send().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Connection timed out. Please check your network or server status.');
          },
        );
        
        // Get the response
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
            'message': decodedResponse['detail'] ?? 'Failed to detect disease: ${responseData}',
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