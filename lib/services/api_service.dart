import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatbotApiService {
  static const String baseUrl = 'https://8d4c-117-232-118-93.ngrok-free.app';

  /// Sends a chat message to the chatbot API and gets a response.
  static Future<String> sendMessage({
    required String userId,
    required String message,
  }) async {
    final String endpoint = '$baseUrl/chat';
    final Map<String, String> requestBody = {
      'user_id': userId,
      'message': message,
    };

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'];
      } else {
        throw Exception('Failed to fetch response: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error occurred: $e');
    }
  }
}