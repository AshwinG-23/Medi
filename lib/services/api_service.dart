// api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl =
      'https://1392-2409-40c2-204a-c0d5-587b-410-1ee0-6948.ngrok-free.app';

  String _processMarkdownText(String text) {
    // First, handle escaped newlines
    String processed = text.replaceAll('\\n', '\n');

    // Handle double newlines that might have extra spaces
    processed = processed.replaceAll('\n \n', '\n\n');

    // Remove any JSON string escaping
    processed = processed.replaceAll('\\"', '"');

    // Ensure proper spacing for list items
    processed = processed.replaceAll('*  ', '* ');

    // Remove any potential HTML encoding
    processed = processed.replaceAll('&nbsp;', ' ');

    processed = processed.substring(1, processed.length - 1);

    return processed;
  }

  Future<String> getDiseases(String context, String symptom) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/general'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'question': symptom,
          'context': context,
        }),
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body.codeUnits}');

      if (response.statusCode == 200) {
        // The response is directly a string based on your backend code
        return _processMarkdownText(response.body);
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in API call: $e');
      throw Exception('Failed to communicate with server: $e');
    }
  }

  Future<String> getSymptoms(String symptom) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/get_diseases'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'symptom': symptom,
        }),
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body.codeUnits}');

      if (response.statusCode == 200) {
        // The response is directly a string based on your backend code
        return _processMarkdownText(response.body);
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in API call: $e');
      throw Exception('Failed to communicate with server: $e');
    }
  }
}
