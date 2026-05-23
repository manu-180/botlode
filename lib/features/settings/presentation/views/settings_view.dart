// Archivo: lib/features/settings/presentation/views/settings_view.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/providers/auth_provider.dart';
import 'package:botslode/core/ui/app_background.dart';
import 'package:botslode/core/ui/hud/hud_corner_brackets.dart';
import 'package:botslode/core/ui/hud/hud_divider.dart';
import 'package:botslode/core/ui/panels/holo_panel.dart';
import 'package:botslode/core/ui/responsive/breakpoints.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';
import 'package:botslode/features/settings/presentation/widgets/about_botslode_dialog.dart';
import 'package:botslode/features/settings/presentation/widgets/change_password_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsView extends ConsumerStatefulWidget {
  static const String routeName = 'settings';

  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  bool _isLoggingOut = false;

  void _showChangePassword() {
    showDialog(
      context: context,
      builder: (_) => const ChangePasswordDialog(),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (_) => const AboutBotslodeDialog(),
    );
  }

  void _showLogoutConfirm() {
    if (_isLoggingOut) return;
    showDialog(
      context: context,
      builder: (ctx) => _LogoutConfirmDialog(
        onConfirm: () async {
          Navigator.of(ctx).pop();
          setState(() => _isLoggingOut = true);
          final router = GoRouter.of(context);
          try {
            await ref.read(authProvider.notifier).signOut();
            if (!mounted) return;
            router.go('/login');
          } catch (_) {
            if (!mounted) return;
            setState(() => _isLoggingOut = false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final isMobile = Breakpoints.isMobile(context);
    // En mobile bajamos el "neon": sin glow exterior en los paneles, sin
    // shimmer en el header. El acento se mantiene pero más sutil.
    final Color? gold = isMobile ? null : AppColors.gold;
    final Color? cyan = isMobile ? null : AppColors.cyan;
    final Color? danger = isMobile ? null : AppColors.danger;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimens.space32,
                  horizontal: AppDimens.space20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Header ---
                    _SecurityHeader(reduced: reduced || isMobile)
                        .animate(delay: AppMotion.staggerDelay(0))
                        .fadeIn(
                          duration: AppMotion.durBase,
                          curve: AppMotion.easeEntrance,
                        )
                        .moveY(
                          begin: reduced ? 0 : 12,
                          end: 0,
                          duration: AppMotion.durBase,
                          curve: AppMotion.easeEntrance,
                        ),

                    const SizedBox(height: AppDimens.space40),

                    // --- Actualizar contraseña ---
                    HoloPanel(
                      interactive: true,
                      onTap: _showChangePassword,
                      glowAccent: gold,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.space20,
                        vertical: AppDimens.space16,
                      ),
                      child: const _SettingRow(
                        label: 'Actualizar contraseña',
                        description:
                            'Modificar clave de acceso del operador',
                        accent: AppColors.gold,
                        icon: Icons.password_rounded,
                      ),
                    )
                        .animate(delay: AppMotion.staggerDelay(1))
                        .fadeIn(
                          duration: AppMotion.durBase,
                          curve: AppMotion.easeEntrance,
                        )
                        .moveY(
                          begin: reduced ? 0 : 12,
                          end: 0,
                          duration: AppMotion.durBase,
                          curve: AppMotion.easeEntrance,
                        ),

                    const SizedBox(height: AppDimens.space12),

                    // --- Sobre BotLode ---
                    HoloPanel(
                      interactive: true,
                      onTap: _showAbout,
                      glowAccent: cyan,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.space20,
                        vertical: AppDimens.space16,
                      ),
                      child: const _SettingRow(
                        label: 'Sobre BotLode',
                        description:
                            'Versión, motor y licencia del sistema',
                        accent: AppColors.cyan,
                        icon: Icons.info_outline_rounded,
                      ),
                    )
                        .animate(delay: AppMotion.staggerDelay(2))
                        .fadeIn(
                          duration: AppMotion.durBase,
                          curve: AppMotion.easeEntrance,
                        )
                        .moveY(
                          begin: reduced ? 0 : 12,
                          end: 0,
                          duration: AppMotion.durBase,
                          curve: AppMotion.easeEntrance,
                        ),

                    const SizedBox(height: AppDimens.space24),

                    // --- Divider SESIÓN ---
                    const HudDivider(label: 'SESIÓN'),

                    const SizedBox(height: AppDimens.space24),

                    // --- Cerrar sesión ---
                    HoloPanel(
                      interactive: true,
                      onTap: _showLogoutConfirm,
                      glowAccent: danger,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.space20,
                        vertical: AppDimens.space16,
                      ),
                      child: _SettingRow(
                        label: 'Cerrar sesión',
                        description: 'Desconectar del sistema central',
                        accent: AppColors.danger,
                        icon: Icons.power_settings_new_rounded,
                        isLoading: _isLoggingOut,
                      ),
                    )
                        .animate(delay: AppMotion.staggerDelay(3))
                        .fadeIn(
                          duration: AppMotion.durBase,
                          curve: AppMotion.easeEntrance,
                        )
                        .moveY(
                          begin: reduced ? 0 : 12,
                          end: 0,
                          duration: AppMotion.durBase,
                          curve: AppMotion.easeEntrance,
                        ),

                    const SizedBox(height: AppDimens.space32),

                    // --- Footer ---
                    Text(
                      'SECURE CONNECTION // ENCRYPTED',
                      style: AppTextStyles.mono.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      textAlign: TextAlign.center,
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

// ---------------------------------------------------------------------------
// _SecurityHeader
// ---------------------------------------------------------------------------

class _SecurityHeader extends StatelessWidget {
  final bool reduced;

  const _SecurityHeader({required this.reduced});

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = Container(
      width: 76,
      height: 76,
      decoration: const BoxDecoration(
        color: AppColors.surfaceHud,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          Icons.security_rounded,
          size: 48,
          color: AppColors.gold,
        ),
      ),
    );

    if (!reduced) {
      iconWidget = iconWidget
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            duration: AppMotion.durShimmer,
            color: AppColors.gold.withValues(alpha: 0.4),
          );
    }

    return Column(
      children: [
        // HUD ring stack
        SizedBox(
          width: 116,
          height: 116,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.borderGold,
                    width: 1.5,
                  ),
                  boxShadow: AppDimens.glowGold,
                ),
              ),
              // Mid ring — radial gradient gives the gold a soft falloff
              // toward the inner circle, replacing the previous flat fill.
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.gold.withValues(alpha: 0.28),
                      AppColors.gold.withValues(alpha: 0.08),
                    ],
                    stops: const [0.0, 1.0],
                  ),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
              ),
              // Inner circle with icon
              iconWidget,
            ],
          ),
        ),

        const SizedBox(height: AppDimens.space24),

        Text(
          'PROTOCOLO DE SEGURIDAD',
          style: AppTextStyles.displayM.copyWith(
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppDimens.space8),

        Text(
          'Gestión de credenciales y acceso al sistema central.',
          style: AppTextStyles.bodyM.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _SettingRow — pure StatelessWidget, call site wraps in HoloPanel
// ---------------------------------------------------------------------------

class _SettingRow extends StatelessWidget {
  final String label;
  final String description;
  final Color accent;
  final IconData icon;
  final bool isLoading;

  const _SettingRow({
    required this.label,
    required this.description,
    required this.accent,
    required this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icon container
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: AppDimens.brM,
            border: Border.all(
              color: accent.withValues(alpha: 0.28),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(icon, size: AppDimens.iconM, color: accent),
          ),
        ),

        const SizedBox(width: AppDimens.space16),

        // Label + description
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.titleM.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimens.space4),
              Text(
                description,
                style: AppTextStyles.bodyS.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Trailing: loader or animated chevron (the chevron brightens
        // and lifts when the parent HoloPanel receives hover via WidgetState).
        if (isLoading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: accent,
            ),
          )
        else
          _AnimatedRowChevron(accent: accent),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _AnimatedRowChevron
// Listens to the ancestor HoloPanel hover state (propagated via a
// `HoloPanel`'s WidgetStatesController) to brighten and translate slightly
// to the right, giving each setting row a tactile, forward-leaning feel.
// Falls back gracefully when no controller is found.
// ---------------------------------------------------------------------------

class _AnimatedRowChevron extends StatefulWidget {
  final Color accent;

  const _AnimatedRowChevron({required this.accent});

  @override
  State<_AnimatedRowChevron> createState() => _AnimatedRowChevronState();
}

class _AnimatedRowChevronState extends State<_AnimatedRowChevron> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final highlighted = !reduced && _hovered;

    return MouseRegion(
      // Track hover at the row level — works for desktop pointer users.
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedSlide(
        offset: highlighted ? const Offset(0.18, 0) : Offset.zero,
        duration: AppMotion.durFast,
        curve: AppMotion.easeStandard,
        child: AnimatedDefaultTextStyle(
          duration: AppMotion.durFast,
          style: const TextStyle(),
          child: Icon(
            Icons.chevron_right_rounded,
            size: AppDimens.iconS,
            color: widget.accent.withValues(
              alpha: highlighted ? 1.0 : 0.4,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _LogoutConfirmDialog
// ---------------------------------------------------------------------------

class _LogoutConfirmDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const _LogoutConfirmDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: HudCornerBrackets(
          child: HoloPanel(
            padding: const EdgeInsets.all(AppDimens.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '¿CERRAR SESIÓN?',
                  style: AppTextStyles.titleL.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppDimens.space12),
                Text(
                  'El operador será desconectado del sistema.',
                  style: AppTextStyles.bodyM.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimens.space24),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.ghost(
                        label: 'Cancelar',
                        onPressed: () => Navigator.of(context).pop(),
                        expand: true,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space12),
                    Expanded(
                      child: AppButton.danger(
                        label: 'Cerrar sesión',
                        onPressed: onConfirm,
                        expand: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
