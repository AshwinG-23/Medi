import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

class QuestionnaireScreen extends StatefulWidget {
  final User? user;

  const QuestionnaireScreen({super.key, this.user});

  @override
  _QuestionnaireScreenState createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  String _selectedGender = '';
  DateTime? _selectedDate;

  Widget _buildGenderButton(String gender, IconData icon) {
    bool isSelected = _selectedGender == gender;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton.icon(
          icon: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.grey,
            size: 24,
          ),
          label: Text(
            gender,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontSize: 16,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.blue : Colors.grey[900],
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          onPressed: () => setState(() => _selectedGender = gender),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              surface: Color.fromARGB(255, 0, 0, 0),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey[900],
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _submitQuestionnaire() async {
    if (_nameController.text.isEmpty ||
        _selectedGender.isEmpty ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      // Calculate age from date of birth
      final now = DateTime.now();
      final age = now.year -
          _selectedDate!.year -
          (now.month > _selectedDate!.month ||
                  (now.month == _selectedDate!.month &&
                      now.day >= _selectedDate!.day)
              ? 0
              : 1);

      // Update user document in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user!.uid)
          .update({
        'name': _nameController.text,
        'dateOfBirth': _dobController.text,
        'age': age,
        'gender': _selectedGender,
        'isProfileComplete': true,
        'profileCompletedAt': FieldValue.serverTimestamp(),
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit profile: $e')),
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
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                const Text(
                  'Complete Your Profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Name',
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: "Enter your name",
                    hintStyle: const TextStyle(color: Colors.grey),
                    fillColor: Colors.grey[900],
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Date of Birth',
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
                const SizedBox(height: 5),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      hintText: "Select your date of birth",
                      hintStyle: const TextStyle(color: Colors.grey),
                      fillColor: Colors.grey[900],
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDate == null
                              ? "Select your date of birth"
                              : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                          style: TextStyle(
                            color: _selectedDate == null
                                ? Colors.grey
                                : Colors.white,
                          ),
                        ),
                        const Icon(Icons.calendar_today, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Gender',
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildGenderButton('Male', Icons.male),
                    _buildGenderButton('Female', Icons.female),
                    _buildGenderButton('Other', Icons.person_outline),
                  ],
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _submitQuestionnaire,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text("Submit"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
