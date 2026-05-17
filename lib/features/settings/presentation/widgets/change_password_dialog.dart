// Archivo: lib/features/settings/presentation/widgets/change_password_dialog.dart
import 'dart:async';
import 'dart:ui';

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/providers/auth_provider.dart';
import 'package:botslode/core/ui/hud/hud_chamfer.dart';
import 'package:botslode/core/ui/hud/hud_corner_brackets.dart';
import 'package:botslode/core/ui/hud/hud_divider.dart';
import 'package:botslode/core/ui/inputs/app_text_field.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';
import 'package:botslode/core/ui/widgets/app_icon_button.dart';
import 'package:botslode/core/ui/widgets/error_feedback_card.dart';
import 'package:botslode/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Strength helper (file-private) ──────────────────────────────────────────

int _calcPasswordStrength(String password) {
  if (password.isEmpty) return 0;
  int score = 0;
  if (password.length >= 6) score++;
  if (password.length >= 12) score++;
  if (password.contains(RegExp(r'[A-Z]'))) score++;
  if (password.contains(RegExp(r'[a-z]'))) score++;
  if (password.contains(RegExp(r'[0-9]'))) score++;
  if (password.contains(RegExp(r'[^a-zA-Z0-9]'))) score++;
  if (score <= 0) return 0;
  if (score <= 2) return 1;
  if (score == 3) return 2;
  if (score <= 4) return 3;
  return 4;
}

// ─── Intent ───────────────────────────────────────────────────────────────────

class _DialogSubmitIntent extends Intent {
  const _DialogSubmitIntent();
}

// ─── Widget ───────────────────────────────────────────────────────────────────

class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  ConsumerState<ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog>
    with SingleTickerProviderStateMixin {
  // Controllers
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  // Focus nodes
  final _currentFocus = FocusNode();
  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();

  // Entry animation
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryAnim;

  // Auto-close timer
  Timer? _closeTimer;

  // UI state
  bool _isLoading = false;
  bool _success = false;
  String? _errorMessage;
  String? _currentPassError;
  String? _newPassError;
  String? _confirmPassError;
  bool _hasChanges = false;
  String _newPassValue = '';

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(vsync: this, duration: AppMotion.durSlow);
    _entryAnim =
        CurvedAnimation(parent: _entryCtrl, curve: AppMotion.easeEntrance);

    _currentPassCtrl.addListener(_onAnyTextChanged);
    _newPassCtrl.addListener(_onNewPassTextChanged);
    _confirmPassCtrl.addListener(_onAnyTextChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (AppMotion.reduced(context)) {
        _entryCtrl.duration = AppMotion.durCrossfadeReduced;
      }
      _entryCtrl.forward();
      _currentFocus.requestFocus();
    });
  }

  void _onAnyTextChanged() {
    final hasText = _currentPassCtrl.text.isNotEmpty ||
        _newPassCtrl.text.isNotEmpty ||
        _confirmPassCtrl.text.isNotEmpty;
    if (hasText != _hasChanges) setState(() => _hasChanges = hasText);
  }

  void _onNewPassTextChanged() {
    final v = _newPassCtrl.text;
    setState(() {
      _newPassValue = v;
      final hasText = _currentPassCtrl.text.isNotEmpty ||
          v.isNotEmpty ||
          _confirmPassCtrl.text.isNotEmpty;
      _hasChanges = hasText;
    });
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    _currentFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── Validation ──────────────────────────────────────────────────────────────

  bool _validateAll() {
    final currentErr = _currentPassCtrl.text.isEmpty
        ? 'La contraseña actual es requerida'
        : null;
    final newErr = _validateNewPass(_newPassCtrl.text);
    final confirmErr = _newPassCtrl.text != _confirmPassCtrl.text
        ? 'Las contraseñas no coinciden'
        : null;

    setState(() {
      _currentPassError = currentErr;
      _newPassError = newErr;
      _confirmPassError = confirmErr;
    });

    if (currentErr != null) {
      _currentFocus.requestFocus();
      return false;
    }
    if (newErr != null) {
      _newFocus.requestFocus();
      return false;
    }
    if (confirmErr != null) {
      _confirmFocus.requestFocus();
      return false;
    }
    return true;
  }

  String? _validateNewPass(String value) {
    if (value.length < 6) return 'Mínimo 6 caracteres';
    if (_calcPasswordStrength(value) == 1) return 'Contraseña demasiado débil';
    return null;
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  void _handleClose() {
    if (_hasChanges && !_success && !_isLoading) {
      showDialog<bool>(
        context: context,
        barrierColor: AppColors.scrim,
        builder: (ctx) => Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppDimens.brL,
            side: const BorderSide(color: AppColors.borderDefault),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DESCARTAR CAMBIOS', style: AppTextStyles.titleM),
                const SizedBox(height: AppDimens.space8),
                Text(
                  '¿Salir sin guardar los cambios realizados?',
                  style: AppTextStyles.bodyS
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppDimens.space24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton.ghost(
                      label: 'CANCELAR',
                      onPressed: () => Navigator.pop(ctx, false),
                      size: AppButtonSize.sm,
                    ),
                    const SizedBox(width: AppDimens.space12),
                    AppButton.danger(
                      label: 'DESCARTAR',
                      onPressed: () => Navigator.pop(ctx, true),
                      size: AppButtonSize.sm,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ).then((discard) {
        if (mounted && discard == true) Navigator.of(context).pop();
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    if (!_validateAll()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Verify current password via re-authentication
      final email =
          ref.read(authStateProvider).session?.user.email ?? '';
      if (email.isNotEmpty) {
        await ref.read(authRepositoryProvider).signIn(
              email: email,
              password: _currentPassCtrl.text,
            );
      }

      // Update password
      await ref
          .read(authStateProvider.notifier)
          .updatePassword(_newPassCtrl.text);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _success = true;
        });
        _closeTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    } catch (e) {
      if (mounted) {
        final raw = e.toString().toLowerCase();
        setState(() {
          _isLoading = false;
          if (raw.contains('invalid login credentials') ||
              raw.contains('invalid_credentials') ||
              raw.contains('email not confirmed')) {
            _currentPassError = 'Contraseña actual incorrecta';
            _currentFocus.requestFocus();
          } else {
            _errorMessage = e
                .toString()
                .replaceAll('Exception:', '')
                .replaceAll('AuthException:', '')
                .trim();
          }
        });
      }
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);

    return PopScope(
      canPop: !_hasChanges || _success,
      onPopInvokedWithResult: (bool didPop, _) {
        if (!didPop) _handleClose();
      },
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): _DialogSubmitIntent(),
        },
        child: Actions(
          actions: {
            _DialogSubmitIntent: CallbackAction<_DialogSubmitIntent>(
              onInvoke: (_) async {
                await _submit();
                return null;
              },
            ),
          },
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(AppDimens.space24),
              child: AnimatedBuilder(
                animation: _entryAnim,
                builder: (_, child) {
                  final t = _entryAnim.value;
                  return Opacity(
                    opacity: t,
                    child: reduced
                        ? child!
                        : Transform.scale(
                            scale: 0.96 + 0.04 * t,
                            child: child,
                          ),
                  );
                },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: _buildPanel(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel() {
    return HudCornerBrackets(
      armLength: 18,
      color: AppColors.borderGold,
      child: Container(
        decoration: const ShapeDecoration(
          color: Colors.transparent,
          shape: ChamferBorder(
            chamfer: AppDimens.chamferM,
            side: BorderSide(color: AppColors.borderGold, width: 1),
          ),
          shadows: [...AppDimens.elev3, ...AppDimens.glowGold],
        ),
        child: ClipPath(
          clipper: const ChamferClipper(chamfer: AppDimens.chamferM),
          child: Container(
            color: AppColors.glassSurfaceStrong,
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.space32),
              child: AnimatedSwitcher(
                duration: AppMotion.durBase,
                switchInCurve: AppMotion.easeStandard,
                switchOutCurve: AppMotion.easeStandard,
                child: _success ? _buildSuccessOverlay() : _buildForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Form content ────────────────────────────────────────────────────────────

  Widget _buildForm() {
    return Column(
      key: const ValueKey('form'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: AppDimens.space8),
        Text(
          "Establezca una nueva clave de acceso segura para el operador.",
          style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppDimens.space16),
        const HudDivider(),
        const SizedBox(height: AppDimens.space16),

        // Field 1 — current password
        AppPasswordField(
          controller: _currentPassCtrl,
          label: 'CONTRASEÑA ACTUAL',
          hint: '••••••••',
          focusNode: _currentFocus,
          enabled: !_isLoading,
          textInputAction: TextInputAction.next,
          onChanged: (_) {
            if (_currentPassError != null) {
              setState(() => _currentPassError = null);
            }
          },
          onSubmitted: (_) => _newFocus.requestFocus(),
          errorText: _currentPassError,
        ),
        const SizedBox(height: AppDimens.space20),

        // Field 2 — new password
        AppPasswordField(
          controller: _newPassCtrl,
          label: 'NUEVA CONTRASEÑA',
          hint: '••••••••',
          focusNode: _newFocus,
          enabled: !_isLoading,
          textInputAction: TextInputAction.next,
          onChanged: (v) {
            if (_newPassError != null) {
              setState(() => _newPassError = _validateNewPass(v));
            }
          },
          onSubmitted: (_) => _confirmFocus.requestFocus(),
          errorText: _newPassError,
        ),
        const SizedBox(height: AppDimens.space8),
        _PasswordStrengthMeter(password: _newPassValue),
        const SizedBox(height: AppDimens.space20),

        // Field 3 — confirm password
        AppPasswordField(
          controller: _confirmPassCtrl,
          label: 'CONFIRMAR CONTRASEÑA',
          hint: '••••••••',
          focusNode: _confirmFocus,
          enabled: !_isLoading,
          textInputAction: TextInputAction.done,
          onChanged: (_) {
            if (_confirmPassError != null) {
              final match = _newPassCtrl.text == _confirmPassCtrl.text;
              setState(() => _confirmPassError =
                  match ? null : 'Las contraseñas no coinciden');
            }
          },
          onSubmitted: (_) => _submit(),
          errorText: _confirmPassError,
        ),

        const SizedBox(height: AppDimens.space24),

        if (_errorMessage != null) ...[
          Semantics(
            liveRegion: true,
            child: ErrorFeedbackCard(
              title: 'ERROR AL GUARDAR',
              message: _errorMessage!,
              onRetry: _submit,
              onDismiss: () => setState(() => _errorMessage = null),
            ),
          ),
          const SizedBox(height: AppDimens.space16),
        ],

        const HudDivider(),
        const SizedBox(height: AppDimens.space16),
        _buildFooter(),
      ],
    );
  }

  Widget _buildHeader() {
    final reduced = AppMotion.reduced(context);

    Widget icon = const Icon(
      Icons.lock_outline_rounded,
      size: AppDimens.iconM,
      color: AppColors.gold,
    );
    if (!reduced) {
      icon = icon
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            duration: AppMotion.durShimmer,
            color: Colors.white.withValues(alpha: 0.4),
          );
    }

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.10),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.28),
            ),
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
          ),
          child: icon,
        ),
        const SizedBox(width: AppDimens.space16),
        Expanded(
          child: Text(
            "ACTUALIZAR CREDENCIALES",
            style: AppTextStyles.titleL,
          ),
        ),
        AppIconButton(
          icon: Icons.close_rounded,
          onPressed: _handleClose,
          tooltip: 'Cerrar',
          variant: AppButtonVariant.ghost,
          size: AppButtonSize.sm,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AppButton.ghost(
          label: 'CANCELAR',
          onPressed: _isLoading ? null : _handleClose,
          size: AppButtonSize.md,
        ),
        const SizedBox(width: AppDimens.space12),
        AppButton.primary(
          label: 'GUARDAR',
          onPressed: _isLoading ? null : _submit,
          loading: _isLoading,
          size: AppButtonSize.md,
        ),
      ],
    );
  }

  // ── Success overlay ─────────────────────────────────────────────────────────

  Widget _buildSuccessOverlay() {
    final reduced = AppMotion.reduced(context);

    Widget checkIcon = const Icon(
      Icons.check_rounded,
      size: 28,
      color: AppColors.success,
    );
    if (!reduced) {
      checkIcon = checkIcon
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            duration: AppMotion.durShimmer,
            color: Colors.white.withValues(alpha: 0.4),
          );
    }

    return Column(
      key: const ValueKey('success'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.40),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.successGlow,
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: checkIcon,
        ),
        const SizedBox(height: AppDimens.space20),
        Text(
          "CLAVE ACTUALIZADA",
          style: AppTextStyles.titleL.copyWith(color: AppColors.success),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimens.space8),
        Text(
          "Las credenciales han sido renovadas correctamente en el sistema central.",
          style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimens.space16),
        Text(
          "Cerrando automáticamente...",
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

// ─── Password Strength Meter ─────────────────────────────────────────────────

class _PasswordStrengthMeter extends StatelessWidget {
  final String password;

  const _PasswordStrengthMeter({required this.password});

  Color _levelColor(int segs) {
    switch (segs) {
      case 1:
        return AppColors.danger;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.warning;
      case 4:
        return AppColors.success;
      default:
        return AppColors.borderSubtle;
    }
  }

  String _levelLabel(int segs) {
    switch (segs) {
      case 1:
        return 'DÉBIL';
      case 2:
        return 'MEDIA';
      case 3:
        return 'BUENA';
      case 4:
        return 'FUERTE';
      default:
        return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _calcPasswordStrength(password);
    final levelColor = _levelColor(s);
    final label = _levelLabel(s);

    return Semantics(
      label: 'Fuerza de contraseña: $label',
      excludeSemantics: false,
      child: Row(
        children: [
          for (int i = 0; i < 4; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: AppMotion.durFast,
                curve: AppMotion.easeStandard,
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimens.radiusXS),
                  color: i < s ? levelColor : AppColors.borderSubtle,
                  boxShadow: (i < s && s == 4)
                      ? AppDimens.glowStatus(AppColors.success)
                      : null,
                ),
              ),
            ),
            if (i < 3) const SizedBox(width: AppDimens.space4),
          ],
          const SizedBox(width: AppDimens.space8),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: s == 0 ? AppColors.textTertiary : levelColor,
            ),
          ),
        ],
      ),
    );
  }
}
