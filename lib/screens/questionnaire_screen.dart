import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

class QuestionnaireScreen extends StatefulWidget {
  final User? user;

  const QuestionnaireScreen({super.key, required this.user});

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
        child: Container(
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(20.0), // Match button's border radius
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                spreadRadius: 0.1,
                blurRadius: 5,
                offset: const Offset(0, 5),
              ),
            ],
          ),
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
              backgroundColor: isSelected
                  ? const Color(0xFF6295E2)
                  : const Color(0xFF302D2D),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              elevation: 0, // Disable default button elevation
            ),
            onPressed: () => setState(() => _selectedGender = gender),
          ),
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

    if (widget.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found')),
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
      backgroundColor: const Color(0xFF222121),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                Center(
                  child: Image.asset('lib/assets/logo.png', height: 70),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Center(
                  child: const Text(
                    'A little about yourself',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Name',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
                const SizedBox(height: 5),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        spreadRadius: 0.1,
                        blurRadius: 5,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: "Enter your name",
                      hintStyle: const TextStyle(color: Colors.grey),
                      fillColor: Color(0xFF302D2D),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Date of Birth',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
                const SizedBox(height: 5),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        spreadRadius: 0.1,
                        blurRadius: 5,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        hintText: "Select your date of birth",
                        hintStyle: const TextStyle(color: Colors.grey),
                        fillColor: Color(0xFF302D2D),
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
                ),
                const SizedBox(height: 20),
                const Text(
                  'Gender',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildGenderButton('Male', Icons.male),
                    _buildGenderButton('Female', Icons.female),
                    _buildGenderButton('Other', Icons.person_outline),
                  ],
                ),
                const SizedBox(height: 310),
                Align(
                  alignment: Alignment.center,
                  child: FractionallySizedBox(
                    widthFactor: 0.6, // 70% of the parent's width
                    child: ElevatedButton(
                      onPressed: _submitQuestionnaire,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6295E2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text("Submit"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
