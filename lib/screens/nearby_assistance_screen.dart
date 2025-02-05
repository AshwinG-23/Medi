import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';
import '../utils/location_data.dart';
import 'dart:async';

class NearbyAssistanceScreen extends StatefulWidget {
  const NearbyAssistanceScreen({super.key});

  @override
  State<NearbyAssistanceScreen> createState() => _NearbyAssistanceScreenState();
}

class _NearbyAssistanceScreenState extends State<NearbyAssistanceScreen> {
  final AppData _appData = AppData();
  final LocationService _locationService = LocationService();
  bool _isLoading = false;
  int _selectedHospitalIndex = -1;
  bool _showHospitalInfo = false;
  bool _showHospitalsList = false;

  // Move colors to a separate class for better organization
  static const _colors = _NearbyAssistanceColors();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (!_appData.isDataFetched) {
      await _fetchData();
    }
  }

  Future<void> _fetchData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      await _appData.fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching data: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onSearchRadiusChanged(double value) async {
    if (mounted) {
      setState(() => _appData.searchRadius = value * 1000);
    }
    await _fetchData();
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
    try {
      await _locationService.launchGoogleMapsNavigation(lat, lng);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error launching navigation: ${e.toString()}')),
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
            if (_showHospitalInfo || _showHospitalsList)
              _buildGradientOverlay(),
            _buildSearchRadiusSlider(),
            if (_showHospitalInfo && _selectedHospitalIndex != -1)
              _buildHospitalInfo(),
            if (_showHospitalsList) _buildHospitalsList(),
            if (!_showHospitalsList && !_showHospitalInfo)
              _buildListToggleButton(),
            if (_isLoading) _buildLoadingIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    if (_appData.userLocation == null) {
      return Center(child: CircularProgressIndicator(color: _colors.primary));
    }

    return Stack(
      children: [
        // The map with grayscale effect
        FlutterMap(
          options: MapOptions(
            initialCenter: _appData.userLocation!,
            initialZoom: 16,
            onTap: (_, __) => _closeModals(),
            keepAlive: true,
          ),
          children: [
            _buildTileLayer(),
            _buildMarkerLayer(),
          ],
        ),
        // The gradient overlay at the bottom
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height *
                  0.4, // Adjust this to control the fade area height
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent, // Top part: transparent
                    Colors.black.withOpacity(0.9), // Fading into black
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  TileLayer _buildTileLayer() {
    return TileLayer(
      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    );
  }

  MarkerLayer _buildMarkerLayer() {
    return MarkerLayer(
      markers: [
        _buildUserLocationMarker(),
        ..._buildHospitalMarkers(),
      ],
    );
  }

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
          child: Icon(
            Icons.pin_drop_sharp,
            color: _selectedHospitalIndex == index ? Colors.red : Colors.green,
            size: 40,
          ),
        ),
      );
    }).toList();
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
                Colors.black.withOpacity(0.1),
                Colors.black.withOpacity(0.5),
                Colors.black.withOpacity(0.7),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _colors.card,
          borderRadius: BorderRadius.circular(8),
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
              max: 50,
              divisions: 9,
              activeColor: _colors.primary,
              label: "${(_appData.searchRadius / 1000).toStringAsFixed(1)} km",
              onChanged: _onSearchRadiusChanged,
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
        hospital["properties"]["address_line1"] ?? "No address available";
    final distance = hospital["properties"]["distance"];

    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: GestureDetector(
        onTap: () {},
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
                        icon: const Icon(Icons.close),
                        color: _colors.text.withOpacity(0.7),
                        onPressed: _closeModals,
                      ),
                      IconButton(
                        icon: const Icon(Icons.directions),
                        color: _colors.primary,
                        onPressed: () {
                          final coordinates =
                              hospital["geometry"]["coordinates"] as List;
                          _navigateToHospital(coordinates[1], coordinates[0]);
                        },
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
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
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
          backgroundColor: _colors.card,
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
