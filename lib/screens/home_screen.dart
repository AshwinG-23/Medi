import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'medical_management_screen.dart';
import 'health_monitor_screen.dart';
import 'chatbot_screen.dart';
import 'nearby_assistance_screen.dart';
import '../utils/location_data.dart';
import 'login_screen.dart';
import '../services/sos_service.dart';
import '../services/background_fetch_service.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final bool _showNavBar = true;
  final GlobalKey<CurvedNavigationBarState> _bottomNavKey = GlobalKey();
  final AppData _appData = AppData();
  late List<Widget> _screens;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _userData;
  final BackgroundFetchService _fetchService = BackgroundFetchService();

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeContentScreen(),
      const HealthMonitorScreen(),
      const ChatScreen(),
      const NearbyAssistanceScreen(),
      const MedicalManagementScreen(),
    ];
    _fetchUserData();
    _startBackgroundFetching();
  }

  Future<void> _startBackgroundFetching() async {
    // Fetch hospitals for all radii in the background
    final userLocation = await _fetchService.getCurrentLocation();
    if (userLocation != null) {
      final hospitals =
          await _fetchService.fetchHospitalsForAllRadii(userLocation);
      _appData.updateData(
          userLocation, hospitals); // Update AppData with fetched data
    }
  }

  Future<void> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      setState(() {
        _userData = userDoc.data();
      });
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(100, 0, 0, 0),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 30, 30, 30),
        elevation: 0,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          GestureDetector(
            onLongPress: () {
              SosService.startLongPress(); // Start the timer on long press
            },
            onLongPressEnd: (details) {
              SosService.cancelLongPress(); // Cancel if released early
            },
            child: IconButton(
              icon: const Icon(Icons.sos, color: Colors.red),
              onPressed: () {
                // Optional: Add another action if needed on normal press
              },
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _screens[_currentIndex],
      bottomNavigationBar: _showNavBar
          ? CurvedNavigationBar(
              key: _bottomNavKey,
              index: _currentIndex,
              height: 60.0,
              items: const <Widget>[
                Icon(Icons.home, size: 25, color: Colors.orange),
                Icon(Icons.health_and_safety, size: 30, color: Colors.orange),
                Icon(Icons.chat, size: 30, color: Colors.orange),
                Icon(Icons.monitor_heart, size: 30, color: Colors.orange),
                Icon(Icons.location_on, size: 30, color: Colors.orange),
              ],
              color: Colors.black,
              buttonBackgroundColor: Colors.black,
              backgroundColor: const Color.fromARGB(255, 29, 29, 29),
              animationCurve: Curves.easeInOut,
              animationDuration: const Duration(milliseconds: 600),
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            )
          : null,
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Colors.black,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.black,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage:
                        _userData != null && _userData!['profileImage'] != null
                            ? NetworkImage(_userData!['profileImage'])
                            : null,
                    child:
                        _userData == null || _userData!['profileImage'] == null
                            ? const Icon(Icons.person,
                                size: 30, color: Colors.white)
                            : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _userData != null ? _userData!['name'] : 'Loading...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _userData != null ? _userData!['email'] : '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: const Text('Edit Profile',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                // Navigate to edit profile screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title:
                  const Text('Logout', style: TextStyle(color: Colors.white)),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }
}

class HomeContentScreen extends StatelessWidget {
  const HomeContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 30, 30, 30),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListView(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildCaloriesCard(),
              const SizedBox(height: 20),
              _buildSleepCard(),
              const SizedBox(height: 20),
              _buildArticles(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Hello Vikas,",
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          "How is u rigggs doin?",
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildCaloriesCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('medical_tracker')
          .orderBy('timestamp', descending: true)
          .limit(7)
          .snapshots(),
      builder: (context, snapshot) {
        List<FlSpot> caloriesData = [];
        double todayCalories = 0;

        if (snapshot.hasData) {
          final documents = snapshot.data!.docs.reversed.toList();
          for (int i = 0; i < documents.length; i++) {
            final calories = (documents[i].data() as Map)['calories'] ?? 0.0;
            caloriesData.add(FlSpot(i.toDouble(), calories.toDouble()));
            if (i == documents.length - 1) todayCalories = calories.toDouble();
          }
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 45, 45, 45),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_fire_department, color: Colors.orange[400]),
                  const SizedBox(width: 8),
                  Text(
                    "Calories",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange[400],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                todayCalories.toStringAsFixed(0),
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                "Cal/Day",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: caloriesData,
                        isCurved: true,
                        color: Colors.orange[400],
                        barWidth: 2,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.orange.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSleepCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('medical_tracker')
          .orderBy('timestamp', descending: true)
          .limit(7)
          .snapshots(),
      builder: (context, snapshot) {
        List<FlSpot> sleepData = [];
        String sleepTime = "0:00 AM";

        if (snapshot.hasData) {
          final documents = snapshot.data!.docs.reversed.toList();
          for (int i = 0; i < documents.length; i++) {
            final sleep = (documents[i].data() as Map)['sleep_hours'] ?? 0.0;
            sleepData.add(FlSpot(i.toDouble(), sleep.toDouble()));
            if (i == documents.length - 1) {
              final sleepStart =
                  (documents[i].data() as Map)['sleep_start'] as Timestamp?;
              if (sleepStart != null) {
                sleepTime = DateFormat('h:mm a').format(sleepStart.toDate());
              }
            }
          }
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 45, 45, 45),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bedtime, color: Colors.blue[400]),
                  const SizedBox(width: 8),
                  Text(
                    "Sleep Cycle",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[400],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                sleepTime,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                "Sleep Time/Day",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: sleepData,
                        isCurved: true,
                        color: Colors.orange,
                        barWidth: 2,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildArticles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Latest Articles",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('articles')
              .orderBy('timestamp', descending: true)
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return GestureDetector(
                  onTap: () {
                    // Open the article URL when tapped
                    if (data['articleUrl'] != null &&
                        data['articleUrl'].isNotEmpty) {
                      launchUrl(data['articleUrl']);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          data['imageUrl'] ?? '',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[800],
                              child: Icon(Icons.image, color: Colors.grey[600]),
                            );
                          },
                        ),
                      ),
                      title: Text(
                        data['title'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        data['subtitle'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
