// Archivo: lib/features/store/presentation/views/store_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/app_background.dart';
import 'package:botslode/core/ui/hud/hud_divider.dart';
import 'package:botslode/core/ui/inputs/app_text_field.dart';
import 'package:botslode/core/ui/panels/holo_panel.dart';
import 'package:botslode/core/ui/responsive/breakpoints.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';
import 'package:botslode/core/ui/widgets/empty_state.dart';
import 'package:botslode/core/ui/widgets/page_title.dart';
import 'package:botslode/core/ui/widgets/skeleton_base.dart';
import 'package:botslode/features/store/domain/models/store_product.dart';
import 'package:botslode/features/store/presentation/widgets/product_card.dart';
import 'package:flutter/services.dart';

class StoreView extends ConsumerStatefulWidget {
  static const String routeName = 'store';

  const StoreView({super.key});

  @override
  ConsumerState<StoreView> createState() => _StoreViewState();
}

class _StoreViewState extends ConsumerState<StoreView> {
  String _searchQuery = '';
  ProductCategory? _selectedCategory;
  final _searchCtrl = TextEditingController();
  // Always false for now; branch is ready for async catalog loading.
  final bool _isLoading = false;

  List<StoreProduct> get _filteredProducts {
    var list = StoreProduct.catalog;
    if (_selectedCategory != null) {
      list = list.where((p) => p.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearFilter() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = null;
    });
    _searchCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final catalogEmpty = StoreProduct.catalog.isEmpty;
    final products = _filteredProducts;
    final formFactor = Breakpoints.of(context);
    final hPadding = Breakpoints.horizontalPadding(formFactor);
    final vPadding = formFactor == FormFactor.mobile
        ? AppDimens.space16
        : AppDimens.space32;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(hPadding, vPadding, hPadding, 0),
              child: const PageTitle(
                title: 'TIENDA',
                subtitle: 'Potencia tus unidades con módulos premium',
                style: PageTitleStyle.techBar,
                accentColor: AppColors.gold,
              ),
            ),
            const SizedBox(height: AppDimens.space24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPadding),
              child: _StoreToolbar(
                searchCtrl: _searchCtrl,
                selectedCategory: _selectedCategory,
                onSearchChanged: (v) => setState(() => _searchQuery = v),
                onCategorySelected: (cat) =>
                    setState(() => _selectedCategory = cat),
              ),
            ),
            const SizedBox(height: AppDimens.space16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPadding),
              child: const ExcludeSemantics(
                child: HudDivider(nodeColor: AppColors.gold),
              ),
            ),
            const SizedBox(height: AppDimens.space8),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppMotion.durBase,
                switchInCurve: AppMotion.easeStandard,
                switchOutCurve: AppMotion.easeStandard,
                child: _isLoading
                    ? const _StoreSkeletonGrid(key: ValueKey('loading'))
                    : catalogEmpty
                        ? _StoreCatalogEmptyState(
                            key: const ValueKey('catalog-empty'),
                            onGoToHangar: () => context.go('/dashboard'),
                          )
                        : products.isEmpty
                            ? _StoreFilterEmptyState(
                                key: const ValueKey('filter-empty'),
                                onClearFilter: _clearFilter,
                              )
                            : _StoreProductGrid(
                                key: const ValueKey('grid'),
                                products: products,
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Toolbar ──────────────────────────────────────────────────────────────────

class _StoreToolbar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final ProductCategory? selectedCategory;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ProductCategory?> onCategorySelected;

  const _StoreToolbar({
    required this.searchCtrl,
    required this.selectedCategory,
    required this.onSearchChanged,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);

    final chipRow = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _CategoryChip(
            label: 'TODOS',
            isActive: selectedCategory == null,
            onTap: () => onCategorySelected(null),
          ),
          for (final cat in ProductCategory.values) ...[
            const SizedBox(width: AppDimens.space8),
            _CategoryChip(
              label: cat.displayName,
              isActive: selectedCategory == cat,
              accentColor: cat.color,
              onTap: () => onCategorySelected(cat),
            ),
          ],
        ],
      ),
    );

    final searchField = Semantics(
      label: 'Buscar módulo',
      explicitChildNodes: true,
      child: AppSearchField(
        controller: searchCtrl,
        hint: 'Buscar módulo...',
        width: isMobile ? double.infinity : 280,
        onChanged: onSearchChanged,
        onClear: () => onSearchChanged(''),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          chipRow,
          const SizedBox(height: AppDimens.space12),
          searchField,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: chipRow),
        const SizedBox(width: AppDimens.space16),
        searchField,
      ],
    );
  }
}

// ─── Category chip ────────────────────────────────────────────────────────────

class _CategoryChip extends StatefulWidget {
  final String label;
  final bool isActive;
  final Color? accentColor;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.accentColor,
  });

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _hovered = false;
  bool _focused = false;

  Color get _tint => widget.accentColor ?? AppColors.gold;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive;
    final reduced = AppMotion.reduced(context);
    final hoverScale = (!reduced && _hovered && !isActive) ? 1.03 : 1.0;

    final borderColor = isActive
        ? _tint.withValues(alpha: 0.5)
        : _hovered
            ? AppColors.borderStrong
            : AppColors.borderDefault;

    return Semantics(
      selected: isActive,
      button: true,
      label: widget.label,
      child: Focus(
        onFocusChange: (f) => setState(() => _focused = f),
        onKeyEvent: (_, event) {
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
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: hoverScale,
              duration: AppMotion.durFast,
              curve: AppMotion.easeStandard,
              child: AnimatedContainer(
                duration: AppMotion.durFast,
                curve: AppMotion.easeStandard,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space16,
                  vertical: AppDimens.space8,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? _tint.withValues(alpha: 0.12)
                      : _hovered
                          ? _tint.withValues(alpha: 0.06)
                          : Colors.transparent,
                  borderRadius: AppDimens.brPill,
                  border: Border.all(
                    color: _focused ? AppColors.cyan : borderColor,
                    width: _focused ? 2.0 : (isActive ? 1.5 : 1.0),
                  ),
                  boxShadow: _focused
                      ? [
                          const BoxShadow(
                            color: AppColors.cyanGlow,
                            blurRadius: 12,
                            spreadRadius: 0.5,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  widget.label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isActive ? _tint : AppColors.textSecondary,
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

// ─── Catalog empty state (ceremonial) ─────────────────────────────────────────

class _StoreCatalogEmptyState extends StatefulWidget {
  final VoidCallback onGoToHangar;

  const _StoreCatalogEmptyState({
    super.key,
    required this.onGoToHangar,
  });

  @override
  State<_StoreCatalogEmptyState> createState() =>
      _StoreCatalogEmptyStateState();
}

class _StoreCatalogEmptyStateState extends State<_StoreCatalogEmptyState>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryAnim;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: AppMotion.durHeartbeat,
    );
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: AppMotion.easeStandard),
    );

    _entryCtrl = AnimationController(
      vsync: this,
      duration: AppMotion.durSlow,
    );
    _entryAnim = CurvedAnimation(
      parent: _entryCtrl,
      curve: AppMotion.easeEntrance,
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = AppMotion.reduced(context);
    if (reduced) {
      _pulseCtrl.stop();
      _pulseCtrl.value = 1.0;
    } else if (!_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);

    return AnimatedBuilder(
      animation: _entryAnim,
      builder: (_, child) {
        final t = _entryAnim.value;
        final scale = reduced ? 1.0 : (0.96 + 0.04 * t);
        return Opacity(
          opacity: t,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: HoloPanel(
            padding: const EdgeInsets.all(AppDimens.space40),
            cornerBrackets: true,
            scanlines: true,
            glowAccent: AppColors.gold,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Pulsating icon ring
                ExcludeSemantics(
                  child: AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Opacity(
                      opacity: reduced ? 1.0 : _pulseAnim.value,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceHud,
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                          boxShadow: AppDimens.glowStatus(AppColors.gold),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          size: 36,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.space24),
                // Title
                Semantics(
                  header: true,
                  child: Text(
                    'CATÁLOGO EN PREPARACIÓN',
                    style: AppTextStyles.titleL.copyWith(
                      color: AppColors.textPrimary,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppDimens.space8),
                // Mono status line (decorative)
                ExcludeSemantics(
                  child: Text(
                    '// SYNC_PENDING — MÓDULOS EN ENSAMBLAJE',
                    style: AppTextStyles.mono.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 0.8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppDimens.space16),
                // Description
                Text(
                  'Los módulos premium para tus unidades estarán disponibles próximamente.',
                  style: AppTextStyles.bodyM.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimens.space24),
                // CTA
                AppButton.ghost(
                  label: 'VOLVER AL HANGAR',
                  onPressed: widget.onGoToHangar,
                  size: AppButtonSize.md,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Filter empty state ───────────────────────────────────────────────────────

class _StoreFilterEmptyState extends StatelessWidget {
  final VoidCallback onClearFilter;

  const _StoreFilterEmptyState({super.key, required this.onClearFilter});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off_rounded,
      title: 'SIN COINCIDENCIAS',
      description: 'No se encontraron módulos con los filtros actuales.',
      variant: EmptyStateVariant.noResults,
      action: AppButton.ghost(
        label: 'LIMPIAR FILTRO',
        onPressed: onClearFilter,
        size: AppButtonSize.sm,
      ),
    );
  }
}

// ─── Skeleton grid ────────────────────────────────────────────────────────────

class _StoreSkeletonGrid extends StatelessWidget {
  const _StoreSkeletonGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final formFactor = Breakpoints.of(context);
    final hPadding = Breakpoints.horizontalPadding(formFactor);
    final maxExtent = formFactor == FormFactor.mobile ? 200.0 : 320.0;

    return Padding(
      padding: EdgeInsets.only(
        left: hPadding,
        right: hPadding,
        bottom: AppDimens.space32,
      ),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: maxExtent,
          childAspectRatio: formFactor == FormFactor.mobile ? 0.6 : 0.82,
          crossAxisSpacing: AppDimens.space20,
          mainAxisSpacing: AppDimens.space20,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => const SkeletonBase(radius: AppDimens.radiusL),
      ),
    );
  }
}

// ─── Product grid ─────────────────────────────────────────────────────────────

class _StoreProductGrid extends StatelessWidget {
  final List<StoreProduct> products;

  const _StoreProductGrid({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final formFactor = Breakpoints.of(context);
    final hPadding = Breakpoints.horizontalPadding(formFactor);
    final maxExtent = formFactor == FormFactor.mobile ? 200.0 : 320.0;

    return Padding(
      padding: EdgeInsets.only(
        left: hPadding,
        right: hPadding,
        bottom: AppDimens.space32,
      ),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: maxExtent,
          childAspectRatio: formFactor == FormFactor.mobile ? 0.6 : 0.82,
          crossAxisSpacing: AppDimens.space20,
          mainAxisSpacing: AppDimens.space20,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final card = ProductCard(product: products[index]);
          if (reduced) {
            return card;
          }
          final staggerDelay = AppMotion.staggerDelay(index);
          final totalMs = AppMotion.durBase.inMilliseconds +
              staggerDelay.inMilliseconds;
          // Start of the easing window inside the combined duration.
          final intervalStart =
              (staggerDelay.inMilliseconds / totalMs).clamp(0.0, 1.0);
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: AppMotion.durBase + staggerDelay,
            curve: Interval(
              intervalStart,
              1.0,
              curve: AppMotion.easeEntrance,
            ),
            builder: (_, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 12),
                child: child,
              ),
            ),
            child: card,
          );
        },
      ),
    );
  }
}
