import 'package:flutter/material.dart';

class HealthMonitorScreen extends StatelessWidget {
  const HealthMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          "Health Monitor Screen",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
