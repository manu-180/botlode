// Archivo: lib/core/config/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // --- BASES (Fondos oscuros profundos) ---
  static const Color background = Color(0xFF050A10); 
  static const Color surface = Color(0xFF0F1621); 
  static const Color glassSurface = Color.fromRGBO(20, 30, 45, 0.7);

  // --- ACENTOS (REBRANDING: INDUSTRIAL GOLD) ---
  static const Color primary = Color(0xFFFFC000); // Oro Industrial
  static const Color secondary = Color(0xFF00F0FF); // Cian Secundario
  
  // Estados
  static const Color error = Color(0xFFFF003C);   // Rojo (Disabled/Error)
  static const Color success = Color(0xFF00FF94); // Verde (Active)
  
  // --- AQUÍ ESTABA EL FALTANTE ---
  // Color Naranja Industrial para "Mantenimiento" o Advertencias
  static const Color warning = Color(0xFFFF9900); 

  // --- TEXTOS & BORDES ---
  static const Color textPrimary = Color(0xFFE0E6ED);
  static const Color textSecondary = Color(0xFF94A3B8);
  
  static const Color borderGlass = Color.fromRGBO(255, 255, 255, 0.1);
  static const Color borderHighlight = Color.fromRGBO(255, 192, 0, 0.3);

  // Gradiente "Lingote Cyberpunk"
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFC000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}