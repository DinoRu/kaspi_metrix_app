import 'package:flutter/material.dart';

class AppColors {
  // Energy Green Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00AA44), Color(0xFF00D555)],
  );

  // Subtle Background Gradient
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF5F9F6)],
  );

  // Card Gradient (subtle)
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFFAFDFB)],
  );

  // Success Gradient
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF00E676)],
  );

  // Sync Status Gradients
  static LinearGradient getSyncGradient(String status) {
    switch (status) {
      case 'synced':
        return const LinearGradient(
          colors: [Color(0xFF66BB6A), Color(0xFF81C784)],
        );
      case 'pending':
        return const LinearGradient(
          colors: [Color(0xFFFFA726), Color(0xFFFFB74D)],
        );
      case 'syncing':
        return const LinearGradient(
          colors: [Color(0xFF29B6F6), Color(0xFF4FC3F7)],
        );
      case 'failed':
        return const LinearGradient(
          colors: [Color(0xFFEF5350), Color(0xFFE57373)],
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFFBDBDBD), Color(0xFFE0E0E0)],
        );
    }
  }

  // Meter Type Colors
  static Color getMeterTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'electricity':
        return const Color(0xFFFFC107);
      case 'water':
        return const Color(0xFF2196F3);
      case 'gas':
        return const Color(0xFFFF5722);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}
