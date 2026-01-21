// Archivo: lib/features/dashboard/presentation/widgets/rive_bot_card_display.dart
import 'dart:ui';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/providers/rive_provider.dart'; // Importamos el caché
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart';

class RiveBotCardDisplay extends ConsumerStatefulWidget {
  final Color primaryColor;
  final double cycleProgress;
  final Offset? pointerLocalPos; 

  const RiveBotCardDisplay({
    super.key, 
    required this.primaryColor,
    required this.cycleProgress,
    this.pointerLocalPos,
  });

  @override
  ConsumerState<RiveBotCardDisplay> createState() => _RiveBotCardDisplayState();
}

class _RiveBotCardDisplayState extends ConsumerState<RiveBotCardDisplay> with SingleTickerProviderStateMixin {
  StateMachineController? _controller;
  SMINumber? _moodInput;
  SMINumber? _lookXInput;
  SMINumber? _lookYInput;

  late Ticker _ticker;
  double _targetX = 50.0;
  double _targetY = 50.0;
  double _currentX = 50.0;
  double _currentY = 50.0;
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

  @override
  void didUpdateWidget(covariant RiveBotCardDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.pointerLocalPos != null) {
      _isTracking = true;
      const double robotCenterX = 47.0;
      const double robotCenterY = 47.0;
      final double dx = widget.pointerLocalPos!.dx - robotCenterX;
      final double dy = widget.pointerLocalPos!.dy - robotCenterY;

      _targetX = (50 + (dx * 0.3)).clamp(0.0, 100.0);
      _targetY = (50 + (dy * 0.3)).clamp(0.0, 100.0);
    } else {
      _isTracking = false;
      _targetX = 50.0;
      _targetY = 50.0;
    }
  }

  void _onTick(Duration elapsed) {
    if (_lookXInput == null) return;
    final double smoothFactor = _isTracking ? 0.25 : 0.05;
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
      _assignMoodByColor();
    }
  }

  void _assignMoodByColor() {
    if (_moodInput == null) return;
    final color = widget.primaryColor;
    if (color.red > 200 && color.green < 100) _moodInput!.value = 1; 
    else if (color.green > 200) _moodInput!.value = 5; 
    else if (color.red > 200 && color.green > 150) _moodInput!.value = 3; 
    else _moodInput!.value = 0; 
  }

  @override
  Widget build(BuildContext context) {
    // Leemos el archivo desde el caché
    final riveFileAsync = ref.watch(riveHeadFileProvider);

    return SizedBox(
      width: 54, height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 54, height: 54,
            child: CircularProgressIndicator(
              value: 1.0, 
              strokeWidth: 3,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          SizedBox(
            width: 54, height: 54,
            child: CircularProgressIndicator(
              value: widget.cycleProgress, 
              strokeWidth: 3,
              color: AppColors.secondary, 
              strokeCap: StrokeCap.round,
            ),
          ),
          Container(
            width: 44, height: 44,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
            child: ClipOval(
              // Usamos .when para manejar la carga del archivo cacheado
              child: riveFileAsync.when(
                data: (file) => RiveAnimation.direct(
                  file, // Usamos 'direct' para inyectar el archivo ya cargado
                  fit: BoxFit.cover,
                  onInit: _onRiveInit,
                ),
                loading: () => Container(color: Colors.black), // Instantáneo
                error: (_, __) => const Icon(Icons.error, size: 20, color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
}