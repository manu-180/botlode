// Archivo: lib/features/dashboard/presentation/widgets/dashboard_toolbar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/panels/holo_panel.dart';
import 'package:botslode/core/ui/inputs/app_text_field.dart';
import 'package:botslode/core/ui/hud/hud_status_dot.dart';
import 'package:botslode/core/ui/badges/app_badge.dart' hide BotStatus;
import 'package:botslode/core/ui/responsive/breakpoints.dart';
import 'package:botslode/features/dashboard/domain/models/bot.dart';
import 'package:botslode/features/dashboard/presentation/providers/bots_provider.dart';
import 'package:botslode/features/dashboard/presentation/providers/dashboard_controller.dart';

// Fix 1: named constant replaces the raw literal 6 used in dot sizes
const double _kFilterDotSize = 6.0;

// ---------------------------------------------------------------------------
// DashboardToolbar
// ---------------------------------------------------------------------------

class DashboardToolbar extends ConsumerStatefulWidget {
  const DashboardToolbar({super.key});

  @override
  ConsumerState<DashboardToolbar> createState() => _DashboardToolbarState();
}

class _DashboardToolbarState extends ConsumerState<DashboardToolbar> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentFilter = ref.watch(dashboardFilterProvider);
    final botsAsync = ref.watch(botsProvider);
    final allBots = botsAsync.value ?? [];

    final activeCount = allBots.where((b) => b.status == BotStatus.active).length;
    final offlineCount = allBots.where(
      (b) =>
          b.status == BotStatus.disabled ||
          b.status == BotStatus.maintenance ||
          b.status == BotStatus.creditSuspended,
    ).length;

    final isMobile = Breakpoints.isMobile(context);

    return SizedBox(
      height: isMobile ? 80 : 64,
      child: HoloPanel(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? AppDimens.space12 : AppDimens.space16,
          vertical: isMobile ? AppDimens.space8 : AppDimens.space12,
        ),
        borderColor: AppColors.borderDefault,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Search field ───────────────────────────────────────────────
            Expanded(
              child: AppSearchField(
                controller: _searchCtrl,
                hint: isMobile
                    ? 'BUSCAR UNIDAD...'
                    : 'BUSCAR UNIDAD POR ID O NOMBRE...',
                onChanged: (value) =>
                    ref.read(dashboardSearchProvider.notifier).setSearch(value),
                onClear: () =>
                    ref.read(dashboardSearchProvider.notifier).setSearch(''),
              ),
            ),

            // ── Segmented filter (sólo desktop/tablet) ─────────────────────
            // En mobile lo ocultamos — su layout exige > 300 px adicionales
            // y entra en infinite relayout cuando el ancho es chico.
            if (!isMobile) ...[
              const SizedBox(width: AppDimens.space20),
              _SegmentedFilter(
                currentFilter: currentFilter,
                allCount: allBots.length,
                activeCount: activeCount,
                offlineCount: offlineCount,
                onFilterChanged: (filter) => ref
                    .read(dashboardFilterProvider.notifier)
                    .setFilter(filter),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SegmentedFilter
// ---------------------------------------------------------------------------

class _SegmentedFilter extends StatefulWidget {
  final BotFilter currentFilter;
  final int allCount;
  final int activeCount;
  final int offlineCount;
  final ValueChanged<BotFilter> onFilterChanged;

  const _SegmentedFilter({
    required this.currentFilter,
    required this.allCount,
    required this.activeCount,
    required this.offlineCount,
    required this.onFilterChanged,
  });

  @override
  State<_SegmentedFilter> createState() => _SegmentedFilterState();
}

class _SegmentedFilterState extends State<_SegmentedFilter> {
  // Index within our 3-chip list: 0=TODOS, 1=ACTIVOS, 2=OFFLINE
  int get _selectedIndex => switch (widget.currentFilter) {
        BotFilter.all      => 0,
        BotFilter.active   => 1,
        BotFilter.disabled => 2,
        // maintenance has no dedicated chip; fall back to TODOS
        BotFilter.maintenance => 0,
      };

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduced(context);

    // Fix 2: sliding indicator — delegate to _SlidingRail
    return Container(
      height: 36,
      padding: const EdgeInsets.all(AppDimens.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceHud,
        borderRadius: AppDimens.brPill,
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: _SlidingRail(
        selectedIndex: _selectedIndex,
        reduce: reduce,
        chips: [
          _FilterChip(
            label: 'TODOS',
            count: widget.allCount,
            isSelected: _selectedIndex == 0,
            dotWidget: const _NeutralDot(),
            badgeColorActive: AppColors.gold,
            badgeTextActive: AppColors.textOnGold,
            badgeColorInactive: AppColors.surfaceRaised,
            badgeTextInactive: AppColors.textSecondary,
            semanticLabel: 'Filtro: Todos, ${widget.allCount} unidades',
            onTap: () => widget.onFilterChanged(BotFilter.all),
          ),
          _FilterChip(
            label: 'ACTIVOS',
            count: widget.activeCount,
            isSelected: _selectedIndex == 1,
            dotWidget: const HudStatusDot(status: HudStatus.online, size: _kFilterDotSize),
            badgeColorActive: AppColors.success,
            badgeTextActive: AppColors.surfaceHud,
            badgeColorInactive: AppColors.surfaceRaised,
            badgeTextInactive: AppColors.textSecondary,
            semanticLabel: 'Filtro: Activos, ${widget.activeCount} unidades',
            onTap: () => widget.onFilterChanged(BotFilter.active),
          ),
          _FilterChip(
            label: 'OFFLINE',
            count: widget.offlineCount,
            isSelected: _selectedIndex == 2,
            dotWidget: _DangerDot(isActive: _selectedIndex == 2, reduce: reduce),
            badgeColorActive: AppColors.danger,
            badgeTextActive: AppColors.textPrimary,
            badgeColorInactive: AppColors.surfaceRaised,
            badgeTextInactive: AppColors.textSecondary,
            semanticLabel: 'Filtro: Offline, ${widget.offlineCount} unidades',
            onTap: () => widget.onFilterChanged(BotFilter.disabled),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SlidingRail — sliding indicator that physically travels between chips
// ---------------------------------------------------------------------------

class _SlidingRail extends StatelessWidget {
  final int selectedIndex;
  final bool reduce;
  final List<Widget> chips;

  const _SlidingRail({
    required this.selectedIndex,
    required this.reduce,
    required this.chips,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final chipWidth = totalWidth / chips.length;
        final indicatorLeft = selectedIndex * chipWidth;

        final indicatorDur =
            reduce ? AppMotion.durCrossfadeReduced : AppMotion.durBase;
        final indicatorCurve =
            reduce ? Curves.linear : AppMotion.easeEntrance;

        return Stack(
          children: [
            // Sliding indicator (behind chips)
            AnimatedPositioned(
              duration: indicatorDur,
              curve: indicatorCurve,
              left: indicatorLeft,
              top: 0,
              bottom: 0,
              width: chipWidth,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.16),
                  borderRadius: AppDimens.brPill,
                  border: Border.all(color: AppColors.borderGold, width: 1),
                ),
              ),
            ),
            // Chips row (on top of indicator)
            Row(
              children: chips
                  .map((chip) => SizedBox(width: chipWidth, child: chip))
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _FilterChip
// ---------------------------------------------------------------------------

class _FilterChip extends StatefulWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Widget dotWidget;
  final Color badgeColorActive;
  final Color badgeTextActive;
  final Color badgeColorInactive;
  final Color badgeTextInactive;
  final String semanticLabel;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.dotWidget,
    required this.badgeColorActive,
    required this.badgeTextActive,
    required this.badgeColorInactive,
    required this.badgeTextInactive,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduced(context);
    final animDur = reduce ? AppMotion.durCrossfadeReduced : AppMotion.durBase;
    final animCurve = reduce ? Curves.linear : AppMotion.easeEntrance;
    final fastDur = reduce ? AppMotion.durCrossfadeReduced : AppMotion.durFast;

    final labelColor = widget.isSelected
        ? AppColors.textPrimary
        : AppColors.textSecondary;
    final badgeColor =
        widget.isSelected ? widget.badgeColorActive : widget.badgeColorInactive;
    final badgeText =
        widget.isSelected ? widget.badgeTextActive : widget.badgeTextInactive;

    // Fix 2: chip no longer paints its own selection background — the sliding
    // indicator in _SlidingRail handles it. Only show hover tint.
    Color bgColor = Colors.transparent;
    if (!widget.isSelected && _hovered && !_pressed) {
      bgColor = AppColors.surfaceRaised.withValues(alpha: 0.5);
    }

    // Fix 2 / Fix 1: indicator handles the selection border; focus ring when focused
    Widget chip = AnimatedContainer(
      duration: animDur,
      curve: animCurve,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppDimens.brPill,
        border: _focused ? Border.all(color: AppColors.borderStrong, width: 1) : null,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space12,
        vertical: AppDimens.space4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.dotWidget,
          const SizedBox(width: AppDimens.space8),
          AnimatedDefaultTextStyle(
            duration: fastDur,
            curve: AppMotion.easeStandard,
            style: AppTextStyles.label.copyWith(color: labelColor),
            child: Text(widget.label),
          ),
          const SizedBox(width: AppDimens.space8),
          AnimatedSwitcher(
            duration: fastDur,
            child: CounterBadge(
              key: ValueKey('${widget.label}_${widget.isSelected}'),
              count: widget.count,
              color: badgeColor,
              textColor: badgeText,
            ),
          ),
        ],
      ),
    );

    // Press scale
    chip = AnimatedScale(
      scale: _pressed ? AppMotion.pressScale : 1.0,
      duration: _pressed ? AppMotion.durInstant : AppMotion.durFast,
      curve: AppMotion.easeEntrance,
      child: chip,
    );

    return Semantics(
      button: true,
      selected: widget.isSelected,
      label: widget.semanticLabel,
      onTap: widget.onTap,
      child: Focus(
        onFocusChange: (focused) => setState(() => _focused = focused),
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
               event.logicalKey == LogicalKeyboardKey.space)) {
            widget.onTap();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() {
            _hovered = false;
            _pressed = false;
          }),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
            onTapCancel: () => setState(() => _pressed = false),
            child: chip,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _NeutralDot  — static textSecondary dot for TODOS chip
// ---------------------------------------------------------------------------

class _NeutralDot extends StatelessWidget {
  const _NeutralDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kFilterDotSize,
      height: _kFilterDotSize,
      decoration: const BoxDecoration(
        color: AppColors.textSecondary,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _DangerDot  — danger-colored dot for OFFLINE chip; glow when active
// ---------------------------------------------------------------------------

class _DangerDot extends StatelessWidget {
  final bool isActive;
  final bool reduce;

  const _DangerDot({required this.isActive, required this.reduce});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: reduce ? AppMotion.durCrossfadeReduced : AppMotion.durBase,
      // Fix 4: respect reduced-motion for the curve
      curve: reduce ? Curves.linear : AppMotion.easeStandard,
      width: _kFilterDotSize,
      height: _kFilterDotSize,
      decoration: BoxDecoration(
        color: AppColors.danger,
        shape: BoxShape.circle,
        boxShadow: isActive ? AppDimens.glowStatus(AppColors.danger) : null,
      ),
    );
  }
}
