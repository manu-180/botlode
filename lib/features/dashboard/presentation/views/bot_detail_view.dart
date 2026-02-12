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
import 'package:botslode/features/dashboard/presentation/widgets/credit_limit_reached_dialog.dart';
import 'package:botslode/features/dashboard/presentation/widgets/delete_protocol_dialog.dart';
import 'package:botslode/features/dashboard/presentation/widgets/edit_color_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; 
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Intent para que Enter dispare la acción principal en diálogos.
class _DialogSubmitIntent extends Intent {
  const _DialogSubmitIntent();
}

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
    ref.read(botsProvider.notifier).toggleStatus(botId).then((success) {
      if (!success && context.mounted) {
        CreditLimitReachedDialog.show(context);
      }
    });
  }

  // --- DIÁLOGOS ---
  /// Código completo del embed (igual que botlode_web / APEX): iframe + hitzones + script.
  void _showEmbedDialog(Bot bot) {
    final String baseUrl = AppConfig.playerBaseUrl;
    final String botId = bot.id;
    final String embedCode = '''
  <!-- BotLode - Burbuja flotante embebida -->
  <!-- Pegar antes del </body> en cualquier HTML -->

  <style>
    #botlode-player {
      background: none !important;
      background-color: transparent !important;
      -webkit-background-color: transparent !important;
      touch-action: manipulation !important;
      -webkit-tap-highlight-color: transparent !important;
    }
  </style>

  <link rel="preconnect" href="$baseUrl">
  <link rel="dns-prefetch" href="$baseUrl">

  <iframe
    id="botlode-player"
    src="$baseUrl?botId=$botId&v=2.5"
    style="
      position: fixed;
      bottom: 16px;
      right: 16px;
      width: 150px;
      height: 150px;
      border: none;
      z-index: 100001;
      pointer-events: auto;
      background: transparent !important;
      opacity: 0;
      will-change: width, height;
      transform: translateZ(0);
      touch-action: manipulation;
    "
    allow="clipboard-write"
    loading="lazy"
    allowtransparency="true">
  </iframe>

  <div id="botlode-hitzone-bot" style="
    position: fixed;
    bottom: 28px;
    right: 28px;
    width: 100px;
    height: 100px;
    z-index: 100002;
    pointer-events: none;
    cursor: pointer;
    border-radius: 50%;
    display: none;
  "></div>

  <div id="botlode-hitzone-wpp" style="
    position: fixed;
    bottom: 168px;
    right: 28px;
    width: 100px;
    height: 100px;
    z-index: 100002;
    pointer-events: none;
    cursor: pointer;
    border-radius: 50%;
    display: none;
  "></div>

  <script>
  (function() {
    console.log('🎯 IFRAME SCRIPT v3.0 - pointer-events: auto permanente, taps directos a Flutter');
    const iframe = document.getElementById('botlode-player');
    const hitzoneBotEl = document.getElementById('botlode-hitzone-bot');
    const hitzoneWppEl = document.getElementById('botlode-hitzone-wpp');
    if (!iframe) return;

    let isExpanded = false;
    let isOpening = false; // ⬅️ Evita carreras visuales durante apertura
    let isAnimatingBubble = false;
    let botDisabled = false;
    const BUBBLE_HEIGHT_SOLO_BOT = 150;
    const BUBBLE_HEIGHT_WITH_WPP = 290;
    const BUBBLE_HEIGHT_OFF = 0;
    const BUBBLE_WIDTH_SOLO_BOT = 150;
    const BUBBLE_WIDTH_WITH_WPP = 140;
    let bubbleHeight = BUBBLE_HEIGHT_SOLO_BOT;
    let bubbleWidth = BUBBLE_WIDTH_SOLO_BOT;
    let iframeReady = false;
    let justClosedTimestamp = 0; // ⬅️ Para bloquear comandos justo después de cerrar
    let firstOpenWarmupDone = false; // ⬅️ Oculta glitch del primer render
    const FIRST_OPEN_REVEAL_DELAY_MS = 45;
    let firstOpenLayoutPrimed = false; // ⬅️ Precalentamiento de layout (open->close oculto)

    // ⬅️ PROTECCIÓN MÁXIMA: Guardamos el estado expandido del iframe
    let expandedStyleCache = null;
    
    function cacheExpandedStyle() {
      if (isExpanded) {
        expandedStyleCache = {
          width: iframe.style.width,
          height: iframe.style.height,
          left: iframe.style.left,
          top: iframe.style.top,
          right: iframe.style.right,
          bottom: iframe.style.bottom
        };
        console.log('💾 Cache de estilo expandido guardado:', expandedStyleCache);
      }
    }
    
    function restoreExpandedStyle() {
      if (isExpanded && expandedStyleCache) {
        console.log('🔄 Restaurando estilo expandido desde cache');
        iframe.style.transition = 'none';
        Object.keys(expandedStyleCache).forEach(function(key) {
          iframe.style[key] = expandedStyleCache[key];
        });
        iframe.offsetHeight;
        iframe.style.transition = '';
      }
    }

    function activateIframe(source) {
      if (iframeReady) return;
      console.log('✅ BotLode Player LISTO (' + source + ') - Activando iframe con pointer-events: auto');
      iframeReady = true;
      
      // ⬅️ CAMBIO ARQUITECTURAL v3: El iframe pasa a pointer-events: auto PERMANENTE.
      // Flutter maneja los taps DIRECTAMENTE (GestureDetector en la burbuja).
      iframe.style.pointerEvents = 'auto';
      
      // ⬅️ Desactivar hitzones: ya no son necesarias como intermediario.
      if (hitzoneBotEl) {
        hitzoneBotEl.style.pointerEvents = 'none';
        hitzoneBotEl.style.display = 'none';
      }
      if (hitzoneWppEl) {
        hitzoneWppEl.style.pointerEvents = 'none';
        hitzoneWppEl.style.display = 'none';
      }
      
      // ⬅️ Fade-in del iframe (estaba oculto con opacity:0 para evitar flash blanco)
      iframe.style.transition = 'opacity 0.3s ease-out';
      iframe.style.opacity = '1';
      setTimeout(function() {
        iframe.style.transition = '';
        primeFirstOpenLayout();
      }, 350);
    }

    function isNarrowScreen() {
      return window.innerWidth < 600;
    }

    function applyBubblePosition() {
      // ⬅️ PROTECCIÓN: No cambiar a tamaño burbuja si el chat está expandido
      if (isExpanded) {
        console.warn('⚠️ applyBubblePosition() ignorado: el chat está expandido');
        return;
      }
      
      iframe.style.left = 'auto';
      iframe.style.top = 'auto';
      iframe.style.right = '16px';
      iframe.style.bottom = '16px';
      iframe.style.width = bubbleWidth + 'px';
      iframe.style.height = bubbleHeight + 'px';
    }

    function primeFirstOpenLayout() {
      if (firstOpenLayoutPrimed) return;
      firstOpenLayoutPrimed = true;

      // Precalentar layout de chat abierto en oculto para evitar
      // el frame glitch (flash arriba-izquierda) del primer CMD_OPEN.
      const prevTransition = iframe.style.transition;
      const prevVisibility = iframe.style.visibility;
      const prevOpacity = iframe.style.opacity;
      const prevFilter = iframe.style.filter;
      const prevTransform = iframe.style.transform;

      iframe.style.transition = 'none';
      iframe.style.visibility = 'hidden';
      iframe.style.opacity = '0';
      iframe.style.filter = '';
      iframe.style.transform = 'translateZ(0)';

      if (isNarrowScreen()) {
        iframe.style.left = '0';
        iframe.style.top = '0';
        iframe.style.right = '0';
        iframe.style.bottom = '0';
        iframe.style.width = '100%';
        iframe.style.height = '100%';
      } else {
        iframe.style.left = 'auto';
        iframe.style.top = 'auto';
        iframe.style.right = '16px';
        iframe.style.bottom = '16px';
        iframe.style.width = '450px';
        iframe.style.height = 'calc(100vh - 32px)';
      }
      iframe.offsetHeight;

      applyBubblePosition();
      iframe.offsetHeight;

      iframe.style.transition = prevTransition || 'none';
      iframe.style.visibility = prevVisibility || 'visible';
      iframe.style.opacity = prevOpacity || '1';
      iframe.style.filter = prevFilter || '';
      iframe.style.transform = prevTransform || 'translateZ(0)';
      console.log('🧊 First-open layout primed');
    }

    const T = {
      closeFadeOut: 120,
      closeWaitChat: 380,
      pauseBeforeEntrance: 100,
      entranceDelay: 60,
      entranceMain: 380,
      entranceBounce2: 180,
      entranceSettle: 120,
      resetAfter: 80
    };

    function animateBubbleEntrance() {
      isAnimatingBubble = true;
      iframe.style.opacity = '0';
      iframe.style.transform = 'translateZ(0) scale(0.3) rotate(-15deg)';
      iframe.style.filter = 'blur(8px) brightness(2)';

      setTimeout(function() {
        iframe.style.transition = 'opacity ' + (T.entranceMain * 0.4) + 'ms cubic-bezier(0.34, 1.56, 0.64, 1), transform ' + T.entranceMain + 'ms cubic-bezier(0.34, 1.56, 0.64, 1), filter ' + (T.entranceMain * 0.5) + 'ms ease-out';
        requestAnimationFrame(function() {
          iframe.style.opacity = '1';
          iframe.style.transform = 'translateZ(0) scale(1.1) rotate(3deg)';
          iframe.style.filter = 'blur(0px) brightness(1.3)';
        });

        setTimeout(function() {
          iframe.style.transition = 'transform ' + T.entranceBounce2 + 'ms cubic-bezier(0.25, 0.46, 0.45, 0.94), filter ' + T.entranceBounce2 + 'ms ease-out';
          iframe.style.transform = 'translateZ(0) scale(0.95) rotate(-1deg)';
          iframe.style.filter = 'blur(0px) brightness(1.1)';

          setTimeout(function() {
            iframe.style.transition = 'transform ' + T.entranceSettle + 'ms ease-out, filter ' + T.entranceSettle + 'ms ease-out';
            iframe.style.transform = 'translateZ(0) scale(1) rotate(0deg)';
            iframe.style.filter = 'blur(0px) brightness(1)';
            setTimeout(function() {
              iframe.style.transition = '';
              iframe.style.filter = '';
              isAnimatingBubble = false;
              console.log('✨ Animación de burbuja completada');
            }, T.resetAfter);
          }, T.entranceBounce2 * 0.6);
        }, T.entranceMain);
      }, T.entranceDelay);
    }

    window.addEventListener('message', function(event) {
      const data = event.data;
      
      // ⬅️ Log detallado de todos los comandos para debug
      if (typeof data === 'string' && data.startsWith('CMD_')) {
        console.log('📨 Comando recibido:', data, '| isExpanded:', isExpanded, '| botDisabled:', botDisabled);
      }
      
      // ⬅️ PROTECCIÓN: Bloquear comandos que cambien tamaño cuando está expandido
      if ((isExpanded || isOpening) && (data === 'CMD_WPP_VISIBLE' || data === 'CMD_WPP_HIDDEN')) {
        console.warn('⚠️ Comando', data, 'bloqueado: chat está expandido');
        return; // Ignorar estos comandos cuando está expandido
      }
      
      // ⬅️ PROTECCIÓN: Bloquear comandos problemáticos justo después de cerrar
      const timeSinceClose = Date.now() - justClosedTimestamp;
      if (justClosedTimestamp > 0 && timeSinceClose < 500 && 
          (data === 'CMD_WPP_VISIBLE' || data === 'CMD_WPP_HIDDEN' || data === 'CMD_OPEN')) {
        console.warn('⚠️ Comando', data, 'bloqueado: acabamos de cerrar hace', timeSinceClose, 'ms');
        return;
      }
      
      if (data === 'CMD_READY') {
        activateIframe('CMD_READY');
        return;
      }
      
      if (data === 'CMD_BOT_DISABLED') {
        botDisabled = true;
        isExpanded = false; // ⬅️ Resetear estado expandido
        bubbleHeight = BUBBLE_HEIGHT_OFF;
        iframe.style.transition = 'height 0.25s ease-out, width 0.25s ease-out, opacity 0.25s ease-out';
        iframe.style.height = '0px';
        iframe.style.width = '0px';
        iframe.style.minWidth = '0px';
        iframe.style.minHeight = '0px';
        iframe.style.opacity = '0';
        iframe.style.pointerEvents = 'none';
        iframe.style.visibility = 'hidden';
        iframe.style.overflow = 'hidden';
        iframe.style.display = 'none';
        if (hitzoneBotEl) { hitzoneBotEl.style.display = 'none'; }
        if (hitzoneWppEl) { hitzoneWppEl.style.display = 'none'; }
        return;
      }
      
      if (data === 'CMD_BOT_ENABLED') {
        // ⬅️ SOLO procesar si el bot estaba realmente deshabilitado
        if (botDisabled) {
          console.log('🔄 CMD_BOT_ENABLED - Reactivando bot desde modo REALMENTE deshabilitado');
          botDisabled = false;
          isExpanded = false; // ⬅️ Resetear SOLO si venía de deshabilitado
          bubbleHeight = BUBBLE_HEIGHT_SOLO_BOT;
          bubbleWidth = BUBBLE_WIDTH_SOLO_BOT;
          iframe.style.display = '';
          iframe.style.visibility = '';
          iframe.style.overflow = '';
          iframe.style.minWidth = '';
          iframe.style.minHeight = '';
          iframe.style.transition = 'height 0.25s ease-out, width 0.25s ease-out, opacity 0.25s ease-out';
          iframe.style.width = bubbleWidth + 'px';
          iframe.style.height = bubbleHeight + 'px';
          iframe.style.opacity = '1';
          if (iframeReady) iframe.style.pointerEvents = 'auto';
          applyBubblePosition(); // Ahora respeta isExpanded
        } else {
          console.log('⚠️ CMD_BOT_ENABLED ignorado: el bot ya estaba habilitado (isExpanded=' + isExpanded + ')');
        }
        return;
      }
      
      if (data === 'CMD_OPEN') {
        if (botDisabled) return;
        if (!isExpanded && !isOpening) {
          console.log('🚀 CMD_OPEN recibido - Expandiendo iframe');
          isOpening = true;
          isExpanded = true; // marcar temprano para bloquear CMD_WPP_* durante apertura
          isAnimatingBubble = false;
          
          // Usar la misma secuencia estable que index.html
          iframe.style.filter = '';
          iframe.style.transform = 'translateZ(0)';
          iframe.style.transition = 'none';
          iframe.style.opacity = '0';
          const isFirstOpen = !firstOpenWarmupDone;
          if (isFirstOpen) {
            // Blindaje corto SOLO en primera apertura para tapar el frame fantasma
            iframe.style.visibility = 'hidden';
            iframe.style.clipPath = 'inset(100% 100% 100% 100%)';
            iframe.style.webkitClipPath = 'inset(100% 100% 100% 100%)';
          }

          if (isNarrowScreen()) {
            iframe.style.left = '0';
            iframe.style.top = '0';
            iframe.style.right = '0';
            iframe.style.bottom = '0';
            iframe.style.width = '100%';
            iframe.style.height = '100%';
          } else {
            iframe.style.left = 'auto';
            iframe.style.top = 'auto';
            iframe.style.right = '16px';
            iframe.style.bottom = '16px';
            iframe.style.width = '450px';
            iframe.style.height = 'calc(100vh - 32px)';
          }

          iframe.offsetHeight;

          const revealDelay = isFirstOpen ? FIRST_OPEN_REVEAL_DELAY_MS : 0;
          setTimeout(function() {
            requestAnimationFrame(function() {
              requestAnimationFrame(function() {
                iframe.style.transition = 'opacity 100ms ease-out';
                if (isFirstOpen) {
                  iframe.style.visibility = 'visible';
                  iframe.style.clipPath = 'none';
                  iframe.style.webkitClipPath = 'none';
                }
                iframe.style.opacity = '1';
                setTimeout(function() {
                  iframe.style.transition = 'none';
                  isOpening = false;
                }, 150);
              });
            });
          }, revealDelay);
          firstOpenWarmupDone = true;
          
          // ⬅️ Guardar el estilo expandido en cache
          setTimeout(cacheExpandedStyle, 50);
        }
      } else if (data === 'CMD_CLOSE') {
        if (botDisabled) return;
        if (isExpanded) {
          console.log('🎭 CMD_CLOSE recibido - Cerrando con animación de burbuja');

          // Marcar cierre inmediatamente para que protecciones/estados sean consistentes
          isExpanded = false;
          isOpening = false;
          expandedStyleCache = null;
          justClosedTimestamp = Date.now();
          isAnimatingBubble = false;

          // Limpiar residuos visuales del chat y hacer fade-out corto
          iframe.style.filter = 'none';
          iframe.style.transform = 'none';
          iframe.style.transition = 'opacity ' + (T.closeFadeOut / 1000) + 's ease-out';
          iframe.style.opacity = '0';

          // Pasar a tamaño burbuja y ejecutar la animación épica de entrada
          setTimeout(function() {
            if (botDisabled) return;
            iframe.style.transition = 'none';
            if (isNarrowScreen()) {
              applyBubblePosition();
            } else {
              iframe.style.width = bubbleWidth + 'px';
              iframe.style.height = bubbleHeight + 'px';
            }
            iframe.offsetHeight;
            setTimeout(animateBubbleEntrance, T.pauseBeforeEntrance);
          }, T.closeWaitChat);
        }
      } else if (data === 'CMD_WPP_VISIBLE') {
        if (botDisabled) return;
        console.log('📱 CMD_WPP_VISIBLE - isExpanded:', isExpanded);
        bubbleHeight = BUBBLE_HEIGHT_WITH_WPP;
        bubbleWidth = BUBBLE_WIDTH_WITH_WPP;
        // ⬅️ Solo cambiar tamaño si NO está expandido
        if (!isExpanded) {
          iframe.style.transition = 'height 0.25s ease-out, width 0.25s ease-out';
          iframe.style.width = bubbleWidth + 'px';
          iframe.style.height = BUBBLE_HEIGHT_WITH_WPP + 'px';
        }
      } else if (data === 'CMD_WPP_HIDDEN') {
        if (botDisabled) return;
        console.log('📱 CMD_WPP_HIDDEN - isExpanded:', isExpanded);
        bubbleHeight = BUBBLE_HEIGHT_SOLO_BOT;
        bubbleWidth = BUBBLE_WIDTH_SOLO_BOT;
        // ⬅️ Solo cambiar tamaño si NO está expandido
        if (!isExpanded) {
          iframe.style.transition = 'height 0.25s ease-out, width 0.25s ease-out';
          iframe.style.width = bubbleWidth + 'px';
          iframe.style.height = BUBBLE_HEIGHT_SOLO_BOT + 'px';
        }
      }
    });

    setTimeout(function() {
      if (!iframeReady) {
        console.warn('⚠️ Timeout: iframe no envió CMD_READY en 8s. Activando de todos modos...');
        activateIframe('timeout');
      }
    }, 8000);

    // ⬅️ PROTECCIÓN GLOBAL: Vigilar cambios de tamaño inesperados cuando está expandido
    let lastExpandedCheck = 0;
    const sizeObserver = new MutationObserver(function(mutations) {
      const now = Date.now();
      if (now - lastExpandedCheck < 50) return; // Throttle reducido a 50ms
      lastExpandedCheck = now;
      
      if (isExpanded && !isAnimatingBubble && !isOpening) {
        const currentWidth = parseInt(iframe.style.width) || iframe.offsetWidth;
        const currentHeight = parseInt(iframe.style.height) || iframe.offsetHeight;
        const isNarrow = isNarrowScreen();
        
        // Si está expandido, verificar que tenga el tamaño correcto
        const expectedMinWidth = isNarrow ? 300 : 400;
        const expectedMinHeight = isNarrow ? 400 : 500;
        
        if (currentWidth < expectedMinWidth || currentHeight < expectedMinHeight) {
          console.error('🚨 [MutationObserver] IFRAME ACHICADO INESPERADAMENTE');
          console.error('   Estado: isExpanded=', isExpanded, 'Tamaño actual:', currentWidth, 'x', currentHeight);
          restoreExpandedStyle();
        }
      }
    });
    
    // Observar cambios en el atributo style del iframe
    sizeObserver.observe(iframe, { 
      attributes: true, 
      attributeFilter: ['style'] 
    });
    console.log('🛡️ Protección de tamaño activada - vigilando iframe');
    
    // ⬅️ PROTECCIÓN ADICIONAL: Verificación periódica cada 16ms (~60fps) cuando está expandido
    setInterval(function() {
      if (isExpanded && !isAnimatingBubble && !isOpening) {
        const currentWidth = parseInt(iframe.style.width) || iframe.offsetWidth;
        const currentHeight = parseInt(iframe.style.height) || iframe.offsetHeight;
        const isNarrow = isNarrowScreen();
        const expectedMinWidth = isNarrow ? 300 : 400;
        const expectedMinHeight = isNarrow ? 400 : 500;
        
        if (currentWidth < expectedMinWidth || currentHeight < expectedMinHeight) {
          console.error('🚨 [Interval] IFRAME ACHICADO - Restaurando');
          restoreExpandedStyle();
        }
      }
    }, 16);

    // Mouse tracking para RIV (solo desktop)
    const isTouchDevice = ('ontouchstart' in window) || (navigator.maxTouchPoints > 0);
    if (!isTouchDevice) {
      let lastMouseUpdate = 0;
      const MOUSE_THROTTLE_MS = 50;
      
      function onMouseMove(event) {
        const now = Date.now();
        if (now - lastMouseUpdate < MOUSE_THROTTLE_MS) return;
        lastMouseUpdate = now;
        
        try {
          if (!iframe.contentWindow) return;
          const iframeRect = iframe.getBoundingClientRect();
          iframe.contentWindow.postMessage({
            type: 'MOUSE_MOVE',
            x: event.clientX,
            y: event.clientY,
            iframeX: iframeRect.left,
            iframeY: iframeRect.top,
            iframeWidth: iframeRect.width,
            iframeHeight: iframeRect.height
          }, '*');
        } catch (e) {}
      }
      
      function onMouseLeave() {
        try {
          if (iframe.contentWindow) {
            iframe.contentWindow.postMessage({ type: 'MOUSE_LEAVE' }, '*');
          }
        } catch (e) {}
      }
      
      document.addEventListener('mousemove', onMouseMove, true);
      document.addEventListener('mouseleave', onMouseLeave, true);
      document.documentElement.addEventListener('mouseleave', onMouseLeave, true);
      console.log('🖱️ Mouse tracking activado');
    }
  })();
  </script>

  <!-- Snackbars de conectividad (show_offline_alert): sin WiFi / reconexión -->
  <script>
  (function() {
    'use strict';
    console.log('[BotLode Connectivity] Inicializando sistema de notificaciones...');
    
    var C = 'botlode-connectivity-snackbars', O = 'botlode-snackbar-offline', N = 'botlode-snackbar-online';
    var showOfflineAlert = true;
    var currentNetworkStatus = typeof navigator !== 'undefined' ? navigator.onLine : true;
    var onlineTimeout = null, lastOnlineCallTime = 0, DEBOUNCE_MS = 500;
    
    var SVG_OFFLINE = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.55a11 11 0 0 1 14.08 0"/><path d="M1.42 9a16 16 0 0 1 21.16 0"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><line x1="12" y1="20" x2="12.01" y2="20"/><line x1="2" y1="2" x2="22" y2="22" stroke-dasharray="2 2"/></svg>';
    var SVG_ONLINE = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>';
    
    function injectStyles() {
      if (document.getElementById('botlode-connectivity-styles')) return;
      var s = document.createElement('style'); 
      s.id = 'botlode-connectivity-styles';
      s.textContent = '#' + C + '{position:fixed;bottom:32px;left:50%;transform:translateX(-50%);z-index:2147483647;display:flex;flex-direction:column;align-items:center;gap:12px;pointer-events:none}' +
        '.botlode-snackbar{position:relative;display:flex;align-items:center;gap:16px;padding:18px 26px;min-width:320px;max-width:min(90vw,480px);border-radius:16px;font-family:Oxanium,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;font-size:15px;font-weight:600;letter-spacing:.6px;box-sizing:border-box;pointer-events:auto;opacity:0;transform:translateY(24px) scale(.94);transition:opacity .45s cubic-bezier(.34,1.56,.64,1),transform .45s cubic-bezier(.34,1.56,.64,1),box-shadow .35s ease;backdrop-filter:blur(20px);-webkit-backdrop-filter:blur(20px);box-shadow:0 8px 32px rgba(0,0,0,.3),0 2px 8px rgba(0,0,0,.2)}' +
        '.botlode-snackbar.show{opacity:1;transform:translateY(0) scale(1)}' +
        '.botlode-snackbar.hide{opacity:0;transform:translateY(-16px) scale(.92);transition-duration:.32s}' +
        '.botlode-snackbar-offline{background:linear-gradient(135deg,rgba(25,14,10,.92) 0%,rgba(18,10,6,.95) 100%);border:1.5px solid rgba(255,145,70,.6);color:#ffc299;box-shadow:0 0 28px rgba(255,120,50,.22),inset 0 1px 0 rgba(255,200,120,.12),0 12px 40px rgba(0,0,0,.35)}' +
        '.botlode-snackbar-offline .snackbar-glow{position:absolute;inset:-2px;border-radius:16px;padding:2px;background:linear-gradient(135deg,rgba(255,145,70,.3) 0%,transparent 50%,rgba(220,70,50,.2) 100%);-webkit-mask:linear-gradient(#fff 0 0) content-box,linear-gradient(#fff 0 0);mask:linear-gradient(#fff 0 0) content-box,linear-gradient(#fff 0 0);-webkit-mask-composite:xor;mask-composite:exclude;pointer-events:none;animation:botlode-pulse-off 2.8s ease-in-out infinite}' +
        '@keyframes botlode-pulse-off{0%,100%{opacity:.65}50%{opacity:1}}' +
        '.botlode-snackbar-online{background:linear-gradient(135deg,rgba(10,28,18,.92) 0%,rgba(6,20,14,.95) 100%);border:1.5px solid rgba(90,230,150,.55);color:#a0ffcc;box-shadow:0 0 28px rgba(70,230,130,.18),inset 0 1px 0 rgba(140,255,200,.14),0 12px 40px rgba(0,0,0,.35)}' +
        '.botlode-snackbar-online .snackbar-glow{position:absolute;inset:-2px;border-radius:16px;padding:2px;background:linear-gradient(135deg,rgba(90,230,150,.25) 0%,transparent 50%,rgba(70,190,110,.15) 100%);-webkit-mask:linear-gradient(#fff 0 0) content-box,linear-gradient(#fff 0 0);mask:linear-gradient(#fff 0 0) content-box,linear-gradient(#fff 0 0);-webkit-mask-composite:xor;mask-composite:exclude;pointer-events:none;animation:botlode-pulse-on 2.8s ease-in-out infinite}' +
        '@keyframes botlode-pulse-on{0%,100%{opacity:.55}50%{opacity:1}}' +
        '.botlode-snackbar .snackbar-icon{flex-shrink:0;width:32px;height:32px;display:flex;align-items:center;justify-content:center;animation:botlode-icon-pop .5s cubic-bezier(.34,1.56,.64,1)}' +
        '@keyframes botlode-icon-pop{0%{transform:scale(.4) rotate(-12deg);opacity:0}60%{transform:scale(1.12) rotate(4deg)}100%{transform:scale(1) rotate(0deg);opacity:1}}' +
        '.botlode-snackbar .snackbar-icon svg{width:100%;height:100%}' +
        '.botlode-snackbar-offline .snackbar-icon{color:#ff9d6e;filter:drop-shadow(0 0 8px rgba(255,140,80,.4))}' +
        '.botlode-snackbar-online .snackbar-icon{color:#70f0a0;filter:drop-shadow(0 0 8px rgba(100,240,160,.45))}' +
        '.botlode-snackbar .snackbar-text{flex:1;line-height:1.5;text-shadow:0 1px 2px rgba(0,0,0,.3)}';
      (document.head || document.documentElement).appendChild(s);
      console.log('[BotLode Connectivity] ✓ Estilos inyectados');
    }
    
    function createSnackbars() {
      if (document.getElementById(C)) return;
      var w = document.createElement('div'); 
      w.id = C; 
      w.setAttribute('aria-live', 'polite');
      w.innerHTML = '<div id="' + O + '" class="botlode-snackbar botlode-snackbar-offline" role="status" hidden>' +
        '<span class="snackbar-glow"></span>' +
        '<span class="snackbar-icon" aria-hidden="true">' + SVG_OFFLINE + '</span>' +
        '<span class="snackbar-text">Conexión perdida. Comprueba tu red.</span>' +
        '</div>' +
        '<div id="' + N + '" class="botlode-snackbar botlode-snackbar-online" role="status" hidden>' +
        '<span class="snackbar-glow"></span>' +
        '<span class="snackbar-icon" aria-hidden="true">' + SVG_ONLINE + '</span>' +
        '<span class="snackbar-text">Reconexión exitosa</span>' +
        '</div>';
      document.body.appendChild(w);
      console.log('[BotLode Connectivity] ✓ Contenedores de snackbar creados');
    }
    
    function showOffline() {
      currentNetworkStatus = false;
      console.log('[BotLode Connectivity] 📡 Mostrando alerta OFFLINE (showOfflineAlert=' + showOfflineAlert + ')');
      if (!showOfflineAlert) return;
      var so = document.getElementById(O), son = document.getElementById(N);
      if (!so) { console.warn('[BotLode Connectivity] ⚠️ Elemento offline no encontrado'); return; }
      if (onlineTimeout) { clearTimeout(onlineTimeout); onlineTimeout = null; }
      if (son) { son.classList.remove('show'); son.classList.add('hide'); son.setAttribute('hidden', ''); }
      so.removeAttribute('hidden'); 
      so.classList.remove('hide'); 
      requestAnimationFrame(function() { 
        so.classList.add('show'); 
        console.log('[BotLode Connectivity] ✓ Snackbar offline visible');
      });
    }
    
    function showOnline() {
      currentNetworkStatus = true;
      console.log('[BotLode Connectivity] 📶 Mostrando alerta ONLINE (showOfflineAlert=' + showOfflineAlert + ')');
      if (!showOfflineAlert) return;
      var now = Date.now(); 
      if (now - lastOnlineCallTime < DEBOUNCE_MS) { console.log('[BotLode Connectivity] ⏱️ Debounce activo, ignorando'); return; }
      lastOnlineCallTime = now;
      var so = document.getElementById(O), son = document.getElementById(N);
      if (!son || !so) { console.warn('[BotLode Connectivity] ⚠️ Elementos no encontrados'); return; }
      so.classList.remove('show'); 
      so.classList.add('hide'); 
      setTimeout(function() { so.setAttribute('hidden', ''); so.classList.remove('hide'); }, 300);
      son.removeAttribute('hidden'); 
      son.classList.remove('hide'); 
      requestAnimationFrame(function() { 
        son.classList.add('show'); 
        console.log('[BotLode Connectivity] ✓ Snackbar online visible');
      });
      if (onlineTimeout) clearTimeout(onlineTimeout);
      onlineTimeout = setTimeout(function() {
        if (son) { 
          son.classList.remove('show'); 
          son.classList.add('hide'); 
          setTimeout(function() { 
            if (son) { son.setAttribute('hidden', ''); son.classList.remove('show', 'hide'); } 
            console.log('[BotLode Connectivity] ✓ Snackbar online ocultado');
          }, 300); 
        }
        onlineTimeout = null;
      }, 3000);
    }
    
    function onMessage(ev) {
      var d = ev.data;
      if (d && typeof d === 'object' && d.type === 'BOT_CONFIG') {
        var prev = showOfflineAlert; 
        showOfflineAlert = d.showOfflineAlert === true;
        console.log('[BotLode Connectivity] 📩 BOT_CONFIG recibido: showOfflineAlert=' + showOfflineAlert);
        if (!showOfflineAlert) {
          var so = document.getElementById(O);
          if (so && so.classList.contains('show')) { 
            so.classList.remove('show'); 
            so.classList.add('hide'); 
            setTimeout(function() { so.setAttribute('hidden', ''); }, 300); 
          }
        } else if (showOfflineAlert && !prev && !currentNetworkStatus) { 
          if (!navigator.onLine) showOffline(); 
        }
        return;
      }
      if (d && typeof d === 'object' && d.type === 'connectivity') { 
        console.log('[BotLode Connectivity] 📩 Mensaje connectivity recibido: online=' + d.online);
        if (d.online) showOnline(); else showOffline(); 
        return; 
      }
      if (d === 'NETWORK_OFFLINE') { console.log('[BotLode Connectivity] 📩 Mensaje NETWORK_OFFLINE (legacy)'); showOffline(); return; }
      if (d === 'NETWORK_ONLINE') { console.log('[BotLode Connectivity] 📩 Mensaje NETWORK_ONLINE (legacy)'); showOnline(); return; }
    }
    
    function onWindowOffline() {
      currentNetworkStatus = false;
      console.log('[BotLode Connectivity] 🌐 Evento window.offline detectado');
      if (showOfflineAlert) showOffline();
    }
    
    function onWindowOnline() {
      currentNetworkStatus = true;
      console.log('[BotLode Connectivity] 🌐 Evento window.online detectado');
      var so = document.getElementById(O);
      if (so && so.classList.contains('show')) showOnline();
    }
    
    function init() {
      injectStyles(); 
      createSnackbars();
      window.addEventListener('message', onMessage);
      window.addEventListener('online', onWindowOnline);
      window.addEventListener('offline', onWindowOffline);
      console.log('[BotLode Connectivity] ✓ Sistema inicializado. Estado inicial: ' + (currentNetworkStatus ? 'ONLINE' : 'OFFLINE'));
      console.log('[BotLode Connectivity] 💡 Para probar: abre DevTools > Network > marca "Offline"');
    }
    
    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init); else init();
  })();
  </script>
''';
    bool isFullscreen = false;
    showDialog(
      context: context,
      builder: (context) => Shortcuts(
        shortcuts: const { SingleActivator(LogicalKeyboardKey.enter): _DialogSubmitIntent() },
        child: Actions(
          actions: {
            _DialogSubmitIntent: CallbackAction<_DialogSubmitIntent>(onInvoke: (_) {
              Clipboard.setData(ClipboardData(text: embedCode));
              Navigator.pop(context);
              _showEpicNotify("PROTOCOLO COPIADO");
              return null;
            }),
          },
          child: StatefulBuilder(
        builder: (context, setModalState) {
          final size = MediaQuery.of(context).size;
          final padding = MediaQuery.of(context).padding;
          // En fullscreen dejar espacio para la barra de la ventana (cerrar, minimizar, etc.)
          const double windowBarHeight = 40.0;
          final topInset = isFullscreen ? (windowBarHeight + padding.top) : 0.0;
          final availableHeight = isFullscreen ? (size.height - topInset) : null;
          return Dialog(
            backgroundColor: AppColors.surface,
            insetPadding: isFullscreen
                ? EdgeInsets.only(top: topInset, left: 0, right: 0, bottom: 0)
                : const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              width: isFullscreen ? size.width : null,
              height: isFullscreen ? availableHeight : null,
              constraints: isFullscreen ? BoxConstraints(maxWidth: size.width, maxHeight: availableHeight!) : null,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: isFullscreen ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text("CÓDIGO DE ENLACE NEURAL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: Icon(isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded, color: AppColors.primary, size: 22),
                        tooltip: isFullscreen ? "Salir de pantalla completa" : "Pantalla completa",
                        onPressed: () => setModalState(() => isFullscreen = !isFullscreen),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isFullscreen)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderGlass)),
                        child: SingleChildScrollView(
                          child: Text(embedCode, style: const TextStyle(color: AppColors.success, fontFamily: 'Courier', fontSize: 10)),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 150,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderGlass)),
                      child: SingleChildScrollView(
                        child: Text(embedCode, style: const TextStyle(color: AppColors.success, fontFamily: 'Courier', fontSize: 10)),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("CERRAR")),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () { Clipboard.setData(ClipboardData(text: embedCode)); Navigator.pop(context); _showEpicNotify("PROTOCOLO COPIADO"); },
                        child: const Text("COPIAR PROTOCOLO"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
          ),
        ),
      ),
    );
  }

  void _showPinDialog(Bot bot) {
    final pin = bot.accessPin ?? '0000';

    showDialog(
      context: context,
      builder: (context) => Shortcuts(
        shortcuts: const { SingleActivator(LogicalKeyboardKey.enter): _DialogSubmitIntent() },
        child: Actions(
          actions: {
            _DialogSubmitIntent: CallbackAction<_DialogSubmitIntent>(onInvoke: (_) {
              Clipboard.setData(ClipboardData(text: pin));
              Navigator.pop(context);
              _showEpicNotify("PIN COPIADO");
              return null;
            }),
          },
          child: AlertDialog(
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
        ),
      ),
    );
  }

  void _showEditPromptDialog(Bot bot) {
    // ⬅️ SIMPLIFICADO: Usar solo system_prompt (todo en un solo campo)
    final TextEditingController promptCtrl = TextEditingController(text: bot.systemPrompt);
    bool isFullscreen = false;

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Shortcuts(
          shortcuts: const { SingleActivator(LogicalKeyboardKey.enter): _DialogSubmitIntent() },
          child: Actions(
            actions: {
              _DialogSubmitIntent: CallbackAction<_DialogSubmitIntent>(onInvoke: (_) async {
                await ref.read(botsProvider.notifier).updateBotPrompt(bot.id, promptCtrl.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  _showEpicNotify("NÚCLEO REPROGRAMADO");
                }
                return null;
              }),
            },
            child: StatefulBuilder(
          builder: (context, setModalState) {
            final size = MediaQuery.of(context).size;
            final padding = MediaQuery.of(context).padding;
            // En fullscreen dejar espacio para la barra de la ventana (cerrar, minimizar, etc.)
            const double windowBarHeight = 40.0;
            final topInset = isFullscreen ? (windowBarHeight + padding.top) : 0.0;
            final availableHeight = isFullscreen ? (size.height - topInset) : null;
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: isFullscreen
                  ? EdgeInsets.only(top: topInset, left: 0, right: 0, bottom: 0)
                  : const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Container(
                width: isFullscreen ? size.width : 600,
                height: isFullscreen ? availableHeight : null,
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
                  mainAxisSize: isFullscreen ? MainAxisSize.max : MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 28),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "REPROGRAMACIÓN DE NÚCLEO",
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Oxanium',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded, color: AppColors.primary, size: 22),
                          tooltip: isFullscreen ? "Salir de pantalla completa" : "Pantalla completa",
                          onPressed: () => setModalState(() => isFullscreen = !isFullscreen),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Modifique las directivas primarias de la unidad. Aquí defines TODO: comportamiento, personalidad, tono, estilo...",
                      style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 12),
                    ),
                    const SizedBox(height: 24),
                    if (isFullscreen)
                      Expanded(
                        child: TextField(
                          controller: promptCtrl,
                          maxLines: null,
                          minLines: 8,
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
                      )
                    else
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
            );
          },
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
        child: Shortcuts(
          shortcuts: const { SingleActivator(LogicalKeyboardKey.enter): _DialogSubmitIntent() },
          child: Actions(
            actions: {
              _DialogSubmitIntent: CallbackAction<_DialogSubmitIntent>(onInvoke: (_) async {
                if (!formKey.currentState!.validate()) return null;
                final phone = phoneCtrl.text.trim();
                try {
                  await ref.read(botsProvider.notifier).updateWppConfig(bot.id, true, phone);
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
                return null;
              }),
            },
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
                    "Número con código de país, sin espacios ni símbolos.\nEj: 1134272488",
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
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Courier',
                      fontSize: 16,
                      letterSpacing: 1.5,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.5),
                      hintText: "Teléfono",
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
        child: Shortcuts(
          shortcuts: const { SingleActivator(LogicalKeyboardKey.enter): _DialogSubmitIntent() },
          child: Actions(
            actions: {
              _DialogSubmitIntent: CallbackAction<_DialogSubmitIntent>(onInvoke: (_) async {
                final newMessage = messageCtrl.text.trim();
                if (newMessage.isEmpty) return null;
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
                return null;
              }),
            },
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

    return Focus(
      onKeyEvent: (_, KeyEvent event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Tooltip(
          message: '${widget.tooltip} (Enter)',
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
                    ref.read(botsProvider.notifier).toggleStatus(bot.id).then((success) {
                      if (!success && context.mounted) {
                        CreditLimitReachedDialog.show(context);
                      }
                    });
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

  static const double _minSize = 70.0;
  static const double _maxSize = 120.0;

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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
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
          ),
        ),
      ),
    ); 
  }
}

class _StatCard extends StatelessWidget {
  final String title; final Widget valueWidget; final String subValue; final IconData icon; final Color color; final double progress;
  const _StatCard({required this.title, required this.valueWidget, required this.subValue, required this.icon, required this.color, required this.progress});
  @override Widget build(BuildContext context) { return Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: AppColors.surface.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderGlass)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 8), Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold))]), const SizedBox(height: 16), Row(crossAxisAlignment: CrossAxisAlignment.end, children: [valueWidget, const SizedBox(width: 8), Text(subValue, style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7)))]), const SizedBox(height: 16), LinearProgressIndicator(value: progress, backgroundColor: Colors.black, color: color, minHeight: 6)])); }
}