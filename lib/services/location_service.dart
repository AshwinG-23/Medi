import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  final String geoapifyApiKey = "729d2fa8846945deb1088c6e1666d625"; // Replace with your API Key

  /// Get the current location of the user
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      return null;
    }
  }

  /// Fetch nearby hospitals based on latitude and longitude
  Future<List<dynamic>> getNearbyHospitals(
      double latitude, double longitude, double radius) async {
    final String url =
        "https://api.geoapify.com/v2/places?categories=healthcare.hospital&filter=circle:$longitude,$latitude,$radius&limit=10&apiKey=$geoapifyApiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> hospitals = data['features'];

        hospitals.sort((a, b) {
          return a['properties']['name'].compareTo(b['properties']['name']);
        });

        return hospitals;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}