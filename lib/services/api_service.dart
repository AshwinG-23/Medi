import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatbotApiService {
  static const String baseUrl = 'https://medisync-nine.vercel.app/';

  /// Sends symptoms to the chatbot API and gets a response.
  static Future<String> getDiseases({
    required String symptom1,
    required String symptom2,
    required String symptom3,
  }) async {
    final String endpoint = '$baseUrl/get_diseases';
    final Map<String, String> requestBody = {
      'symptom1': symptom1,
      'symptom2': symptom2,
      'symptom3': symptom3,
    };

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response']; // Adjust based on API response format.
      } else {
        throw Exception('Failed to fetch diseases: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error occurred: $e');
    }
  }
}
