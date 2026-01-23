// Archivo: lib/features/dashboard/presentation/widgets/dashboard_toolbar.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/dashboard/domain/models/bot.dart';
import 'package:botslode/features/dashboard/presentation/providers/bots_provider.dart';
import 'package:botslode/features/dashboard/presentation/providers/dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardToolbar extends ConsumerWidget {
  const DashboardToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(dashboardFilterProvider);
    
    final botsAsync = ref.watch(botsProvider);
    final allBots = botsAsync.value ?? []; 

    final activeCount = allBots.where((b) => b.status == BotStatus.active).length;
    // CORRECCIÓN: Offline ahora incluye Disabled + Maintenance + CreditSuspended
    final offlineCount = allBots.where((b) => 
        b.status == BotStatus.disabled || 
        b.status == BotStatus.maintenance || 
        b.status == BotStatus.creditSuspended // <-- AQUI
    ).length;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGlass),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) => ref.read(dashboardSearchProvider.notifier).setSearch(value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                hintText: "BUSCAR UNIDAD POR ID O NOMBRE...",
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const VerticalDivider(width: 32, color: AppColors.borderGlass, indent: 12, endIndent: 12),

          Row(
            children: [
              _FilterTab(
                label: "TODOS",
                count: allBots.length,
                isSelected: currentFilter == BotFilter.all,
                onTap: () => ref.read(dashboardFilterProvider.notifier).setFilter(BotFilter.all),
              ),
              const SizedBox(width: 8),
              _FilterTab(
                label: "ACTIVOS",
                count: activeCount,
                isSelected: currentFilter == BotFilter.active,
                activeColor: AppColors.success,
                onTap: () => ref.read(dashboardFilterProvider.notifier).setFilter(BotFilter.active),
              ),
              const SizedBox(width: 8),
              _FilterTab(
                label: "OFFLINE",
                count: offlineCount, // Usamos la variable corregida
                isSelected: currentFilter == BotFilter.disabled,
                activeColor: AppColors.textSecondary,
                onTap: () => ref.read(dashboardFilterProvider.notifier).setFilter(BotFilter.disabled),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;

  const _FilterTab({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    this.activeColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor.withValues(alpha: 0.5) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? activeColor : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}