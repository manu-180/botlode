// Las keys NO se hardcodean. Pasarlas con:
//   flutter run --dart-define=SERPAPI_KEYS=key1,key2,key3
//   flutter build windows --dart-define=SERPAPI_KEYS=...
// Si SERPAPI_KEYS está vacío, los features que usan SerpAPI deben degradar grácilmente.

class SerpApiKeyInfo {
  final String key;
  final String name;

  const SerpApiKeyInfo({required this.key, required this.name});

  String get masked => '${key.substring(0, 4)}...${key.substring(key.length - 4)}';
}

class SerpApiKeysConfig {
  // Inyectado con --dart-define=SERPAPI_KEYS=key1,key2,key3
  static const String _rawKeys =
      String.fromEnvironment('SERPAPI_KEYS', defaultValue: '');

  static List<String> get keys {
    if (_rawKeys.isEmpty) return const [];
    return _rawKeys
        .split(',')
        .map((k) => k.trim())
        .where((k) => k.isNotEmpty)
        .toList();
  }

  static bool get isConfigured => keys.isNotEmpty;
}

/// Lista de API keys activas. Fuente: --dart-define=SERPAPI_KEYS (CSV).
/// Mantiene el contrato List<SerpApiKeyInfo> que usan los consumidores existentes.
List<SerpApiKeyInfo> get serpApiKeys {
  return SerpApiKeysConfig.keys
      .asMap()
      .entries
      .map((e) => SerpApiKeyInfo(key: e.value, name: 'Key ${e.key + 1}'))
      .toList();
}
