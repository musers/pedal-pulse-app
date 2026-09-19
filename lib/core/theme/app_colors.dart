import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Accents (Modern electric emerald / energetic mobility teal)
  static const Color primary = Color(0xFF0F766E); // Deep Teal
  static const Color primaryLight = Color(0xFF14B8A6); // Vibrant Teal Accent
  static const Color primaryDark = Color(0xFF115E59);
  static const Color secondary = Color(0xFFF59E0B); // Amber Accent (warm energetic)
  static const Color secondaryLight = Color(0xFFFBBF24);

  // Backgrounds & Surfaces (Light)
  static const Color lightBg = Color(0xFFF8FAFC); // Slate 50
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceCard = Color(0xFFF1F5F9); // Slate 100
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Backgrounds & Surfaces (Dark)
  static const Color darkBg = Color(0xFF0B0F19); // Midnight Deep Slate
  static const Color darkSurface = Color(0xFF111827); // Dark Slate 900
  static const Color darkSurfaceCard = Color(0xFF1F2937); // Dark Slate 800
  static const Color darkBorder = Color(0xFF374151);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Status & Feedback
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Electric Battery / Fuel Status
  static const Color batteryFull = Color(0xFF10B981);
  static const Color batteryMedium = Color(0xFFF59E0B);
  static const Color batteryLow = Color(0xFFEF4444);

  // Gradients for Modern Web Aesthetics
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF042F2E), Color(0xFF0F766E), Color(0xFF115E59)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardOverlayGradient = LinearGradient(
    colors: [Colors.transparent, Color(0xCC000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
