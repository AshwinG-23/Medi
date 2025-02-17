import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.white,
  colorScheme: const ColorScheme.light(
    primary: Colors.green,
    secondary: Colors.lightGreen,
    surface: Colors.white,
  ),
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    color: Colors.white,
    iconTheme: IconThemeData(color: Colors.black),
  ),
  cardColor: Colors.grey[200],
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black),
    bodyMedium: TextStyle(color: Colors.black87),
  ),
  iconTheme: const IconThemeData(
    color: Colors.black,
  ),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.black,
  colorScheme: const ColorScheme.dark(
    primary: Colors.deepOrange,
    secondary: Colors.deepOrange,
    surface: Color(0xFF212121),
  ),
  scaffoldBackgroundColor: const Color(0xFF212121),
  appBarTheme: const AppBarTheme(
    color: Color(0xFF212121),
    iconTheme: IconThemeData(color: Colors.white),
  ),
  cardColor: Colors.grey[800],
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white70),
  ),
  iconTheme: const IconThemeData(
    color: Colors.white,
  ),
);
