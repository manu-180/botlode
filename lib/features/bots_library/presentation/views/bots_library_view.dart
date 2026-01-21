// Archivo: lib/features/bots_library/presentation/views/bots_library_view.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/bots_library/domain/models/blueprint.dart';
import 'package:botslode/features/bots_library/presentation/widgets/blueprint_card.dart';
import 'package:botslode/features/dashboard/presentation/widgets/create_bot_modal.dart';
import 'package:flutter/material.dart';

class BotsLibraryView extends StatelessWidget {
  static const String routeName = 'bots_library';

  const BotsLibraryView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blueprints = BotBlueprint.catalog;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo Radial Sutil
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, 0.0),
                  radius: 1.0,
                  colors: [
                    AppColors.surface.withOpacity(0.9),
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
                // --- HEADER ---
                Text(
                  "BIBLIOTECA DE PLANOS",
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  "Seleccione un prototipo para iniciar el ensamblaje",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                
                const SizedBox(height: 40),

                // --- GRILLA DE PLANOS ---
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 350,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                    ),
                    itemCount: blueprints.length,
                    itemBuilder: (context, index) {
                      final bp = blueprints[index];
                      return BlueprintCard(
                        blueprint: bp,
                        onTap: () {
                          // --- AQUI ESTA LA MAGIA ---
                          // Pasamos el blueprint 'bp' al modal
                          showDialog(
                            context: context,
                            builder: (context) => CreateBotModal(template: bp),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}