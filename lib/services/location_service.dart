import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class LocationService {
  final String geoapifyApiKey = "729d2fa8846945deb1088c6e1666d625";

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

  Future<List<dynamic>> getNearbyHospitals(
      double latitude, double longitude, double radius) async {
    final String url =
        "https://api.geoapify.com/v2/places?categories=healthcare.hospital&filter=circle:$longitude,$latitude,$radius&limit=20&apiKey=$geoapifyApiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> hospitals = data['features'];

        // Add distance calculation and sort by distance
        hospitals = hospitals.map((hospital) {
          final hospitalLat = hospital['geometry']['coordinates'][1];
          final hospitalLng = hospital['geometry']['coordinates'][0];
          final distance = Geolocator.distanceBetween(
            latitude,
            longitude,
            hospitalLat,
            hospitalLng,
          );
          hospital['properties']['distance'] = distance;
          return hospital;
        }).toList();

        hospitals.sort((a, b) {
          return (a['properties']['distance'] as double)
              .compareTo(b['properties']['distance'] as double);
        });

        return hospitals;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> launchGoogleMapsNavigation(double lat, double lng) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}
