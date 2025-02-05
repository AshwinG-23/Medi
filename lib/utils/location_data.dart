import '../services/location_service.dart';
import 'package:latlong2/latlong.dart';

class AppData {
  static final AppData _instance = AppData._internal();
  factory AppData() => _instance;
  AppData._internal();

  LatLng? userLocation;
  List<dynamic> nearbyHospitals = [];
  bool isDataFetched = false;
  double searchRadius = 5000; // Default search radius

  Future<void> fetchData({double? radius}) async {
    final locationService = LocationService();
    var position = await locationService.getCurrentLocation();
    if (position != null) {
      userLocation = LatLng(position.latitude, position.longitude);
      nearbyHospitals = await locationService.getNearbyHospitals(
        userLocation!.latitude,
        userLocation!.longitude,
        radius ?? searchRadius, // Use provided radius or default
      );
      isDataFetched = true;
    }
  }
}