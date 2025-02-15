import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class HealthMonitorScreen extends StatefulWidget {
  const HealthMonitorScreen({super.key});

  @override
  _HealthMonitorScreenState createState() => _HealthMonitorScreenState();
}

class _HealthMonitorScreenState extends State<HealthMonitorScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime selectedDate = DateTime.now();
  String expandedCard = 'Recommended Routine'; // Set default expanded card

  final TextEditingController _calorieInputController = TextEditingController();
  TimeOfDay? _selectedSleepTime;
  bool showCalorieInput = false;

  // Mock function to simulate calorie prediction
  int predictCalories(String food) {
    return 250; // Mock implementation
  }

  List<DateTime> _getWeekDates() {
    final List<DateTime> dates = [];
    final DateTime now = DateTime.now();
    for (int i = -3; i <= 3; i++) {
      dates.add(DateTime(now.year, now.month, now.day + i));
    }
    return dates;
  }

  Future<void> _addCalorieEntry(int calories) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('medical_tracker')
            .doc('calories')
            .collection(dateStr)
            .add({
          'calories': calories,
          'timestamp': Timestamp.now(),
        });

        _calorieInputController.clear();
        setState(() {
          showCalorieInput = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding calorie entry: $e')),
      );
    }
  }

  Future<void> _updateCalories(int calories) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

        final querySnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('medical_tracker')
            .doc('calories')
            .collection(dateStr)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final docId = querySnapshot.docs.first.id;
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('medical_tracker')
              .doc('calories')
              .collection(dateStr)
              .doc(docId)
              .update({
            'calories': calories,
          });
        } else {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('medical_tracker')
              .doc('calories')
              .collection(dateStr)
              .add({
            'calories': calories,
            'timestamp': Timestamp.now(),
          });
        }

        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating calories: $e')),
      );
    }
  }

  Future<void> _addSleepEntry(TimeOfDay sleepTime) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('medical_tracker')
            .doc('sleep')
            .collection(dateStr)
            .add({
          'sleep_time': '${sleepTime.hour}:${sleepTime.minute}',
          'timestamp': Timestamp.now(),
        });

        setState(() {
          _selectedSleepTime = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding sleep entry: $e')),
      );
    }
  }

  Widget _buildDateSlider() {
    final now = DateTime.now();
    return Container(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = _getWeekDates()[index];
          final isSelected = DateUtils.isSameDay(date, selectedDate);
          final dayName = DateFormat('EEE').format(date).toUpperCase();
          final dayNum = date.day.toString();
          final isAfterToday = date.isAfter(now);

          return GestureDetector(
            onTap:
                isAfterToday ? null : () => setState(() => selectedDate = date),
            child: Container(
              width: 50,
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.deepOrange
                    : isAfterToday
                        ? Colors.grey[800]
                        : Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      color: isAfterToday
                          ? Colors.grey[600]
                          : (isSelected ? Colors.white : Colors.grey),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    dayNum,
                    style: TextStyle(
                      color: isAfterToday
                          ? Colors.grey[600]
                          : (isSelected ? Colors.white : Colors.grey),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpandableCard({
    required String title,
    required IconData icon,
    required Widget expandedContent,
  }) {
    final isExpanded = expandedCard == title;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: Colors.deepOrange),
            title: Text(
              title,
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            trailing: Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.deepOrange,
            ),
            onTap: () {
              setState(() {
                expandedCard =
                    isExpanded ? '' : title; // Use empty string instead of null
              });
            },
          ),
          if (isExpanded)
            Container(
              padding: EdgeInsets.all(16),
              child: expandedContent,
            ),
        ],
      ),
    );
  }

  Widget _buildCaloriePredictorCard() {
    return _buildExpandableCard(
      title: 'Calorie Predictor',
      icon: Icons.fastfood,
      expandedContent: Column(
        children: [
          TextField(
            controller: _calorieInputController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter food item',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                final predictedCalories = predictCalories(value);
                _calorieInputController.text = predictedCalories.toString();
              }
            },
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_calorieInputController.text.isNotEmpty) {
                final calories = int.parse(_calorieInputController.text);
                _addCalorieEntry(calories);
              }
            },
            child: Text('Add Calories'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .collection('medical_tracker')
          .doc('calories')
          .collection(DateFormat('yyyy-MM-dd').format(selectedDate))
          .snapshots(),
      builder: (context, snapshot) {
        int totalCalories = 0;
        List<QueryDocumentSnapshot> calorieEntries = [];

        if (snapshot.hasData) {
          calorieEntries = snapshot.data!.docs;
          totalCalories = calorieEntries.fold<int>(
            0,
            (sum, doc) {
              final data = doc.data() as Map<String, dynamic>;
              return sum + (data['calories'] as int);
            },
          );
        }

        return _buildExpandableCard(
          title: 'Food Intake',
          icon: Icons.restaurant,
          expandedContent: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today\'s Calories: $totalCalories',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: Colors.deepOrange,
                    ),
                    onPressed: () {
                      setState(() {
                        showCalorieInput = !showCalorieInput;
                        if (!showCalorieInput) {
                          _calorieInputController.clear();
                        }
                      });
                    },
                  ),
                ],
              ),
              if (showCalorieInput) ...[
                SizedBox(height: 16),
                TextField(
                  controller: _calorieInputController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter calories',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                  keyboardType: TextInputType.number,
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      final calories = int.parse(value);
                      _updateCalories(calories);
                    }
                  },
                ),
              ],
              SizedBox(height: 16),
              FutureBuilder<List<FlSpot>>(
                future: _getCalorieSpots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return Container(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: snapshot.data!,
                              isCurved: true,
                              color: Colors.deepOrange,
                              barWidth: 3,
                              dotData: FlDotData(show: false),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<FlSpot>> _getCalorieSpots() async {
    final List<FlSpot> spots = [];
    final List<DateTime> dates = _getWeekDates();
    for (int i = 0; i < dates.length; i++) {
      final dateStr = DateFormat('yyyy-MM-dd').format(dates[i]);
      final calories = await _getCaloriesForDate(dateStr);
      spots.add(FlSpot(i.toDouble(), calories.toDouble()));
    }
    return spots;
  }

  Future<int> _getCaloriesForDate(String dateStr) async {
    final user = _auth.currentUser;
    if (user != null) {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medical_tracker')
          .doc('calories')
          .collection(dateStr)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.fold<int>(
          0,
          (sum, doc) {
            final data = doc.data() as Map<String, dynamic>;
            return sum + (data['calories'] as int);
          },
        );
      }
    }
    return 0;
  }

  Widget _buildSleepCard() {
    return _buildExpandableCard(
      title: 'Sleep Cycle',
      icon: Icons.bedtime,
      expandedContent: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              final TimeOfDay? time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time != null) {
                _addSleepEntry(time);
              }
            },
            child: Text('Add Sleep Time'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
            ),
          ),
          SizedBox(height: 16),
          FutureBuilder<List<FlSpot>>(
            future: _getSleepSpots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return Container(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: snapshot.data!,
                          isCurved: true,
                          color: Colors.deepOrange,
                          barWidth: 3,
                          dotData: FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<List<FlSpot>> _getSleepSpots() async {
    final List<FlSpot> spots = [];
    final List<DateTime> dates = _getWeekDates();
    for (int i = 0; i < dates.length; i++) {
      final dateStr = DateFormat('yyyy-MM-dd').format(dates[i]);
      final sleepTime = await _getSleepTimeForDate(dateStr);
      spots.add(FlSpot(i.toDouble(), sleepTime.toDouble()));
    }
    return spots;
  }

  Future<int> _getSleepTimeForDate(String dateStr) async {
    final user = _auth.currentUser;
    if (user != null) {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medical_tracker')
          .doc('sleep')
          .collection(dateStr)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final sleepTime =
            querySnapshot.docs.first.data()['sleep_time'] as String;
        final timeParts = sleepTime.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        return hour + (minute / 60).round();
      }
    }
    return 0;
  }

  Widget _buildRoutineCard() {
    return _buildExpandableCard(
      title: 'Recommended Routine',
      icon: Icons.schedule,
      expandedContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Based on your patterns:',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            '• Recommended sleep time: 10:30 PM\n• Target daily calories: 2000 cal',
            style: TextStyle(color: Colors.grey[400]),
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
        child: Column(
          children: [
            _buildDateSlider(),
            Expanded(
              child: ListView(
                children: [
                  _buildCaloriePredictorCard(),
                  _buildFoodCard(),
                  _buildSleepCard(),
                  _buildRoutineCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
