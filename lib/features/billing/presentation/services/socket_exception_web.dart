// Archivo: lib/features/billing/presentation/services/socket_exception_web.dart
//
// Implementación web. `dart:io` no existe en web; aproximamos
// `SocketException` chequeando el `toString()` del error (el error real
// suele ser un `ClientException` de `package:http` o un error de browser).

bool isNetworkException(Object error) {
  final repr = error.toString().toLowerCase();
  return repr.contains('socketexception') ||
      repr.contains('clientexception') ||
      repr.contains('failed to fetch') ||
      repr.contains('network request failed') ||
      repr.contains('network error');
}
