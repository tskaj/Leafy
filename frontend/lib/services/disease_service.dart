import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class DiseaseService {
  static Future<Map<String, dynamic>> detectDisease(
      File imageFile, String token) async {
    try {
      final url = Uri.parse('http://10.0.2.2:8000/api/users/predict/');
      
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
      
      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to detect disease. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }
}