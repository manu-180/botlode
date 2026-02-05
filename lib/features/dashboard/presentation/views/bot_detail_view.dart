// Archivo: lib/features/dashboard/presentation/views/bot_detail_view.dart
import 'dart:async';
import 'dart:ui';
import 'package:botslode/core/config/app_config.dart';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/providers/connectivity_provider.dart'; 
import 'package:botslode/core/ui/widgets/animated_ticker.dart';
import 'package:botslode/features/bot_engine/presentation/providers/bot_mood_provider.dart';
import 'package:botslode/features/bot_engine/presentation/widgets/bot_chat_console.dart';
import 'package:botslode/features/bot_engine/presentation/widgets/rive_bot_display.dart';
import 'package:botslode/features/bot_engine/presentation/widgets/status_indicator.dart';
import 'package:botslode/features/dashboard/domain/models/bot.dart';
import 'package:botslode/features/dashboard/presentation/providers/bots_provider.dart';
import 'package:botslode/features/dashboard/domain/exceptions/credit_limit_reached_exception.dart';
import 'package:botslode/features/dashboard/presentation/widgets/credit_limit_reached_dialog.dart';
import 'package:botslode/features/dashboard/presentation/widgets/delete_protocol_dialog.dart';
import 'package:botslode/features/dashboard/presentation/widgets/edit_color_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; 
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BotDetailView extends ConsumerStatefulWidget {
  static const String routeName = 'bot_detail';
  final String botId;

  const BotDetailView({super.key, required this.botId});

  @override
  ConsumerState<BotDetailView> createState() => _BotDetailViewState();
}

class _BotDetailViewState extends ConsumerState<BotDetailView> {
  int _selectedTab = 0; 

  // --- NOTIFICACIÓN "EPIC" ---
  void _showEpicNotify(String message) {
    OverlayState? overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.4,
        left: MediaQuery.of(context).size.width * 0.35,
        right: MediaQuery.of(context).size.width * 0.35,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          builder: (context, value, child) => Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform.scale(scale: 0.9 + (0.1 * value), child: child),
          ),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.95),
                border: Border.all(color: AppColors.primary, width: 2),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 40, spreadRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.terminal_rounded, color: AppColors.primary, size: 40),
                  const SizedBox(height: 16),
                  Text(message, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 4, fontFamily: 'Courier')),
                  const SizedBox(height: 8),
                  Text("SISTEMA ACTUALIZADO", style: TextStyle(color: AppColors.primary.withValues(alpha: 0.7), fontSize: 9, letterSpacing: 2, fontFamily: 'Courier')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    overlayState.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () => overlayEntry.remove());
  }

  void _handleEnergyToggle(BuildContext context, String botId) {
    ref.read(botsProvider.notifier).toggleStatus(botId).catchError((e, _) {
      if (e is CreditLimitReachedException && context.mounted) {
        CreditLimitReachedDialog.show(context);
      }
    });
  }

  // --- DIÁLOGOS ---
  void _showEmbedDialog(Bot bot) {
    final String embedCode = '''<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        #botlode-wrapper { position: fixed; bottom: 35px; right: 35px; z-index: 9999; }
        
        #backdrop {
            position: fixed; top: 0; left: 0; width: 100vw; height: 100vh;
            display: none; z-index: 9998;
        }

        #botlode-iframe { 
            position: absolute; 
            width: 450px; 
            height: 750px; 
            max-height: 85vh; 
            bottom: -40px; 
            right: -40px; 
            border: none; 
            transition: all 0.4s cubic-bezier(0.25, 0.8, 0.25, 1); 
            pointer-events: auto;
        }
        
        #botlode-wrapper.expanded #botlode-iframe { 
            width: 400px; 
            bottom: 0; right: 0; 
            border-radius: 28px; 
            box-shadow: 0 20px 60px rgba(0,0,0,0.5); 
        }
        body.chat-open #backdrop { display: block; }
    </style>
</head>
<body>
    <div id="backdrop"></div>
    <div id="botlode-wrapper">
        <iframe 
            id="botlode-iframe" 
            src="${AppConfig.playerBaseUrl}/?botId=${bot.id}" 
            allow="microphone; clipboard-write"
        ></iframe>
    </div>
    <script>
        const wrapper = document.getElementById('botlode-wrapper');
        const iframe = document.getElementById('botlode-iframe');
        const backdrop = document.getElementById('backdrop');

        // 1. RASTREO DE MOUSE GLOBAL (Coordenadas relativas al iframe)
        document.addEventListener('mousemove', (e) => {
            try {
                const iframeRect = iframe.getBoundingClientRect();
                const relativeX = e.clientX - iframeRect.left;
                const relativeY = e.clientY - iframeRect.top;
                iframe.contentWindow.postMessage({
                    type: 'MOUSE_MOVE',
                    x: relativeX,
                    y: relativeY
                }, '*');
            } catch (err) {}
        });
        
        document.addEventListener('mouseleave', () => {
            try {
                iframe.contentWindow.postMessage({
                    type: 'MOUSE_LEAVE'
                }, '*');
            } catch (err) {}
        });

        // 2. ESCUCHA DE EVENTOS DE FLUTTER
        window.addEventListener('message', (event) => {
            const cmd = event.data;
            if (cmd === 'CMD_CLOSE') closeChat();
            if (cmd === 'CMD_OPEN') openChat();
        });

        function openChat() {
            wrapper.classList.add('expanded');
            document.body.classList.add('chat-open');
            setTimeout(() => { 
                iframe.contentWindow.postMessage('CMD_OPEN', '*'); 
            }, 100);
        }

        function closeChat() {
            wrapper.classList.remove('expanded');
            document.body.classList.remove('chat-open');
            iframe.contentWindow.postMessage('CMD_CLOSE', '*');
        }
        
        backdrop.addEventListener('click', closeChat);
    </script>
</body>
</html>''';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("CÓDIGO DE ENLACE NEURAL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Container(
          height: 150, padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderGlass)),
          child: SingleChildScrollView(child: Text(embedCode, style: const TextStyle(color: AppColors.success, fontFamily: 'Courier', fontSize: 10))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CERRAR")),
          ElevatedButton(
            onPressed: () { Clipboard.setData(ClipboardData(text: embedCode)); Navigator.pop(context); _showEpicNotify("PROTOCOLO COPIADO"); },
            child: const Text("COPIAR PROTOCOLO"),
          ),
        ],
      ),
    );
  }

  void _showPinDialog(Bot bot) {
    final pin = bot.accessPin ?? '0000';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Icon(Icons.lock_rounded, color: AppColors.success, size: 24),
            const SizedBox(width: 12),
            const Text(
              "PIN DE ACCESO AL HISTORIAL",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Comparte este PIN con tu cliente para que pueda acceder al historial de conversaciones:",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'Courier',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Text(
                  pin,
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 32,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CERRAR", style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: pin));
              Navigator.pop(context);
              _showEpicNotify("PIN COPIADO");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.black,
            ),
            child: const Text("COPIAR PIN"),
          ),
        ],
      ),
    );
  }

  void _showEditPromptDialog(Bot bot) {
    // ⬅️ SIMPLIFICADO: Usar solo system_prompt (todo en un solo campo)
    final TextEditingController promptCtrl = TextEditingController(text: bot.systemPrompt);

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 30, spreadRadius: 2),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      "REPROGRAMACIÓN DE NÚCLEO",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Oxanium',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Modifique las directivas primarias de la unidad. Aquí defines TODO: comportamiento, personalidad, tono, estilo...",
                  style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 12),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: promptCtrl,
                  maxLines: 8,
                  style: const TextStyle(color: Colors.white, fontFamily: 'Courier', height: 1.5),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.5),
                    hintText: "Ej: 'Comportate serio y profesional' o 'Sé relajado y amigable. Responde de forma casual.'",
                    hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("CANCELAR", style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await ref.read(botsProvider.notifier).updateBotPrompt(bot.id, promptCtrl.text);
                        if (context.mounted) {
                          Navigator.pop(context);
                          _showEpicNotify("NÚCLEO REPROGRAMADO");
                        }
                      },
                      icon: const Icon(Icons.save_as_rounded),
                      label: const Text("GUARDAR DIRECTIVAS"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showWppPhoneDialog(Bot bot) {
    final TextEditingController phoneCtrl = TextEditingController(
      text: bot.telefono ?? '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.98),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF25D366).withValues(alpha: 0.15),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF25D366).withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Icon(
                          Icons.chat_rounded,
                          color: Color(0xFF25D366),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          "NÚMERO DE WHATSAPP",
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Oxanium',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Número con código de país, sin espacios ni símbolos. Ej: 1134272488",
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    autofocus: true,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Courier',
                      fontSize: 16,
                      letterSpacing: 1.5,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.5),
                      hintText: "1134272488",
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.4),
                      ),
                      prefixIcon: Icon(
                        Icons.phone_android_rounded,
                        color: const Color(0xFF25D366).withValues(alpha: 0.8),
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF25D366),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.error),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) return "El número es obligatorio.";
                      if (!RegExp(r'^[0-9]{10,15}$').hasMatch(v)) {
                        return "Solo dígitos, 10 a 15 caracteres.";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "CANCELAR",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final phone = phoneCtrl.text.trim();
                          try {
                            await ref
                                .read(botsProvider.notifier)
                                .updateWppConfig(bot.id, true, phone);
                            if (context.mounted) {
                              Navigator.pop(context);
                              _showEpicNotify("WHATSAPP CONFIGURADO");
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString().replaceFirst('Exception: ', '')),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 20),
                        label: const Text("GUARDAR NÚMERO"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditInitialMessageDialog(Bot bot) {
    final TextEditingController messageCtrl = TextEditingController(
      text: bot.initialMessage ?? 'Sistema en línea. ¿En qué puedo ayudarte hoy?'
    );

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(color: AppColors.secondary.withValues(alpha: 0.1), blurRadius: 30, spreadRadius: 2),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, color: AppColors.secondary, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      "MENSAJE INICIAL",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Oxanium',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Este es el primer mensaje que verá el usuario al iniciar una conversación con el bot.",
                  style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 12),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: messageCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontFamily: 'Courier', height: 1.5),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.5),
                    hintText: "Ej: '¡Hola! ¿En qué puedo ayudarte?' o 'Bienvenido, ¿cómo puedo asistirte hoy?'",
                    hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.secondary)),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("CANCELAR", style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final newMessage = messageCtrl.text.trim();
                        if (newMessage.isEmpty) return;
                        try {
                          await ref.read(botsProvider.notifier).updateInitialMessage(bot.id, newMessage);
                          if (context.mounted) {
                            Navigator.pop(context);
                            _showEpicNotify("MENSAJE ACTUALIZADO");
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString().replaceFirst('Exception: ', '')),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.black,
                      ),
                      icon: const Icon(Icons.save_as_rounded),
                      label: const Text("GUARDAR MENSAJE"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final botsAsync = ref.watch(botsProvider);
    final currentMoodIndex = ref.watch(terminalBotMoodProvider);
    final connectivityAsync = ref.watch(connectivityProvider);
    final isOnline = connectivityAsync.asData?.value ?? true; 

    return botsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary))),
      error: (err, stack) => Scaffold(body: Center(child: Text("ERROR DE ENLACE: $err"))),
      data: (bots) {
        final bot = bots.cast<Bot?>().firstWhere((b) => b?.id == widget.botId, orElse: () => null);
        if (bot == null) return const Scaffold(body: Center(child: Text("UNIDAD NO ENCONTRADA")));

        final isActive = bot.status == BotStatus.active;

        return MouseRegion(
          onHover: (event) {
            final screenWidth = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height;
            final double dx = event.position.dx - (screenWidth * 0.3); 
            final double dy = event.position.dy - (screenHeight * 0.5);
            ref.read(terminalPointerPositionProvider.notifier).state = Offset(dx, dy);
          },
          onExit: (_) => ref.read(terminalPointerPositionProvider.notifier).state = null,
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false, // 2. SACAR FLECHA ATRÁS
              
              title: Row(
                children: [
                  Container(
                    width: 4, height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withValues(alpha: 0.6), blurRadius: 10, spreadRadius: 1)
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // 3. NOMBRE EDITABLE (CLICK-TO-EDIT)
                  Expanded(
                    child: _EditableHeader(
                      initialName: bot.name,
                      onSave: (newName) async {
                        if (newName.trim().isNotEmpty && newName != bot.name) {
                          await ref.read(botsProvider.notifier).updateBotName(bot.id, newName.trim());
                        }
                      },
                    ),
                  ),
                ],
              ),
              
              actions: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderGlass),
                  ),
                  child: Row(
                    children: [
                      _ActionButton(
                        icon: Icons.edit_note_rounded,
                        color: AppColors.secondary,
                        tooltip: "Editar Prompt",
                        onTap: () => _showEditPromptDialog(bot),
                      ),
                      Container(width: 1, height: 20, color: AppColors.borderGlass),
                      _ActionButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        color: AppColors.secondary,
                        tooltip: "Editar Mensaje Inicial",
                        onTap: () => _showEditInitialMessageDialog(bot),
                      ),
                      Container(width: 1, height: 20, color: AppColors.borderGlass),
                      _ActionButton(
                        icon: Icons.code_rounded,
                        color: AppColors.primary,
                        tooltip: "Código Web",
                        onTap: () => _showEmbedDialog(bot),
                      ),
                      Container(width: 1, height: 20, color: AppColors.borderGlass),
                      _ActionButton(
                        icon: Icons.lock_rounded,
                        color: AppColors.success,
                        tooltip: "PIN de Acceso",
                        onTap: () => _showPinDialog(bot),
                      ),
                      Container(width: 1, height: 20, color: AppColors.borderGlass),
                      _ActionButton(
                        icon: Icons.palette_rounded,
                        color: bot.primaryColor,
                        tooltip: "Editar Color",
                        onTap: () => showDialog(
                          context: context,
                          builder: (c) => EditColorDialog(bot: bot),
                        ),
                      ),
                      Container(width: 1, height: 20, color: AppColors.borderGlass),
                      _ActionButton(
                        icon: Icons.delete_forever_rounded,
                        color: AppColors.error,
                        tooltip: "Desmantelar",
                        isDangerous: true,
                        onTap: () => showDialog(
                          context: context, 
                          builder: (c) => DeleteProtocolDialog(
                            botName: bot.name, 
                            currentBalance: bot.calculatedDebt, 
                            onConfirm: () { 
                              ref.read(botsProvider.notifier).removeBot(widget.botId); 
                              context.pop(); 
                            }
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
              ],
            ),
            body: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: bot.themeMode == 'light'
                          ? const Color(0xFFE8EAED)
                          : const Color(0xFF181818),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: bot.themeMode == 'light'
                            ? Colors.black.withValues(alpha: 0.12)
                            : AppColors.borderGlass,
                        width: 1.0,
                      ),
                      boxShadow: [
                        if (bot.themeMode == 'light')
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 28,
                            spreadRadius: -6,
                            offset: const Offset(0, 4),
                          )
                        else
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        if (bot.themeMode == 'light')
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.06),
                            blurRadius: 40,
                            spreadRadius: -8,
                            offset: Offset.zero,
                          ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const RiveBotDisplay(),
                        Positioned(
                          top: 24,
                          right: 24,
                          child: StatusIndicator(
                            isLoading: false,
                            isOnline: isOnline,
                            moodIndex: currentMoodIndex,
                            isDarkMode: bot.themeMode == 'dark',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
                    child: Column(
                      children: [
                        _SciFiSlidingTabs(
                          selectedIndex: _selectedTab,
                          onTabSelected: (index) => setState(() => _selectedTab = index),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _selectedTab == 0
                                ? _MonitorPanel(
                                    bot: bot,
                                    isActive: isActive,
                                    ref: ref,
                                    onOpenWppPhoneDialog: () => _showWppPhoneDialog(bot),
                                    onEnergyToggle: _handleEnergyToggle,
                                  )
                                : BotChatConsole(botName: bot.name, botColor: AppColors.primary, botId: bot.id),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- WIDGET DE EDICIÓN DE NOMBRE (NUEVO) ---
class _EditableHeader extends StatefulWidget {
  final String initialName;
  final ValueChanged<String> onSave;

  const _EditableHeader({required this.initialName, required this.onSave});

  @override
  State<_EditableHeader> createState() => _EditableHeaderState();
}

class _EditableHeaderState extends State<_EditableHeader> {
  late TextEditingController _ctrl;
  bool _isEditing = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialName);
  }
  
  @override
  void didUpdateWidget(covariant _EditableHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialName != oldWidget.initialName && !_isEditing) {
      _ctrl.text = widget.initialName;
    }
  }

  void _confirm() {
    widget.onSave(_ctrl.text);
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return SizedBox(
        height: 40,
        child: TextField(
          controller: _ctrl,
          focusNode: _focusNode,
          autofocus: true,
          style: const TextStyle(
            fontFamily: 'Oxanium',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          onSubmitted: (_) => _confirm(),
          onTapOutside: (_) => _confirm(),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() => _isEditing = true);
        _focusNode.requestFocus();
      },
      child: Text(
        widget.initialName.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Oxanium',
          fontSize: 22,
          fontWeight: FontWeight.w700, 
          letterSpacing: 1.5,
          color: Colors.white,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ... _ActionButton, _SciFiSlidingTabs se mantienen igual ...
class _ActionButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  final bool isDangerous; 

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
    this.isDangerous = false, 
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bgHoverColor = widget.isDangerous 
        ? widget.color.withValues(alpha: 0.25) 
        : widget.color.withValues(alpha: 0.1);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isHovered ? bgHoverColor : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: (_isHovered && widget.isDangerous)
                  ? Border.all(color: widget.color.withValues(alpha: 0.5))
                  : Border.all(color: Colors.transparent),
            ),
            child: Icon(
              widget.icon, 
              color: _isHovered ? widget.color : widget.color.withValues(alpha: 0.7),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _SciFiSlidingTabs extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _SciFiSlidingTabs({required this.selectedIndex, required this.onTabSelected});

  @override
  State<_SciFiSlidingTabs> createState() => _SciFiSlidingTabsState();
}

class _SciFiSlidingTabsState extends State<_SciFiSlidingTabs> {
  final List<GlobalKey> _keys = [GlobalKey(), GlobalKey()];
  double _indicatorLeft = 0;
  double _indicatorWidth = 0;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) => _updateIndicator());
  }

  @override
  void didUpdateWidget(covariant _SciFiSlidingTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    SchedulerBinding.instance.addPostFrameCallback((_) => _updateIndicator());
  }

  void _updateIndicator() {
    if (!mounted) return;
    final key = _keys[widget.selectedIndex];
    final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final parentRenderBox = context.findRenderObject() as RenderBox?;
      if (parentRenderBox != null) {
        final itemOffset = renderBox.localToGlobal(Offset.zero);
        final parentOffset = parentRenderBox.localToGlobal(Offset.zero);
        setState(() {
          _indicatorLeft = itemOffset.dx - parentOffset.dx;
          _indicatorWidth = renderBox.size.width;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGlass, width: 1.5),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              _buildTabItem(0, "MONITOR", Icons.monitor_heart_outlined),
              Container(width: 1, height: 30, color: AppColors.borderGlass), 
              _buildTabItem(1, "TERMINAL", Icons.terminal_rounded),
            ],
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: const Cubic(0.25, 0.8, 0.25, 1.0), 
            left: _indicatorLeft,
            width: _indicatorWidth,
            bottom: 0, 
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.6), blurRadius: 8, offset: const Offset(0, -2)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    final isSelected = widget.selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => widget.onTabSelected(index),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        child: Center(
          child: Container(
            key: _keys[index], 
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8), 
            child: Row(
              mainAxisSize: MainAxisSize.min, 
              children: [
                Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonitorPanel extends StatelessWidget {
  final Bot bot;
  final bool isActive;
  final WidgetRef ref;
  final VoidCallback? onOpenWppPhoneDialog;
  final void Function(BuildContext context, String botId)? onEnergyToggle;

  const _MonitorPanel({
    required this.bot,
    required this.isActive,
    required this.ref,
    this.onOpenWppPhoneDialog,
    this.onEnergyToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          _StatCard(title: "CICLO OPERATIVO", valueWidget: AnimatedTicker(value: bot.daysActive.toDouble(), suffix: ' DÍAS', decimals: 0), subValue: "de 30 Días", icon: Icons.calendar_today_rounded, color: AppColors.secondary, progress: bot.cycleProgress),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderGlass)),
            child: Column(
              children: [
              _ConfigSwitch(
                label: "ESTADO DE ENERGÍA",
                value: isActive,
                onChanged: (val) {
                  if (onEnergyToggle != null) {
                    onEnergyToggle!(context, bot.id);
                  } else {
                    ref.read(botsProvider.notifier).toggleStatus(bot.id);
                  }
                },
                activeText: "ACTIVADO",
                inactiveText: "DESACTIVADO",
                activeColor: AppColors.success,
              ),
              const Divider(height: 32, color: AppColors.borderGlass),
              _ConfigSwitch(
                label: "AVISO DE CONEXIÓN", 
                value: bot.showOfflineAlert, 
                onChanged: (val) => ref.read(botsProvider.notifier).updateOfflineAlert(bot.id, val), 
                activeText: "NOTIFICAR", 
                inactiveText: "SILENCIADO", 
                activeColor: AppColors.success
              ),
              const Divider(height: 32, color: AppColors.borderGlass),
              _ConfigSwitch(
                label: "MODO DE INTERFAZ", 
                value: bot.themeMode == 'light', 
                onChanged: (val) => ref.read(botsProvider.notifier).updateThemeMode(bot.id, val ? 'light' : 'dark'), 
                activeText: "MODO CLARO", 
                inactiveText: "MODO OSCURO", 
                activeColor: Colors.white,
                activeIcon: Icons.wb_sunny_rounded,
                inactiveIcon: Icons.nightlight_round,
              ),
              const Divider(height: 32, color: AppColors.borderGlass),
              _WppSection(
                bot: bot,
                ref: ref,
                onOpenWppPhoneDialog: onOpenWppPhoneDialog,
              ),
              const Divider(height: 32, color: AppColors.borderGlass),
              _BubbleSizeSlider(
                bot: bot,
                ref: ref,
              ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WppSection extends StatelessWidget {
  final Bot bot;
  final WidgetRef ref;
  final VoidCallback? onOpenWppPhoneDialog;

  const _WppSection({
    required this.bot,
    required this.ref,
    this.onOpenWppPhoneDialog,
  });

  static const Color _wppGreen = Color(0xFF25D366);

  Future<void> _onWppSwitchChanged(bool value) async {
    final notifier = ref.read(botsProvider.notifier);
    if (value) {
      final hasPhone = bot.telefono != null && bot.telefono!.trim().isNotEmpty;
      if (!hasPhone) {
        onOpenWppPhoneDialog?.call();
        return;
      }
      await notifier.updateWppConfig(bot.id, true, bot.telefono);
    } else {
      await notifier.updateWppConfig(bot.id, false, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ConfigSwitch(
          label: "BURBUJA WHATSAPP",
          value: bot.wpp,
          onChanged: _onWppSwitchChanged,
          activeText: "VISIBLE",
          inactiveText: "OCULTA",
          activeColor: _wppGreen,
          activeIcon: Icons.chat_rounded,
          inactiveIcon: Icons.chat_bubble_outline_rounded,
        ),
        if (bot.wpp) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _wppGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _wppGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.phone_android_rounded, color: _wppGreen.withValues(alpha: 0.9), size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    bot.telefono ?? "—",
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Courier',
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onOpenWppPhoneDialog,
                  style: TextButton.styleFrom(
                    foregroundColor: _wppGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text("EDITAR", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// --- CONFIG SWITCH REFACTORIZADO PARA SOPORTAR ICONOS ---
class _BubbleSizeSlider extends StatefulWidget {
  final Bot bot;
  final WidgetRef ref;

  const _BubbleSizeSlider({
    required this.bot,
    required this.ref,
  });

  @override
  State<_BubbleSizeSlider> createState() => _BubbleSizeSliderState();
}

class _BubbleSizeSliderState extends State<_BubbleSizeSlider> {
  late double _currentSize;
  Timer? _debounceTimer;

  static const double _minSize = 60.0;
  static const double _maxSize = 100.0;

  @override
  void initState() {
    super.initState();
    _currentSize = widget.bot.bubbleSize.clamp(_minSize, _maxSize);
  }

  @override
  void didUpdateWidget(_BubbleSizeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bot.bubbleSize != oldWidget.bot.bubbleSize) {
      _currentSize = widget.bot.bubbleSize.clamp(_minSize, _maxSize);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSizeChanged(double value) {
    setState(() => _currentSize = value);
    
    // Debounce: solo guardar en BD después de 500ms sin cambios
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      widget.ref.read(botsProvider.notifier).updateBubbleSize(widget.bot.id, value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.circle_outlined, color: AppColors.primary.withValues(alpha: 0.8), size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "TAMAÑO DE BURBUJAS",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                "${_currentSize.round()}px",
                style: TextStyle(
                  color: AppColors.primary,
                  fontFamily: 'Courier',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary.withValues(alpha: 0.8),
            inactiveTrackColor: AppColors.borderGlass,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: _currentSize,
            min: _minSize,
            max: _maxSize,
            divisions: 40,
            onChanged: _onSizeChanged,
          ),
        ),
      ],
    );
  }
}

class _ConfigSwitch extends StatelessWidget {
  final String label; 
  final bool value; 
  final ValueChanged<bool> onChanged; 
  final String activeText; 
  final String inactiveText; 
  final Color activeColor;
  final IconData? activeIcon;
  final IconData? inactiveIcon;

  const _ConfigSwitch({
    required this.label, 
    required this.value, 
    required this.onChanged, 
    required this.activeText, 
    required this.inactiveText, 
    required this.activeColor,
    this.activeIcon,
    this.inactiveIcon,
  });

  @override 
  Widget build(BuildContext context) { 
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)), 
            const SizedBox(height: 4), 
            Row(
              children: [
                if (value && activeIcon != null) ...[
                  Icon(activeIcon, color: activeColor, size: 16),
                  const SizedBox(width: 8),
                ],
                if (!value && inactiveIcon != null) ...[
                  Icon(inactiveIcon, color: AppColors.textSecondary, size: 16),
                  const SizedBox(width: 8),
                ],
                Text(
                  value ? activeText : inactiveText, 
                  style: TextStyle(
                    color: value ? activeColor : AppColors.textSecondary, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 16
                  )
                ),
              ],
            )
          ]
        ), 
        Switch(
          value: value, 
          activeColor: activeColor, 
          onChanged: onChanged
        )
      ]
    ); 
  }
}

class _StatCard extends StatelessWidget {
  final String title; final Widget valueWidget; final String subValue; final IconData icon; final Color color; final double progress;
  const _StatCard({required this.title, required this.valueWidget, required this.subValue, required this.icon, required this.color, required this.progress});
  @override Widget build(BuildContext context) { return Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: AppColors.surface.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderGlass)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 8), Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold))]), const SizedBox(height: 16), Row(crossAxisAlignment: CrossAxisAlignment.end, children: [valueWidget, const SizedBox(width: 8), Text(subValue, style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7)))]), const SizedBox(height: 16), LinearProgressIndicator(value: progress, backgroundColor: Colors.black, color: color, minHeight: 6)])); }
}