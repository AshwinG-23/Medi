import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to home screen after 3 seconds
    Future.delayed(Duration(seconds: 1), () {
      Navigator.pushReplacementNamed(
          context, '/home'); // Replace with your home route
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'lib/assets/logo.png', // Your logo path
          width: 200, // Adjust size as needed
          height: 200,
        ),
      ),
    );
  }
}
