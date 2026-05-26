import 'package:flutter/material.dart';

class AppTheme {
  // ── Colors ──
  static const Color primaryColor = Color(0xFF673AB7);
  static const Color primaryDark = Color(0xFF311B92);
  static const Color accentColor = Colors.purpleAccent;

  // ── Gradient ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Theme Data ──
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.deepPurple,
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.grey[50],
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        iconTheme: IconThemeData(color: Colors.black87),
      ),
    );
  }
}
