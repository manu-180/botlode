// Archivo: lib/features/billing/presentation/widgets/empty_state.dart
//
// T4·29 — Reusable empty-state widget for the billing feature.
// Pure presentation: no providers, no business logic.

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
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
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.space24, vertical: AppDimens.space20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustration != null) ...[
              ExcludeSemantics(child: illustration!),
              const SizedBox(height: AppDimens.space16),
            ],
            Text(
              title,
              style: AppTextStyles.titleM.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.space8),
            Text(
              subtitle,
              style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (ctaLabel != null) ...[
              const SizedBox(height: AppDimens.space24),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onCta,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.gold),
                    foregroundColor: AppColors.gold,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppDimens.brM,
                    ),
                  ),
                  child: Text(
                    ctaLabel!,
                    style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
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
