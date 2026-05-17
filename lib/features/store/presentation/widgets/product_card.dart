// Archivo: lib/features/store/presentation/widgets/product_card.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/panels/holo_panel.dart';
import 'package:botslode/core/ui/hud/hud_grid_texture.dart';
import 'package:botslode/core/ui/hud/hud_id_tag.dart';
import 'package:botslode/core/ui/hud/hud_ticker.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';
import 'package:botslode/features/store/domain/models/store_product.dart';

class ProductCard extends StatefulWidget {
  final StoreProduct product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;
  // Starts at 0 so HudTicker counts up on entry.
  double _priceDisplay = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _priceDisplay = widget.product.price);
    });
  }

  StoreProduct get _p => widget.product;

  bool get _isOwned => _p.isOwned;
  // Unavailable = coming soon (not owned, not available)
  bool get _isUnavailable => !_p.isAvailable && !_p.isOwned;
  bool get _canInteract => _p.isAvailable && !_p.isOwned;

  double get _scale {
    if (_isPressed) return AppMotion.pressScale; // 0.97
    if (_isHovered) return 1.02;
    return 1.0;
  }

  Duration get _scaleDur =>
      _isPressed ? AppMotion.durInstant : AppMotion.durFast;

  // Focus ring gold takes priority over hover border.
  Color get _borderColor {
    if (_isFocused) return AppColors.gold;
    if (_isHovered) return _p.accentColor.withValues(alpha: 0.45);
    return AppColors.borderDefault;
  }

  // Glow is gold when price > 0 (monetary), else accent.
  Color? get _glowAccent {
    if (!_isHovered || _isPressed) return null;
    return _p.price > 0 ? AppColors.gold : _p.accentColor;
  }

  void _onEnter(dynamic _) => setState(() => _isHovered = true);
  void _onExit(dynamic _) => setState(() => _isHovered = false);

  void _onTapDown(TapDownDetails _) => setState(() => _isPressed = true);
  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    _handleAction();
  }
  void _onTapCancel() => setState(() => _isPressed = false);

  void _handleAction() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        'Compra de ${_p.name} próximamente',
        style: AppTextStyles.bodyS,
      ),
      backgroundColor: AppColors.surfaceHud,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final dur = reduced ? AppMotion.durCrossfadeReduced : AppMotion.durFast;

    Widget card = HoloPanel(
      padding: EdgeInsets.zero,
      borderColor: _borderColor,
      glowAccent: _glowAccent,
      child: Opacity(
        opacity: _isUnavailable ? 0.55 : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
            _buildFooter(reduced),
          ],
        ),
      ),
    );

    // Hover translateY + press has no translate (already handled by scale)
    card = AnimatedContainer(
      duration: dur,
      curve: AppMotion.easeStandard,
      transform: Matrix4.translationValues(
        0.0,
        (reduced || !_isHovered || _isPressed) ? 0.0 : -4.0,
        0.0,
      ),
      transformAlignment: Alignment.center,
      child: card,
    );

    // Press (0.97) and hover (1.02) scale
    card = AnimatedScale(
      scale: reduced ? 1.0 : _scale,
      duration: reduced ? AppMotion.durCrossfadeReduced : _scaleDur,
      curve: AppMotion.easeStandard,
      child: card,
    );

    // Interaction layer
    card = GestureDetector(
      onTapDown: _canInteract ? _onTapDown : null,
      onTapUp: _canInteract ? _onTapUp : null,
      onTapCancel: _canInteract ? _onTapCancel : null,
      child: MouseRegion(
        cursor: _canInteract ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: _onEnter,
        onExit: _onExit,
        child: card,
      ),
    );

    // Keyboard focus
    card = Focus(
      onFocusChange: (f) => setState(() => _isFocused = f),
      child: card,
    );

    return Semantics(
      button: true,
      label: 'Producto ${_p.name}, ${_p.formattedPrice}',
      child: card,
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final accent = _p.accentColor;

    return SizedBox(
      height: 120,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Gradient + HUD grid background
          HudGridTexture(
            color: accent,
            opacity: 0.05,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withValues(alpha: 0.12),
                    accent.withValues(alpha: 0.04),
                  ],
                ),
              ),
            ),
          ),

          // Radial glow behind icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.22),
                    blurRadius: 36,
                    spreadRadius: 12,
                  ),
                ],
              ),
            ),
          ),

          // Circular HUD icon frame
          Center(
            child: Container(
              padding: const EdgeInsets.all(AppDimens.space20),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.90),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accent.withValues(alpha: 0.32),
                  width: 2,
                ),
                boxShadow: AppDimens.glowStatus(accent),
              ),
              child: FaIcon(
                _p.icon,
                color: accent,
                size: AppDimens.iconL,
              ),
            ),
          ),

          // HudIdTag — product id code (top-left)
          Positioned(
            top: AppDimens.space12,
            left: AppDimens.space12,
            child: HudIdTag(
              text: _p.id.length > 8 ? _p.id.substring(0, 8) : _p.id,
            ),
          ),

          // Status badge (top-right) — only one shown
          if (_isOwned)
            const Positioned(
              top: AppDimens.space12,
              right: AppDimens.space12,
              child: _ProductBadge(
                label: 'ACTIVO',
                color: AppColors.success,
                icon: FontAwesomeIcons.check,
              ),
            )
          else if (_isUnavailable)
            const Positioned(
              top: AppDimens.space12,
              right: AppDimens.space12,
              child: _ProductBadge(
                label: 'PRÓXIMAMENTE',
                color: AppColors.warning,
                icon: FontAwesomeIcons.clock,
              ),
            ),
        ],
      ),
    );
  }

  // ─── Body ─────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    final accent = _p.accentColor;

    return Padding(
      padding: const EdgeInsets.all(AppDimens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CategoryChip(label: _p.category.displayName, color: _p.category.color),
          const SizedBox(height: AppDimens.space12),

          // Product name
          Text(
            _p.name,
            style: AppTextStyles.titleM,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimens.space8),

          // Description
          Text(
            _p.description,
            style: AppTextStyles.bodyS.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const Spacer(),

          // Features — up to 3
          ..._p.features.take(3).map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: AppDimens.space4),
                  child: Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.check,
                        color: accent.withValues(alpha: 0.70),
                        size: AppDimens.iconXS,
                      ),
                      const SizedBox(width: AppDimens.space8),
                      Expanded(
                        child: Text(
                          feature,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  // ─── Footer ───────────────────────────────────────────────────────────────

  Widget _buildFooter(bool reduced) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceHud,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Price block
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_p.priceDefined && _p.price > 0) ...[
                HudTicker(
                  value: reduced ? _p.price : _priceDisplay,
                  prefix: r'$',
                  decimals: 0,
                  style: AppTextStyles.numericTicker
                      .copyWith(color: AppColors.gold),
                  animate: !reduced,
                ),
                Text(
                  'PAGO ÚNICO',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 9,
                  ),
                ),
              ] else if (_p.priceDefined && _p.price == 0)
                Text(
                  'GRATIS',
                  style: AppTextStyles.numericTicker
                      .copyWith(color: AppColors.success),
                )
              else
                Text(
                  'A DEFINIR',
                  style: AppTextStyles.hudReadout
                      .copyWith(color: AppColors.textSecondary),
                ),
            ],
          ),

          const Spacer(),

          // Action button — variant depends on state
          if (_isOwned)
            AppButton.secondary(
              label: 'ABRIR',
              onPressed: _handleAction,
              size: AppButtonSize.sm,
            )
          else if (_p.isAvailable)
            AppButton.primary(
              label: 'ADQUIRIR',
              onPressed: _handleAction,
              size: AppButtonSize.sm,
            )
          else
            const AppButton.ghost(
              label: 'NOTIFICAR',
              onPressed: null,
              size: AppButtonSize.sm,
            ),
        ],
      ),
    );
  }
}

// ─── _ProductBadge ────────────────────────────────────────────────────────────
// Status badge for the header (ACTIVO, PRÓXIMAMENTE, AGOTADO).
// Mirrors StatusTag visual language (pill + border + icon + text) with custom labels.

class _ProductBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _ProductBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space8,
        vertical: AppDimens.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.32), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 9, color: color),
          const SizedBox(width: AppDimens.space4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _CategoryChip ────────────────────────────────────────────────────────────
// Category pill in the card body — same visual language as StatusTag chips.

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color color;

  const _CategoryChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space8,
        vertical: AppDimens.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 1),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }
}
