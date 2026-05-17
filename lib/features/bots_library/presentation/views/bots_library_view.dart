// Archivo: lib/features/bots_library/presentation/views/bots_library_view.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/app_background.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';
import 'package:botslode/core/ui/widgets/app_text_field.dart';
import 'package:botslode/core/ui/widgets/empty_state.dart';
import 'package:botslode/core/ui/widgets/page_title.dart';
import 'package:botslode/core/ui/widgets/skeleton_base.dart';
import 'package:botslode/features/bots_library/domain/models/blueprint.dart';
import 'package:botslode/features/bots_library/presentation/widgets/blueprint_card.dart';
import 'package:botslode/features/dashboard/presentation/widgets/create_bot_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

// _LibraryCategoryChip design constants
const double _kChipHeight = AppDimens.hitTargetMin; // 32px — minimum hit target per §10
const double _kSearchFieldWidth = 280.0;
const int _kSkeletonCount = 8;
const double _kCategoryChipSelectedFillAlpha = 0.12;
const double _kCategoryChipSelectedFillHoverAlpha = 0.18;
const double _kCategoryChipSelectedBorderAlpha = 0.40;

// ─────────────────────────────────────────────────────────────────────────────
// BotsLibraryView
// ─────────────────────────────────────────────────────────────────────────────

class BotsLibraryView extends StatefulWidget {
  static const String routeName = 'bots_library';

  const BotsLibraryView({super.key});

  @override
  State<BotsLibraryView> createState() => _BotsLibraryViewState();
}

class _BotsLibraryViewState extends State<BotsLibraryView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory; // null = "TODOS"
  final bool _isLoading = false; // false for now — branch ready for future async

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BotBlueprint> get _filteredBlueprints {
    var all = BotBlueprint.catalog;
    if (_selectedCategory != null) {
      all = all.where((bp) => bp.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      all = all
          .where(
            (bp) =>
                bp.name.toLowerCase().contains(q) ||
                bp.description.toLowerCase().contains(q),
          )
          .toList();
    }
    return all;
  }

  void _clearFilter() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = null;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.space32,
              vertical: AppDimens.space32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────────
                const PageTitle(
                  title: 'BIBLIOTECA DE PLANOS',
                  subtitle: 'Seleccione un prototipo para iniciar el ensamblaje',
                  accentColor: AppColors.cyan,
                  style: PageTitleStyle.techBar,
                ),

                const SizedBox(height: AppDimens.space24),

                // ── Toolbar ─────────────────────────────────────────────────
                _LibraryToolbar(
                  selectedCategory: _selectedCategory,
                  onCategorySelected: (cat) {
                    setState(() => _selectedCategory = cat);
                  },
                  searchController: _searchController,
                  onSearchChanged: (val) {
                    setState(() => _searchQuery = val);
                  },
                ),

                const SizedBox(height: AppDimens.space24),

                // ── Grid / States ────────────────────────────────────────────
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final filtered = _filteredBlueprints;
                      return AnimatedSwitcher(
                        duration: AppMotion.durFast,
                        switchInCurve: AppMotion.easeStandard,
                        switchOutCurve: AppMotion.easeExit,
                        child: _LibraryGrid(
                          key: ValueKey(filtered.isEmpty ? 'empty' : 'grid'),
                          filteredBlueprints: filtered,
                          isLoading: _isLoading,
                          onClearFilter: _clearFilter,
                        ),
                      );
                    },
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

// ─────────────────────────────────────────────────────────────────────────────
// _LibraryToolbar
// ─────────────────────────────────────────────────────────────────────────────

class _LibraryToolbar extends StatelessWidget {
  const _LibraryToolbar({
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.searchController,
    required this.onSearchChanged,
  });

  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  static final List<String> _categories = [
    'TODOS',
    ...BotBlueprint.catalog.map((b) => b.category).toSet(),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Category chips
        Wrap(
          spacing: AppDimens.space8,
          children: _categories.map((cat) {
            final isAll = cat == 'TODOS';
            final isSelected =
                isAll ? selectedCategory == null : selectedCategory == cat;
            return _LibraryCategoryChip(
              label: cat,
              selected: isSelected,
              onTap: () => onCategorySelected(isAll ? null : cat),
            );
          }).toList(),
        ),

        const Spacer(),

        // Search field
        SizedBox(
          width: _kSearchFieldWidth,
          child: AppTextField(
            controller: searchController,
            label: 'Buscar plano...',
            variant: AppTextFieldVariant.search,
            onChanged: onSearchChanged,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LibraryCategoryChip
// ─────────────────────────────────────────────────────────────────────────────

class _LibraryCategoryChip extends StatefulWidget {
  const _LibraryCategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_LibraryCategoryChip> createState() => _LibraryCategoryChipState();
}

class _LibraryCategoryChipState extends State<_LibraryCategoryChip> {
  bool _hovered = false;
  bool _focused = false;

  Color get _fillColor {
    if (widget.selected) {
      return _hovered
          ? AppColors.cyan.withValues(alpha: _kCategoryChipSelectedFillHoverAlpha)
          : AppColors.cyan.withValues(alpha: _kCategoryChipSelectedFillAlpha);
    }
    return _hovered ? AppColors.borderSubtle : Colors.transparent;
  }

  Color get _borderColor {
    if (widget.selected) {
      return AppColors.cyan.withValues(alpha: _kCategoryChipSelectedBorderAlpha);
    }
    return _hovered ? AppColors.borderStrong : AppColors.borderDefault;
  }

  double get _borderWidth => widget.selected ? 1.5 : 1.0;

  Color get _textColor =>
      widget.selected ? AppColors.cyan : AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: Focus(
        onFocusChange: (focused) => setState(() => _focused = focused),
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
               event.logicalKey == LogicalKeyboardKey.space)) {
            widget.onTap();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: AnimatedContainer(
          duration: AppMotion.durFast,
          curve: AppMotion.easeStandard,
          padding: EdgeInsets.all(_focused ? 2 : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusPill + 4),
            border: _focused
                ? Border.all(color: AppColors.cyan, width: 2)
                : null,
          ),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: AppMotion.durFast,
                curve: AppMotion.easeStandard,
                height: _kChipHeight,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space12,
                ),
                decoration: BoxDecoration(
                  color: _fillColor,
                  borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                  border: Border.all(color: _borderColor, width: _borderWidth),
                ),
                child: Center(
                  child: Text(
                    widget.label.toUpperCase(),
                    style: AppTextStyles.label.copyWith(color: _textColor),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LibraryGrid
// ─────────────────────────────────────────────────────────────────────────────

class _LibraryGrid extends StatelessWidget {
  const _LibraryGrid({
    super.key,
    required this.filteredBlueprints,
    required this.isLoading,
    required this.onClearFilter,
  });

  final List<BotBlueprint> filteredBlueprints;
  final bool isLoading;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    // ── Loading branch ────────────────────────────────────────────────────────
    if (isLoading) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 350,
          childAspectRatio: 0.78,
          crossAxisSpacing: AppDimens.space20,
          mainAxisSpacing: AppDimens.space20,
        ),
        padding: const EdgeInsets.only(bottom: AppDimens.space32),
        itemCount: _kSkeletonCount,
        itemBuilder: (_, __) => const SkeletonBase(
          radius: AppDimens.radiusL,
          height: double.infinity,
        ),
      );
    }

    // ── Empty branch ──────────────────────────────────────────────────────────
    if (filteredBlueprints.isEmpty) {
      if (BotBlueprint.catalog.isEmpty) {
        return const EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'ARCHIVO DE PLANOS VACÍO',
          description: 'No hay prototipos disponibles en este momento.',
          variant: EmptyStateVariant.neutral,
        );
      }
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'SIN COINCIDENCIAS',
        description: 'Ningún plano coincide con el filtro actual.',
        variant: EmptyStateVariant.noResults,
        action: AppButton(
          label: 'Limpiar filtro',
          onPressed: onClearFilter,
          variant: AppButtonVariant.secondary,
          size: AppButtonSize.sm,
        ),
      );
    }

    // ── Default: grid with stagger entrance ───────────────────────────────────
    final isReduced = AppMotion.reduced(context);

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 350,
        childAspectRatio: 0.78,
        crossAxisSpacing: AppDimens.space20,
        mainAxisSpacing: AppDimens.space20,
      ),
      padding: const EdgeInsets.only(bottom: AppDimens.space32),
      itemCount: filteredBlueprints.length,
      itemBuilder: (context, index) {
        final bp = filteredBlueprints[index];

        Widget card = BlueprintCard(
          blueprint: bp,
          onTap: () => showDialog(
            context: context,
            builder: (_) => CreateBotModal(template: bp),
          ),
        );

        if (isReduced) {
          card = card
              .animate()
              .fadeIn(duration: AppMotion.durCrossfadeReduced);
        } else {
          card = card
              .animate(delay: AppMotion.staggerDelay(index))
              .fadeIn(
                duration: AppMotion.durBase,
                curve: AppMotion.easeEntrance,
              )
              .move(
                begin: const Offset(0, 12),
                end: Offset.zero,
                duration: AppMotion.durBase,
                curve: AppMotion.easeEntrance,
              );
        }

        return card;
      },
    );
  }
}
