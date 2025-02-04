import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart'; // For opening Google Maps
import '../services/location_service.dart';

class NearbyAssistanceScreen extends StatefulWidget {
  const NearbyAssistanceScreen({super.key});

  @override
  _NearbyAssistanceScreenState createState() => _NearbyAssistanceScreenState();
}

class _NearbyAssistanceScreenState extends State<NearbyAssistanceScreen> {
  final LocationService _locationService = LocationService();
  LatLng? _userLocation;
  double _searchRadius = 5000; // Default 5 km
  double _zoom = 13; // Initial zoom level
  List<dynamic> _nearbyHospitals = [];
  bool _isLoading = false;
  int _selectedHospitalIndex = -1;
  bool _showHospitalInfo = false;
  bool _showHospitalsList = false;

  @override
  void initState() {
    super.initState();
    _fetchUserLocationAndHospitals();
  }

  Future<void> _fetchUserLocationAndHospitals() async {
    setState(() {
      _isLoading = true;
    });

    var position = await _locationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });

      await _fetchHospitals();
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Failed to get location. Please enable GPS.")),
      );
    }
  }

  Future<void> _fetchHospitals() async {
    if (_userLocation != null) {
      List<dynamic> hospitals = await _locationService.getNearbyHospitals(
        _userLocation!.latitude,
        _userLocation!.longitude,
        _searchRadius,
      );

      setState(() {
        _nearbyHospitals = hospitals;
        _isLoading = false;
      });
    }
  }

  void _onSearchRadiusChanged(double value) {
    setState(() {
      _searchRadius = value * 1000; // Convert km to meters
      _zoom = _calculateZoomLevel(_searchRadius);
    });
    _fetchHospitals();
  }

  double _calculateZoomLevel(double radius) {
    if (radius <= 1000) return 15;
    if (radius <= 5000) return 13;
    if (radius <= 10000) return 11;
    return 9;
  }

  void _onHospitalPinTap(int index) {
    setState(() {
      _selectedHospitalIndex = index;
      _showHospitalInfo = true;
    });
  }

  void _closeModals() {
    setState(() {
      _showHospitalInfo = false;
      _showHospitalsList = false;
    });
  }

  void _toggleHospitalsList() {
    setState(() {
      _showHospitalsList = !_showHospitalsList;
    });
  }

  // Function to open Google Maps with directions
  Future<void> _navigateToHospital(LatLng destination) async {
    if (_userLocation == null) return;

    final String googleMapsUrl =
        "https://www.google.com/maps/dir/?api=1&origin=${_userLocation!.latitude},${_userLocation!.longitude}&destination=${destination.latitude},${destination.longitude}&travelmode=driving";

    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch Google Maps")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Map Section
          _userLocation == null
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  options: MapOptions(
                    initialCenter: _userLocation!,
                    initialZoom: _zoom,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    ),
                    MarkerLayer(
                      markers: [
                        // User Location Marker
                        Marker(
                          width: 50,
                          height: 50,
                          point: _userLocation!,
                          child: const Icon(Icons.my_location,
                              color: Colors.blue, size: 40),
                        ),
                        // Hospital Markers
                        ..._nearbyHospitals.asMap().entries.map((entry) {
                          final index = entry.key;
                          final hospital = entry.value;
                          final LatLng hospitalLocation = LatLng(
                            hospital["geometry"]["coordinates"][1],
                            hospital["geometry"]["coordinates"][0],
                          );
                          return Marker(
                            width: 50,
                            height: 50,
                            point: hospitalLocation,
                            child: GestureDetector(
                              onTap: () => _onHospitalPinTap(index),
                              child: Icon(
                                Icons.location_on_rounded,
                                color: _selectedHospitalIndex == index
                                    ? Colors.red
                                    : Colors.green,
                                size: 40,
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ],
                ),

          // Darken the map when modals are shown
          if (_showHospitalInfo || _showHospitalsList)
            GestureDetector(
              onTap: _closeModals,
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),

          // Search Radius Slider
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    "Search Radius (km)",
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  Slider(
                    value: _searchRadius / 1000,
                    min: 5,
                    max: 50,
                    divisions: 9,
                    label: "${(_searchRadius / 1000).toStringAsFixed(1)} km",
                    onChanged: _onSearchRadiusChanged,
                  ),
                ],
              ),
            ),
          ),

          // Nearby Hospitals Button
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _toggleHospitalsList,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                "Nearby Hospitals",
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),

          // Hospital Information Overlay
          if (_showHospitalInfo && _selectedHospitalIndex != -1)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: GestureDetector(
                onTap: () {}, // Prevent closing when tapping inside the modal
                child: AnimatedOpacity(
                  opacity: _showHospitalInfo ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nearbyHospitals[_selectedHospitalIndex]["properties"]
                                  ["name"] ??
                              "Unknown",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _nearbyHospitals[_selectedHospitalIndex]["properties"]
                                  ["address_line1"] ??
                              "No address available",
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Nearby Hospitals List
          if (_showHospitalsList)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: GestureDetector(
                onTap: () {}, // Prevent closing when tapping inside the modal
                child: AnimatedOpacity(
                  opacity: _showHospitalsList ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Nearby Hospitals",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 200, // Adjust height as needed
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _nearbyHospitals.length,
                            itemBuilder: (context, index) {
                              final hospital = _nearbyHospitals[index];
                              final name =
                                  hospital["properties"]["name"] ?? "Unknown";
                              final address = hospital["properties"]
                                      ["address_line1"] ??
                                  "No address available";
                              final LatLng hospitalLocation = LatLng(
                                hospital["geometry"]["coordinates"][1],
                                hospital["geometry"]["coordinates"][0],
                              );

                              return ListTile(
                                title: Text(
                                  name,
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                subtitle: Text(
                                  address,
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.directions,
                                    color:
                                        isDarkMode ? Colors.white : Colors.blue,
                                  ),
                                  onPressed: () =>
                                      _navigateToHospital(hospitalLocation),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
