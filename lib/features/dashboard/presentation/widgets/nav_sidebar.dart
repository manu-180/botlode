// Archivo: lib/features/dashboard/presentation/widgets/nav_sidebar.dart
import 'package:botslode/core/config/theme/app_colors.dart';
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
      width: 80, // Barra delgada estilo "Dock"
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface, // Fondo oscuro base
        border: Border(
          right: BorderSide(color: AppColors.borderGlass),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 30),
          // Logo pequeño o Icono de la App
          Icon(Icons.hexagon, color: theme.colorScheme.primary, size: 32),
          const SizedBox(height: 40),

          // --- Ítems de Navegación ---
          _NavItem(
            icon: Icons.dashboard_rounded,
            label: 'Hangar',
            isSelected: currentIndex == 0,
            onTap: () => _onTap(context, 0),
          ),
          const SizedBox(height: 20),
          _NavItem(
            icon: Icons.smart_toy_rounded,
            label: 'Bots',
            isSelected: currentIndex == 1,
            onTap: () => _onTap(context, 1), // Todavía no existe, pero preparamos el botón
          ),
          const SizedBox(height: 20),
          _NavItem(
            icon: Icons.credit_card_rounded,
            label: 'Pagos',
            isSelected: currentIndex == 2,
            onTap: () => _onTap(context, 2),
          ),
          
          const Spacer(), // Empujar configuración al fondo
          
          _NavItem(
            icon: Icons.settings_rounded,
            label: 'Ajustes',
            isSelected: currentIndex == 3,
            onTap: () => _onTap(context, 3), // Placeholder
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Animación suave al cambiar de estado
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              // Efecto NEÓN si está seleccionado
              color: isSelected 
                  ? AppColors.primary.withOpacity(0.15) 
                  : Colors.transparent,
              border: isSelected
                  ? Border.all(color: AppColors.primary.withOpacity(0.5))
                  : Border.all(color: Colors.transparent),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 12,
                        spreadRadius: 1,
                      )
                    ]
                  : [],
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 26,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}