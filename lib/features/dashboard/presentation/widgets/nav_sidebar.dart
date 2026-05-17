// Archivo: lib/features/dashboard/presentation/widgets/nav_sidebar.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_icons.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavSidebar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const NavSidebar({
    super.key,
    required this.navigationShell,
  });

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIndex = navigationShell.currentIndex;

    return Container(
      width: AppDimens.sidebarWidth, // Barra delgada estilo "Dock"
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface, // Fondo oscuro base
        border: Border(
          right: BorderSide(color: AppColors.borderDefault),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppDimens.space32),
          // Logo pequeño o Icono de la App
          AppIcons.icon(Icons.hexagon, size: AppDimens.iconL, color: AppColors.gold),
          const SizedBox(height: AppDimens.space40),

          // --- Ítems de Navegación ---
          _NavItem(
            icon: AppIcons.dashboard,
            label: 'Hangar',
            isSelected: currentIndex == 0,
            onTap: () => _onTap(context, 0),
          ),
          const SizedBox(height: AppDimens.space20),
          _NavItem(
            icon: AppIcons.bots,
            label: 'Bots',
            isSelected: currentIndex == 1,
            onTap: () => _onTap(context, 1), // Todavía no existe, pero preparamos el botón
          ),
          const SizedBox(height: AppDimens.space20),
          _NavItem(
            icon: AppIcons.billing,
            label: 'Pagos',
            isSelected: currentIndex == 2,
            onTap: () => _onTap(context, 2),
          ),

          const Spacer(), // Empujar configuración al fondo

          _NavItem(
            icon: AppIcons.settings,
            label: 'Ajustes',
            isSelected: currentIndex == 3,
            onTap: () => _onTap(context, 3), // Placeholder
          ),
          const SizedBox(height: AppDimens.space20),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: widget.isSelected,
      label: widget.label,
      child: Focus(
        onFocusChange: (focused) => setState(() => _focused = focused),
        child: AnimatedContainer(
          duration: AppMotion.durFast,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(AppDimens.radiusS),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppDimens.space12),
                padding: const EdgeInsets.symmetric(vertical: AppDimens.space12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimens.radiusS),
                  color: widget.isSelected
                      ? AppColors.gold.withValues(alpha: 0.15)
                      : Colors.transparent,
                  border: widget.isSelected
                      ? Border.all(color: AppColors.gold.withValues(alpha: 0.5))
                      : _focused
                          ? Border.all(color: AppColors.cyan, width: 2)
                          : Border.all(color: Colors.transparent),
                  boxShadow: widget.isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.2),
                            blurRadius: 12,
                            spreadRadius: 1,
                          )
                        ]
                      : [],
                ),
                child: Column(
                  children: [
                    AppIcons.icon(
                      widget.icon,
                      size: AppDimens.iconM,
                      color: widget.isSelected ? AppColors.gold : AppColors.textSecondary,
                    ),
                    const SizedBox(height: AppDimens.space4),
                    Text(
                      widget.label,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: widget.isSelected ? AppColors.gold : AppColors.textSecondary,
                        fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
