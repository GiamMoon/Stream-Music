import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colores base (Inspirados en apps premium como Tidal/Spotify)
  static const Color primary = Color(0xFF1DB954); // Verde vibrante (o elige el que gustes)
  static const Color background = Color(0xFF121212); // Negro suave (mejor para OLED)
  static const Color surface = Color(0xFF282828); // Gris oscuro para tarjetas
  static const Color white = Color(0xFFFFFFFF);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,

      // Configuración de textos global
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: white,
        displayColor: white,
      ),

      // Configuración de botones por defecto
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),

      // Configuración de Inputs (Login)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: white.withOpacity(0.5)),
      ),
    );
  }
}