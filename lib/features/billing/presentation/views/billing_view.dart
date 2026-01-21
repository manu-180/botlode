// Archivo: lib/features/billing/presentation/views/billing_view.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/ui/widgets/animated_ticker.dart';
import 'package:botslode/features/billing/domain/models/transaction.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/widgets/digital_card.dart';
import 'package:botslode/features/billing/presentation/widgets/payment_checkout_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BillingView extends ConsumerWidget {
  static const String routeName = 'billing';
  const BillingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final billingAsync = ref.watch(billingProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Fondo Radial Industrial
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.8, -0.8),
                  radius: 1.2,
                  colors: [
                    AppColors.surface.withValues(alpha: 0.8),
                    AppColors.background
                  ],
                ),
              ),
            ),
          ),

          billingAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (err, stack) => Center(
              child: Text("ERROR FINANCIERO: $err", style: const TextStyle(color: AppColors.error)),
            ),
            data: (billing) => Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER ---
                  Text("TERMINAL FINANCIERA", style: theme.textTheme.displayMedium),
                  Text(
                    "Gestión de liquidaciones y métodos de pago", 
                    style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                  ),
                  
                  const SizedBox(height: 40),

                  // --- CONTENIDO ---
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // COLUMNA IZQUIERDA: Balance y Tarjeta
                        Expanded(
                          flex: 4,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildBalanceCard(context, ref, billing.totalDebt),
                                const SizedBox(height: 40),
                                const Text(
                                  "MÉTODO DE PAGO PRINCIPAL", 
                                  style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                ),
                                const SizedBox(height: 16),
                                 ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: 450), 
                                  child: DigitalCard(),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 40),

                        // COLUMNA DERECHA: Historial
                        Expanded(
                          flex: 5,
                          // CORRECCIÓN 1: Usamos 'transactions' en lugar de 'history'
                          child: _buildHistoryPanel(billing.transactions),
                        ),
                      ],
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

  Widget _buildBalanceCard(BuildContext context, WidgetRef ref, double total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderGlass),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.03),
            blurRadius: 30,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "DEUDA ACTUAL ACUMULADA", 
            style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          AnimatedTicker(
            value: total, 
            prefix: '\$ ',
            style: const TextStyle(
              fontFamily: 'Oxanium', 
              fontSize: 64, 
              fontWeight: FontWeight.bold, 
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: total > 0 
                  ? () => showDialog(
                      context: context, 
                      builder: (c) => PaymentCheckoutModal(amount: total),
                    )
                  : null,
              icon: const Icon(Icons.payment_rounded),
              label: const Text("PROCESAR PAGO AHORA"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success, 
                foregroundColor: Colors.black, 
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPanel(List<BotTransaction> history) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3), 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: AppColors.borderGlass),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "REGISTRO DE OPERACIONES", 
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                Icon(Icons.history, color: AppColors.textSecondary),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderGlass),
          Expanded(
            child: history.isEmpty 
              ? const Center(
                  child: Text(
                    "SIN MOVIMIENTOS REGISTRADOS", 
                    style: TextStyle(color: Colors.white24, letterSpacing: 2.0),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _TransactionItem(tx: history[index]),
                ),
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final BotTransaction tx;
  const _TransactionItem({required this.tx});

  @override
  Widget build(BuildContext context) {
    // Lógica visual: Si es liquidación (pago), es "bueno" (verde/negativo). Si es cargo, es normal.
    final bool isPayment = tx.type == TransactionType.liquidation;
    final String sign = isPayment ? '-' : '+';
    final Color amountColor = isPayment ? AppColors.success : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tx.color.withValues(alpha: 0.1), 
              shape: BoxShape.circle,
            ),
            child: Icon(tx.icon, color: tx.color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // CORRECCIÓN 2: Usamos 'description' en lugar de 'botName'
                  tx.description, 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  // Usamos ID corto y fecha
                  "#${tx.id.substring(0, 8)} • ${tx.date.toLocal().toString().split('.')[0]}", 
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontFamily: 'Courier'),
                ),
              ],
            ),
          ),
          Text(
            "$sign\$${tx.amount.toStringAsFixed(2)}",
            style: TextStyle(
              color: amountColor, 
              fontWeight: FontWeight.bold, 
              fontFamily: 'Oxanium', 
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}