import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/api_service2.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class HealthMonitorScreen extends StatefulWidget {
  const HealthMonitorScreen({super.key});

  @override
  _HealthMonitorScreenState createState() => _HealthMonitorScreenState();
}

class _HealthMonitorScreenState extends State<HealthMonitorScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiService _apiService = ApiService();

  DateTime selectedDate = DateTime.now();
  String expandedCard = 'Recommended Routine';

  final TextEditingController _caloriePredictorController =
      TextEditingController();
  final TextEditingController _calorieIntakeController =
      TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  TimeOfDay? _selectedSleepTime;
  bool showCalorieInput = false;
  bool showBMIInput = false;

  String predictedCalories = '';
  String recommendedRoutine = 'Waiting For more information';
  DateTime lastRoutineFetchTime = DateTime.now();

  final ScrollController _dateSliderController = ScrollController();

  Future<void> predictCalories(String food) async {
    try {
      final calories = await _apiService.getCalorieInfo(food);
      setState(() {
        predictedCalories = calories;
      });
    } catch (e) {
      setState(() {
        predictedCalories = 'Error predicting calories: $e';
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

    return Container(
      height: 120,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      color: const Color.fromARGB(255, 30, 30, 30),
      clipBehavior: Clip.none,
      child: ListView.builder(
        controller: _dateSliderController,
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        itemBuilder: (context, index) {
          final date = DateTime(now.year, now.month, now.day - 7 + index);
          final isSelected = DateUtils.isSameDay(date, selectedDate);
          final dayName = DateFormat('EEE').format(date).toUpperCase();
          final dayNum = date.day.toString();
          final isAfterToday = date.isAfter(now);

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            child: GestureDetector(
              onTap: isAfterToday
                  ? null
                  : () {
                      setState(() {
                        selectedDate = date;
                      });
                      _getRecommendedRoutine();
                      Future.delayed(Duration(milliseconds: 100), () {
                        _dateSliderController.animateTo(
                          index * 60.0,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      });
                    },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                width: 55,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.deepOrange
                      : isAfterToday
                          ? Colors.grey[800]
                          : Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      spreadRadius: 2,
                      blurRadius: 6,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            spreadRadius: 0.01,
            blurRadius: 5,
            offset: const Offset(0, 9),
          ),
        ],
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
                expandedCard = isExpanded ? '' : title;
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
                    await predictCalories(foodItem);
                  }
                },
              ),
            ],
          ),
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
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .collection('medical_tracker')
          .doc('calorie')
          .snapshots(),
      builder: (context, snapshot) {
        int totalCalories = 0;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          totalCalories = data[dateStr] ?? 0;
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
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SpinKitThreeBounce(
                        color: Colors.deepOrange,
                        size: 30.0,
                      );
                    } else if (snapshot.hasError) {
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

  Future<List<BarChartGroupData>> _getCalorieBars() async {
    final List<BarChartGroupData> bars = [];
    final List<DateTime> dates = _getWeekDates().toList();
    final DateTime now = DateTime.now();

    for (int i = 0; i < dates.length; i++) {
      final dateStr = DateFormat('yyyy-MM-dd').format(dates[i]);
      final calories = await _getCaloriesForDate(dateStr);
      final isToday = DateUtils.isSameDay(dates[i], now);

      bars.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: calories.toDouble(),
            color: isToday ? Colors.deepOrange : Colors.grey,
            width: 30,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ));
    }
    return bars;
  }

  Future<void> _updateCalories(int calories) async {
    final user = _auth.currentUser;
    if (user != null) {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medical_tracker')
          .doc('calorie')
          .set({
        dateStr: FieldValue.increment(calories),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _addSleepEntry(TimeOfDay time) async {
    final user = _auth.currentUser;
    if (user != null) {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final sleepTime =
          '${time.hour.toString().padLeft(2, '0')}${time.minute.toString().padLeft(2, '0')}';
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medical_tracker')
          .doc('sleep_hours')
          .set({
        dateStr: sleepTime,
      }, SetOptions(merge: true));
    }
  }

  Future<int> _getCaloriesForDate(String dateStr) async {
    final user = _auth.currentUser;
    if (user != null) {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medical_tracker')
          .doc('calorie')
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        return data[dateStr] ?? 0;
      }
    }
    return 0;
  }

  Widget _buildSleepCard() {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .collection('medical_tracker')
          .doc('sleep_hours')
          .snapshots(),
      builder: (context, snapshot) {
        String sleepTime = "Not Entered";
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final storedTime = data[dateStr] as String?;
          if (storedTime != null) {
            final hour = int.parse(storedTime.substring(0, 2));
            final minute = int.parse(storedTime.substring(2, 4));
            final timeOfDay = TimeOfDay(hour: hour, minute: minute);
            sleepTime = timeOfDay.format(context);
          }
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
                    'Today\'s Bedtime:  $sleepTime',
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
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SpinKitThreeBounce(
                      color: Colors.deepOrange,
                      size: 30.0,
                    );
                  } else if (snapshot.hasError) {
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
                              isCurved: false,
                              color: Colors.deepOrange,
                              barWidth: 3,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  final isToday = index ==
                                      _getWeekDates().indexWhere((date) =>
                                          DateUtils.isSameDay(
                                              date, DateTime.now()));
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: isToday
                                        ? Colors.deepOrange
                                        : Colors.grey,
                                    strokeWidth: 2,
                                    strokeColor: Colors.transparent,
                                  );
                                },
                              ),
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
    final DateTime now = DateTime.now();

    for (int i = 0; i < dates.length; i++) {
      final dateStr = DateFormat('yyyy-MM-dd').format(dates[i]);
      final sleepTime = await _getSleepTimeForDate(dateStr);
      final isToday = DateUtils.isSameDay(dates[i], now);

      spots.add(FlSpot(i.toDouble(), sleepTime.toDouble()));
    }
    return spots;
  }

  Future<double> _getSleepTimeForDate(String dateStr) async {
    final user = _auth.currentUser;
    if (user != null) {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medical_tracker')
          .doc('sleep_hours')
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final storedTime = data[dateStr] as String?;
        if (storedTime != null) {
          final hour = int.parse(storedTime.substring(0, 2));
          final minute = int.parse(storedTime.substring(2, 4));

          final bedtimeMinutes = hour * 60 + minute;
          final baselineMinutes = 16 * 60;

          double adjustedBedtime;
          if (bedtimeMinutes < baselineMinutes) {
            adjustedBedtime = bedtimeMinutes + 1440;
          } else {
            adjustedBedtime = bedtimeMinutes.toDouble();
          }

          return adjustedBedtime;
        }
      }
    }
    return 0.0;
  }

  Widget _buildRoutineCard() {
    return _buildExpandableCard(
      title: 'Recommended Routine',
      icon: Icons.schedule,
      expandedContent: FutureBuilder<String>(
        future: _getRecommendedRoutine(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SpinKitThreeBounce(
              color: Colors.deepOrange,
              size: 30.0,
            );
          } else if (snapshot.hasError) {
            return Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: Colors.white),
            );
          } else {
            return MarkdownBody(
              data: snapshot.data ?? 'No recommendations available.',
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(color: Colors.white),
              ),
              softLineBreak: true,
            );
          }
        },
      ),
    );
  }

  Future<String> _getRecommendedRoutine() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

    // Check if the routine is already stored in Firestore for the selected date
    final user = _auth.currentUser;
    if (user != null) {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medical_tracker')
          .doc('recroutine')
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final storedRoutine = data[dateStr] as String?;
        if (storedRoutine != null) {
          return storedRoutine;
        }
      }
    }

    // If no routine is stored, fetch a new one
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

    final bmi = await _getBMI();
    final calorieString = calorieData.join(',');
    final sleepString = sleepData.join(',');

    try {
      final routine = await _apiService.getRecommendedRoutine(
          bmi, calorieString, sleepString);

      // Store the routine in Firestore for the selected date
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('medical_tracker')
            .doc('recroutine')
            .set({
          dateStr: routine,
        }, SetOptions(merge: true));
      }

      return routine;
    } catch (e) {
      return 'Error fetching recommendations: $e';
    }
  }

  Widget _buildBMICard() {
    return _buildExpandableCard(
      title: 'BMI Calculator',
      icon: Icons.monitor_weight,
      expandedContent: Column(
        children: [
          FutureBuilder<String>(
            future: _getBMI(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SpinKitThreeBounce(
                  color: Colors.deepOrange,
                  size: 30.0,
                );
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                final bmi = snapshot.data ?? 'N/A';
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'BMI: $bmi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: AnimatedSwitcher(
                            duration: Duration(milliseconds: 300),
                            child: showBMIInput
                                ? Icon(Icons.close, color: Colors.deepOrange)
                                : Icon(Icons.edit, color: Colors.deepOrange),
                          ),
                          onPressed: () {
                            setState(() {
                              showBMIInput = !showBMIInput;
                              if (!showBMIInput) {
                                _heightController.clear();
                                _weightController.clear();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    AnimatedSize(
                      duration: Duration(milliseconds: 300),
                      child: showBMIInput
                          ? Column(
                              children: [
                                TextField(
                                  controller: _heightController,
                                  style: TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Enter height in cm',
                                    hintStyle: TextStyle(color: Colors.grey),
                                    border: InputBorder.none,
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                                TextField(
                                  controller: _weightController,
                                  style: TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Enter weight in kg',
                                    hintStyle: TextStyle(color: Colors.grey),
                                    border: InputBorder.none,
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    if (_heightController.text.isNotEmpty &&
                                        _weightController.text.isNotEmpty) {
                                      final height =
                                          double.parse(_heightController.text);
                                      final weight =
                                          double.parse(_weightController.text);
                                      await _updateBMI(height, weight);
                                      setState(() {
                                        showBMIInput = false;
                                      });
                                    }
                                  },
                                  child: Text('Calculate BMI'),
                                ),
                              ],
                            )
                          : SizedBox.shrink(),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updateBMI(double height, double weight) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'height': height,
        'weight': weight,
      }, SetOptions(merge: true));
    }
  }

  Future<String> _getBMI() async {
    final user = _auth.currentUser;
    if (user != null) {
      final docSnapshot =
          await _firestore.collection('users').doc(user.uid).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final height = data['height'] as double?;
        final weight = data['weight'] as double?;
        if (height != null && weight != null && height > 0) {
          final bmi =
              (weight / ((height / 100) * (height / 100))).toStringAsFixed(2);
          return bmi;
        }
      }
    }
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 30, 30, 30),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 30, 30, 30),
        toolbarHeight: 50,
        title: Row(
          children: [
            SvgPicture.asset(
              'lib/assets/icon _Cardiogram_.svg',
              width: 22,
              height: 22,
              color: Colors.deepOrange,
            ),
            const SizedBox(width: 8),
            const Text(
              'Health Monitor',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildDateSlider(),
            SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildCaloriePredictorCard(),
                  SizedBox(height: 20),
                  _buildFoodCard(),
                  SizedBox(height: 20),
                  _buildSleepCard(),
                  SizedBox(height: 20),
                  _buildRoutineCard(),
                  SizedBox(height: 20),
                  _buildBMICard(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
