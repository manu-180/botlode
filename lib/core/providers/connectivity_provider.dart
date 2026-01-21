// Archivo: lib/core/providers/connectivity_provider.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Este provider emite TRUE si hay internet, FALSE si se cayó.
final connectivityProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();
  
  // Escuchamos los cambios de estado
  return connectivity.onConnectivityChanged.map((results) {
    // Si la lista contiene 'none', estamos desconectados.
    // connectivity_plus 6.0 devuelve una lista, versiones anteriores un enum simple.
    // Esta lógica cubre ambos casos comunes comprobando si hay alguna conexión válida.
    return !results.contains(ConnectivityResult.none);
  });
});