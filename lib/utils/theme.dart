import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Colors.blue,
      secondary: Colors.green,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.grey[900],
    scaffoldBackgroundColor: Colors.black,
    colorScheme: const ColorScheme.dark(
      primary: Colors.blue,
      secondary: Colors.green,
    ),
  );
}


class ThemeProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;

  ThemeProvider() {
    _loadTheme(); // Load theme when app starts
  }

  bool get isDarkMode {
    if (themeMode == ThemeMode.system) {
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return themeMode == ThemeMode.dark;
  }

  void toggleTheme() {
    themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    Hive.box('settings').put('themeMode', themeMode.index); // Store in Hive
    notifyListeners();
  }

  void _loadTheme() async {
    var box = await Hive.openBox('settings');
    int? storedTheme = box.get('themeMode');
    if (storedTheme != null) {
      themeMode = ThemeMode.values[storedTheme];
      notifyListeners();
    }
  }
}