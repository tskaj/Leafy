import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';  // Add this import for MediaType
import 'disease_service.dart';

class CommunityService {
  static Future<Map<String, dynamic>> getPosts(String token) async {
    try {
      final url = Uri.parse('${DiseaseService.getBaseUrl()}/community/posts/');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Failed to fetch posts',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> createPost(
    String caption,
    Map<String, dynamic> imageData,
    String token,
  ) async {
    try {
      final url = Uri.parse('${DiseaseService.getBaseUrl()}/community/posts/');
      
      // Create a multipart request
      var request = http.MultipartRequest('POST', url);
      
      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add text fields
      request.fields['caption'] = caption;
      
      // Add the image file
      if (kIsWeb) {
        // For web
        final bytes = imageData['bytes'] as Uint8List;
        final fileName = imageData['name'] as String;
        
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: fileName,
            contentType: MediaType.parse(imageData['mimeType']),
          ),
        );
      } else {
        // For mobile
        final file = File(imageData['path']);
        request.files.add(
          await http.MultipartFile.fromPath('image', file.path),
        );
      }
      
      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Failed to create post',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> likePost(int postId, String token) async {
    try {
      final url = Uri.parse('${DiseaseService.getBaseUrl()}/community/posts/$postId/like/');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Failed to like post',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Add the missing addComment method
  static Future<Map<String, dynamic>> addComment(int postId, String content, String token) async {
    try {
      final url = Uri.parse('${DiseaseService.getBaseUrl()}/community/posts/$postId/comments/');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'content': content,
        }),
      );
      
      final responseData = json.decode(response.body);
      
      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Failed to add comment',
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