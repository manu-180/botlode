import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:botslode/features/empresas_sin_dominio/data/serpapi_keys_config.dart';

class SerpApiKeyStatus {
  final SerpApiKeyInfo info;
  final int creditsLeft;
  final int usedThisMonth;
  final String planName;
  final bool hasError;
  final String? errorMessage;

  const SerpApiKeyStatus({
    required this.info,
    this.creditsLeft = 0,
    this.usedThisMonth = 0,
    this.planName = '',
    this.hasError = false,
    this.errorMessage,
  });

  bool get isExhausted => creditsLeft <= 0 && !hasError;
  bool get isAvailable => creditsLeft > 0;
}

/// Provider que consulta créditos de todas las API keys en paralelo.
final serpApiKeysStatusProvider =
    FutureProvider.autoDispose<List<SerpApiKeyStatus>>((ref) async {
  final futures = serpApiKeys.map(_fetchKeyStatus);
  return Future.wait(futures);
});

Future<SerpApiKeyStatus> _fetchKeyStatus(SerpApiKeyInfo info) async {
  try {
    final uri = Uri.parse(
      'https://serpapi.com/account.json?api_key=${info.key}',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      return SerpApiKeyStatus(
        info: info,
        hasError: true,
        errorMessage: 'HTTP ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return SerpApiKeyStatus(
      info: info,
      creditsLeft: (data['total_searches_left'] as num?)?.toInt() ?? 0,
      usedThisMonth: (data['this_month_usage'] as num?)?.toInt() ?? 0,
      planName: (data['plan_name'] as String?) ?? 'N/A',
    );
  } catch (e) {
    return SerpApiKeyStatus(
      info: info,
      hasError: true,
      errorMessage: e.toString().length > 80
          ? '${e.toString().substring(0, 80)}...'
          : e.toString(),
    );
  }
}
