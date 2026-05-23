// Archivo: lib/core/ui/responsive/mobile_bottom_nav.dart
//
// Bottom navigation bar para mobile. Consume `kAppNavDestinations` para
// mantenerse sincronizado con el Sidebar desktop.

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/responsive/nav_destinations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MobileBottomNav extends StatelessWidget {
  const MobileBottomNav({super.key, required this.currentLocation});

  final String currentLocation;

  @override
  Widget build(BuildContext context) {
    final destinations = kAppNavDestinations
        .where((d) => d.showInBottomNav)
        .toList(growable: false);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.voidBlack,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final dest in destinations)
                Expanded(
                  child: _BottomNavItem(
                    destination: dest,
                    isActive: dest.matches(currentLocation),
                    onTap: () => context.goNamed(dest.routeName),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.destination,
    required this.isActive,
    required this.onTap,
  });

  final NavDestination destination;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.gold : AppColors.textTertiary;
    final labelStyle = AppTextStyles.labelSmall.copyWith(
      fontSize: 9,
      letterSpacing: 1.2,
      color: color,
    );

    return Semantics(
      selected: isActive,
      button: true,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimens.space8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(destination.icon, size: AppDimens.iconM, color: color),
              const SizedBox(height: AppDimens.space4),
              Text(
                destination.label,
                style: labelStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (isActive)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Container(
                    width: 16,
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradGold,
                      borderRadius: AppDimens.brPill,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
