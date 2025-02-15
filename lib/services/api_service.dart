import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static String? _baseUrl; // Cached base URL

  Future<void> _fetchBaseUrl() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('config')
          .doc('api')
          .get();

      if (snapshot.exists && snapshot.data() != null) {
        _baseUrl = snapshot['baseUrl'];
        print("Fetched base URL: $_baseUrl");
      } else {
        throw Exception("Base URL not found in Firestore.");
      }
    } catch (e) {
      print("Error fetching base URL: $e");
      throw Exception("Failed to fetch base URL.");
    }
  }

  Future<String> getDiseases(String context, String symptom) async {
    if (_baseUrl == null) await _fetchBaseUrl(); // Ensure base URL is available

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/general'),
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
    if (_baseUrl == null) await _fetchBaseUrl();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/get_diseases'),
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
        return _processMarkdownText(response.body);
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in API call: $e');
      throw Exception('Failed to communicate with server: $e');
    }
  }

  String _processMarkdownText(String text) {
    String processed = text.replaceAll('\\n', '\n')
        .replaceAll('\n \n', '\n\n')
        .replaceAll('\\"', '"')
        .replaceAll('*  ', '* ')
        .replaceAll('&nbsp;', ' ');

    return processed.substring(1, processed.length - 1);
  }
}
