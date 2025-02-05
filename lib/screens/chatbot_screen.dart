import 'package:flutter/material.dart';
import '../services/api_service.dart'; // Import your ChatbotApiService

class ChatbotScreen extends StatefulWidget {
  final VoidCallback onClose;

  const ChatbotScreen({super.key, required this.onClose});

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _symptom1Controller = TextEditingController();
  final TextEditingController _symptom2Controller = TextEditingController();
  final TextEditingController _symptom3Controller = TextEditingController();

  String _response = '';
  bool _isLoading = false;

  /// Validates user input and fetches diseases from the API.
  Future<void> _fetchDiseases() async {
    // Validate input
    if (_symptom1Controller.text.trim().isEmpty ||
        _symptom2Controller.text.trim().isEmpty ||
        _symptom3Controller.text.trim().isEmpty) {
      setState(() {
        _response = 'Please fill in all the symptom fields.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _response = '';
    });

    try {
      final String response = await ChatbotApiService.getDiseases(
        symptom1: _symptom1Controller.text.trim(),
        symptom2: _symptom2Controller.text.trim(),
        symptom3: _symptom3Controller.text.trim(),
      );

      setState(() {
        _response = response;
      });
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter Symptoms',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _symptom1Controller,
              decoration: InputDecoration(
                labelText: 'Symptom 1',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _symptom2Controller,
              decoration: InputDecoration(
                labelText: 'Symptom 2',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _symptom3Controller,
              decoration: InputDecoration(
                labelText: 'Symptom 3',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _fetchDiseases,
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : Text('Get Diseases'),
            ),
            SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _response.isEmpty ? 'Response will appear here.' : _response,
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _symptom1Controller.dispose();
    _symptom2Controller.dispose();
    _symptom3Controller.dispose();
    super.dispose();
  }
}
