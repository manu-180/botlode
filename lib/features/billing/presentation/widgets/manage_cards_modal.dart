// Archivo: lib/features/billing/presentation/widgets/manage_cards_modal.dart
import 'dart:ui';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/billing/domain/models/card_info.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/widgets/add_card_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ManageCardsModal extends ConsumerWidget {
  const ManageCardsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billingState = ref.watch(billingProvider);
    final allCards = billingState.value?.allCards ?? [];
    
    // Check si hay múltiples para mostrar el badge "Principal"
    final hasMultiple = allCards.length > 1;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderGlass),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("GESTIÓN DE MÉTODOS", style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, letterSpacing: 2.0, fontSize: 12, fontFamily: 'Courier')),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white54))
                ],
              ),
              const SizedBox(height: 20),
              
              const Text("Tus Tarjetas", style: TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'Oxanium', fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              Flexible(
                child: allCards.isEmpty 
                  ? _buildEmptyItem()
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: allCards.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) => _buildCardItem(context, ref, allCards[i], hasMultiple),
                    ),
              ),

              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); 
                    showDialog(context: context, builder: (c) => const AddCardModal()); 
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("AÑADIR NUEVA TARJETA"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardItem(BuildContext context, WidgetRef ref, CardInfo card, bool hasMultiple) {
    final isPrimary = card.isPrimary;
    
    return InkWell(
      // Si no es la principal, clickearla la convierte en principal
      onTap: !isPrimary 
        ? () => ref.read(billingProvider.notifier).setAsPrimary(card.id)
        : null, 
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary ? AppColors.primary.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1)
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPrimary ? AppColors.primary.withValues(alpha: 0.2) : Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.credit_card, color: isPrimary ? AppColors.primary : Colors.white54),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text("•••• ${card.lastFour}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Oxanium')),
                      const SizedBox(width: 10),
                      
                      // LOGICA DEL BADGE: Solo mostrar si es principal Y hay más de una tarjeta
                      if (isPrimary && hasMultiple)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                          child: const Text("PRINCIPAL", style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  Text(card.brand, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _confirmDelete(context, ref, card.id),
              icon: Icon(Icons.delete_outline, color: AppColors.error.withValues(alpha: 0.7)),
              tooltip: "Eliminar",
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyItem() {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      decoration: BoxDecoration(border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
      child: const Text("No hay métodos vinculados", style: TextStyle(color: Colors.white30)),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String cardId) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF09090B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10)),
        title: const Text("¿Eliminar método?", style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text("Esta acción no se puede deshacer.", style: TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("CANCELAR", style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              ref.read(billingProvider.notifier).removeCard(cardId);
            }, 
            child: const Text("ELIMINAR", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
}