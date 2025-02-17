import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'medical_management_screen.dart';
import 'health_monitor_screen.dart';
import 'chatbot_screen.dart';
import 'nearby_assistance_screen.dart';
import '../utils/location_data.dart';
import 'login_screen.dart';
import '../services/sos_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../services/background_fetch_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  void setCurrentIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _startBackgroundFetching() async {
    final userLocation = await _fetchService.getCurrentLocation();
    if (userLocation != null) {
      final hospitals =
          await _fetchService.fetchHospitalsForAllRadii(userLocation);
      _appData.updateData(userLocation, hospitals);
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
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');

      await _auth.signOut();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 30, 30, 30),
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
              SosService.startLongPress();
            },
            onLongPressEnd: (details) {
              SosService.cancelLongPress();
            },
            child: IconButton(
              onPressed: () {},
              icon: Container(
                width: 30, // Size of the circular button
                height: 30,
                decoration: const BoxDecoration(
                  color: Colors.red, // Red background
                  shape: BoxShape.circle, // Circular shape
                ),
                child: const Center(
                  child: Icon(
                    Icons.sos_rounded, // SOS icon
                    color: Colors.black, // Black icon color
                    size: 28, // Adjust size as needed
                  ),
                ),
              ),
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
              items: <Widget>[
                Icon(
                  Icons.home,
                  size: _currentIndex == 0 ? 30 : 25,
                  color: _currentIndex == 0 ? Colors.deepOrange : Colors.grey,
                ),
                SvgPicture.asset(
                  'lib/assets/icon _Cardiogram_.svg',
                  width: _currentIndex == 1 ? 27 : 22,
                  height: _currentIndex == 1 ? 27 : 22,
                  color: _currentIndex == 1 ? Colors.deepOrange : Colors.grey,
                ),
                SvgPicture.asset(
                  'lib/assets/icon _chatbot_.svg',
                  width: _currentIndex == 2 ? 30 : 25,
                  height: _currentIndex == 2 ? 30 : 25,
                  color: _currentIndex == 2 ? Colors.deepOrange : Colors.grey,
                ),
                SvgPicture.asset(
                  'lib/assets/icon _Location_.svg',
                  width: _currentIndex == 3 ? 30 : 25,
                  height: _currentIndex == 3 ? 30 : 25,
                  color: _currentIndex == 3 ? Colors.deepOrange : Colors.grey,
                ),
                SvgPicture.asset(
                  'lib/assets/icon_Alternate File_.svg',
                  width: _currentIndex == 4 ? 30 : 25,
                  height: _currentIndex == 4 ? 30 : 25,
                  color: _currentIndex == 4 ? Colors.deepOrange : Colors.grey,
                ),
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
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    final userName = homeState?._userData?['name'] ?? 'User';

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 30, 30, 30),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListView(
            children: [
              _buildHeader(userName, homeState),
              const SizedBox(height: 20),
              _buildCaloriesCard(context),
              const SizedBox(height: 20),
              _buildSleepCard(context),
              const SizedBox(height: 20),
              _buildArticles(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String userName, _HomeScreenState? homeState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Hello $userName,",
          style: GoogleFonts.poppins(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        GestureDetector(
          onTap: () {
            homeState?.setCurrentIndex(2); // Navigate to Chatbot Screen
          },
          child: Text(
            "How are you doing?\n"
            "Do you need help with anything.....?",
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[400],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCaloriesCard(BuildContext context) {
    final today = DateTime.now();
    final List<String> last7Days = List.generate(7, (index) {
      final date = today.subtract(Duration(days: index));
      return DateFormat('yyyy-MM-dd').format(date);
    }).reversed.toList(); // Reverse to show earlier dates on the left

    return GestureDetector(
      onTap: () {
        final homeState = context.findAncestorStateOfType<_HomeScreenState>();
        homeState?.setCurrentIndex(1);
      },
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('medical_tracker')
            .doc('calorie')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Container();
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          List<BarChartGroupData> calorieBars = [];
          double totalCalories = 0;
          int validEntries = 0;

          for (int i = 0; i < last7Days.length; i++) {
            final date = last7Days[i];
            final calories =
                double.tryParse(data[date]?.toString() ?? '0') ?? 0.0;
            if (calories > 0) {
              calorieBars.add(
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: calories,
                      color: Colors.deepOrange[400]!,
                      width: 12, // Width of each bar
                    ),
                  ],
                ),
              );
              totalCalories += calories;
              validEntries++;
            }
          }

          final averageCalories =
              validEntries > 0 ? totalCalories / validEntries : 0;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF302D2D),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  spreadRadius: 0.01,
                  blurRadius: 5,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: Colors.deepOrange[400],
                          size: 40,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Calories",
                          style: GoogleFonts.poppins(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange[400],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 70),
                  ],
                ),
                Positioned(
                  bottom: 0,
                  left: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${averageCalories.truncate()}',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Avg Cal/Day",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: SizedBox(
                    width: 100,
                    height: 50,
                    child: BarChart(
                      BarChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: calorieBars,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSleepCard(BuildContext context) {
    final today = DateTime.now();
    final List<String> last7Days = List.generate(7, (index) {
      final date = today.subtract(Duration(days: index));
      return DateFormat('yyyy-MM-dd').format(date);
    }).reversed.toList(); // Reverse to show earlier dates on the left

    return GestureDetector(
      onTap: () {
        final homeState = context.findAncestorStateOfType<_HomeScreenState>();
        homeState?.setCurrentIndex(1);
      },
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('medical_tracker')
            .doc('sleep_hours')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Container();
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          List<FlSpot> bedtimeSpots = [];
          List<int> bedtimeMinutes = [];
          int validEntries = 0;

          for (int i = 0; i < last7Days.length; i++) {
            final date = last7Days[i];
            final bedtime = data[date]?.toString() ?? '';
            if (bedtime.isNotEmpty) {
              // Parse bedtime (e.g., "0200" or "2130")
              final hours = int.tryParse(bedtime.substring(0, 2)) ?? 0;
              final minutes = int.tryParse(bedtime.substring(2)) ?? 0;
              final totalMinutes = hours * 60 + minutes;

              // Adjust for bedtimes from midnight (00:00) to 10:00 AM
              final isNextDay = hours >= 0 && hours < 10; // 00:00 to 10:00 AM
              final adjustedMinutes = isNextDay
                  ? totalMinutes +
                      1440 // Add 24 hours if between 00:00 and 10:00 AM
                  : totalMinutes;

              bedtimeSpots
                  .add(FlSpot(i.toDouble(), adjustedMinutes.toDouble()));
              bedtimeMinutes.add(adjustedMinutes);
              validEntries++;
            }
          }

          // Calculate average bedtime in minutes
          final averageBedtimeMinutes = validEntries > 0
              ? bedtimeMinutes.reduce((a, b) => a + b) ~/ validEntries
              : 0;

          // Convert average bedtime back to HH:mm format
          final averageHours = (averageBedtimeMinutes % 1440) ~/ 60;
          final averageMinutes = averageBedtimeMinutes % 60;
          final averageBedtime =
              '${averageHours.toString().padLeft(2, '0')}:${averageMinutes.toString().padLeft(2, '0')}';

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF302D2D),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  spreadRadius: 0.01,
                  blurRadius: 5,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bedtime,
                          color: Colors.blue[400],
                          size: 33,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Sleep Cycle",
                          style: GoogleFonts.poppins(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[400],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
                Positioned(
                  bottom: 0,
                  left: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('h:mm a')
                            .format(DateFormat('HH:mm').parse(averageBedtime)),
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Avg Bedtime",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: SizedBox(
                    width: 100,
                    height: 50,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineTouchData: LineTouchData(
                            enabled: false), // Disable interactivity
                        lineBarsData: [
                          LineChartBarData(
                            spots: bedtimeSpots,
                            isCurved: false, // Sharp lines
                            color: Colors.deepOrange,
                            barWidth: 2,
                            dotData: FlDotData(show: false), // Hide dots
                            belowBarData: BarAreaData(
                              show: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildArticles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Latest Articles",
          style: GoogleFonts.poppins(
            fontSize: 25,
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
              return Container();
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return GestureDetector(
                  onTap: () async {
                    final urlString = data['articleUrl'];
                    if (urlString != null && urlString.isNotEmpty) {
                      Uri? uri = Uri.tryParse(urlString);
                      if (uri != null) {
                        // Specify Chrome as the browser
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      } else {
                        print("Invalid URL: $urlString");
                      }
                    } else {
                      print("No URL found");
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF302D2D),
                      borderRadius: BorderRadius.circular(40),
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: data['imageUrl'] != null &&
                                  Uri.tryParse(data['imageUrl'])
                                          ?.hasAbsolutePath ==
                                      true
                              ? Image.network(
                                  data['imageUrl'],
                                  width: double.infinity,
                                  height: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: double.infinity,
                                      height: 150,
                                      color: Colors.grey[800],
                                      child: Icon(Icons.image,
                                          color: Colors.grey[600]),
                                    );
                                  },
                                )
                              : Container(
                                  width: double.infinity,
                                  height: 150,
                                  color: Colors.grey[800],
                                  child: Icon(Icons.image,
                                      color: Colors.grey[600]),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['title'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                data['subtitle'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
