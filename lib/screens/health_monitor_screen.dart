import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HealthMonitorScreen extends StatefulWidget {
  const HealthMonitorScreen({super.key});

  @override
  _HealthMonitorScreenState createState() => _HealthMonitorScreenState();
}

class _HealthMonitorScreenState extends State<HealthMonitorScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Controllers for new entries
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _sleepHoursController = TextEditingController();
  
  Future<void> _addMedicalData(String type, double value) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final today = DateTime.now();
        final dateStr = DateFormat('yyyy-MM-dd').format(today);
        
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('medical_tracker')
            .doc(dateStr)
            .set({
          type: value,
          'timestamp': today,
        }, SetOptions(merge: true));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$type updated successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating $type: $e')),
        );
      }
    }
  }

  Widget _buildTrackerCard(String title, String subtitle, IconData icon, 
      TextEditingController controller, String type, String unit) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.deepOrange),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter $type',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    suffix: Text(unit, style: const TextStyle(color: Colors.white)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.deepOrange),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                ),
                onPressed: () {
                  final value = double.tryParse(controller.text);
                  if (value != null) {
                    _addMedicalData(type, value);
                    controller.clear();
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView(
          children: [
            // Existing prescription widgets...
            
            const SizedBox(height: 20),
            _buildTrackerCard(
              'Sleep Tracker',
              'Track your daily sleep duration',
              Icons.bedtime,
              _sleepHoursController,
              'sleep_hours',
              'hours',
            ),
            _buildTrackerCard(
              'Calorie Tracker',
              'Track your daily calorie intake',
              Icons.restaurant,
              _caloriesController,
              'calories',
              'cal',
            ),
          ],
        ),
      ),
    );
  }
}
