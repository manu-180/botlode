// Archivo: lib/features/dashboard/presentation/views/dashboard_view.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/ui/widgets/animated_ticker.dart';
import 'package:botslode/core/ui/widgets/page_title.dart';
import 'package:botslode/core/ui/widgets/skeleton_base.dart'; // IMPORTAR SKELETON
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/widgets/payment_checkout_modal.dart';
import 'package:botslode/features/dashboard/presentation/providers/dashboard_controller.dart';
import 'package:botslode/features/dashboard/presentation/widgets/bot_card.dart';
import 'package:botslode/features/dashboard/presentation/widgets/create_bot_modal.dart';
import 'package:botslode/features/dashboard/presentation/widgets/dashboard_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class DashboardView extends ConsumerWidget {
  static const String routeName = 'dashboard';

  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final botsAsync = ref.watch(filteredBotsProvider);
    final billingAsync = ref.watch(billingProvider);

    final billingState = billingAsync.valueOrNull;
    final totalDebt = billingState?.totalDebt ?? 0.0;
    final limit = billingState?.creditLimit ?? 0.0;
    final dollarRate = billingState?.dollarRate ?? 1200.0;
    
    final statusColor = billingState?.statusColor ?? AppColors.primary;
    final usagePercent = billingState?.usagePercentage ?? 0.0;
    
    final isCritical = billingState?.health == FinanceHealth.critical;
    final hasCard = billingState?.primaryCard != null;

    return Scaffold(
      body: Stack(
        children: [
          // FONDO
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.8, -0.8), 
                  radius: 1.5,
                  colors: [
                    AppColors.surface.withValues(alpha: 0.8),
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER HUD
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const PageTitle(
                      title: "BAHÍA DE CARGA",
                      subtitle: "Gestión operativa de unidades autónomas",
                      style: PageTitleStyle.techBar, // Barra lateral amarilla
                    ),
                    
                    // --- PANEL DE CRÉDITO SCI-FI ---
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5), 
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: statusColor.withValues(alpha: 0.5)), 
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.1), 
                            blurRadius: 20, 
                            spreadRadius: 2
                          )
                        ]
                      ),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                isCritical 
                                    ? "!!! CRÉDITO AGOTADO !!!" 
                                    : "USO DE CRÉDITO",
                                style: TextStyle(
                                  color: statusColor, 
                                  fontSize: 10, 
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  AnimatedTicker(
                                    value: totalDebt,
                                    prefix: "\$ ",
                                    style: TextStyle(
                                      color: statusColor, 
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Oxanium',
                                    ),
                                  ),
                                  Text(
                                    " / \$${limit.toInt()}",
                                    style: TextStyle(
                                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                                      fontSize: 14,
                                      fontFamily: 'Oxanium',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: 150,
                                height: 4,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: usagePercent,
                                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                                    color: statusColor,
                                  ),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(width: 24),
                          
                          // BOTÓN MUTANTE INTELIGENTE
                          _SmartActionButton(
                            isCritical: isCritical,
                            hasCard: hasCard,
                            debtAmount: totalDebt,
                            onAssemble: () => showDialog(
                              context: context,
                              builder: (context) => const CreateBotModal(),
                            ),
                            onPayCard: () => _confirmPayment(context, ref, totalDebt),
                            onPayLink: () => showDialog(
                              context: context,
                              builder: (context) => PaymentCheckoutModal(
                                amount: totalDebt,
                                exchangeRate: dollarRate, 
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const DashboardToolbar(),
                const SizedBox(height: 24),

                // GRID CON SKELETON
                Expanded(
                  child: botsAsync.when(
                    // CAMBIO: Usamos el Skeleton propio del Dashboard
                    loading: () => const _DashboardSkeleton(),
                    error: (err, stack) => Center(
                      child: Text(
                        "ERROR DE ENLACE: $err",
                        style: const TextStyle(color: AppColors.error, fontFamily: 'Courier'),
                      ),
                    ),
                    data: (bots) => bots.isEmpty 
                      ? _buildEmptyState()
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 400, 
                            childAspectRatio: 1.4,   
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                          ),
                          itemCount: bots.length,
                          itemBuilder: (context, index) {
                            final bot = bots[index];
                            return BotCard(
                              bot: bot,
                              onTap: () => context.goNamed(
                                'bot_detail', 
                                pathParameters: {'botId': bot.id},
                              ),
                            );
                          },
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmPayment(BuildContext context, WidgetRef ref, double amount) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF09090B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.success)),
        title: const Text("CONFIRMAR PAGO RÁPIDO", style: TextStyle(color: Colors.white, fontFamily: 'Oxanium', fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Se debitará el total adeudado de su tarjeta principal para restablecer el servicio.", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            Text(
              "\$ ${amount.toStringAsFixed(2)} USD",
              style: const TextStyle(color: AppColors.success, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Oxanium'),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("CANCELAR", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(c);
              ref.read(billingProvider.notifier).processPayment(amount);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.black),
            child: const Text("PAGAR AHORA", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            "NO SE ENCONTRARON UNIDADES",
            style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5), letterSpacing: 2.0),
          ),
        ],
      ),
    );
  }
}

class _SmartActionButton extends StatelessWidget {
  final bool isCritical;
  final bool hasCard;
  final double debtAmount;
  final VoidCallback onAssemble;
  final VoidCallback onPayCard;
  final VoidCallback onPayLink;

  const _SmartActionButton({
    required this.isCritical,
    required this.hasCard,
    required this.debtAmount,
    required this.onAssemble,
    required this.onPayCard,
    required this.onPayLink,
  });

  @override
  Widget build(BuildContext context) {
    if (!isCritical) {
      return ElevatedButton.icon(
        onPressed: onAssemble,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text("ENSAMBLAR UNIDAD"),
      );
    }

    if (hasCard) {
      return ElevatedButton.icon(
        onPressed: onPayCard,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error, 
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 10,
          shadowColor: AppColors.error.withValues(alpha: 0.5),
        ),
        icon: const Icon(Icons.flash_on_rounded),
        label: Text("PAGAR \$${debtAmount.toInt()} AHORA"),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPayLink,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF009EE3), 
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      icon: const FaIcon(FontAwesomeIcons.handshake, size: 18), 
      label: const Text("PAGAR ONLINE"),
    );
  }
}

// --- SKELETON ESPECÍFICO DE DASHBOARD ---
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    // Simula la Grilla de Bots
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(), // Estático mientras carga
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400, 
        childAspectRatio: 1.4,   
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: 6, // Mostramos 6 tarjetas falsas
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          padding: const EdgeInsets.all(20),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Cabeza del Bot (Círculo)
                  SkeletonBase(width: 54, height: 54, shape: BoxShape.circle),
                  // Badge de Estado
                  SkeletonBase(width: 80, height: 24, borderRadius: 20),
                ],
              ),
              Spacer(),
              // Nombre
              SkeletonBase(width: 150, height: 24, borderRadius: 4),
              SizedBox(height: 8),
              // Descripción (2 líneas)
              SkeletonBase(width: double.infinity, height: 12, borderRadius: 4),
              SizedBox(height: 4),
              SkeletonBase(width: 200, height: 12, borderRadius: 4),
              SizedBox(height: 12),
              // ID
              SkeletonBase(width: 100, height: 10, borderRadius: 4),
            ],
          ),
        );
      },
    );
  }
}