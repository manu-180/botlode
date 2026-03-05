import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/serpapi/serpapi_keys_provider.dart';

/// Tarjeta que muestra cuántas API keys de SerpAPI quedan disponibles.
/// Al tocarla abre un modal con el detalle de cada key.
class SerpApiKeysCard extends ConsumerWidget {
  const SerpApiKeysCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keysAsync = ref.watch(serpApiKeysStatusProvider);

    return keysAsync.when(
      loading: () => _buildCardShell(
        context: context,
        child: const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
        subtitle: 'Consultando...',
      ),
      error: (_, __) => _buildCardShell(
        context: context,
        child: const Icon(Icons.error_outline, color: AppColors.error, size: 16),
        subtitle: 'Error',
        onTap: () => ref.invalidate(serpApiKeysStatusProvider),
      ),
      data: (keys) {
        final available = keys.where((k) => k.isAvailable).length;
        final total = keys.length;
        final totalCredits = keys.fold<int>(0, (sum, k) => sum + k.creditsLeft);
        final allExhausted = available == 0;

        return _buildCardShell(
          context: context,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: allExhausted ? AppColors.error : AppColors.success,
                  boxShadow: [
                    BoxShadow(
                      color: (allExhausted ? AppColors.error : AppColors.success)
                          .withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$available/$total',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Oxanium',
                ),
              ),
            ],
          ),
          subtitle: '$totalCredits créditos',
          onTap: () => _showKeysModal(context, ref),
        );
      },
    );
  }

  Widget _buildCardShell({
    required BuildContext context,
    required Widget child,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.08),
                AppColors.primary.withValues(alpha: 0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FaIcon(
                FontAwesomeIcons.key,
                color: AppColors.primary,
                size: 14,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'SERP API',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Oxanium',
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      child,
                      const SizedBox(width: 8),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                          fontSize: 10,
                          fontFamily: 'Oxanium',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showKeysModal(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _SerpApiKeysModal(ref: ref),
    );
  }
}

class _SerpApiKeysModal extends StatelessWidget {
  final WidgetRef ref;
  const _SerpApiKeysModal({required this.ref});

  @override
  Widget build(BuildContext context) {
    final keysAsync = ref.watch(serpApiKeysStatusProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 480,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 40,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildModalHeader(context),
            Flexible(
              child: keysAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
                data: (keys) => _buildKeysList(keys),
              ),
            ),
            _buildModalFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildModalHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: const FaIcon(
              FontAwesomeIcons.key,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'API Keys SerpAPI',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Oxanium',
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Los créditos se renuevan cada mes',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontFamily: 'Oxanium',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => ref.invalidate(serpApiKeysStatusProvider),
            tooltip: 'Actualizar',
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close_rounded,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeysList(List<SerpApiKeyStatus> keys) {
    final available = keys.where((k) => k.isAvailable).toList();
    final exhausted = keys.where((k) => !k.isAvailable).toList();
    final totalCredits = keys.fold<int>(0, (sum, k) => sum + k.creditsLeft);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.surface,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                _buildStatBadge(
                  '${available.length}',
                  'Activas',
                  AppColors.success,
                ),
                const SizedBox(width: 16),
                _buildStatBadge(
                  '${exhausted.length}',
                  'Agotadas',
                  exhausted.isEmpty
                      ? AppColors.textSecondary
                      : AppColors.error,
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$totalCredits',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Oxanium',
                      ),
                    ),
                    Text(
                      'créditos totales',
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontFamily: 'Oxanium',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (available.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSectionLabel('Disponibles', AppColors.success),
            const SizedBox(height: 8),
            ...available.map(_buildKeyTile),
          ],
          if (exhausted.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSectionLabel('Sin créditos', AppColors.error),
            const SizedBox(height: 8),
            ...exhausted.map(_buildKeyTile),
          ],
        ],
      ),
    );
  }

  Widget _buildStatBadge(String value, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Oxanium',
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                fontSize: 10,
                fontFamily: 'Oxanium',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            color: color.withValues(alpha: 0.9),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            fontFamily: 'Oxanium',
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildKeyTile(SerpApiKeyStatus status) {
    final isAvailable = status.isAvailable;
    final color = status.hasError
        ? AppColors.warning
        : isAvailable
            ? AppColors.success
            : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                status.info.name[0].toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Oxanium',
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.info.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Oxanium',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status.hasError
                      ? 'Error: ${status.errorMessage}'
                      : '${status.planName} · Usadas: ${status.usedThisMonth}',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontFamily: 'Oxanium',
                  ),
                ),
              ],
            ),
          ),
          if (!status.hasError)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${status.creditsLeft}',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Oxanium',
                ),
              ),
            ),
          if (status.hasError)
            Icon(Icons.warning_amber_rounded, color: color, size: 20),
        ],
      ),
    );
  }

  Widget _buildModalFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
            size: 14,
          ),
          const SizedBox(width: 8),
          Text(
            'SerpAPI renueva créditos cada mes según tu plan',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.5),
              fontSize: 10,
              fontFamily: 'Oxanium',
            ),
          ),
        ],
      ),
    );
  }
}
