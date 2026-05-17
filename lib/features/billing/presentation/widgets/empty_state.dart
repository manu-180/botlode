// Archivo: lib/features/billing/presentation/widgets/empty_state.dart
//
// T4·29 — Reusable empty-state widget for the billing feature.
// Pure presentation: no providers, no business logic.

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:flutter/material.dart';

class BillingEmptyState extends StatelessWidget {
  const BillingEmptyState({
    super.key,
    this.illustration,
    required this.title,
    required this.subtitle,
    this.ctaLabel,
    this.onCta,
  });

  final Widget? illustration;
  final String title;
  final String subtitle;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: ctaLabel != null
          ? '$title. $subtitle. Botón: $ctaLabel'
          : '$title. $subtitle',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustration != null) ...[
              ExcludeSemantics(child: illustration!),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (ctaLabel != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onCta,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    ctaLabel!,
                    style: const TextStyle(
                      fontFamily: 'Oxanium',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
