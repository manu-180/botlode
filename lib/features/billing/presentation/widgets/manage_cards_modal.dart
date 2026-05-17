// Archivo: lib/features/billing/presentation/widgets/manage_cards_modal.dart
// T4·53 — ManageCardsModal rediseñado como panel de inventario HoloPanel Hangar OS.
// Presenta scrim + BackdropFilter, lista de mini-HoloPanels, menú HUD contextual,
// estado vacío/loading/error y animaciones de entrada escalonada y eliminación.
// Usar ManageCardsModal.show(context) para abrir.
import 'dart:ui';

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud_corner_brackets.dart';
import 'package:botslode/core/ui/hud/hud_divider.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';
import 'package:botslode/core/ui/widgets/app_icon_button.dart';
import 'package:botslode/core/ui/widgets/empty_state.dart';
import 'package:botslode/core/ui/widgets/error_feedback_card.dart';
import 'package:botslode/core/ui/widgets/hud_popover_menu.dart';
import 'package:botslode/core/ui/widgets/skeleton_base.dart';
import 'package:botslode/features/billing/domain/models/payment_method.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/widgets/add_card_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

const _kActiveStatuses = {
  SubscriptionStatus.active,
  SubscriptionStatus.trialing,
  SubscriptionStatus.pastDue,
};

const double _kMaxWidth = 480;
const double _kScrollFadeHeight = 16.0;

// ─── Entry point ──────────────────────────────────────────────────────────────

class ManageCardsModal extends ConsumerStatefulWidget {
  const ManageCardsModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: AppColors.scrim,
      barrierDismissible: true,
      builder: (ctx) => const ManageCardsModal(),
    );
  }

  @override
  ConsumerState<ManageCardsModal> createState() => _ManageCardsModalState();
}

// ─── State ────────────────────────────────────────────────────────────────────

class _ManageCardsModalState extends ConsumerState<ManageCardsModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _scrimAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  // Tracks items being removed for exit animation.
  final Set<String> _removingIds = {};

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: AppMotion.durSlow);

    _scrimAnim = CurvedAnimation(parent: _entryCtrl, curve: AppMotion.easeEntrance);
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: AppMotion.easeEntrance);
    _scaleAnim = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: AppMotion.easeEntrance),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduced = AppMotion.reduced(context);
      if (reduced) {
        _entryCtrl.duration = AppMotion.durCrossfadeReduced;
      }
      _entryCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    final reduced = AppMotion.reduced(context);
    final exitDur = reduced
        ? AppMotion.durCrossfadeReduced
        : AppMotion.exitOf(AppMotion.durSlow);
    await _entryCtrl.animateBack(0, duration: exitDur, curve: AppMotion.easeExit);
    if (mounted) Navigator.of(context).pop();
  }

  // ─── Actions ─────────────────────────────────────────────────────────────

  Future<void> _setDefault(String id) async {
    try {
      await ref.read(billingV2Provider.notifier).setDefaultPaymentMethod(id);
    } on BillingException catch (e) {
      _showErrorSnack(e.message);
    } catch (_) {
      _showErrorSnack('No se pudo actualizar el método predeterminado.');
    }
  }

  Future<void> _handleDelete(PaymentMethod pm) async {
    final current = ref.read(billingV2Provider).valueOrNull;
    final methods = current?.paymentMethods ?? [];
    final subscription = current?.subscription;
    final hasActiveSub =
        subscription != null && _kActiveStatuses.contains(subscription.status);

    if (methods.length == 1 && hasActiveSub) {
      _showErrorSnack(
        'No podés eliminar tu único método de pago con una suscripción activa. '
        'Primero agregá otra tarjeta.',
        duration: const Duration(seconds: 5),
      );
      return;
    }

    final confirm = await _showDeleteConfirmation(pm);
    if (confirm != true || !mounted) return;

    setState(() => _removingIds.add(pm.id));

    try {
      await ref.read(billingV2Provider.notifier).removePaymentMethod(pm.id);
    } on BillingException catch (e) {
      if (mounted) setState(() => _removingIds.remove(pm.id));
      final msg = e.code == 'only_pm_active'
          ? 'No podés eliminar tu único método de pago con una suscripción activa.'
          : e.message;
      _showErrorSnack(msg);
    } catch (_) {
      if (mounted) setState(() => _removingIds.remove(pm.id));
      _showErrorSnack('No se pudo eliminar la tarjeta.');
    }
  }

  Future<bool?> _showDeleteConfirmation(PaymentMethod pm) {
    if (!mounted) return Future.value(false);
    return showDialog<bool>(
      context: context,
      barrierColor: AppColors.scrim,
      builder: (ctx) => _DeleteConfirmDialog(pm: pm),
    );
  }

  void _showErrorSnack(String message, {Duration? duration}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Semantics(
          liveRegion: true,
          child: Text(message),
        ),
        backgroundColor: AppColors.danger,
        duration: duration ?? const Duration(seconds: 4),
      ),
    );
  }

  void _openAddCard() {
    _close().then((_) {
      if (mounted) AddCardModal.show(context);
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final screen = MediaQuery.sizeOf(context);
    final isDesktop = screen.width >= 600;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: KeyboardListener(
        focusNode: FocusNode(),
        autofocus: false,
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            _close();
          }
        },
        child: AnimatedBuilder(
          animation: _entryCtrl,
          builder: (ctx, child) {
            return Stack(
              children: [
                // Scrim (click to close)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _close,
                    child: FadeTransition(
                      opacity: _scrimAnim,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: const ColoredBox(color: Colors.transparent),
                      ),
                    ),
                  ),
                ),
                // Panel
                Center(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: reduced
                        ? child!
                        : ScaleTransition(scale: _scaleAnim, child: child),
                  ),
                ),
              ],
            );
          },
          child: _buildPanel(context, isDesktop, screen, reduced),
        ),
      ),
    );
  }

  Widget _buildPanel(
      BuildContext context, bool isDesktop, Size screen, bool reduced) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: isDesktop ? _kMaxWidth : screen.width - AppDimens.space32,
        maxHeight: screen.height * 0.7,
      ),
      child: HudCornerBrackets(
        color: AppColors.borderGold,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.radiusXL),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.glassSurfaceStrong,
                borderRadius: BorderRadius.circular(AppDimens.radiusXL),
                border: Border.all(
                  color: AppColors.glassBorder,
                  width: 1,
                ),
                boxShadow: AppDimens.elev3,
              ),
              child: _buildContent(context, reduced),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool reduced) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space24,
        vertical: AppDimens.space24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: AppDimens.space16),
          const HudDivider(),
          const SizedBox(height: AppDimens.space16),
          Flexible(child: _buildBody(context, reduced)),
          const SizedBox(height: AppDimens.space16),
          const HudDivider(),
          const SizedBox(height: AppDimens.space16),
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '// GESTIÓN DE MÉTODOS',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: AppDimens.space4),
              Text(
                'TUS TARJETAS',
                style: AppTextStyles.titleM.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        AppIconButton(
          icon: Icons.close_rounded,
          onPressed: _close,
          tooltip: 'Cerrar',
          variant: AppButtonVariant.ghost,
          size: AppButtonSize.sm,
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, bool reduced) {
    final billingAsync = ref.watch(billingV2Provider);

    return billingAsync.when(
      loading: () => _buildSkeletons(),
      error: (_, __) => ErrorFeedbackCard(
        title: 'Error al cargar tarjetas',
        message: 'No se pudieron cargar los métodos de pago. Intentá de nuevo.',
        onRetry: () async => ref.invalidate(billingV2Provider),
        variant: ErrorVariant.inline,
      ),
      data: (state) {
        final methods = state.paymentMethods;
        if (methods.isEmpty) return _buildEmptyState();
        return _buildList(methods, reduced);
      },
    );
  }

  Widget _buildSkeletons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(height: AppDimens.space12),
          _SkeletonCardRow(),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 200,
      child: EmptyState(
        icon: Icons.credit_card_off_rounded,
        title: 'Sin métodos de pago',
        description: 'Agregá una tarjeta para habilitar el cobro automático.',
        action: AppButton.secondary(
          label: 'AÑADIR TARJETA',
          onPressed: _openAddCard,
          leadingIcon: Icons.add_card,
          size: AppButtonSize.sm,
        ),
      ),
    );
  }

  Widget _buildList(List<PaymentMethod> methods, bool reduced) {
    return _FadedScrollList(
      itemCount: methods.length,
      itemBuilder: (index) {
        final pm = methods[index];
        final isRemoving = _removingIds.contains(pm.id);
        return _CardRow(
          key: ValueKey(pm.id),
          pm: pm,
          index: index,
          isRemoving: isRemoving,
          reduced: reduced,
          onSetDefault: () => _setDefault(pm.id),
          onDelete: () => _handleDelete(pm),
        );
      },
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Semantics(
        label: 'Agregar nueva tarjeta de pago',
        button: true,
        child: AppButton.secondary(
          label: 'AÑADIR TARJETA',
          onPressed: _openAddCard,
          leadingIcon: Icons.add_card,
          size: AppButtonSize.lg,
          expand: true,
        ),
      ),
    );
  }
}

// ─── Faded scroll list ────────────────────────────────────────────────────────

class _FadedScrollList extends StatelessWidget {
  const _FadedScrollList({
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final Widget Function(int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.white,
          Colors.white,
          Colors.transparent,
        ],
        stops: [0.0, 0.06, 0.94, 1.0],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: _kScrollFadeHeight),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: AppDimens.space12),
        itemBuilder: (_, index) => itemBuilder(index),
      ),
    );
  }
}

// ─── Card row item ────────────────────────────────────────────────────────────

class _CardRow extends StatefulWidget {
  const _CardRow({
    super.key,
    required this.pm,
    required this.index,
    required this.isRemoving,
    required this.reduced,
    required this.onSetDefault,
    required this.onDelete,
  });

  final PaymentMethod pm;
  final int index;
  final bool isRemoving;
  final bool reduced;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  @override
  State<_CardRow> createState() => _CardRowState();
}

class _CardRowState extends State<_CardRow>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;

  late final AnimationController _entryCtrl;
  late final Animation<double> _entryAnim;

  late final AnimationController _exitCtrl;
  late final Animation<double> _exitOpacity;
  late final Animation<double> _exitHeight;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: AppMotion.durBase,
    );
    _entryAnim = CurvedAnimation(
      parent: _entryCtrl,
      curve: AppMotion.easeEntrance,
    );

    _exitCtrl = AnimationController(
      vsync: this,
      duration: AppMotion.durBase,
    );
    _exitOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: AppMotion.easeExit),
    );
    _exitHeight = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: AppMotion.easeExit),
    );

    // Staggered entrance
    final delay = widget.reduced
        ? Duration.zero
        : AppMotion.staggerDelay(widget.index);
    Future.delayed(delay, () {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void didUpdateWidget(_CardRow old) {
    super.didUpdateWidget(old);
    if (widget.isRemoving && !old.isRemoving && !widget.reduced) {
      _exitCtrl.forward();
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  Color get _borderColor {
    if (widget.pm.isDefault) return AppColors.borderGold;
    if (_hovered) return AppColors.borderStrong;
    return AppColors.borderDefault;
  }

  double get _borderWidth => widget.pm.isDefault ? 1.5 : 1.0;

  Color get _bgColor => widget.pm.isDefault
      ? AppColors.gold.withValues(alpha: 0.06)
      : AppColors.surfaceHud;

  @override
  Widget build(BuildContext context) {
    Widget row = _buildInnerRow();

    // Exit animation wrapping
    if (!widget.reduced) {
      row = AnimatedBuilder(
        animation: _exitCtrl,
        builder: (_, child) {
          if (_exitCtrl.value == 0) return child!;
          return SizeTransition(
            sizeFactor: _exitHeight,
            axisAlignment: -1,
            child: FadeTransition(
              opacity: _exitOpacity,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset.zero,
                  end: const Offset(0.06, 0),
                ).animate(_exitCtrl),
                child: child,
              ),
            ),
          );
        },
        child: row,
      );
    }

    // Entry animation
    row = AnimatedBuilder(
      animation: _entryCtrl,
      builder: (_, child) {
        final t = _entryAnim.value;
        return Opacity(
          opacity: t,
          child: widget.reduced
              ? child!
              : Transform.translate(
                  offset: Offset(0, (1 - t) * 12),
                  child: child,
                ),
        );
      },
      child: row,
    );

    return row;
  }

  Widget _buildInnerRow() {
    final pm = widget.pm;
    final last4 = pm.last4 ?? '—';
    final brand = (pm.brand ?? '').isNotEmpty ? pm.brand! : 'desconocida';

    return Semantics(
      label: 'Tarjeta terminada en $last4, $brand',
      child: MouseRegion(
        cursor: SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: AppMotion.durFast,
            curve: AppMotion.easeStandard,
            padding: const EdgeInsets.all(AppDimens.space16),
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
              border: Border.all(color: _borderColor, width: _borderWidth),
              boxShadow: _hovered && !_pressed ? AppDimens.elev2 : AppDimens.elev1,
            ),
            child: AnimatedScale(
              scale: _pressed ? AppMotion.pressScale : 1.0,
              duration: AppMotion.durInstant,
              curve: AppMotion.easeEntrance,
              child: Row(
                children: [
                  ExcludeSemantics(child: _buildBrandLogo(pm.brand)),
                  const SizedBox(width: AppDimens.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '•••• ${pm.last4 ?? '—'}',
                          style: AppTextStyles.hudReadout.copyWith(
                            fontWeight: FontWeight.w600,
                            color: pm.isDefault
                                ? AppColors.gold
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          _expiryLabel(pm),
                          style: AppTextStyles.bodyS.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (pm.isDefault) ...[
                    _DefaultTag(),
                    const SizedBox(width: AppDimens.space8),
                  ],
                  Semantics(
                    label: 'Opciones para tarjeta terminada en $last4',
                    child: _MenuButton(
                      pm: pm,
                      onSetDefault: widget.onSetDefault,
                      onDelete: widget.onDelete,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandLogo(String? brand) {
    final b = brand?.toLowerCase();
    final IconData icon;
    if (b == 'visa') {
      icon = FontAwesomeIcons.ccVisa;
    } else if (b == 'mastercard') {
      icon = FontAwesomeIcons.ccMastercard;
    } else if (b == 'amex' || b == 'american_express') {
      icon = FontAwesomeIcons.ccAmex;
    } else if (b == 'discover') {
      icon = FontAwesomeIcons.ccDiscover;
    } else {
      return Container(
        width: 50,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusS),
        ),
        child: const Icon(
          Icons.credit_card,
          color: AppColors.textSecondary,
          size: 20,
        ),
      );
    }

    return Container(
      width: 50,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusS),
      ),
      child: Center(
        child: FaIcon(icon, color: AppColors.textSecondary, size: 20),
      ),
    );
  }

  String _expiryLabel(PaymentMethod pm) {
    final brand = (pm.brand ?? '').toUpperCase();
    final month = pm.expMonth?.toString().padLeft(2, '0');
    final year = pm.expYear;
    if (month != null && year != null) {
      return brand.isNotEmpty ? '$brand  ·  $month/$year' : '$month/$year';
    }
    return brand.isNotEmpty ? brand : '—';
  }
}

// ─── Default tag ──────────────────────────────────────────────────────────────

class _DefaultTag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space8,
          vertical: AppDimens.space4,
        ),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppDimens.radiusPill),
          border: Border.all(
            color: AppColors.borderGold,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: AppColors.gold, size: 10),
            const SizedBox(width: AppDimens.space4),
            Text(
              'PREDETERMINADA',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.gold),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Menu button ──────────────────────────────────────────────────────────────

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.pm,
    required this.onSetDefault,
    required this.onDelete,
  });

  final PaymentMethod pm;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: Icons.more_vert_rounded,
      tooltip: 'Opciones',
      variant: AppButtonVariant.ghost,
      size: AppButtonSize.sm,
      onPressed: () {
        final box = context.findRenderObject() as RenderBox;
        final pos = box.localToGlobal(Offset.zero);
        final anchor = Offset(pos.dx, pos.dy + box.size.height);

        showHudPopover(
          context: context,
          anchor: anchor,
          items: [
            if (!pm.isDefault)
              HudPopoverItem(
                label: 'Marcar como predeterminada',
                icon: Icons.star_outline_rounded,
                onSelected: onSetDefault,
              ),
            HudPopoverItem(
              label: 'Eliminar',
              icon: Icons.delete_outline_rounded,
              destructive: true,
              onSelected: onDelete,
            ),
          ],
        );
      },
    );
  }
}

// ─── Skeleton card row ────────────────────────────────────────────────────────

class _SkeletonCardRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceHud,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          const SkeletonBase(
            width: 50,
            height: 34,
            radius: AppDimens.radiusS,
          ),
          const SizedBox(width: AppDimens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SkeletonBase(
                  width: double.infinity,
                  height: 14,
                  radius: AppDimens.radiusXS,
                ),
                const SizedBox(height: AppDimens.space8),
                SkeletonBase(
                  width: MediaQuery.sizeOf(context).width * 0.3,
                  height: 11,
                  radius: AppDimens.radiusXS,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.space12),
          const SkeletonBase(
            width: 28,
            height: 28,
            shape: BoxShape.circle,
          ),
        ],
      ),
    );
  }
}

// ─── Delete confirmation dialog ───────────────────────────────────────────────

class _DeleteConfirmDialog extends StatelessWidget {
  const _DeleteConfirmDialog({required this.pm});

  final PaymentMethod pm;

  @override
  Widget build(BuildContext context) {
    final last4 = pm.last4 ?? '—';
    final brand = (pm.brand ?? '').isNotEmpty ? (pm.brand ?? '').toUpperCase() : 'TARJETA';

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.radiusXL),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.glassSurfaceStrong,
                borderRadius: BorderRadius.circular(AppDimens.radiusXL),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.40),
                  width: 1,
                ),
                boxShadow: AppDimens.elev3,
              ),
              padding: const EdgeInsets.all(AppDimens.space24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿ELIMINAR ESTE MÉTODO?',
                    style: AppTextStyles.titleM.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: AppDimens.space12),
                  const HudDivider(),
                  const SizedBox(height: AppDimens.space16),
                  Text(
                    'Vas a eliminar la $brand terminada en $last4 de tus métodos '
                    'de pago. Si tenés cobros pendientes, esto podría afectar tu '
                    'suscripción.',
                    style: AppTextStyles.bodyM.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppDimens.space24),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton.ghost(
                          label: 'CANCELAR',
                          onPressed: () => Navigator.pop(context, false),
                          size: AppButtonSize.md,
                          expand: true,
                        ),
                      ),
                      const SizedBox(width: AppDimens.space12),
                      Expanded(
                        child: AppButton.danger(
                          label: 'ELIMINAR',
                          onPressed: () => Navigator.pop(context, true),
                          size: AppButtonSize.md,
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
      ),
    );
  }
}
