import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';

class BackgroundFetchService {
  final String geoapifyApiKey = "729d2fa8846945deb1088c6e1666d625";
  final List<double> searchRadii = [5000, 15000, 25000, 35000, 45000, 55000]; // Radii in meters

  Future<LatLng?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    try {
      final position = await Geolocator.getCurrentPosition();
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      return null;
    }
  }

  Future<Map<double, List<dynamic>>> fetchHospitalsForAllRadii(LatLng userLocation) async {
    Map<double, List<dynamic>> hospitalsMap = {};

    for (double radius in searchRadii) {
      final hospitals = await getNearbyHospitals(
        userLocation.latitude,
        userLocation.longitude,
        radius,
      );
      hospitalsMap[radius] = hospitals;
    }

    return hospitalsMap;
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
}