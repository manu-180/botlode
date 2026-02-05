// Archivo: lib/features/hunter_bot/presentation/widgets/help_button.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:botslode/core/config/theme/app_colors.dart';

/// Botón de ayuda que abre WhatsApp
class HelpButton extends StatelessWidget {
  const HelpButton({super.key});

  static const String _whatsappNumber = '1134272488';
  static const String _defaultMessage = 
      'Hola! Necesito ayuda para configurar HunterBot en Botslode.';

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Contactar soporte por WhatsApp',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openWhatsApp(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF25D366).withOpacity(0.3),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(
                  FontAwesomeIcons.whatsapp,
                  color: Color(0xFF25D366),
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'AYUDA',
                  style: TextStyle(
                    color: Color(0xFF25D366),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Oxanium',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final encodedMessage = Uri.encodeComponent(_defaultMessage);
    final whatsappUrl = 'https://wa.me/$_whatsappNumber?text=$encodedMessage';
    
    final uri = Uri.parse(whatsappUrl);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'No se pudo abrir WhatsApp. Contacta al +$_whatsappNumber',
                style: TextStyle(fontFamily: 'Oxanium'),
              ),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Copiar',
                textColor: Colors.white,
                onPressed: () {
                  // Se podría copiar el número aquí
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al abrir WhatsApp: $e',
              style: const TextStyle(fontFamily: 'Oxanium'),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
