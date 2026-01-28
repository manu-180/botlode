// Archivo: lib/features/auth/presentation/views/login_view.dart
import 'dart:async';
import 'dart:ui';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/providers/auth_provider.dart';
import 'package:botslode/core/providers/rive_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart' hide LinearGradient;

class LoginView extends ConsumerStatefulWidget {
  static const String routeName = 'login';
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  
  String? _errorMessage;
  bool _showError = false;
  Timer? _errorTimer;

  // --- VARIABLES RIVE ---
  StateMachineController? _riveController;
  SMINumber? _lookXInput;
  SMINumber? _lookYInput;
  SMINumber? _moodInput;

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
    _emailController.dispose();
    _passController.dispose();
    _errorTimer?.cancel();
    _ticker.dispose();
    _riveController?.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_lookXInput == null || _lookYInput == null) return;
    
    final double smoothFactor = _isTracking ? 0.2 : 0.05;
    
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
      _riveController = controller;
      
      _lookXInput = controller.findInput<double>('LookX') as SMINumber?;
      _lookYInput = controller.findInput<double>('LookY') as SMINumber?;
      _moodInput = controller.findInput<double>('Mood') as SMINumber?;

      // CAMBIO: Estado 3.0 (Amarillo/Vendedor) para coincidir con el Branding Dorado
      _moodInput?.value = 3.0; 
    }
  }

  void _onHover(PointerEvent event, BoxConstraints constraints) {
    _isTracking = true;
    final double centerX = constraints.maxWidth / 2;
    final double centerY = constraints.maxHeight / 2;
    final double deltaX = event.localPosition.dx - centerX;
    final double deltaY = event.localPosition.dy - centerY;

    _targetX = (50 + (deltaX / 5.0)).clamp(0.0, 100.0);
    _targetY = (50 + (deltaY / 5.0)).clamp(0.0, 100.0);
  }

  void _onExit(PointerEvent event) {
    _isTracking = false;
    _targetX = 50.0;
    _targetY = 50.0;
  }

  void _triggerError(String msg) {
    _errorTimer?.cancel();
    setState(() {
      _errorMessage = msg;
      _showError = true;
    });
    
    // Estado de alerta/tristeza temporal
    _moodInput?.value = 1.0; 

    _errorTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() => _showError = false);
        // CAMBIO: Al recuperarse vuelve a ser Dorado (3.0)
        _moodInput?.value = 3.0; 
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_showError) setState(() => _showError = false);

    final email = _emailController.text.trim();
    final pass = _passController.text.trim();

    ref.read(authProvider.notifier).signIn(email, pass);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final riveFileAsync = ref.watch(riveFullBotFileProvider);

    ref.listen(authProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        _triggerError(next.error!);
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Row(
            children: [
              // --- IZQUIERDA: VISUAL INTERACTIVO ---
              Expanded(
                flex: 5,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return MouseRegion(
                      onHover: (event) => _onHover(event, constraints),
                      onExit: _onExit,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: riveFileAsync.when(
                              data: (file) => RiveAnimation.direct(
                                file,
                                fit: BoxFit.cover,
                                artboard: 'Catbot', 
                                onInit: _onRiveInit,
                              ),
                              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                              error: (_, __) => Center(
                                child: Icon(Icons.broken_image, color: AppColors.error)
                                    .animate(onPlay: (c) => c.repeat())
                                    .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.5))
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.3),
                                    Colors.black.withValues(alpha: 0.8),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 60,
                            left: 60,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.primary),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    "FACTORY TERMINAL v1.0",
                                    style: TextStyle(color: AppColors.primary, fontFamily: 'Courier', fontWeight: FontWeight.bold, letterSpacing: 2.0),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "BotLode",
                                  style: TextStyle(fontFamily: 'Oxanium', fontSize: 80, height: 1.0, fontWeight: FontWeight.w900, color: Colors.white),
                                ).animate().fadeIn(duration: 800.ms).moveY(begin: 20, end: 0),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: 400,
                                  child: Text(
                                    "Gestión avanzada de flotas autónomas y sistemas de inteligencia artificial conversacional.",
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 16, height: 1.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                ),
              ),

              // --- DERECHA: FORMULARIO ---
              Expanded(
                flex: 4,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A0A0A),
                    border: Border(left: BorderSide(color: AppColors.borderGlass)),
                  ),
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(60),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 450),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 48)
                                .animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                            const SizedBox(height: 24),
                            const Text(
                              "IDENTIFICACIÓN REQUERIDA",
                              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Oxanium'),
                            ),
                            const SizedBox(height: 8),
                            Text("Ingrese sus credenciales para acceder al núcleo.", style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8))),
                            const SizedBox(height: 48),

                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  _LoginInput(
                                    controller: _emailController,
                                    label: "CORREO ELECTRÓNICO",
                                    icon: Icons.alternate_email_rounded,
                                    textInputAction: TextInputAction.next,
                                    validator: (val) {
                                      if (val == null || val.isEmpty) return "Requerido";
                                      if (!val.contains('@')) return "Formato de correo inválido";
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  _LoginInput(
                                    controller: _passController,
                                    label: "CLAVE DE ACCESO",
                                    icon: Icons.vpn_key_rounded,
                                    isPassword: true,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => _submit(),
                                    validator: (val) {
                                      if (val == null || val.isEmpty) return "Requerido";
                                      if (val.length < 6) return "Mínimo 6 caracteres";
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 40),

                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: authState.isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: authState.isLoading
                                    ? Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)),
                                          const SizedBox(width: 12),
                                          const Text(
                                            "VERIFICANDO...",
                                            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12),
                                          ),
                                        ],
                                      )
                                    : const Text(
                                        "ACCEDER AL SISTEMA",
                                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                      ),
                              ),
                            ),

                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // --- TOAST "PRO" ---
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            top: _showError ? 40 : -150,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF140000),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.error, width: 2),
                  boxShadow: [
                    BoxShadow(color: AppColors.error.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: 5),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28)
                          .animate(onPlay: (c) => c.repeat())
                          .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.5)),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "ACCESO DENEGADO",
                            style: TextStyle(
                              color: AppColors.error, 
                              fontWeight: FontWeight.w900, 
                              fontSize: 12, 
                              letterSpacing: 2.0,
                              fontFamily: 'Courier'
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _errorMessage ?? "Error desconocido en protocolo.",
                            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;

  const _LoginInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
  });

  @override
  State<_LoginInput> createState() => _LoginInputState();
}

class _LoginInputState extends State<_LoginInput> {
  late FocusNode _focusNode;
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      setState(() => _touched = true);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.isPassword,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onSubmitted,
          style: const TextStyle(color: Colors.white, fontFamily: 'Courier'),
          cursorColor: AppColors.primary,
          autovalidateMode: _touched ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          validator: widget.validator,
          decoration: InputDecoration(
            prefixIcon: Icon(widget.icon, color: AppColors.textSecondary),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
            errorStyle: const TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.bold),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
      ],
    );
  }
}