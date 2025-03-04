import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/api_service.dart';
import '../screens/symtom_predictor_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingButton = false;

  @override
  void initState() {
    super.initState();
    _loadPreviousChats();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 140 && !_showFloatingButton) {
      setState(() {
        _showFloatingButton = true;
      });
    } else if (_scrollController.offset <= 140 && _showFloatingButton) {
      setState(() {
        _showFloatingButton = false;
      });
    }
  }

  void _navigateToSymptomPredictor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SymptomPredictorScreen(),
      ),
    );
  }

  void _loadPreviousChats() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      var chatQuery = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('chats')
          .orderBy('timestamp', descending: false)
          .limitToLast(15)
          .get();

      List<Map<String, dynamic>> loadedMessages = chatQuery.docs
          .map((doc) => {
                'sender': doc['sender'],
                'message': doc['message'],
                'timestamp': doc['timestamp']
              })
          .toList();

      setState(() {
        _messages = loadedMessages;
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      print('Error loading previous chats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    String symptom = _controller.text;
    if (symptom.isEmpty) return;

    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Create context from the last 10 messages
    String context = _messages
        .sublist(_messages.length - 10 < 0 ? 0 : _messages.length - 10)
        .map((msg) => "${msg['sender']}: ${msg['message']}")
        .join('\n');

    setState(() {
      _messages.add(
        {'sender': 'user', 'message': symptom, 'timestamp': DateTime.now()},
      );
    });
    _controller.clear();

    _scrollToBottom();

    try {
      String response = await _apiService.getDiseases(context, symptom);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Store the question and response pair in Firebase
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('chats')
          .doc(timestamp.toString())
          .set({
        'sender': 'user',
        'message': symptom,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('chats')
          .doc((timestamp + 1).toString())
          .set({
        'sender': 'bot',
        'message': response,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _messages.add({
          'sender': 'bot',
          'message': response,
          'timestamp': DateTime.now()
        });
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'bot',
          'message':
              'Sorry, I encountered an error while analyzing your symptoms. Please try again.',
          'timestamp': DateTime.now()
        });
      });
      print('Error getting disease prediction: $e');
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
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: _messages.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Column(
                                children: [
                                  GestureDetector(
                                    onTap:
                                        _navigateToSymptomPredictor, // Navigate on tap
                                    child: Container(
                                      width: double.infinity,
                                      height: 140,
                                      color:
                                          const Color.fromARGB(255, 30, 30, 30),
                                      child: Center(
                                        child: Image.asset(
                                          'lib/assets/chatbot_logo.png',
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
                                      'Click above to use the Symptom Predictor instead',
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400),
                                    ),
                                  ),
                                ],
                              );
                            }

                            final message = _messages[index - 1];
                            return Align(
                              alignment: message['sender'] == 'user'
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 8),
                                padding: EdgeInsets.all(12),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 22, 22, 22),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: MarkdownBody(
                                  data: message['message'],
                                  styleSheet: MarkdownStyleSheet(
                                    p: const TextStyle(color: Colors.white),
                                  ),
                                  softLineBreak: true,
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Let me know your concern',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: Colors.deepOrange),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.send,
                          color: Colors.deepOrange,
                        ),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 17,
                )
              ],
            ),
          ),
          // Floating button for navigation when top section scrolls out of view
          if (_showFloatingButton)
            Positioned(
              top: 10,
              right: 10,
              child: FloatingActionButton(
                onPressed: _navigateToSymptomPredictor,
                backgroundColor: const Color.fromARGB(255, 30, 30, 30),
                child: Image.asset(
                  'lib/assets/chatbot_logo.png',
                  height: 45,
                  width: 45,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
