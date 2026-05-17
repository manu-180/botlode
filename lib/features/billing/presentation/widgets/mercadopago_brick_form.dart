// lib/features/billing/presentation/widgets/mercadopago_brick_form.dart
// Stub — real implementation pending T5 MercadoPago Brick integration.

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:flutter/material.dart';

class MercadoPagoBrickForm extends StatelessWidget {
  final void Function(String token) onToken;
  final void Function(String message) onError;
  final int amountCents;
  final String mpPublicKey;
  final String? fallbackCheckoutUrl;

  const MercadoPagoBrickForm({
    super.key,
    required this.onToken,
    required this.onError,
    required this.amountCents,
    required this.mpPublicKey,
    this.fallbackCheckoutUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_balance_wallet_rounded,
              color: AppColors.textSecondary, size: 32),
          SizedBox(height: 12),
          Text(
            'MercadoPago Brick — T5',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
