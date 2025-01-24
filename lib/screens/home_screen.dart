import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 2; // Default active index is the Chatbot

  final List<Widget> _screens = [
    MedicalManagementScreen(),
    HealthMonitorScreen(),
    ChatbotScreen(),
    NearbyAssistanceScreen(),
    AccountDetailsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.black),
          onPressed: () {},
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 40,
            ),
            SizedBox(width: 8),
            Text(
              'MediSync',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.red),
            onPressed: () {},
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          BottomNavigationBarItem(
            icon:
                _buildNavIcon(0, Icons.medical_services, "Medical Management"),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(1, Icons.health_and_safety, "Health Monitor"),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(2, Icons.chat, "Chatbot"),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(3, Icons.location_on, "Nearby Assistance"),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(4, Icons.account_circle, "Account Details"),
            label: '',
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(int index, IconData icon, String tooltip) {
    final bool isActive = _currentIndex == index;
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.blue.shade200,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  )
                ]
              : [],
        ),
        padding: EdgeInsets.all(8),
        child: Icon(
          icon,
          size: isActive ? 36 : 28,
          color: isActive ? Colors.blue : Colors.grey,
        ),
      ),
    );
  }
}

// Placeholder widgets for the different screens
class MedicalManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Medical Management Screen"));
  }
}

class HealthMonitorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Health Monitor Screen"));
  }
}

class ChatbotScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Chatbot Screen"));
  }
}

class NearbyAssistanceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Nearby Assistance Screen"));
  }
}

class AccountDetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Account Details Screen"));
  }
}
