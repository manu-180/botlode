// Archivo: lib/features/dashboard/presentation/widgets/sidebar.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/billing/presentation/views/billing_view.dart';
import 'package:botslode/features/bots_library/presentation/views/bots_library_view.dart';
import 'package:botslode/features/dashboard/presentation/views/dashboard_view.dart';
import 'package:botslode/features/settings/presentation/views/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;

    return Container(
      width: 80,
      color: const Color(0xFF050505),
      child: Column(
        children: [
          const SizedBox(height: 32),
          
          // LOGO FLOTANTE (REDUCCIÓN TÁCTICA DE TAMAÑO)
          SizedBox(
            width: 40, 
            height: 40,
            child: Image.asset(
              'assets/icon/botlode_logo.png',
              fit: BoxFit.contain,
            ),
          ),
          
          const SizedBox(height: 48),

          // ÍTEMS DE NAVEGACIÓN
          _SidebarItem(
           icon: FontAwesomeIcons.robot,
            label: "BOTS", 
            isActive: location.startsWith('/dashboard') || location == '/', 
            onTap: () => context.goNamed(DashboardView.routeName),
          ),
          const SizedBox(height: 24),
          _SidebarItem(
            icon: Icons.copy_all_rounded, 
            label: "PROTOTIPOS", 
            isActive: location.startsWith('/bots'), 
            onTap: () => context.goNamed(BotsLibraryView.routeName),
          ),
          const SizedBox(height: 24),
          _SidebarItem(
            icon: Icons.credit_card_rounded,
            label: "PAGOS",
            isActive: location == '/billing',
            onTap: () => context.goNamed(BillingView.routeName),
          ),
          
          const Spacer(),
          
          _SidebarItem(
            icon: Icons.settings_rounded,
            label: "AJUSTES",
            isActive: location == '/settings',
            onTap: () => context.goNamed(SettingsView.routeName),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isActive ? [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2)
              ] : [],
            ),
            child: FaIcon(
              icon,
              color: isActive ? Colors.black : AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}