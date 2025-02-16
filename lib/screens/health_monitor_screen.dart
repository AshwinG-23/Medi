import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service2.dart'; // Import the ApiService

class HealthMonitorScreen extends StatefulWidget {
  const HealthMonitorScreen({super.key});

  @override
  _HealthMonitorScreenState createState() => _HealthMonitorScreenState();
}

class _HealthMonitorScreenState extends State<HealthMonitorScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiService _apiService = ApiService(); // Initialize ApiService

  DateTime selectedDate = DateTime.now();
  String expandedCard = 'Recommended Routine'; // Set default expanded card

  final TextEditingController _caloriePredictorController =
      TextEditingController();
  final TextEditingController _calorieIntakeController =
      TextEditingController();
  TimeOfDay? _selectedSleepTime;
  bool showCalorieInput = false;

  String predictedCalories = ''; // Move predictedCalories to the state
  String recommendedRoutine =
      'Waiting For more information'; // Cache for recommended routine
  DateTime lastRoutineFetchTime = DateTime.now(); // Track last fetch time

  final ScrollController _dateSliderController = ScrollController();

  Future<void> predictCalories(String food) async {
    try {
      final calories = await _apiService.getCalorieInfo(food);
      setState(() {
        predictedCalories = calories; // Update predicted calories
      });
    } catch (e) {
      setState(() {
        predictedCalories =
            'Error predicting calories: $e'; // Update with error message
      });
    }
  }

  List<DateTime> _getWeekDates() {
    final List<DateTime> dates = [];
    final DateTime now = DateTime.now();
    for (int i = -7; i <= 0; i++) {
      dates.add(DateTime(now.year, now.month, now.day + i));
    }
    return dates;
  }

  Widget _buildDateSlider() {
    final now = DateTime.now();
    final initialScrollIndex =
    
        7; // Today's date is at index 10 (middle of the list)

    return Container(
      height: 80,
      color: Colors.black,
      child: ListView.builder(
        controller: _dateSliderController,
        scrollDirection: Axis.horizontal,
        itemCount: 14, // 14 days (7 past and 7 future)
        itemBuilder: (context, index) {
          final date = DateTime(now.year, now.month, now.day - 7 + index);
          final isSelected = DateUtils.isSameDay(date, selectedDate);
          final dayName = DateFormat('EEE').format(date).toUpperCase();
          final dayNum = date.day.toString();
          final isAfterToday = date.isAfter(now);

          return GestureDetector(
            onTap: isAfterToday
                ? null
                : () {
                    setState(() {
                      selectedDate = date;
                    });
                    // Animate to center the selected date
                    Future.delayed(Duration(milliseconds: 100), () {
                      _dateSliderController.animateTo(
                        index * 20.0, // Adjust scroll offset
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    });
                  },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
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
          Row(
            children: [
              // Send Arrow Button
              Expanded(
                child: TextField(
                  controller: _caloriePredictorController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter food item',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: Colors.deepOrange),
                onPressed: () async {
                  if (_caloriePredictorController.text.isNotEmpty) {
                    final foodItem = _caloriePredictorController.text;
                    await predictCalories(foodItem); // Call predictCalories
                  }
                },
              ),
            ],
          ),
          // Display Predicted Calories
          if (predictedCalories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: MarkdownBody(
                data: predictedCalories,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(color: Colors.white),
                ),
                softLineBreak: true,
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
          title: 'Calorie Intake',
          icon: Icons.restaurant,
          expandedContent: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today\'s Calories:   $totalCalories',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      child: showCalorieInput
                          ? Icon(Icons.close, color: Colors.deepOrange)
                          : Icon(Icons.add, color: Colors.deepOrange),
                    ),
                    onPressed: () {
                      setState(() {
                        showCalorieInput = !showCalorieInput;
                        if (!showCalorieInput) {
                          _calorieIntakeController.clear();
                        }
                      });
                    },
                  ),
                ],
              ),
              AnimatedSize(
                duration: Duration(milliseconds: 300),
                child: showCalorieInput
                    ? Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: TextField(
                          controller: _calorieIntakeController,
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
                              setState(() {
                                showCalorieInput = false;
                              });
                            }
                          },
                        ),
                      )
                    : SizedBox.shrink(),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: FutureBuilder<List<BarChartGroupData>>(
                  future: _getCalorieBars(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      return SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: snapshot.data ?? [],
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateCalories(int calories) async {
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
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  // Define the _addSleepEntry method
  Future<void> _addSleepEntry(TimeOfDay time) async {
    final user = _auth.currentUser;
    if (user != null) {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final sleepTime = '${time.hour}:${time.minute}';
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medical_tracker')
          .doc('sleep')
          .collection(dateStr)
          .add({
        'sleep_time': sleepTime,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<List<BarChartGroupData>> _getCalorieBars() async {
    final List<BarChartGroupData> bars = [];
    final List<DateTime> dates = _getWeekDates();
    for (int i = 0; i < dates.length; i++) {
      final dateStr = DateFormat('yyyy-MM-dd').format(dates[i]);
      final calories = await _getCaloriesForDate(dateStr);
      bars.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: calories.toDouble(), // Use toY instead of y
            color: Colors.deepOrange,
          ),
        ],
      ));
    }
    return bars;
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
            final data = doc.data();
            return sum + (data['calories'] as int);
          },
        );
      }
    }
    return 0;
  }

  Widget _buildSleepCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .collection('medical_tracker')
          .doc('sleep')
          .collection(DateFormat('yyyy-MM-dd').format(selectedDate))
          .snapshots(),
      builder: (context, snapshot) {
        String sleepTime = "Not Entered";
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          sleepTime = data['sleep_time'] as String;
        }

        return _buildExpandableCard(
          title: 'Sleep Cycle',
          icon: Icons.bedtime,
          expandedContent: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today\'s Sleep Time: $sleepTime',
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
                    onPressed: () async {
                      final TimeOfDay? time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        _addSleepEntry(time);
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),
              FutureBuilder<List<FlSpot>>(
                future: _getSleepSpots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: snapshot.data ?? [],
                              isCurved: false, // Sharp line curve
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
      expandedContent: FutureBuilder<String>(
        future: _getRecommendedRoutine(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return Text(
              snapshot.data ?? 'No recommendations available.',
              style: TextStyle(color: Colors.white),
            );
          }
        },
      ),
    );
  }

  Future<String> _getRecommendedRoutine() async {
    final now = DateTime.now();
    if (now.hour >= 0 && now.hour < 12 && lastRoutineFetchTime.day != now.day) {
      final List<DateTime> dates = _getWeekDates();
      final List<String> calorieData = [];
      final List<String> sleepData = [];

      for (final date in dates) {
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final calories = await _getCaloriesForDate(dateStr);
        final sleepTime = await _getSleepTimeForDate(dateStr);

        calorieData.add(calories.toString());
        sleepData.add(sleepTime.toString());
      }

      final bmi = "25"; // Hardcoded BMI for now
      final calorieString = calorieData.join(',');
      final sleepString = sleepData.join(',');

      try {
        final routine = await _apiService.getRecommendedRoutine(
            bmi, calorieString, sleepString);
        setState(() {
          recommendedRoutine = routine;
          lastRoutineFetchTime = now;
        });
        return routine;
      } catch (e) {
        return 'Error fetching recommendations: $e';
      }
    } else {
      return recommendedRoutine;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 30, 30, 30),
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
