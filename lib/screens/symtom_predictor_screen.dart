import 'package:flutter/material.dart';

class SymptomPredictorScreen extends StatelessWidget {
  const SymptomPredictorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          "Symptom Predictor Screen",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
