// lib/core/ui/widgets/status_tag.dart
// Tag de estado «Hangar OS» — muestra el estado operativo de una unidad.
// Non-interactive. El color nunca es el único indicador: el texto siempre
// diferencia cada estado independientemente de la percepción del color.
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_text_styles.dart';
import '../hud/hud_status_dot.dart';

// ─── Spec-defined tag height (not in AppDimens) ───────────────────────────────
const double _kTagHeight = 22;

// Spec-defined dot size for StatusTag (HudStatusDot default is 10).
const double _kStatusDotSize = 8;

// ─── Enum ─────────────────────────────────────────────────────────────────────

enum UnitStatus { online, suspended, offline, processing }

// ─── Widget ───────────────────────────────────────────────────────────────────

class StatusTag extends StatelessWidget {
  const StatusTag({
    super.key,
    required this.status,
    this.compact = false,
  });

  final UnitStatus status;

  /// compact = true → abbreviated label (e.g. 'ON' instead of 'EN LÍNEA')
  /// for layout contexts that need a narrower visual footprint (e.g. table cells).
  final bool compact;

  // ─── Helpers ────────────────────────────────────────────────────────────────

  // offline uses danger for the tag shell (semantic meaning: inactive/error) while
  // HudStatusDot renders the offline dot in textTertiary (no glow — unit doesn't emit).
  // This divergence is intentional per the Hangar OS status spec.
  Color get _color => switch (status) {
        UnitStatus.online      => AppColors.success,
        UnitStatus.suspended   => AppColors.warning,
        UnitStatus.offline     => AppColors.danger,
        UnitStatus.processing  => AppColors.cyan,
      };

  String get _label => switch (status) {
        UnitStatus.online      => 'EN LÍNEA',
        UnitStatus.suspended   => 'SUSPENDIDO',
        UnitStatus.offline     => 'OFFLINE',
        UnitStatus.processing  => 'PROCESANDO',
      };

  String get _labelShort => switch (status) {
        UnitStatus.online      => 'ON',
        UnitStatus.suspended   => 'SUSP',
        UnitStatus.offline     => 'OFF',
        UnitStatus.processing  => 'PROC',
      };

  // Both UnitStatus and HudStatus encode identical states.
  // If HudStatus gains a new case, add the matching UnitStatus case here too.
  HudStatus _toHudStatus(UnitStatus s) => switch (s) {
        UnitStatus.online      => HudStatus.online,
        UnitStatus.processing  => HudStatus.processing,
        UnitStatus.suspended   => HudStatus.suspended,
        UnitStatus.offline     => HudStatus.offline,
      };

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final displayLabel = compact ? _labelShort : _label;

    final content = Container(
      height: _kTagHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
        border: Border.all(
          color: color.withValues(alpha: 0.32),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HudStatusDot(
            status: _toHudStatus(status),
            size: _kStatusDotSize,
          ),
          const SizedBox(width: AppDimens.space8),
          Text(
            displayLabel,
            style: AppTextStyles.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );

    return Semantics(
      label: 'Estado: $_label',
      child: ExcludeSemantics(child: content),
    );
  }
}
