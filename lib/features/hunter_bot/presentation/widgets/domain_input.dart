// Archivo: lib/features/hunter_bot/presentation/widgets/domain_input.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/hunter_bot/presentation/providers/hunter_provider.dart';
import 'package:botslode/features/hunter_bot/presentation/widgets/tips_dialog.dart';

/// Widget para ingresar dominios a scrapear
class DomainInput extends ConsumerStatefulWidget {
  const DomainInput({super.key});

  @override
  ConsumerState<DomainInput> createState() => _DomainInputState();
}

class _DomainInputState extends ConsumerState<DomainInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGlass),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(
                bottom: BorderSide(color: AppColors.success.withOpacity(0.1)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  FontAwesomeIcons.globe,
                  color: AppColors.success.withOpacity(0.8),
                  size: 14,
                ),
                const SizedBox(width: 8),
                const Text(
                  'AGREGAR DOMINIOS',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontFamily: 'Oxanium',
                  ),
                ),
                const Spacer(),
                Text(
                  'Separa con comas o saltos de línea',
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.6),
                    fontSize: 10,
                    fontFamily: 'Oxanium',
                  ),
                ),
                const SizedBox(width: 8),
                // Botón de tips
                Tooltip(
                  message: 'Tips para conseguir URLs',
                  child: InkWell(
                    onTap: () => TipsDialog.show(context),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            FontAwesomeIcons.lightbulb,
                            color: AppColors.secondary.withOpacity(0.8),
                            size: 10,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'TIPS',
                            style: TextStyle(
                              color: AppColors.secondary.withOpacity(0.8),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Oxanium',
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Input area
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLines: 3,
              minLines: 3,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'Oxanium',
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'empresa1.com, startup.io, negocio.es...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.4),
                  fontFamily: 'Oxanium',
                ),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.borderGlass),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.borderGlass),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.success, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
          
          // Submit button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(FontAwesomeIcons.crosshairs, size: 14),
                        SizedBox(width: 8),
                        Text(
                          'CAZAR LEADS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Oxanium',
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Normaliza un texto que puede ser dominio puro o URL (ej. enlaces de Google).
  /// Extrae solo el dominio (ej. estudioesnal.com.ar) para URLs como:
  /// https://www.google.com/url?q=estudioesnal.com.ar o .../search?q=estudioesnal.com.ar
  static String _normalizeDomain(String input) {
    final trimmed = input.trim().toLowerCase();
    if (trimmed.isEmpty) return '';

    // URLs de Google: extraer parámetro q= (dominio real)
    if (trimmed.contains('google.com/url') || trimmed.contains('google.com/search')) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null) {
        final q = uri.queryParameters['q'];
        if (q != null && q.isNotEmpty) {
          return _domainOnly(q);
        }
      }
      // Fallback: regex por si el parseo falla
      final qMatch = RegExp(r'[?&]q=([^&\s]+)').firstMatch(trimmed);
      if (qMatch != null) return _domainOnly(qMatch.group(1)!);
    }

    return _domainOnly(trimmed);
  }

  /// Deja solo el host (sin protocolo, path ni query).
  static String _domainOnly(String s) {
    String out = s.trim().toLowerCase();
    if (out.startsWith('http://')) out = out.substring(7);
    if (out.startsWith('https://')) out = out.substring(8);
    if (out.startsWith('www.')) out = out.substring(4);
    final pathStart = out.indexOf('/');
    if (pathStart != -1) out = out.substring(0, pathStart);
    final queryStart = out.indexOf('?');
    if (queryStart != -1) out = out.substring(0, queryStart);
    return out.trim();
  }

  /// Valida que parezca un dominio (tiene al menos un punto, sin espacios).
  static bool _looksLikeDomain(String s) {
    if (s.isEmpty || s.length > 253) return false;
    if (s.contains(' ')) return false;
    if (!s.contains('.')) return false;
    if (s.startsWith('.') || s.endsWith('.')) return false;
    return true;
  }

  Future<void> _handleSubmit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Parsear y normalizar: aceptar dominios sueltos o URLs (ej. enlaces de Google)
    final raw = text.split(RegExp(r'[,\s\n]+')).map((d) => d.trim()).where((d) => d.isNotEmpty);
    final domains = raw
        .map(_normalizeDomain)
        .where((d) => d.isNotEmpty && _looksLikeDomain(d))
        .toSet()
        .toList();

    if (domains.isEmpty) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      await ref.read(hunterProvider.notifier).addDomains(domains);
      _controller.clear();
      _focusNode.unfocus();
      
      // Mostrar feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              domains.length == 1
                  ? 'Dominio agregado a la cola'
                  : '${domains.length} dominios agregados a la cola',
              style: const TextStyle(fontFamily: 'Oxanium'),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
