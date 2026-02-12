// Archivo: lib/features/hunter_bot/presentation/widgets/tips_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:botslode/core/config/theme/app_colors.dart';

class _DialogSubmitIntent extends Intent {
  const _DialogSubmitIntent();
}

/// Prompt recomendado para conseguir dominios con la IA
const String _aiPrompt = '''
Necesito un listado de 50 dominios (solo el dominio, sin https://) de empresas o negocios reales que cumplan con estos criterios:

INDUSTRIA/NICHO: [ESCRIBE TU NICHO AQUÍ - ej: agencias de marketing digital, consultoras de RRHH, estudios de arquitectura, etc.]

REQUISITOS TÉCNICOS (MUY IMPORTANTE):
- Sitios web tradicionales con HTML renderizado del lado del servidor (NO aplicaciones SPA/React/Vue/Angular/Flutter)
- Deben tener página de contacto o sección "Sobre Nosotros" con emails visibles
- Preferentemente sitios WordPress, HTML estático, o CMS tradicionales
- Evitar sitios que requieran JavaScript para mostrar contenido

REQUISITOS DEL NEGOCIO:
- Empresas pequeñas/medianas que puedan necesitar mis servicios
- Preferentemente de habla hispana o del país [TU PAÍS]
- Activos y con presencia online reciente

FORMATO DE RESPUESTA:
Devuelve solo los dominios, uno por línea, sin numeración ni explicaciones.
Ejemplo:
agenciamarketing.com
consultorarhh.es
estudioarquitectura.com.ar

IMPORTANTE: Verifica que sean sitios reales y accesibles, no inventes dominios.
''';

/// Diálogo con tips para conseguir URLs válidas
class TipsDialog extends StatefulWidget {
  const TipsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const TipsDialog(),
    );
  }

  @override
  State<TipsDialog> createState() => _TipsDialogState();
}

class _TipsDialogState extends State<TipsDialog> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const { SingleActivator(LogicalKeyboardKey.enter): _DialogSubmitIntent() },
      child: Actions(
        actions: {
          _DialogSubmitIntent: CallbackAction<_DialogSubmitIntent>(onInvoke: (_) {
            Navigator.pop(context);
            return null;
          }),
        },
        child: Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderGlass),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoSection(),
                    const SizedBox(height: 24),
                    _buildUrlTypesSection(),
                    const SizedBox(height: 24),
                    _buildPromptSection(),
                    const SizedBox(height: 24),
                    _buildExamplesSection(),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    ),
      ),
    ).animate()
      .fadeIn(duration: 200.ms)
      .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 200.ms);
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary.withOpacity(0.1),
            AppColors.background.withOpacity(0.5),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
        border: Border(
          bottom: BorderSide(color: AppColors.borderGlass),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
            ),
            child: const FaIcon(
              FontAwesomeIcons.lightbulb,
              color: AppColors.secondary,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CÓMO CONSEGUIR URLS VÁLIDAS',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Oxanium',
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tips para maximizar tu tasa de éxito',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontFamily: 'Oxanium',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¿Por qué algunas URLs no funcionan?',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Oxanium',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hunter Bot extrae emails escaneando el HTML de las páginas. Los sitios modernos hechos con frameworks SPA (React, Vue, Angular, Flutter Web) renderizan el contenido con JavaScript, por lo que el scraper solo ve código JS vacío en lugar del texto real.',
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.9),
                    fontSize: 12,
                    fontFamily: 'Oxanium',
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlTypesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('TIPOS DE SITIOS'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildUrlTypeCard(
              title: 'FUNCIONAN ✓',
              color: AppColors.success,
              items: [
                'WordPress',
                'HTML/CSS estático',
                'PHP tradicional',
                'Joomla, Drupal',
                'Wix, Squarespace',
                'Tiendas Shopify',
              ],
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildUrlTypeCard(
              title: 'NO FUNCIONAN ✗',
              color: AppColors.error,
              items: [
                'React / Next.js',
                'Vue / Nuxt.js',
                'Angular',
                'Flutter Web',
                'SPAs en general',
                'Apps renderizadas con JS',
              ],
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildUrlTypeCard({
    required String title,
    required Color color,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'Oxanium',
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  color == AppColors.success ? Icons.check_circle : Icons.cancel,
                  color: color.withOpacity(0.7),
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  item,
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.9),
                    fontSize: 12,
                    fontFamily: 'Oxanium',
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPromptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('PROMPT PARA GENERAR LISTADOS CON IA'),
        const SizedBox(height: 8),
        Text(
          'Copia este prompt y pégalo en ChatGPT, Claude o tu IA favorita para generar listados de dominios válidos:',
          style: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.8),
            fontSize: 12,
            fontFamily: 'Oxanium',
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderGlass),
          ),
          child: Column(
            children: [
              // Header del código
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                  border: Border(bottom: BorderSide(color: AppColors.borderGlass)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'prompt.txt',
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.5),
                        fontSize: 10,
                        fontFamily: 'Oxanium',
                      ),
                    ),
                  ],
                ),
              ),
              // Contenido del prompt
              Container(
                height: 180,
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _aiPrompt.trim(),
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.9),
                      fontSize: 11,
                      fontFamily: 'monospace',
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              // Botón de copiar
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(9)),
                  border: Border(top: BorderSide(color: AppColors.borderGlass)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _copyPrompt,
                    icon: Icon(
                      _copied ? Icons.check : Icons.copy,
                      size: 16,
                    ),
                    label: Text(
                      _copied ? '¡COPIADO!' : 'COPIAR PROMPT',
                      style: const TextStyle(
                        fontFamily: 'Oxanium',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        fontSize: 12,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _copied ? AppColors.success : AppColors.secondary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExamplesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('EJEMPLOS DE NICHOS RENTABLES'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildNicheChip('Agencias de marketing'),
            _buildNicheChip('Consultoras de RRHH'),
            _buildNicheChip('Estudios de arquitectura'),
            _buildNicheChip('Despachos de abogados'),
            _buildNicheChip('Clínicas dentales'),
            _buildNicheChip('Inmobiliarias'),
            _buildNicheChip('Estudios contables'),
            _buildNicheChip('Agencias de diseño'),
            _buildNicheChip('Empresas de software'),
            _buildNicheChip('Consultoras IT'),
          ],
        ),
      ],
    );
  }

  Widget _buildNicheChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.success.withOpacity(0.9),
          fontSize: 11,
          fontFamily: 'Oxanium',
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.textSecondary.withOpacity(0.6),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        fontFamily: 'Oxanium',
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
        border: Border(top: BorderSide(color: AppColors.borderGlass)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.tips_and_updates,
            color: AppColors.secondary.withOpacity(0.5),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tip: Empieza con 10-20 dominios para probar y luego escala.',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.7),
                fontSize: 11,
                fontFamily: 'Oxanium',
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Entendido',
              style: TextStyle(
                color: AppColors.secondary,
                fontFamily: 'Oxanium',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyPrompt() async {
    await Clipboard.setData(ClipboardData(text: _aiPrompt.trim()));
    setState(() => _copied = true);
    
    // Reset después de 2 segundos
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }
}
