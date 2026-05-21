import 'package:flutter/material.dart';

class AppColors {
  static const dark    = Color(0xFF0A1628);
  static const darkAlt = Color(0xFF162540);
  static const amber   = Color(0xFFF5A623);
  static const blue    = Color(0xFF378ADD);
  static const surface = Color(0xFFF8FAFF);
  static const card    = Color(0xFFFFFFFF);
  static const text    = Color(0xFF0A1628);
  static const textMuted = Color(0xFF6B7280);
  static const border  = Color(0xFFE5E7EB);

  // Gradient for hero
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A1628), Color(0xFF0F2040), Color(0xFF0A1E38)],
  );
}
