import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static String? _baseUrl;

  Future<void> _fetchBaseUrl() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('config')
          .doc('api')
          .get();

      if (snapshot.exists && snapshot.data() != null) {
        _baseUrl = snapshot.get('baseUrl');
      } else {
        throw Exception("Base URL not found in Firestore.");
      }
    } catch (e) {
      throw Exception("Failed to fetch base URL: $e");
    }
  }

  Future<String> getCalorieInfo(String item) async {
    if (_baseUrl == null) await _fetchBaseUrl();

    final response = await http.post(
      Uri.parse('$_baseUrl/calorie'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'item': item}),
    );

    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      return _processResponse(response);
    } else {
      throw Exception('Failed to get calorie info: ${response.statusCode}');
    }
  }

  Future<String> getRecommendedRoutine(
      String bmi, String cal, String sleepTimes) async {
    if (_baseUrl == null) await _fetchBaseUrl();

    // Get food recommendations
    final foodResponse = await http.post(
      Uri.parse('$_baseUrl/food'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'bmi': bmi, 'cal': cal}),
    );

    // Get sleep recommendations
    final sleepResponse = await http.post(
      Uri.parse('$_baseUrl/sleep'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'sleep': sleepTimes}),
    );

    if (foodResponse.statusCode == 200 && sleepResponse.statusCode == 200) {
      final foodRecommendations = _processResponse(foodResponse);
      final sleepRecommendations = _processResponse(sleepResponse);

      return """
Diet Recommendations:
$foodRecommendations

Sleep Analysis:
$sleepRecommendations
""";
    } else {
      throw Exception('Failed to get recommendations');
    }
  }

  String _processResponse(http.Response response) {
    try {
      // Decode the response body properly using UTF-8
      String decodedResponse = utf8.decode(response.bodyBytes);

      // Try parsing as JSON
      final decodedJson = jsonDecode(decodedResponse);

      // Extract the message if it exists
      String message = decodedJson is Map<String, dynamic> &&
              decodedJson.containsKey('message')
          ? decodedJson['message']
          : decodedResponse;

      // Clean up escape sequences
      return message
          .replaceAll(RegExp(r'^"|"$'), '') // Remove surrounding quotes
          .replaceAll('\\n', '\n') // Convert escaped newlines
          .replaceAll('\\"', '"'); // Fix escaped quotes
    } catch (e) {
      print("Error decoding response: $e");
      return utf8.decode(response
          .bodyBytes); // Return raw decoded response if JSON parsing fails
    }
  }
}
