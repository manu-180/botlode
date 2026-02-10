// Archivo: lib/features/dashboard/presentation/widgets/sidebar.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/billing/presentation/views/billing_view.dart';
import 'package:botslode/features/bots_library/presentation/views/bots_library_view.dart';
import 'package:botslode/features/dashboard/presentation/views/dashboard_view.dart';
import 'package:botslode/features/hunter_bot/presentation/views/hunter_view.dart';
import 'package:botslode/features/seeder_bot/presentation/views/seeder_view.dart';
import 'package:botslode/features/settings/presentation/views/settings_view.dart';
import 'package:botslode/features/store/presentation/views/store_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
          // Logo fijo arriba
          SizedBox(
            width: 40,
            height: 40,
            child: Image.asset(
              'assets/icon/botlode_logo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 32),
          // Zona central scrolleable (evita overflow)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SidebarItem(
                    icon: FontAwesomeIcons.robot,
                    label: "BOTS",
                    isActive: location.startsWith('/dashboard') || location == '/',
                    onTap: () => context.goNamed(DashboardView.routeName),
                  ),
                  const SizedBox(height: 24),
                  _SidebarItem(
                    icon: Icons.layers_sharp,
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
                  const SizedBox(height: 24),
                  _SidebarItem(
                    icon: FontAwesomeIcons.store,
                    label: "TIENDA",
                    isActive: location == '/store',
                    onTap: () => context.goNamed(StoreView.routeName),
                  ),
                  const SizedBox(height: 24),
                  _SidebarItem(
                    icon: FontAwesomeIcons.crosshairs,
                    label: "HUNTER",
                    isActive: location == '/hunter',
                    onTap: () => context.goNamed(HunterView.routeName),
                  ),
                  const SizedBox(height: 24),
                  _SidebarItem(
                    icon: FontAwesomeIcons.seedling,
                    label: "SEEDER",
                    isActive: location == '/seeder',
                    onTap: () => context.goNamed(SeederView.routeName),
                  ),
                ],
              ),
            ),
          ),
          // AJUSTES fijo abajo
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
          const SizedBox(height: 6),
          _buildLabel(label, isActive),
        ],
      ),
    );
  }
}

// Widget compartido para los labels con efecto WOW
Widget _buildLabel(String label, bool isActive) {
  if (isActive) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [
          AppColors.primary,
          AppColors.primary.withOpacity(0.7),
          AppColors.primary,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(bounds),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          fontFamily: 'Oxanium',
          shadows: [
            Shadow(
              color: AppColors.primary,
              blurRadius: 8,
            ),
            Shadow(
              color: AppColors.primary,
              blurRadius: 12,
            ),
          ],
        ),
      ),
    ).animate(onPlay: (c) => c.repeat())
      .shimmer(
        duration: 2500.ms,
        color: Colors.white.withOpacity(0.6),
        angle: 0,
      );
  } else {
    return Text(
      label,
      style: TextStyle(
        color: AppColors.textSecondary.withOpacity(0.6),
        fontSize: 9,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        fontFamily: 'Oxanium',
      ),
    );
  }
}
