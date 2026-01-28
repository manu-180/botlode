// Archivo: lib/features/bot_engine/presentation/widgets/rive_bot_display.dart
import 'dart:math' as math;
import 'dart:ui';
import 'package:botslode/core/providers/rive_provider.dart';
import 'package:botslode/features/bot_engine/presentation/providers/bot_mood_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart';

class RiveBotDisplay extends ConsumerStatefulWidget {
  const RiveBotDisplay({super.key});
  @override
  ConsumerState<RiveBotDisplay> createState() => _RiveBotDisplayState();
}

class _RiveBotDisplayState extends ConsumerState<RiveBotDisplay> with SingleTickerProviderStateMixin {
  StateMachineController? _controller;
  SMINumber? _moodInput, _lookXInput, _lookYInput;
  late Ticker _ticker;

  double _targetX = 50.0, _targetY = 50.0;
  double _currentX = 50.0, _currentY = 50.0;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_lookXInput == null) return;
    
    // Física Híbrida: 0.4 (Rápido al mirar) / 0.04 (Lento al reposar)
    final double smoothFactor = _isTracking ? 0.4 : 0.04;
    
    _currentX = lerpDouble(_currentX, _targetX, smoothFactor) ?? 50;
    _currentY = lerpDouble(_currentY, _targetY, smoothFactor) ?? 50;
    
    _lookXInput!.value = _currentX;
    _lookYInput!.value = _currentY;
  }

  void _onRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(artboard, 'State Machine 1') ??
                       StateMachineController.fromArtboard(artboard, 'State Machine');
    
    if (controller != null) {
      artboard.addController(controller);
      _controller = controller;
      _moodInput = controller.getNumberInput('Mood');
      _lookXInput = controller.getNumberInput('LookX');
      _lookYInput = controller.getNumberInput('LookY');
      
      // Estado inicial (Ahora siempre será 0 al entrar gracias a autoDispose)
      _moodInput?.value = ref.read(terminalBotMoodProvider).toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final riveFileAsync = ref.watch(riveFullBotFileProvider);

    // Escuchamos cambios de humor
    ref.listen(terminalBotMoodProvider, (p, next) => _moodInput?.value = next.toDouble());
    
    // Escuchamos movimiento del mouse (local en el detalle)
    ref.listen(terminalPointerPositionProvider, (prev, pos) {
      if (pos == null) {
        _isTracking = false; _targetX = 50.0; _targetY = 50.0; return;
      }
      final double distance = math.sqrt(pos.dx * pos.dx + pos.dy * pos.dy);
      const double maxRange = 600.0; 
      
      if (distance < maxRange) {
        _isTracking = true;
        _targetX = (50 + (pos.dx / 400 * 50)).clamp(0, 100);
        _targetY = (50 + (pos.dy / 400 * 50)).clamp(0, 100);
      } else {
        _isTracking = false; _targetX = 50.0; _targetY = 50.0;
      }
    });

    return SizedBox(
      width: 300, height: 300,
      child: riveFileAsync.when(
        data: (file) => RiveAnimation.direct(
          file, 
          fit: BoxFit.contain, 
          onInit: _onRiveInit
        ),
        loading: () => const SizedBox(), 
        error: (_, __) => const SizedBox(),
      ),
    );
  }
}