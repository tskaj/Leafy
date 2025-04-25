import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CommunityService {
  static String getBaseUrl() {
    return dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  }

  static Future<List<dynamic>> getPosts(String? token) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('${getBaseUrl()}/api/community/posts/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Network error: ${error.toString()}');
    }
  }

  static Future<Map<String, dynamic>> likePost(int postId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/api/community/posts/$postId/like/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'is_liked': responseData['is_liked'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Failed to like post',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'message': 'Network error: ${error.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> addComment(
      int postId, String content, String token, {int? parentId}) async {
    try {
      final Map<String, dynamic> requestBody = {
        'content': content,
      };
      
      if (parentId != null) {
        requestBody['parent_id'] = parentId;
      }
      
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/api/community/posts/$postId/comments/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'comment': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Failed to add comment',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'message': 'Network error: ${error.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> createPost(
      String caption, File? image, String token, {Uint8List? imageBytes}) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${getBaseUrl()}/api/community/posts/'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['caption'] = caption;

      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            image.path,
          ),
        );
      } else if (imageBytes != null) {
        // For web platform
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: 'web_image.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Failed to create post',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'message': 'Network error: ${error.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> reactToPost(
      int postId, String reactionType, String token) async {
    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/api/community/posts/$postId/react/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'reaction_type': reactionType,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'reaction': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['detail'] ?? 'Failed to react to post',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'message': 'Network error: ${error.toString()}',
      };
    }
  }
}