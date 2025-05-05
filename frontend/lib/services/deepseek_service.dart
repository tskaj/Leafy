import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DeepSeekService {
  // Base URL for DeepSeek API
  static String getBaseUrl() {
    // You may need to update this with the actual DeepSeek API URL
    return 'https://api.deepseek.com';
  }

  // Get treatment recommendations for a detected plant disease
  static Future<Map<String, dynamic>> getTreatmentRecommendation(String diseaseName, String cropType) async {
    try {
      // Construct a prompt for the DeepSeek API
      final prompt = "Provide a concise treatment recommendation for $diseaseName affecting $cropType plants. Include: \n"
          "1. Brief explanation of the disease\n"
          "2. Organic treatment options\n"
          "3. Chemical treatment options if necessary\n"
          "4. Prevention tips\n"
          "Keep the response informative but concise (150-200 words).";

      // You'll need to add your DeepSeek API key to the .env file
      final apiKey = dotenv.env['DEEPSEEK_API_KEY'] ?? 'sk-2837438af8dd4e8ebe6afdc43166215e';
      if (apiKey.isEmpty) {
        return {
          'success': false,
          'message': 'DeepSeek API key not found',
        };
      }

      // Make the API request to DeepSeek
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',  // Update with the appropriate model name
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 300,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        // Extract the treatment recommendation from the response
        final recommendation = jsonResponse['choices'][0]['message']['content'];
        return {
          'success': true,
          'recommendation': recommendation,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get treatment recommendation: ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (error) {
      return {
        'success': false,
        'message': 'Error getting treatment recommendation: $error',
      };
    }
  }

  // Mock method for testing without actual API calls
  static Future<Map<String, dynamic>> getMockTreatmentRecommendation(String diseaseName, String cropType) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Return a mock response based on the disease name
    String recommendation;
    
    if (diseaseName.toLowerCase().contains('healthy')) {
      recommendation = "Your $cropType plant appears healthy! Continue with regular care:\n\n"
          "1. Water regularly but avoid overwatering\n"
          "2. Ensure adequate sunlight exposure\n"
          "3. Apply balanced fertilizer according to plant needs\n"
          "4. Monitor for early signs of pests or diseases\n\n"
          "Preventative measures: Maintain good air circulation, avoid wetting leaves when watering, and remove any dead or decaying plant material promptly.";
    } else if (diseaseName.toLowerCase().contains('blight')) {
      recommendation = "Treatment for $diseaseName on $cropType:\n\n"
          "1. Disease explanation: Blight is a fungal disease that causes rapid browning and death of plant tissues.\n\n"
          "2. Organic treatments:\n"
          "   - Remove and destroy infected plant parts\n"
          "   - Apply copper-based fungicides or neem oil\n"
          "   - Improve air circulation around plants\n\n"
          "3. Chemical options:\n"
          "   - Chlorothalonil or mancozeb-based fungicides\n"
          "   - Follow label instructions carefully\n\n"
          "4. Prevention:\n"
          "   - Use disease-resistant varieties\n"
          "   - Rotate crops annually\n"
          "   - Avoid overhead watering";
    } else {
      recommendation = "Treatment for $diseaseName on $cropType:\n\n"
          "1. Disease explanation: This condition affects plant health by damaging leaves and potentially reducing yield.\n\n"
          "2. Organic treatments:\n"
          "   - Remove infected plant parts immediately\n"
          "   - Apply organic fungicides like neem oil or copper soap\n"
          "   - Introduce beneficial insects if appropriate\n\n"
          "3. Chemical options:\n"
          "   - Targeted fungicides or pesticides may be necessary for severe cases\n"
          "   - Always follow product instructions and safety guidelines\n\n"
          "4. Prevention:\n"
          "   - Maintain proper plant spacing\n"
          "   - Water at the base of plants\n"
          "   - Practice crop rotation";
    }
    
    return {
      'success': true,
      'recommendation': recommendation,
    };
  }
}