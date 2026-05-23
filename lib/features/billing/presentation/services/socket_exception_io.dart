// Archivo: lib/features/billing/presentation/services/socket_exception_io.dart
//
// Implementación nativa (Android/iOS/Windows/macOS/Linux). Re-exporta
// `SocketException` desde `dart:io` para que el código pueda chequear
// `error is SocketException` sin importar `dart:io` directamente.

import 'dart:io' show SocketException;

bool isNetworkException(Object error) => error is SocketException;
