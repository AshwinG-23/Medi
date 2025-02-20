import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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
  bool _fetchingHistory = false;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchPreviousAnalysis();
  }

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

      if (response.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('symptom_predictions')
            .add({
          'symptom': symptom,
          'response': response,
          'timestamp': FieldValue.serverTimestamp(),
        });
        _fetchPreviousAnalysis();
      }

      _controller.clear();
    } catch (e) {
      setState(() {
        _response = 'Error analyzing symptoms. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _fetchPreviousAnalysis() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    setState(() {
      _fetchingHistory = true;
    });

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('symptom_predictions')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      setState(() {
        _history = snapshot.docs.map((doc) {
          return {
            'symptom': doc['symptom'],
            'response': doc['response'],
            'timestamp': (doc['timestamp'] as Timestamp).toDate().toString(),
          };
        }).toList();
        _fetchingHistory = false;
      });
    } catch (e) {
      setState(() {
        _fetchingHistory = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 30, 30, 30),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 140,
                    color: const Color.fromARGB(255, 30, 30, 30),
                    child: Center(
                      child: Image.asset(
                        'lib/assets/logo2.png',
                        height: 100,
                        width: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Click above to use the General ChatBot instead',
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.w400),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _fetchingHistory
                        ? Center(child: CircularProgressIndicator())
                        : ListView(
                            children: _history.map((entry) {
                              return Card(
                                color: const Color.fromARGB(255, 44, 44, 44),
                                margin: const EdgeInsets.symmetric(vertical: 5),
                                child: Padding(
                                  padding: const EdgeInsets.all(13),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Use MarkdownBody for timestamp
                                      MarkdownBody(
                                        data: "${entry['timestamp']}",
                                        styleSheet: MarkdownStyleSheet(
                                          p: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      // Use MarkdownBody for symptom
                                      MarkdownBody(
                                        data:
                                            "**Symptom:** ${entry['symptom']}",
                                        styleSheet: MarkdownStyleSheet(
                                          p: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                          strong: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      // Use MarkdownBody for prediction
                                      MarkdownBody(
                                        data:
                                            "**Prediction:** ${entry['response']}",
                                        styleSheet: MarkdownStyleSheet(
                                          p: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                          strong: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.purple, Colors.orange],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.all(2), // Border width
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 30, 30, 30),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: TextField(
                              controller: _controller,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Describe your symptoms...',
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.purple, Colors.orange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: FloatingActionButton(
                          onPressed: _predictSymptoms,
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          child: Icon(Icons.arrow_upward, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
