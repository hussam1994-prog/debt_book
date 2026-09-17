import 'package:flutter/material.dart';

class AppColors {
  // ─── الألوان الأساسية ───
  static const primary = Color(0xFF1E3A5F);
  static const primaryLight = Color(0xFF4A6B94);
  static const primaryDark = Color(0xFF0F1F35);
  static const secondary = Color(0xFFD4A574);
  static const accent = Color(0xFF00838F);

  // ─── حالات ───
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFEF6C00);
  static const error = Color(0xFFC62828);
  static const info = Color(0xFF1976D2);

  // ─── حياد (وضع فاتح) ───
  static const surface = Color(0xFFF8F9FB);
  static const card = Colors.white;
  static const border = Color(0xFFE0E0E0);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B6B6B);
  static const textHint = Color(0xFF9E9E9E);

  // ─── الوضع الداكن ───
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkCard = Color(0xFF2A2A2A);
  static const darkBorder = Color(0xFF3A3A3A);
  static const darkTextPrimary = Color(0xFFE0E0E0);
  static const darkTextSecondary = Color(0xFF9E9E9E);

  // ─── ألوان ديناميكية للأفاتار (حسب الاسم) ───
  static const avatarColors = [
    Color(0xFF1E3A5F),
    Color(0xFF2E7D32),
    Color(0xFFC62828),
    Color(0xFF6A1B9A),
    Color(0xFFEF6C00),
    Color(0xFF00838F),
    Color(0xFF4E342E),
  ];

  static Color forName(String name) {
    return avatarColors[name.hashCode.abs() % avatarColors.length];
  }

  // ─── ✅ ألوان Tags للأشخاص (8 ألوان) ───
  static const tagColors = [
    Color(0xFFEF5350), // أحمر
    Color(0xFFFFA726), // برتقالي
    Color(0xFFFFCA28), // أصفر
    Color(0xFF66BB6A), // أخضر
    Color(0xFF26C6DA), // سماوي
    Color(0xFF42A5F5), // أزرق
    Color(0xFF7E57C2), // بنفسجي
    Color(0xFFEC407A), // وردي
  ];
}