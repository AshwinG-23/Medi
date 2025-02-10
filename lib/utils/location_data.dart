import 'package:latlong2/latlong.dart';

class AppData {
  static final AppData _instance = AppData._internal();
  factory AppData() => _instance;
  AppData._internal();
  bool isDataFetched = false;

  LatLng? userLocation;
  Map<double, List<dynamic>> hospitalsMap = {}; // Stores hospitals for all radii
  double searchRadius = 5000; // Default search radius (5 km)

  List<dynamic> get nearbyHospitals => hospitalsMap[searchRadius] ?? [];

  void updateData(LatLng location, Map<double, List<dynamic>> hospitals) {
    userLocation = location;
    hospitalsMap = hospitals;
    isDataFetched = true;
  }
}