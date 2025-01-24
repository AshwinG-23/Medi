import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChatbotScreen extends StatefulWidget {
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _symptom1Controller = TextEditingController();
  final TextEditingController _symptom2Controller = TextEditingController();
  final TextEditingController _symptom3Controller = TextEditingController();
  String _response = '';

  Future<void> _getDiseases() async {
    try {
      final response = await ChatbotApiService.getDiseases(
        symptom1: _symptom1Controller.text,
        symptom2: _symptom2Controller.text,
        symptom3: _symptom3Controller.text,
      );
      setState(() {
        _response = response;
      });
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chatbot')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _symptom1Controller,
              decoration: InputDecoration(labelText: 'Symptom 1'),
            ),
            TextField(
              controller: _symptom2Controller,
              decoration: InputDecoration(labelText: 'Symptom 2'),
            ),
            TextField(
              controller: _symptom3Controller,
              decoration: InputDecoration(labelText: 'Symptom 3'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _getDiseases,
              child: Text('Get Diseases'),
            ),
            SizedBox(height: 20),
            Text(
              _response,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
