// lib/features/dashboard/presentation/widgets/dashboard_empty_states.dart
// Dos estados vacíos diferenciados para la grilla del Dashboard:
//   · DashboardEmptyBay       — bahía sin unidades (cuenta real = 0, sin filtro/búsqueda)
//   · DashboardEmptyNoResults — hay bots pero el filtro/búsqueda no da resultados
import 'package:botslode/core/ui/buttons/app_button.dart';
import 'package:botslode/core/ui/widgets/empty_state.dart';
import 'package:flutter/material.dart';

// ─── Empty A: bahía sin unidades ─────────────────────────────────────────────

class DashboardEmptyBay extends StatelessWidget {
  const DashboardEmptyBay({super.key, required this.onAssemble});

  final VoidCallback onAssemble;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.precision_manufacturing_outlined,
      title: 'NO HAY UNIDADES EN LA BAHÍA',
      description:
          'Ensamblá tu primera unidad autónoma para comenzar a operar.',
      variant: EmptyStateVariant.neutral,
      action: AppButton.primary(
        label: 'ENSAMBLAR PRIMERA UNIDAD',
        leadingIcon: Icons.add_rounded,
        onPressed: onAssemble,
      ),
    );
  }
}

// ─── Empty B: filtro/búsqueda sin resultados ──────────────────────────────────

class DashboardEmptyNoResults extends StatelessWidget {
  const DashboardEmptyNoResults({
    super.key,
    required this.onClear,
    this.query,
  });

  final VoidCallback onClear;

  /// Query de texto activa, si la hay — se incluye en la descripción.
  final String? query;

  String get _description {
    final q = query?.trim();
    if (q != null && q.isNotEmpty) {
      return 'Ninguna unidad coincide con la búsqueda "$q" o el filtro activo.';
    }
    return 'Ninguna unidad coincide con el filtro o la búsqueda actual.';
  }

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off_rounded,
      title: 'SIN COINCIDENCIAS',
      description: _description,
      variant: EmptyStateVariant.noResults,
      action: AppButton.ghost(
        label: 'LIMPIAR BÚSQUEDA',
        leadingIcon: Icons.close_rounded,
        onPressed: onClear,
      ),
    );
  }
}
