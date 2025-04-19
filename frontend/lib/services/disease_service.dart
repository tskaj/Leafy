import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DiseaseService {
  // In your DiseaseService class, update the getBaseUrl method:
  
  static String getBaseUrl() {
    try {
      return dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
    } catch (e) {
      print("Error accessing environment variables: $e");
      return 'http://localhost:8000';
    }
  }
  
  static final String baseUrl = getBaseUrl();

  // For mobile platforms
  static Future<Map<String, dynamic>> detectDisease(
    File imageFile, 
    String token, 
    {String cropType = 'tomato'}
  ) async {
    // Change from /api/detect/ to /predict/
    final url = Uri.parse('$baseUrl/predict/');
    
    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    
    request.files.add(await http.MultipartFile.fromPath(
      'image', 
      imageFile.path,
      contentType: MediaType('image', 'jpeg'),
    ));
    
    request.fields['crop_type'] = cropType;
    
    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      return {
        'success': true,
        'data': json.decode(responseData),
      };
    } else {
      return {
        'success': false,
        'message': 'Failed to detect disease: ${response.statusCode}',
      };
    }
  }
  
  // Update other methods to use the correct endpoints
  
  // For web platforms
  static Future<Map<String, dynamic>> detectDiseaseWeb(
    Uint8List imageBytes, 
    String token,
    {String cropType = 'tomato'}
  ) async {
    // Change from /api/detect/ to /predict/
    final url = Uri.parse('$baseUrl/predict/');
    
    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    
    request.files.add(http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: 'image.jpg',
      contentType: MediaType('image', 'jpeg'),
    ));
    
    request.fields['crop_type'] = cropType;
    
    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      return {
        'success': true,
        'data': json.decode(responseData),
      };
    } else {
      return {
        'success': false,
        'message': 'Failed to detect disease: ${response.statusCode}',
      };
    }
  }
  
  // Anonymous detection for mobile
  static Future<Map<String, dynamic>> detectDiseaseAnonymousMobile(
    File imageFile,
    {String cropType = 'tomato'}
  ) async {
    // Change from /api/detect/anonymous/ to /predict-anonymous/
    final url = Uri.parse('$baseUrl/predict-anonymous/');
    
    var request = http.MultipartRequest('POST', url);
    
    request.files.add(await http.MultipartFile.fromPath(
      'image', 
      imageFile.path,
      contentType: MediaType('image', 'jpeg'),
    ));
    
    request.fields['crop_type'] = cropType;
    
    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      return {
        'success': true,
        'data': json.decode(responseData),
      };
    } else {
      return {
        'success': false,
        'message': 'Failed to detect disease: ${response.statusCode}',
      };
    }
  }
  
  // Anonymous detection for web
  static Future<Map<String, dynamic>> detectDiseaseAnonymousWeb(
    Uint8List imageBytes,
    {String cropType = 'tomato'}
  ) async {
    // Change from /api/detect/anonymous/ to /predict-anonymous/
    final url = Uri.parse('$baseUrl/predict-anonymous/');
    
    var request = http.MultipartRequest('POST', url);
    
    request.files.add(http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: 'image.jpg',
      contentType: MediaType('image', 'jpeg'),
    ));
    
    request.fields['crop_type'] = cropType;
    
    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      return {
        'success': true,
        'data': json.decode(responseData),
      };
    } else {
      return {
        'success': false,
        'message': 'Failed to detect disease: ${response.statusCode}',
      };
    }
  }
  
  // Get available crop types
  static Future<List<String>> getAvailableCrops(String? token) async {
    // You need to implement this endpoint in your Django backend
    // For now, return default values
    return ['tomato', 'apple', 'corn', 'potato', 'rice'];
  }
}