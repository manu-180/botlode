// Archivo: lib/features/dashboard/presentation/views/dashboard_view.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/ui/widgets/animated_ticker.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/dashboard/presentation/providers/dashboard_controller.dart';
import 'package:botslode/features/dashboard/presentation/widgets/bot_card.dart';
import 'package:botslode/features/dashboard/presentation/widgets/create_bot_modal.dart';
import 'package:botslode/features/dashboard/presentation/widgets/dashboard_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardView extends ConsumerWidget {
  static const String routeName = 'dashboard';

  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final botsAsync = ref.watch(filteredBotsProvider);
    final billingAsync = ref.watch(billingProvider);

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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "BAHÍA DE CARGA",
                          style: theme.textTheme.displayMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          "Gestión operativa de unidades autónomas",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderGlass),
                      ),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                "DEUDA TOTAL FACTURABLE",
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                              AnimatedTicker(
                                value: billingAsync.valueOrNull?.totalDebt ?? 0.0,
                                prefix: "\$ ",
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Oxanium',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 24),
                          ElevatedButton.icon(
                            onPressed: () => showDialog(
                              context: context,
                              builder: (context) => const CreateBotModal(),
                            ),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text("ENSAMBLAR UNIDAD"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const DashboardToolbar(),
                const SizedBox(height: 24),

                // GRID
                Expanded(
                  child: botsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
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