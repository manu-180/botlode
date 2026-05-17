// lib/features/dashboard/presentation/widgets/sidebar.dart
// Sidebar «Hangar OS»: iconos con estado activo dorado, glow, reactor, HUD.
import 'package:botslode/core/config/restricted_bots_config.dart';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/providers/supabase_provider.dart';
import 'package:botslode/core/ui/hud/hud_reactor_bar.dart';
import 'package:botslode/features/billing/presentation/views/billing_view.dart';
import 'package:botslode/features/bots_library/presentation/views/bots_library_view.dart';
import 'package:botslode/features/dashboard/presentation/views/dashboard_view.dart';
import 'package:botslode/features/hunter_bot/presentation/views/hunter_view.dart';
import 'package:botslode/features/empresas_sin_dominio/presentation/views/empresas_sin_dominio_view.dart';
import 'package:botslode/features/assistify_leads/presentation/views/assistify_leads_view.dart';
import 'package:botslode/features/seeder_bot/presentation/views/seeder_view.dart';
import 'package:botslode/features/settings/presentation/views/settings_view.dart';
import 'package:botslode/features/store/presentation/views/store_view.dart';
import 'package:botslode/features/wpp_inbox/presentation/providers/wpp_inbox_provider.dart';
import 'package:botslode/features/wpp_inbox/presentation/views/wpp_inbox_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String location = GoRouterState.of(context).uri.path;
    final userId = ref.watch(currentUserIdProvider);
    final canSeeRestricted = RestrictedBotsConfig.canUserSeeRestrictedBots(userId);

    return Container(
      width: AppDimens.sidebarWidth,
      decoration: const BoxDecoration(
        color: AppColors.voidBlack,
        border: Border(
          right: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: Column(
        children: [
          // ─── LOGO ───────────────────────────────────────────────────
          const SizedBox(height: AppDimens.space24),
          SizedBox(
            width: 36,
            height: 36,
            child: Image.asset(
              'assets/icon/botlode_logo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: AppDimens.space4),
          // Reactor line bajo el logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
            child: HudReactorBar(active: true, height: 2),
          ),
          const SizedBox(height: AppDimens.space24),

          // ─── ÍTEMS PRINCIPALES ────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SidebarItem(
                    icon: FontAwesomeIcons.robot,
                    label: 'BOTS',
                    isActive: location.startsWith('/dashboard') || location == '/',
                    onTap: () => context.goNamed(DashboardView.routeName),
                  ),
                  _SidebarItem(
                    icon: FontAwesomeIcons.layerGroup,
                    label: 'PLANTILLAS',
                    isActive: location.startsWith('/bots'),
                    onTap: () => context.goNamed(BotsLibraryView.routeName),
                  ),
                  _SidebarItem(
                    icon: FontAwesomeIcons.creditCard,
                    label: 'PAGOS',
                    isActive: location == '/billing',
                    onTap: () => context.goNamed(BillingView.routeName),
                  ),
                  _SidebarItem(
                    icon: FontAwesomeIcons.store,
                    label: 'TIENDA',
                    isActive: location == '/store',
                    onTap: () => context.goNamed(StoreView.routeName),
                  ),

                  if (canSeeRestricted) ...[
                    _SidebarSection(label: 'PROS.'),
                    _SidebarItem(
                      icon: FontAwesomeIcons.crosshairs,
                      label: 'HUNTER',
                      isActive: location == '/hunter',
                      onTap: () => context.goNamed(HunterView.routeName),
                    ),
                    _SidebarItem(
                      icon: FontAwesomeIcons.seedling,
                      label: 'SEEDER',
                      isActive: location == '/seeder',
                      onTap: () => context.goNamed(SeederView.routeName),
                    ),
                    _SidebarSection(label: 'OUT.'),
                    _SidebarItem(
                      icon: FontAwesomeIcons.buildingCircleCheck,
                      label: 'APEX',
                      isActive: location == '/empresas',
                      onTap: () => context.goNamed(EmpresasSinDominioView.routeName),
                    ),
                    _SidebarItem(
                      icon: FontAwesomeIcons.graduationCap,
                      label: 'ASSIST.',
                      isActive: location == '/assistify',
                      onTap: () => context.goNamed(AssistifyLeadsView.routeName),
                    ),
                    _SidebarSection(label: 'MSG'),
                    _SidebarInboxItem(location: location),
                  ],
                ],
              ),
            ),
          ),

          // ─── SETTINGS (fijo abajo) ────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimens.space16),
            child: Divider(color: AppColors.borderSubtle, thickness: 1),
          ),
          _SidebarItem(
            icon: FontAwesomeIcons.gear,
            label: 'AJUSTES',
            isActive: location == '/settings',
            onTap: () => context.goNamed(SettingsView.routeName),
          ),
          const SizedBox(height: AppDimens.space24),
        ],
      ),
    );
  }
}

// ─── ÍTEM DE NAV ─────────────────────────────────────────────────────────────

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int? badge;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;
    final hov = _hovered && !active;

    final iconColor = active
        ? AppColors.textOnGold
        : (hov ? AppColors.textPrimary : AppColors.textSecondary);

    final labelColor = active
        ? AppColors.gold
        : (hov ? AppColors.textSecondary : AppColors.textTertiary);

    return Semantics(
      selected: active,
      button: true,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AppMotion.durFast,
            curve: AppMotion.easeHover,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppDimens.space8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Indicador activo lateral
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedContainer(
                      duration: AppMotion.durFast,
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.gold
                            : (hov
                                ? AppColors.borderSubtle
                                : Colors.transparent),
                        borderRadius: AppDimens.brM,
                        boxShadow: active ? AppDimens.glowGold : null,
                      ),
                      child: Center(
                        child: FaIcon(widget.icon, size: 18, color: iconColor),
                      ),
                    ),
                    // Badge de contador
                    if (widget.badge != null && widget.badge! > 0)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: AppDimens.brPill,
                          ),
                          child: Text(
                            widget.badge! > 99 ? '99+' : '${widget.badge}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimens.space4),
                Text(
                  widget.label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: labelColor,
                    fontSize: 9,
                    letterSpacing: 1.2,
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

// ─── SEPARADOR DE SECCIÓN ─────────────────────────────────────────────────────

class _SidebarSection extends StatelessWidget {
  final String label;
  const _SidebarSection({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space12,
        vertical: AppDimens.space8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.borderSubtle,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.borderGold,
                fontSize: 7,
                letterSpacing: 1.6,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.borderSubtle,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ÍTEM INBOX CON BADGE ─────────────────────────────────────────────────────

class _SidebarInboxItem extends ConsumerWidget {
  const _SidebarInboxItem({required this.location});
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convsAsync = ref.watch(wppConversationsProvider);
    final totalUnread = convsAsync.valueOrNull?.fold<int>(
          0, (sum, c) => sum + c.unreadCount) ??
        0;

    return _SidebarItem(
      icon: FontAwesomeIcons.whatsapp,
      label: 'INBOX',
      isActive: location == '/inbox',
      badge: totalUnread > 0 ? totalUnread : null,
      onTap: () => context.goNamed(WppInboxView.routeName),
    );
  }
}
