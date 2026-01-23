// Archivo: lib/features/billing/domain/logic/card_validator_logic.dart

enum CardBrand { visa, mastercard, amex, discover, unknown }

class CardValidatorLogic {
  
  /// Algoritmo de Luhn para validación de tarjetas de crédito
  static bool isValidLuhn(String number) {
    if (number.isEmpty) return false;
    
    // Eliminamos espacios por si acaso llegan sucios
    final cleanNumber = number.replaceAll(RegExp(r'\s+\b|\b\s'), '');
    if (int.tryParse(cleanNumber) == null) return false;

    int sum = 0;
    bool alternate = false;
    
    for (int i = cleanNumber.length - 1; i >= 0; i--) {
      int n = int.parse(cleanNumber[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return (sum % 10 == 0);
  }

  /// Detección de marca basada en BIN (Bank Identification Number)
  static CardBrand detectBrand(String number) {
    // Limpieza básica para el análisis
    final clean = number.replaceAll(' ', '');
    if (clean.isEmpty) return CardBrand.unknown;

    if (clean.startsWith('4')) return CardBrand.visa;
    if (RegExp(r'^(5[1-5]|2[2-7])').hasMatch(clean)) return CardBrand.mastercard;
    if (RegExp(r'^3[47]').hasMatch(clean)) return CardBrand.amex;
    if (clean.startsWith('6')) return CardBrand.discover;

    return CardBrand.unknown;
  }

  /// Validación de fecha de expiración (MM/AA)
  static String? validateExpiry(String? value) {
    if (value == null || value.isEmpty) return "Requerido";
    
    final parts = value.split('/');
    if (parts.length != 2) return "Incompleto";
    
    int month = int.tryParse(parts[0]) ?? 0;
    int year = int.tryParse(parts[1]) ?? 0;
    
    if (month < 1 || month > 12) return "Mes inválido";
    
    final now = DateTime.now();
    final currentYear = now.year % 100; // Últimos 2 dígitos (ej: 24)
    final currentMonth = now.month;

    // Validación de año
    if (year < currentYear) return "Vencida";
    
    // Si es el mismo año, validar que el mes no haya pasado
    if (year == currentYear && month < currentMonth) return "Vencida";
    
    // Opcional: Validar que no sea una fecha absurdamente lejana (ej: > 20 años)
    if (year > currentYear + 20) return "Año inválido";

    return null;
  }
}