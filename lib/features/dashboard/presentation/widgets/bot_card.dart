// Archivo: lib/features/dashboard/presentation/widgets/bot_card.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/dashboard/domain/models/bot.dart';
import 'package:botslode/features/dashboard/presentation/widgets/rive_bot_card_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BotCard extends StatefulWidget {
  final Bot bot;
  final VoidCallback onTap;

  const BotCard({super.key, required this.bot, required this.onTap});

  @override
  State<BotCard> createState() => _BotCardState();
}

class _BotCardState extends State<BotCard> {
  bool _isHovered = false;
  Offset? _localMousePos; 

  @override
  Widget build(BuildContext context) {
    // --- LÓGICA VISUAL DE ESTADOS ---
    final isActive = widget.bot.status == BotStatus.active;
    final isSuspended = widget.bot.status == BotStatus.creditSuspended;
    
    Color statusColor;
    String statusText;

    if (isActive) {
      statusColor = AppColors.success;
      statusText = "ACTIVE";
    } else if (isSuspended) {
      statusColor = const Color(0xFFFF8800); // Naranja alerta
      statusText = "SUSPENDED";
    } else {
      statusColor = AppColors.error; // Rojo
      statusText = "OFFLINE";
    }

    return MouseRegion(
      // ... (Resto de la lógica de mouse region igual) ...
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() { _isHovered = false; _localMousePos = null; }),
      onHover: (event) => setState(() => _localMousePos = event.localPosition),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered 
                  ? widget.bot.primaryColor.withValues(alpha: 0.6) 
                  : AppColors.borderGlass,
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.bot.primaryColor.withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: Stack(
            children: [
              // ... (Gradiente de fondo igual) ...
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withValues(alpha: 0.02), Colors.transparent]))),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RiveBotCardDisplay(
                          primaryColor: widget.bot.primaryColor,
                          cycleProgress: widget.bot.cycleProgress,
                          pointerLocalPos: _localMousePos, 
                        ),
                        
                        // BADGE DE ESTADO DINÁMICO
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, size: 8, color: statusColor)
                                .animate(onPlay: (c) => c.repeat(reverse: true)) 
                                .fade(duration: 1000.ms, curve: Curves.easeInOut, begin: 0.2, end: 1.0),
                              
                              const SizedBox(width: 6),
                              
                              Text(
                                statusText, // TEXTO DINÁMICO (ACTIVE / SUSPENDED / OFFLINE)
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // ... (Resto de textos igual) ...
                    Text(widget.bot.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(widget.bot.description ?? "Unidad de propósito general.", style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7), fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 12),
                    Text("ID: ${widget.bot.id}", style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.3), fontFamily: 'Courier', fontSize: 9)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}