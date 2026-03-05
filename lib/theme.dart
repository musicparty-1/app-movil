import 'package:flutter/material.dart';

class AppTheme {
  // Paleta neón dark-mode
  static const Color neonPurple = Color(0xFF6B3FFF);
  static const Color neonCyan = Color(0xFF00F2FF);
  static const Color darkBg = Color(0xFF0D0D1A);
  static const Color darkCard = Color(0xFF16162A);
  static const Color darkSurface = Color(0xFF1E1E35);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0CC);
  static const Color success = Color(0xFF48BB78);
  static const Color errorColor = Color(0xFFFC8181);
  static const Color liveGreen = Color(0xFF48BB78);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBg,
        colorScheme: const ColorScheme.dark(
          primary: neonPurple,
          secondary: neonCyan,
          surface: darkCard,
          onSurface: textPrimary,
          error: errorColor,
        ),
        cardTheme: const CardThemeData(
          color: darkCard,
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: darkBg,
          elevation: 0,
          centerTitle: false,
          foregroundColor: textPrimary,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: neonPurple,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: neonPurple, width: 1.5),
          ),
          hintStyle: const TextStyle(color: textSecondary),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w600,
          ),
          bodyMedium: TextStyle(color: textSecondary),
          bodySmall: TextStyle(color: textSecondary),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: darkSurface,
          labelStyle: const TextStyle(color: textSecondary, fontSize: 12),
          side: const BorderSide(color: Colors.white12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: darkCard,
          contentTextStyle: const TextStyle(color: textPrimary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          behavior: SnackBarBehavior.floating,
        ),
      );

  // ─── Temas por tipo de evento ────────────────────────────────────────────────────
  static const Map<String, EventThemeData> _eventThemes = {
    'club':      EventThemeData(accent: Color(0xFF6B3FFF), neon: Color(0xFF00F2FF), emoji: '🎧'),
    'wedding':   EventThemeData(accent: Color(0xFFD53F8C), neon: Color(0xFFFBD38D), emoji: '💍'),
    'private':   EventThemeData(accent: Color(0xFF48BB78), neon: Color(0xFF9AE6B4), emoji: '🔒'),
    'festival':  EventThemeData(accent: Color(0xFFED8936), neon: Color(0xFFF6E05E), emoji: '🎪'),
    'corporate': EventThemeData(accent: Color(0xFF4299E1), neon: Color(0xFF90CDF4), emoji: '🏢'),
  };

  static EventThemeData eventThemeFor(String? type) =>
      _eventThemes[type] ??
      const EventThemeData(
        accent: Color(0xFF6B3FFF),
        neon: Color(0xFF00F2FF),
        emoji: '🎵',
      );
}

// ─── Datos de tema por tipo de evento ──────────────────────────────────────────────────
class EventThemeData {
  final Color accent;
  final Color neon;
  final String emoji;

  const EventThemeData({
    required this.accent,
    required this.neon,
    required this.emoji,
  });
}
