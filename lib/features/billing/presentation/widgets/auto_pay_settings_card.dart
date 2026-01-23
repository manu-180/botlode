// Archivo: lib/features/billing/presentation/widgets/auto_pay_settings_card.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AutoPaySettingsCard extends ConsumerStatefulWidget {
  const AutoPaySettingsCard({super.key});

  @override
  ConsumerState<AutoPaySettingsCard> createState() => _AutoPaySettingsCardState();
}

class _AutoPaySettingsCardState extends ConsumerState<AutoPaySettingsCard> {
  bool _isExpanded = false;
  
  // Valor temporal del slider (visual)
  double _tempLimit = 0.0;
  bool _hasChanges = false;

  // Bandera para inicialización única
  bool _isInit = false;

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingProvider);

    return billingState.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (billing) {
        if (billing.primaryCard == null) return const SizedBox.shrink();

        // 1. Sincronización Inicial (Solo la primera vez o al cerrar y reabrir para resetear)
        if (!_isInit && !_isExpanded) {
          final dbVal = billing.primaryCard!.autoPayThreshold;
          // Si está en 0 (inactivo), ponemos el slider visualmente en 20 para empezar a configurar
          _tempLimit = dbVal > 0 ? dbVal : 20.0; 
          _isInit = true;
        }

        // Límites Lógicos del Slider
        final double maxLimit = billing.creditLimit;
        const double minLimit = 20.0;

        // Corrección de rango visual (por si bajó el límite de crédito)
        if (_tempLimit > maxLimit) _tempLimit = maxLimit;
        if (_tempLimit < minLimit) _tempLimit = minLimit;

        // Estado Real en Base de Datos
        final double currentDbValue = billing.primaryCard!.autoPayThreshold;
        final bool isSystemActive = currentDbValue > 0;
        final Color statusColor = isSystemActive ? AppColors.primary : AppColors.textSecondary;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutExpo,
          margin: const EdgeInsets.only(top: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F13),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isExpanded 
                  ? AppColors.primary.withOpacity(0.5) 
                  : Colors.white.withOpacity(0.1),
              width: 1
            ),
            boxShadow: [
              if (_isExpanded || isSystemActive)
                BoxShadow(
                  color: statusColor.withOpacity(0.05),
                  blurRadius: 20,
                  spreadRadius: 2
                )
            ]
          ),
          child: Column(
            children: [
              // --- HEADER (SIEMPRE VISIBLE) ---
              InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                    if (!_isExpanded) {
                      _isInit = false; // Resetear al cerrar para leer DB de nuevo la próxima
                      _hasChanges = false;
                    }
                  });
                },
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(16),
                  bottom: Radius.circular(_isExpanded ? 0 : 16)
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Icono de Estado
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSystemActive ? Icons.bolt : Icons.bolt_outlined, 
                          color: statusColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Textos Informativos
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "PROTOCOLO DE AUTOPAGO",
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Oxanium',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                fontSize: 14
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isSystemActive 
                                ? "ACTIVO • LÍMITE: \$${currentDbValue.toStringAsFixed(0)} USD"
                                : "SISTEMA EN ESPERA (MANUAL)",
                              style: TextStyle(
                                color: statusColor.withOpacity(0.8),
                                fontSize: 11,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Flecha Animada
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white.withOpacity(0.5)),
                      ),
                    ],
                  ),
                ),
              ),

              // --- BODY DESPLEGABLE (CONFIGURACIÓN) ---
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutExpo,
                child: _isExpanded 
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05)))
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          
                          // 1. VISUALIZADOR DE LÍMITE
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text("DEFINIR LÍMITE", style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.0)),
                              Text(
                                "\$${_tempLimit.toStringAsFixed(0)} USD",
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  fontFamily: 'Oxanium'
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),

                          // 2. SLIDER
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.primary,
                              inactiveTrackColor: Colors.white10,
                              thumbColor: Colors.white,
                              overlayColor: AppColors.primary.withOpacity(0.2),
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                            ),
                            child: Slider(
                              value: _tempLimit,
                              min: minLimit,
                              max: maxLimit,
                              // Saltos limpios de 10 en 10 aprox
                              divisions: (maxLimit - minLimit) ~/ 10 > 0 
                                  ? (maxLimit - minLimit) ~/ 10 
                                  : 1, 
                              onChanged: (val) {
                                setState(() {
                                  _tempLimit = val;
                                  // Habilitamos el botón de guardar si cambió respecto a la DB
                                  _hasChanges = _tempLimit != currentDbValue;
                                });
                              },
                            ),
                          ),
                          
                          // Etiquetas de rango
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("\$${minLimit.toInt()}", style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
                                Text("\$${maxLimit.toInt()}", style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // 3. ACCIONES
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // BOTÓN DESACTIVAR (Solo si está activo en DB)
                              if (isSystemActive)
                                TextButton(
                                  onPressed: () async {
                                    await ref.read(billingProvider.notifier).updateAutoPayThreshold(0.0);
                                    if (mounted) setState(() => _isExpanded = false);
                                  },
                                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                                  child: const Text("DESACTIVAR", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              
                              if (isSystemActive) const SizedBox(width: 16),

                              // BOTÓN CANCELAR
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isExpanded = false;
                                    _isInit = false; // Resetear
                                    _hasChanges = false;
                                  });
                                },
                                child: Text("CANCELAR", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                              ),
                              
                              const SizedBox(width: 16),
                              
                              // BOTÓN CONFIRMAR
                              ElevatedButton(
                                onPressed: _hasChanges 
                                  ? () async {
                                      // GUARDA EL VALOR DEL SLIDER EN LA DB
                                      await ref.read(billingProvider.notifier)
                                          .updateAutoPayThreshold(_tempLimit);
                                      
                                      if (mounted) {
                                        setState(() {
                                          _isExpanded = false;
                                          _hasChanges = false;
                                        });
                                      }
                                    }
                                  : null, 
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.black,
                                  disabledBackgroundColor: Colors.white.withOpacity(0.1),
                                  disabledForegroundColor: Colors.white.withOpacity(0.3),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                child: const Text("CONFIRMAR LÍMITE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Oxanium')),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}