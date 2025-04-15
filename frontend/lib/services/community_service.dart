import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
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

  // Fix parameter order to match how it's called in community_screen.dart
  static Future<Map<String, dynamic>> createPost(String caption, dynamic image, String token) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${DiseaseService.getBaseUrl()}/community/posts/'),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['caption'] = caption;
      
      // Handle different image types (File for mobile, Uint8List for web)
      if (image != null) {
        if (kIsWeb && image is Uint8List) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'image',
              image,
              filename: 'post_image.jpg',
            ),
          );
        } else if (!kIsWeb && image is File) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'image',
              image.path,
              filename: 'post_image.jpg',
            ),
          );
        } else if (image is String) {
          // Handle case where image is a path string
          request.files.add(
            await http.MultipartFile.fromPath(
              'image',
              image,
              filename: 'post_image.jpg',
            ),
          );
        }
      }
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);
      
      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? 'Failed to create post',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Add the missing likePost method
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
        return {
          'success': true,
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