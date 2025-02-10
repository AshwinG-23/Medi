import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

class SosService {
  static Timer? _timer;

  /// Starts a timer and dials the emergency number if held for 1 second
  static void startLongPress() {
    _timer = Timer(const Duration(seconds: 1), () {
      _callEmergency();
    });
  }

  /// Cancels the timer if the user releases before 1 second
  static void cancelLongPress() {
    _timer?.cancel();
  }

  /// Dials the emergency number
  static Future<void> _callEmergency() async {
    const String emergencyNumber = "112"; // Emergency number
    final Uri phoneUri = Uri(scheme: 'tel', path: emergencyNumber);

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not launch $phoneUri';
    }
  }
}
