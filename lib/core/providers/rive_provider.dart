// Archivo: lib/core/providers/rive_provider.dart
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart';

// --- CACHÉ DE CABEZA (PARA CARDS) ---
final riveHeadFileProvider = FutureProvider<RiveFile>((ref) async {
  try {
    final data = await rootBundle.load('assets/animations/cabezabot.riv');
    return RiveFile.import(data);
  } catch (e) {
    throw Exception("Error cargando núcleo visual (Cabeza): $e");
  }
});

// --- CACHÉ DE CUERPO COMPLETO (PARA DETALLE) ---
final riveFullBotFileProvider = FutureProvider<RiveFile>((ref) async {
  try {
    final data = await rootBundle.load('assets/animations/catbotlode.riv');
    return RiveFile.import(data);
  } catch (e) {
    throw Exception("Error cargando núcleo visual (Cuerpo): $e");
  }
});