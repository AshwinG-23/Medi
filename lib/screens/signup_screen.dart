import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'questionnaire_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isTermsAccepted = false;

  Future<void> _signUp() async {
    if (!_isTermsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Terms and Privacy Policy')),
      );
      return;
    }

    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    try {
      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      // Create user document in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': _emailController.text,
        'createdAt': FieldValue.serverTimestamp(),
        'isProfileComplete': false,
        'emailVerified': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent. Please verify your email.'),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuestionnaireScreen(user: userCredential.user),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-up failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.10),
                Center(
                  child: Image.asset('lib/assets/logo.png', height: 70),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Email',
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: "Enter your email",
                    hintStyle: const TextStyle(color: Colors.grey),
                    fillColor: Colors.grey[900],
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Password',
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    hintText: "Enter your password",
                    hintStyle: const TextStyle(color: Colors.grey),
                    fillColor: Colors.grey[900],
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Confirm Password',
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    hintText: "Confirm your password",
                    hintStyle: const TextStyle(color: Colors.grey),
                    fillColor: Colors.grey[900],
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Checkbox(
                      value: _isTermsAccepted,
                      onChanged: (value) {
                        setState(() {
                          _isTermsAccepted = value ?? false;
                        });
                      },
                      fillColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.blue;
                          }
                          return Colors.grey;
                        },
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        "I agree with Terms and Privacy Policy",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text("Sign Up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}