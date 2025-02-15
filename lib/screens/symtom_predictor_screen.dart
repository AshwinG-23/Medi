import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/api_service.dart';
import '../screens/chatbot_screen.dart';

class SymptomPredictorScreen extends StatefulWidget {
  const SymptomPredictorScreen({super.key});

  @override
  _SymptomPredictorScreenState createState() => _SymptomPredictorScreenState();
}

class _SymptomPredictorScreenState extends State<SymptomPredictorScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _response = '';
  bool _isLoading = false;

  void _predictSymptoms() async {
    String symptom = _controller.text;
    if (symptom.isEmpty) return;

    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String response = await _apiService.getSymptoms(symptom);
      setState(() {
        _response = response;
        _isLoading = false;
      });

      // Store the question and response pair in Firebase
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('symptom_predictions')
          .doc(timestamp.toString())
          .set({
        'symptom': symptom,
        'response': response,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      setState(() {
        _response =
            'Sorry, I encountered an error while analyzing your symptoms. Please try again.';
        _isLoading = false;
      });
      print('Error getting disease prediction: $e');
    }
  }

  void _clearResponse() {
    setState(() {
      _response = '';
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatScreen()),
                );
              },
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 140,
                    color: Colors.black,
                    child: Center(
                      child: Image.asset(
                        'lib/assets/chatbot_logo.png',
                        height: 100,
                        width: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Click above to use ChatBot',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 18,
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _controller,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Describe your symptoms...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.orange),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    _isLoading
                        ? CircularProgressIndicator()
                        : _response.isNotEmpty
                            ? Expanded(
                                child: Markdown(
                                  data: _response,
                                  styleSheet: MarkdownStyleSheet(
                                    p: const TextStyle(color: Colors.white),
                                    h1: const TextStyle(
                                        color: Colors.white, fontSize: 24),
                                    h2: const TextStyle(
                                        color: Colors.white, fontSize: 20),
                                    strong: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                    listBullet:
                                        const TextStyle(color: Colors.white),
                                    em: const TextStyle(color: Colors.white),
                                    blockquote:
                                        const TextStyle(color: Colors.white),
                                    code: const TextStyle(color: Colors.white),
                                    listIndent: 20.0,
                                  ),
                                  softLineBreak: true,
                                ),
                              )
                            : Container(),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _predictSymptoms,
                          child: Text('Predict Symptoms'),
                        ),
                        ElevatedButton(
                          onPressed: _clearResponse,
                          child: Text('Try Again'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
