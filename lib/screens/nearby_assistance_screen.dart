import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../utils/location_data.dart';
import 'dart:async';
import 'package:decorated_icon/decorated_icon.dart';
import 'package:url_launcher/url_launcher.dart';

class NearbyAssistanceScreen extends StatefulWidget {
  const NearbyAssistanceScreen({super.key});

  @override
  State<NearbyAssistanceScreen> createState() => _NearbyAssistanceScreenState();
}

class _NearbyAssistanceScreenState extends State<NearbyAssistanceScreen> {
  final AppData _appData = AppData(); // Use the singleton instance
  bool _isLoading = false;
  int _selectedHospitalIndex = -1;
  bool _showHospitalInfo = false;
  bool _showHospitalsList = false;
  final MapController _mapController = MapController();

  static const _colors = _NearbyAssistanceColors();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (!_appData.isDataFetched) {
      setState(() => _isLoading = true);
      try {
        _adjustMapZoom();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing data: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _adjustMapZoom() {
    if (_appData.userLocation != null && _appData.nearbyHospitals.isNotEmpty) {
      // Create a list of points including user location and all visible hospitals
      List<LatLng> points = [_appData.userLocation!];

      // Add all hospital locations
      for (var hospital in _appData.nearbyHospitals) {
        final coordinates = hospital["geometry"]["coordinates"] as List;
        points.add(LatLng(coordinates[1], coordinates[0]));
      }

      // Calculate bounds that include all points
      final bounds = LatLngBounds.fromPoints(points);

      // Fit the map to these bounds
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50),
        ),
      );

      // After fitting bounds, center back on user
      _mapController.move(_appData.userLocation!, _mapController.camera.zoom);
    }
  }

  void _onSearchRadiusChanged(double value) {
    if (mounted) {
      setState(() {
        _appData.searchRadius = value * 1000; // Update search radius in AppData
        _adjustMapZoom(); // Adjust map zoom for the new radius
      });
    }
  }

  void _onHospitalPinTap(int index) {
    if (mounted) {
      setState(() {
        _selectedHospitalIndex = index;
        _showHospitalInfo = true;
        _showHospitalsList = false;
      });
    }
  }

  void _closeModals() {
    if (mounted) {
      setState(() {
        _showHospitalInfo = false;
        _showHospitalsList = false;
        _selectedHospitalIndex = -1;
      });
    }
  }

  void _toggleHospitalsList() {
    if (mounted) {
      setState(() {
        _showHospitalsList = !_showHospitalsList;
        if (_showHospitalsList) {
          _showHospitalInfo = false;
        }
      });
    }
  }

  Future<void> _navigateToHospital(double lat, double lng) async {
    final Uri googleMapsUrl = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng");

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch Google Maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _colors.background,
        cardColor: _colors.card,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            _buildMap(),
            _buildGradientOverlayMain(),
            if (_showRecenterButton) _buildRecenterButton(),
            if (_showHospitalInfo || _showHospitalsList)
              _buildGradientOverlay(),
            _buildSearchRadiusSlider(),
            if (_showHospitalInfo && _selectedHospitalIndex != -1)
              _buildHospitalInfo(),
            if (_showHospitalsList) _buildHospitalsList(),
            if (_isLoading) _buildLoadingIndicator(),
            if (!_showHospitalsList && !_showHospitalInfo)
              _buildListToggleButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    if (_appData.userLocation == null) {
      return Center(child: CircularProgressIndicator(color: _colors.primary));
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _appData.userLocation!,
        initialZoom: 14,
        onTap: (_, __) => _closeModals(),
        keepAlive: true,
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.all &
              ~InteractiveFlag.rotate, // Disable rotation for better UX
        ),
        onMapEvent: (event) {
          // If user manually pans away from center, add a button to recenter
          if (event is MapEventMove &&
              _mapController.camera.center != _appData.userLocation) {
            setState(() {
              _showRecenterButton = true;
            });
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
        ),
        MarkerLayer(
          markers: [
            _buildUserLocationMarker(),
            ..._buildHospitalMarkers(),
          ],
        ),
      ],
    );
  }

  Widget _buildRecenterButton() {
    return Positioned(
      right: 20,
      bottom: 100,
      child: FloatingActionButton(
        backgroundColor: _colors.card,
        child: Icon(Icons.center_focus_strong, color: _colors.primary),
        onPressed: () {
          _mapController.move(
              _appData.userLocation!, _mapController.camera.zoom);
          setState(() {
            _showRecenterButton = false;
          });
        },
      ),
    );
  }

  bool _showRecenterButton = false;

  Marker _buildUserLocationMarker() {
    return Marker(
      width: 30,
      height: 30,
      point: _appData.userLocation!,
      child: Icon(Icons.my_location, color: _colors.primary, size: 40),
    );
  }

  List<Marker> _buildHospitalMarkers() {
    return _appData.nearbyHospitals.asMap().entries.map((entry) {
      final index = entry.key;
      final hospital = entry.value;
      final coordinates = hospital["geometry"]["coordinates"] as List;
      final location = LatLng(coordinates[1], coordinates[0]);

      return Marker(
        width: 50,
        height: 50,
        point: location,
        child: GestureDetector(
          onTap: () => _onHospitalPinTap(index),
          child: DecoratedIcon(
            Icons.location_on_outlined,
            color: _selectedHospitalIndex == index
                ? Colors.black
                : const Color.fromARGB(255, 99, 99, 99),
            size: 40.0,
            shadows: [
              BoxShadow(
                blurRadius: 5.0,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildGradientOverlayMain() {
    double screenHeight = MediaQuery.of(context).size.height;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Column(
          children: [
            Container(
              height: 360, // Fading effect container
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.5),
                    const Color.fromARGB(255, 30, 30, 30),
                  ],
                ),
              ),
            ),
            Container(
              height: 40, // Solid bar container
              color: const Color.fromARGB(255, 30, 30, 30),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _closeModals,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color.fromARGB(150, 30, 30, 30),
                const Color.fromARGB(150, 30, 30, 30),
                const Color.fromARGB(150, 30, 30, 30),
                const Color.fromARGB(255, 30, 30, 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchRadiusSlider() {
    return Positioned(
      top: 40,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color.fromARGB(150, 0, 0, 0),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              "Search Radius (km)",
              style: TextStyle(color: _colors.text, fontSize: 16),
            ),
            Slider(
              value: _appData.searchRadius / 1000,
              min: 5,
              max: 55,
              divisions: 5,
              activeColor: Colors.grey,
              label: "${(_appData.searchRadius / 1000).toStringAsFixed(1)} km",
              onChanged:
                  _onSearchRadiusChanged, // Triggered when slider value changes
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalInfo() {
    final hospital = _appData.nearbyHospitals[_selectedHospitalIndex];
    final name = hospital["properties"]["name"] ?? "Unknown";
    final address =
        hospital["properties"]["address_line2"] ?? "No address available";
    final distance = hospital["properties"]["distance"];

    return AnimatedPositioned(
      duration: Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      bottom: _showHospitalInfo ? 20 : -300,
      left: 20,
      right: 20,
      child: FadeTransition(
        opacity: _showHospitalInfo
            ? AlwaysStoppedAnimation(1.0)
            : AlwaysStoppedAnimation(0.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _colors.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        color: _colors.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.directions),
                        color: _colors.primary,
                        onPressed: () {
                          final coordinates =
                              hospital["geometry"]["coordinates"] as List;
                          _navigateToHospital(coordinates[1], coordinates[0]);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        color: _colors.text.withOpacity(0.7),
                        onPressed: _closeModals,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                address,
                style: TextStyle(
                  color: _colors.text.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              if (distance != null) ...[
                const SizedBox(height: 8),
                Text(
                  "Distance: ${(distance / 1000).toStringAsFixed(1)} km",
                  style: TextStyle(
                    color: _colors.primary,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalsList() {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      bottom: _showHospitalsList ? 20 : -300,
      left: 20,
      right: 20,
      child: FadeTransition(
        opacity: _showHospitalsList
            ? AlwaysStoppedAnimation(1.0)
            : AlwaysStoppedAnimation(0.0),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: _colors.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHospitalsListHeader(),
              Expanded(
                child: _buildHospitalsListView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalsListHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Nearby Hospitals",
            style: TextStyle(
              color: _colors.text,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            color: _colors.text.withOpacity(0.7),
            onPressed: _closeModals,
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalsListView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _appData.nearbyHospitals.length,
      itemBuilder: (context, index) {
        final hospital = _appData.nearbyHospitals[index];
        final name = hospital["properties"]["name"] ?? "Unknown";
        final address =
            hospital["properties"]["address_line1"] ?? "No address available";
        final distance = hospital["properties"]["distance"];
        final distanceText = distance != null
            ? "${(distance / 1000).toStringAsFixed(1)} km"
            : "Unknown distance";

        return Card(
          color: _colors.surface,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              name,
              style: TextStyle(
                color: _colors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  address,
                  style: TextStyle(
                    color: _colors.text.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  distanceText,
                  style: TextStyle(
                    color: _colors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.directions),
              color: _colors.primary,
              onPressed: () {
                final coordinates = hospital["geometry"]["coordinates"] as List;
                _navigateToHospital(coordinates[1], coordinates[0]);
              },
            ),
            onTap: () => _onHospitalPinTap(index),
          ),
        );
      },
    );
  }

  Widget _buildListToggleButton() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: ElevatedButton(
        onPressed: _toggleHospitalsList,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_alt, color: _colors.text),
            const SizedBox(width: 8),
            Text(
              "Nearby Hospitals",
              style: TextStyle(
                color: _colors.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: _colors.background.withOpacity(0.7),
      child: Center(
        child: CircularProgressIndicator(
          color: _colors.primary,
        ),
      ),
    );
  }
}

class _NearbyAssistanceColors {
  const _NearbyAssistanceColors();

  final Color background = const Color(0xFF121212);
  final Color surface = const Color(0xFF1E1E1E);
  final Color primary = const Color(0xFF2196F3);
  final Color card = const Color(0xFF2C2C2C);
  final Color text = Colors.white;
}
