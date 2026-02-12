import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/billing/domain/models/card_info.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/widgets/add_card_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _DialogSubmitIntent extends Intent {
  const _DialogSubmitIntent();
}

class ManageCardsModal extends ConsumerWidget {
  const ManageCardsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billingState = ref.watch(billingProvider);

    return billingState.when(
      loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox(),
      data: (billing) {
        final cards = billing.allCards;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 16,
            right: 16,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                  decoration: const BoxDecoration(
                    color: Color(0xFF09090B),
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    border: Border.fromBorderSide(BorderSide(color: Colors.white24, width: 1)),
                    boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, 10))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "GESTIÓN DE MÉTODOS",
                                style: TextStyle(color: Colors.white54, fontFamily: 'Oxanium', fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Tus Tarjetas",
                                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.white54),
                          )
                        ],
                      ),
                      
                      const SizedBox(height: 30),

                      // LISTA DE TARJETAS
                      if (cards.isEmpty)
                         _buildEmptyState()
                      else
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: cards.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (ctx, index) {
                              final card = cards[index];
                              return _buildCardItem(context, ref, card);
                            },
                          ),
                        ),

                      const SizedBox(height: 30),

                      // BOTÓN AGREGAR
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context); 
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const AddCardModal(),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            foregroundColor: AppColors.primary,
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text("AÑADIR NUEVA TARJETA", style: TextStyle(fontFamily: 'Oxanium', fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardItem(BuildContext context, WidgetRef ref, CardInfo card) {
    final isPrimary = card.isPrimary;
    
    return InkWell(
      onTap: () {
        if (!isPrimary) {
          ref.read(billingProvider.notifier).setAsPrimary(card.id);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary ? AppColors.primary : Colors.transparent,
            width: 1.5
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 35,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8)
              ),
              child: const Icon(Icons.credit_card, color: Colors.white70, size: 20),
            ),
            const SizedBox(width: 15),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "•••• ${card.lastFour}",
                    style: TextStyle(
                      color: isPrimary ? AppColors.primary : Colors.white,
                      fontFamily: 'Courier',
                      fontSize: 16,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  Text(
                    card.brand.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                      fontFamily: 'Oxanium'
                    ),
                  )
                ],
              ),
            ),

            if (isPrimary)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                child: const Text("PRINCIPAL", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            else
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => _confirmDelete(context, ref, card.id),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        // CORRECCIÓN AQUÍ: Usamos style: BorderStyle.solid (dashed no existe en Flutter nativo)
        border: Border.all(color: Colors.white10, style: BorderStyle.solid) 
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card_off, color: Colors.white24, size: 40),
          SizedBox(height: 10),
          Text(
            "No hay métodos vinculados",
            style: TextStyle(color: Colors.white38),
          )
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String cardId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Shortcuts(
        shortcuts: const { SingleActivator(LogicalKeyboardKey.enter): _DialogSubmitIntent() },
        child: Actions(
          actions: {
            _DialogSubmitIntent: CallbackAction<_DialogSubmitIntent>(onInvoke: (_) {
              Navigator.pop(ctx, true);
              return null;
            }),
          },
          child: AlertDialog(
        backgroundColor: const Color(0xFF09090B),
        title: const Text("ELIMINAR TARJETA", style: TextStyle(color: Colors.white)),
        content: const Text("¿Estás seguro? Esta acción no se puede deshacer.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("ELIMINAR", style: TextStyle(color: Colors.red))
          ),
        ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await ref.read(billingProvider.notifier).removeCard(cardId);
    }
  }
}