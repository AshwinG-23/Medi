// api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'https://07ff-117-232-118-93.ngrok-free.app';

  Future<String> getDiseases(String context, String symptom) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/get_diseases'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'context': context,
          'symptom': symptom,
        }),
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // The response is directly a string based on your backend code
        return response.body;
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in API call: $e');
      throw Exception('Failed to communicate with server: $e');
    }
  }
}