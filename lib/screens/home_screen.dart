import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'medical_management_screen.dart';
import 'health_monitor_screen.dart';
import 'chatbot_screen.dart';
import 'nearby_assistance_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/location_data.dart';
import 'login_screen.dart'; // Import your login screen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _showNavBar = true;
  final GlobalKey<CurvedNavigationBarState> _bottomNavKey = GlobalKey();
  final AppData _appData = AppData();
  late List<Widget> _screens;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeContentScreen(),
      const MedicalManagementScreen(),
      ChatbotScreen(
        userId: _auth.currentUser?.uid ?? '', 
        onClose: () => _resetToHomeScreen(),
      ),
      const HealthMonitorScreen(),
      const NearbyAssistanceScreen(),
    ];

    // Fetch user data from Firestore
    _fetchUserData();
  }
  
  Future<void> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      // If the user is not logged in, navigate to the login screen
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
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _resetToHomeScreen() {
    setState(() {
      _currentIndex = 0;
      _showNavBar = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black, // Dark theme
        elevation: 0,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer(); // Open the drawer
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sos, color: Colors.red),
            onPressed: () {},
          ),
        ],
      ),
      drawer: _buildDrawer(), // Add the drawer
      body: _screens[_currentIndex],
      bottomNavigationBar: _showNavBar
          ? CurvedNavigationBar(
              key: _bottomNavKey,
              index: _currentIndex,
              height: 60.0,
              items: const <Widget>[
                Icon(Icons.medical_services, size: 30, color: Colors.orange),
                Icon(Icons.health_and_safety, size: 30, color: Colors.orange),
                Icon(Icons.chat, size: 30, color: Colors.orange),
                Icon(Icons.monitor_heart, size: 30, color: Colors.orange),
                Icon(Icons.location_on, size: 30, color: Colors.orange),
              ],
              color: Colors.black, // Dark theme
              buttonBackgroundColor: Colors.black, // Dark theme
              backgroundColor: const Color.fromARGB(218, 0, 0, 0), // Dark theme
              animationCurve: Curves.easeInOut,
              animationDuration: const Duration(milliseconds: 800),
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                  _showNavBar = index != 2;
                });
              },
            )
          : null,
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
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
                  child: _userData == null || _userData!['profileImage'] == null
                      ? Icon(Icons.person, size: 30, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 10),
                Text(
                  _userData != null ? _userData!['name'] : 'Loading...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _userData != null ? _userData!['email'] : '',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Profile'),
            onTap: () {
              // Navigate to edit profile screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}

class HomeContentScreen extends StatelessWidget {
  const HomeContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Light background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListView(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildCaloriesCard(),
              const SizedBox(height: 20),
              _buildHealthReminder(),
              const SizedBox(height: 20),
              _buildLatestArticles(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Hello Vikas,",
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCaloriesCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "🍽 Calories",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "1786",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Cal/Day",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            Icon(Icons.bar_chart, size: 50, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthReminder() {
    return _buildCard(
      title: "Blood test",
      subtitle: "Duis hendrerit ex nibh, non",
      date: "23 Mar",
      icon: Icons.bloodtype,
      color: Colors.redAccent,
    );
  }

  Widget _buildLatestArticles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Latest Articles",
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildCard(
          title: "Blood test",
          subtitle: "Duis hendrerit ex nibh, non",
          date: "23 Mar",
          icon: Icons.bloodtype,
          color: Colors.redAccent,
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required String date,
    required IconData icon,
    required Color color,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 14, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(
                        date,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
