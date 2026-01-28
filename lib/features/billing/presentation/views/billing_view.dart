// Archivo: lib/features/billing/presentation/views/billing_view.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/ui/widgets/page_title.dart';
import 'package:botslode/core/ui/widgets/skeleton_base.dart'; // IMPORTAR SKELETON
import 'package:botslode/features/billing/domain/models/card_info.dart';
import 'package:botslode/features/billing/domain/models/transaction.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/widgets/add_card_modal.dart';
import 'package:botslode/features/billing/presentation/widgets/auto_pay_settings_card.dart';
import 'package:botslode/features/billing/presentation/widgets/manage_cards_modal.dart';
import 'package:botslode/features/billing/presentation/widgets/payment_checkout_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class BillingView extends ConsumerStatefulWidget {
  static const String routeName = 'billing';

  const BillingView({super.key});

  @override
  ConsumerState<BillingView> createState() => _BillingViewState();
}

class _BillingViewState extends ConsumerState<BillingView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    print('🏦 [BILLING VIEW] initState llamado');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('🏦 [BILLING VIEW] didChangeDependencies llamado');
  }

  @override
  void dispose() {
    print('🏦 [BILLING VIEW] dispose llamado');
    _searchController.dispose();
    super.dispose();
  }

  DateTime _toArgentinaTime(DateTime utcDate) {
    return utcDate.toUtc().subtract(const Duration(hours: 3));
  }

  @override
  Widget build(BuildContext context) {
    print('🏦 [BILLING VIEW] Build ejecutándose');
    final billingState = ref.watch(billingProvider);
    print('🏦 [BILLING VIEW] Estado actual: ${billingState.runtimeType}');

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: billingState.when(
        // CAMBIO: Skeleton Avanzado en lugar de CircularProgressIndicator
        loading: () => LayoutBuilder(
          builder: (context, constraints) {
            // Decidimos qué skeleton mostrar según el ancho (Desktop/Mobile)
            if (constraints.maxWidth > 900) {
              return const _BillingSkeleton(isMobile: false);
            } else {
              return const _BillingSkeleton(isMobile: true);
            }
          },
        ),
        error: (err, stack) => Center(child: Text("ERROR: $err", style: const TextStyle(color: AppColors.error))),
        data: (billing) {
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return _buildDesktopLayout(context, billing);
              } else {
                return _buildMobileLayout(context, billing);
              }
            },
          );
        },
      ),
    );
  }

  // --- LAYOUTS --- (Sin cambios lógicos, solo visuales ya hechos)

  Widget _buildDesktopLayout(BuildContext context, BillingState billing) {
    final hasCard = billing.primaryCard != null;
    final debt = billing.totalDebt;
    
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PageTitle(
                    title: "PANEL FINANCIERO",
                    subtitle: "Control de transacciones y métodos de pago",
                    accentColor: Color(0xFF00FF88), // Verde financiero
                    style: PageTitleStyle.techBar, // Barra lateral verde
                  ),
                  const SizedBox(height: 20),
                  
                  MouseRegion(
                    cursor: debt > 0.0 ? SystemMouseCursors.click : SystemMouseCursors.basic,
                    child: GestureDetector(
                      onTap: () {
                        if (debt > 0.0) _openCheckoutModal(context, debt, billing.dollarRate);
                      },
                      child: _buildBalanceHud(debt, billing.creditLimit, billing.usagePercentage, billing.dollarRate),
                    ),
                  ),
                  
                  const SizedBox(height: 20),

                  if (hasCard)
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _showManageCardsModal(context),
                        child: _buildSciFiCreditCard(billing.primaryCard!),
                      ),
                    )
                  else 
                    _buildNoCardState(context),
                  
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          context: context,
                          label: "PAGAR AHORA",
                          icon: Icons.payments_outlined,
                          color: AppColors.primary,
                          onPressed: (debt > 0.0) ? () => _openCheckoutModal(context, debt, billing.dollarRate) : null,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildActionButton(
                          context: context,
                          label: "GESTIONAR",
                          icon: Icons.settings_input_component,
                          color: Colors.white10,
                          textColor: Colors.white,
                          onPressed: () => _showManageCardsModal(context),
                        ),
                      ),
                    ],
                  ),

                  if (hasCard) const AutoPaySettingsCard(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 40),
          Expanded(flex: 6, child: _buildHistoryPanel(billing.transactions)),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, BillingState billing) {
    final hasCard = billing.primaryCard != null;
    final debt = billing.totalDebt;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
               if (debt > 0.0) _openCheckoutModal(context, debt, billing.dollarRate);
            },
            child: _buildBalanceHud(debt, billing.creditLimit, billing.usagePercentage, billing.dollarRate),
          ),
          const SizedBox(height: 20),
          
          if (hasCard) 
             GestureDetector(
               onTap: () => _showManageCardsModal(context),
               child: _buildSciFiCreditCard(billing.primaryCard!),
             )
          else 
             _buildNoCardState(context),
             
          const SizedBox(height: 20),

          Row(
            children: [
               Expanded(
                 child: _buildActionButton(
                    context: context, label: "PAGAR", icon: Icons.payments, color: AppColors.primary,
                    onPressed: (debt > 0.0) ? () => _openCheckoutModal(context, debt, billing.dollarRate) : null
                 ),
               ),
               const SizedBox(width: 10),
               Expanded(
                 child: _buildActionButton(
                    context: context, label: "GESTIONAR", icon: Icons.settings, color: Colors.white10, textColor: Colors.white,
                    onPressed: () => _showManageCardsModal(context),
                 ),
               ),
            ],
          ),

          if (hasCard) ...[
            const SizedBox(height: 10),
            const AutoPaySettingsCard(),
          ],
          
          const SizedBox(height: 30),
          const Text("HISTORIAL", style: TextStyle(color: Colors.white54, fontFamily: 'Oxanium')),
          const SizedBox(height: 10),
          Container(
             constraints: const BoxConstraints(minHeight: 300),
             child: _buildHistoryPanel(billing.transactions, isMobile: true)
          ),
        ],
      ),
    );
  }

  Widget _buildSciFiCreditCard(CardInfo card) {
    return Container(
      width: double.infinity,
      height: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
        border: Border.all(color: Colors.white10),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30, bottom: -50,
            child: Icon(Icons.hexagon_outlined, size: 250, color: AppColors.primary.withOpacity(0.08)),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 45, height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE0C179), Color(0xFFB68D40), Color(0xFF8C6A28)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Stack(
                        children: [
                          Center(child: Container(width: 45, height: 1, color: Colors.black12)),
                          Center(child: Container(width: 1, height: 32, color: Colors.black12)),
                          Center(child: Container(width: 20, height: 15, decoration: BoxDecoration(border: Border.all(color: Colors.black12, width: 1), borderRadius: BorderRadius.circular(4)))),
                        ],
                      ),
                    ),
                    Text(card.brand.toUpperCase(), style: const TextStyle(color: Colors.white38, fontFamily: 'Oxanium', fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontFamily: 'Courier', fontSize: 24, letterSpacing: 3.0, height: 1.5),
                      children: [
                        const TextSpan(text: "**** **** **** ", style: TextStyle(color: Colors.white24)),
                        TextSpan(text: card.lastFour, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("TITULAR", style: TextStyle(color: Colors.white24, fontSize: 9, fontFamily: 'Oxanium', letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text(card.holderName.toUpperCase(), style: const TextStyle(color: Colors.white70, fontFamily: 'Oxanium', fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("VENCE", style: TextStyle(color: Colors.white24, fontSize: 9, fontFamily: 'Oxanium', letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text(card.expiryDate, style: const TextStyle(color: Colors.white70, fontFamily: 'Oxanium', fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPanel(List<BotTransaction> transactions, {bool isMobile = false}) {
    final filteredTransactions = transactions.where((tx) {
      final query = _searchQuery.toLowerCase();
      return tx.botName.toLowerCase().contains(query) || 
             tx.amount.toString().contains(query) ||
             (tx.externalPaymentId ?? '').toLowerCase().contains(query);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F13), 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: Colors.white10)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text("REGISTRO DE OPERACIONES", style: TextStyle(color: Colors.white, fontFamily: 'Oxanium', fontWeight: FontWeight.bold)), 
            ]
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(color: Colors.white, fontFamily: 'Oxanium'),
            decoration: InputDecoration(
              hintText: "Buscar por nombre o monto...",
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Colors.white24),
              filled: true,
              fillColor: Colors.black26,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10),
          isMobile 
            ? _buildGroupedList(filteredTransactions)
            : Expanded(child: _buildGroupedList(filteredTransactions))
        ],
      ),
    );
  }

  Widget _buildGroupedList(List<BotTransaction> transactions) {
    if (transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(child: Text("No se encontraron registros.", style: TextStyle(color: Colors.white24))),
      );
    }

    final Map<String, List<BotTransaction>> grouped = {};
    for (var tx in transactions) {
      final argDate = _toArgentinaTime(tx.createdAt);
      final dateKey = _getDateKey(argDate);
      if (!grouped.containsKey(dateKey)) grouped[dateKey] = [];
      grouped[dateKey]!.add(tx);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        final dateKey = grouped.keys.elementAt(index);
        final txs = grouped[dateKey]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(dateKey.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'Oxanium', fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
            ...txs.map((tx) => _buildTransactionItem(tx)),
          ],
        );
      },
    );
  }

  String _getDateKey(DateTime date) {
    final nowArg = _toArgentinaTime(DateTime.now());
    final today = DateTime(nowArg.year, nowArg.month, nowArg.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);
    if (checkDate == today) return "Hoy";
    if (checkDate == yesterday) return "Ayer";
    final months = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"];
    return "${date.day} de ${months[date.month - 1]}";
  }

  Widget _buildTransactionItem(BotTransaction tx) {
    final isPayment = tx.type.toString().contains('liquidation');
    final color = isPayment ? AppColors.success : const Color(0xFFE91E63);
    final icon = isPayment ? Icons.check_circle : Icons.bolt;
    final argDate = _toArgentinaTime(tx.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color.withOpacity(0.8), size: 18)
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.5)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.botName, style: const TextStyle(color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis),
                Text(DateFormat('HH:mm').format(argDate), style: const TextStyle(color: Colors.white24, fontSize: 10, fontFamily: 'Courier')),
              ],
            ),
          ),
          Text("${isPayment ? '-' : '+'}\$${tx.amount.toStringAsFixed(2)}", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontFamily: 'Oxanium', fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildBalanceHud(double debt, double limit, double usage, double rate) {
    final statusColor = usage > 0.9 ? AppColors.error : (usage > 0.5 ? AppColors.warning : AppColors.success);
    final arsAmount = debt * rate;
    final formatter = NumberFormat("#,##0", "es_AR");

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [statusColor.withOpacity(0.15), Colors.transparent], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("DEUDA ACTUAL ACUMULADA", style: TextStyle(color: statusColor, fontSize: 10, fontFamily: 'Oxanium', letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text("\$ ${debt.toStringAsFixed(2)} USD", style: const TextStyle(color: Colors.white, fontSize: 36, fontFamily: 'Oxanium', fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white10)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("≈ \$ ${formatter.format(arsAmount)} ARS", style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Courier', fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Container(width: 1, height: 10, color: Colors.white24),
                    const SizedBox(width: 10),
                    Text("COTIZ: \$${rate.toInt()}", style: const TextStyle(color: AppColors.primary, fontSize: 10, fontFamily: 'Oxanium', fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            ],
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(width: 70, height: 70, child: CircularProgressIndicator(value: usage, strokeWidth: 6, backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation(statusColor))),
              Text("${(usage * 100).toInt()}%", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))
            ],
          )
        ],
      ),
    );
  }

  Widget _buildNoCardState(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A1A).withOpacity(0.3),
            const Color(0xFF0A0A0A).withOpacity(0.3),
          ],
        ),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            // Ícono a la izquierda
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.error.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.lock_outline,
                color: AppColors.error.withOpacity(0.6),
                size: 32,
              )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.5)),
            ),
            const SizedBox(width: 20),
            // Contenido a la derecha
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "SISTEMA DE PAGO NO CONFIGURADO",
                    style: TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Oxanium',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Vincula un método de pago para activar autopagos y liquidación de deudas",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontFamily: 'Courier',
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _showAddCardModal(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add_card, size: 16, color: Colors.black),
                            SizedBox(width: 8),
                            Text(
                              "VINCULAR AHORA",
                              style: TextStyle(
                                color: Colors.black,
                                fontFamily: 'Oxanium',
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required BuildContext context, required String label, required IconData icon, required Color color, Color textColor = Colors.black, VoidCallback? onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: textColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Oxanium', fontSize: 12)),
    );
  }

  void _showManageCardsModal(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const ManageCardsModal());
  }

  void _showAddCardModal(BuildContext context) {
    print('🏦 [BILLING VIEW] Abriendo modal AddCardModal');
    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      backgroundColor: Colors.transparent, 
      builder: (_) => const AddCardModal()
    ).then((_) {
      print('🏦 [BILLING VIEW] Modal cerrado, retornando a BillingView');
    });
  }

  void _openCheckoutModal(BuildContext context, double amount, double rate) {
    showDialog(
      context: context,
      builder: (context) => PaymentCheckoutModal(
        amount: amount,
        exchangeRate: rate,
      ),
    );
  }
}

// --- SKELETON ESPECÍFICO DE BILLING ---
class _BillingSkeleton extends StatelessWidget {
  final bool isMobile;
  const _BillingSkeleton({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonBase(width: 250, height: 32), // Título "PANEL FINANCIERO"
        const SizedBox(height: 20),
        const SkeletonBase(width: double.infinity, height: 120, borderRadius: 20), // HUD Balance
        const SizedBox(height: 20),
        const SkeletonBase(width: double.infinity, height: 210, borderRadius: 24), // Tarjeta
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: const SkeletonBase(height: 50, borderRadius: 12)),
            const SizedBox(width: 15),
            Expanded(child: const SkeletonBase(height: 50, borderRadius: 12)),
          ],
        ),
      ],
    );

    final rightColumn = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F13), 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: Colors.white10)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBase(width: 200, height: 24),
              SkeletonBase(width: 24, height: 24, shape: BoxShape.circle),
            ],
          ),
          const SizedBox(height: 15),
          const SkeletonBase(width: double.infinity, height: 50, borderRadius: 12), // Buscador
          const SizedBox(height: 20),
          const Divider(color: Colors.white10),
          const SizedBox(height: 10),
          // Lista de transacciones fake
          ...List.generate(5, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const SkeletonBase(width: 40, height: 40, borderRadius: 8),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonBase(width: 120, height: 12),
                      const SizedBox(height: 6),
                      const SkeletonBase(width: 80, height: 10),
                    ],
                  ),
                ),
                const SkeletonBase(width: 60, height: 16),
              ],
            ),
          ))
        ],
      ),
    );

    if (isMobile) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            leftColumn,
            const SizedBox(height: 30),
            rightColumn,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 4, child: SingleChildScrollView(child: leftColumn)),
          const SizedBox(width: 40),
          Expanded(flex: 6, child: rightColumn),
        ],
      ),
    );
  }
}