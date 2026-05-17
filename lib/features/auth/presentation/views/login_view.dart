// Archivo: lib/features/auth/presentation/views/login_view.dart
import 'dart:async';
import 'dart:ui';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/providers/auth_provider.dart';
import 'package:botslode/core/providers/rive_provider.dart';
import 'package:botslode/core/ui/app_background.dart';
import 'package:botslode/core/ui/hud/hud_corner_brackets.dart';
import 'package:botslode/core/ui/hud/hud_scanlines.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart' hide LinearGradient, RadialGradient;

class LoginView extends ConsumerStatefulWidget {
  static const String routeName = 'login';
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView>
    with SingleTickerProviderStateMixin {
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
    final controller =
        StateMachineController.fromArtboard(artboard, 'State Machine 1') ??
        StateMachineController.fromArtboard(artboard, 'State Machine');
    if (controller != null) {
      artboard.addController(controller);
      _riveController = controller;
      _lookXInput = controller.findInput<double>('LookX') as SMINumber?;
      _lookYInput = controller.findInput<double>('LookY') as SMINumber?;
      _moodInput = controller.findInput<double>('Mood') as SMINumber?;
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
    _moodInput?.value = 1.0;
    _errorTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() => _showError = false);
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
    final reduce = AppMotion.reduced(context);

    ref.listen(authProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        _triggerError(next.error!);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Row(
            children: [
              // --- IZQUIERDA: PANEL CINEMATOGRÁFICO ---
              Expanded(
                flex: 58,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return MouseRegion(
                      onHover: (event) => _onHover(event, constraints),
                      onExit: _onExit,
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          // Capa 1: fondo ambiental (visible mientras la Rive carga)
                          const Positioned.fill(
                            child: AppBackground(
                              showBlobs: false,
                              child: SizedBox(),
                            ),
                          ),

                          // Capa 2: Rive Catbot (zoom evita que la viñeta exponga bordes)
                          Positioned.fill(
                            child: Transform.scale(
                              scale: 1.06,
                              child: ExcludeSemantics(
                                child: riveFileAsync.when(
                                  data: (file) => RiveAnimation.direct(
                                    file,
                                    fit: BoxFit.cover,
                                    artboard: 'Catbot',
                                    onInit: _onRiveInit,
                                  ),
                                  loading: () => const Center(
                                    child: SizedBox(
                                      width: AppDimens.iconL,
                                      height: AppDimens.iconL,
                                      child: CircularProgressIndicator(
                                        color: AppColors.gold,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                  error: (_, __) => Center(
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      color: AppColors.danger,
                                      size: AppDimens.iconL,
                                    ).animate().fadeIn(
                                          duration: AppMotion.durBase,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Capa 3a: viñeta radial — integra la Rive con el vacío
                          Positioned.fill(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: Alignment.center,
                                    radius: 1.15,
                                    colors: [
                                      Colors.transparent,
                                      Colors.transparent,
                                      AppColors.voidBlack.withValues(alpha: 0.85),
                                    ],
                                    stops: const [0.0, 0.55, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Capa 3b: gradiente inferior de legibilidad
                          Positioned.fill(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.transparent,
                                      AppColors.voidBlack.withValues(alpha: 0.92),
                                    ],
                                    stops: const [0.0, 0.45, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Capa 4: scanlines — textura de pantalla HUD
                          Positioned.fill(
                            child: IgnorePointer(
                              child: HudScanlines(
                                opacity: 0.035,
                                lineSpacing: 3,
                                animate: !reduce,
                                child: const SizedBox(),
                              ),
                            ),
                          ),

                          // Capa 5: brackets de esquina — enmarcan la composición
                          Positioned.fill(
                            child: IgnorePointer(
                              child: const Padding(
                                padding: EdgeInsets.all(AppDimens.space24),
                                child: HudCornerBrackets(
                                  armLength: 20,
                                  thickness: 1.5,
                                  color: AppColors.borderGold,
                                  child: SizedBox(),
                                ),
                              ).animate().fadeIn(
                                    duration: AppMotion.durBase,
                                    delay: 80.ms,
                                  ),
                            ),
                          ),

                          // Capa 6: bloque de marca
                          Positioned(
                            left: AppDimens.space48,
                            bottom: AppDimens.space48,
                            child: _BrandBlock(reduce: reduce),
                          ),

                          // Capa 7: costura HUD vertical (borde derecho del panel)
                          const Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: _SeamLine(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // --- DERECHA: FORMULARIO ---
              Expanded(
                flex: 42,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.bgElevated01,
                  ),
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppDimens.space64),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 450),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              color: AppColors.gold,
                              size: 48,
                            ).animate().scale(
                                  duration: 400.ms,
                                  curve: Curves.elasticOut,
                                ),
                            const SizedBox(height: AppDimens.space24),
                            Text(
                              "IDENTIFICACIÓN REQUERIDA",
                              style: AppTextStyles.displayM,
                            ),
                            const SizedBox(height: AppDimens.space8),
                            Text(
                              "Ingrese sus credenciales para acceder al núcleo.",
                              style: AppTextStyles.bodyM
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: AppDimens.space48),
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
                                      if (val == null || val.isEmpty) {
                                        return "Requerido";
                                      }
                                      if (!val.contains('@')) {
                                        return "Formato de correo inválido";
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: AppDimens.space24),
                                  _LoginInput(
                                    controller: _passController,
                                    label: "CLAVE DE ACCESO",
                                    icon: Icons.vpn_key_rounded,
                                    isPassword: true,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => _submit(),
                                    validator: (val) {
                                      if (val == null || val.isEmpty) {
                                        return "Requerido";
                                      }
                                      if (val.length < 6) {
                                        return "Mínimo 6 caracteres";
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppDimens.space40),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: authState.isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.gold,
                                  foregroundColor: AppColors.textOnGold,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppDimens.radiusM,
                                    ),
                                  ),
                                ),
                                child: authState.isLoading
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: AppColors.textOnGold,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: AppDimens.space12,
                                          ),
                                          Text(
                                            "VERIFICANDO...",
                                            style: AppTextStyles.label.copyWith(
                                              color: AppColors.textOnGold,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        "ACCEDER AL SISTEMA",
                                        style: AppTextStyles.label.copyWith(
                                          color: AppColors.textOnGold,
                                        ),
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

          // --- TOAST DE ERROR ---
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            top: _showError ? 40 : -150,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.space24,
                  vertical: AppDimens.space20,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF140000),
                  borderRadius: BorderRadius.circular(AppDimens.radiusL),
                  border: Border.all(color: AppColors.danger, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.dangerGlow,
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimens.space8),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.danger,
                        size: AppDimens.iconL,
                      )
                          .animate(onPlay: (c) => c.repeat())
                          .shimmer(
                            duration: 2000.ms,
                            color: const Color.fromRGBO(255, 255, 255, 0.5),
                          ),
                    ),
                    const SizedBox(width: AppDimens.space20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "ACCESO DENEGADO",
                            style: AppTextStyles.label
                                .copyWith(color: AppColors.danger),
                          ),
                          const SizedBox(height: AppDimens.space8),
                          Text(
                            _errorMessage ?? "Error desconocido en protocolo.",
                            style: AppTextStyles.bodyM,
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

// ─── Brand Block ──────────────────────────────────────────────────────────────

class _BrandBlock extends StatelessWidget {
  final bool reduce;
  const _BrandBlock({required this.reduce});

  @override
  Widget build(BuildContext context) {
    final tagWidget = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space12,
        vertical: AppDimens.space4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceHud,
        border: Border.all(color: AppColors.borderGold, width: 1),
        borderRadius: BorderRadius.circular(AppDimens.radiusXS),
      ),
      child: Text(
        'FACTORY TERMINAL v1.0',
        style: AppTextStyles.mono.copyWith(
          color: AppColors.gold,
          fontSize: 10,
          letterSpacing: 1.2,
        ),
      ),
    );

    final titleWidget = RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'BotLod',
            style: AppTextStyles.displayXL,
          ),
          TextSpan(
            text: 'e',
            style: AppTextStyles.displayXL.copyWith(
              color: AppColors.gold,
              shadows: const [
                Shadow(
                  color: AppColors.goldGlow,
                  blurRadius: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final subtitleWidget = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Text(
        'Gestión avanzada de flotas autónomas y sistemas de inteligencia artificial conversacional.',
        style: AppTextStyles.bodyL.copyWith(color: AppColors.textSecondary),
      ),
    );

    if (reduce) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          tagWidget
              .animate()
              .fadeIn(duration: AppMotion.durCrossfadeReduced),
          const SizedBox(height: AppDimens.space20),
          titleWidget
              .animate()
              .fadeIn(duration: AppMotion.durCrossfadeReduced),
          const SizedBox(height: AppDimens.space12),
          subtitleWidget
              .animate()
              .fadeIn(duration: AppMotion.durCrossfadeReduced),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tagWidget
            .animate()
            .fadeIn(
              duration: AppMotion.durBase,
              delay: 120.ms,
              curve: AppMotion.easeEntrance,
            )
            .moveY(
              begin: 10,
              end: 0,
              duration: AppMotion.durBase,
              delay: 120.ms,
              curve: AppMotion.easeEntrance,
            ),
        const SizedBox(height: AppDimens.space20),
        titleWidget
            .animate()
            .fadeIn(
              duration: AppMotion.durSlow,
              delay: 220.ms,
              curve: AppMotion.easeEntrance,
            )
            .moveY(
              begin: 16,
              end: 0,
              duration: AppMotion.durSlow,
              delay: 220.ms,
              curve: AppMotion.easeEntrance,
            ),
        const SizedBox(height: AppDimens.space12),
        subtitleWidget
            .animate()
            .fadeIn(
              duration: AppMotion.durSlow,
              delay: 340.ms,
              curve: AppMotion.easeEntrance,
            )
            .moveY(
              begin: 12,
              end: 0,
              duration: AppMotion.durSlow,
              delay: 340.ms,
              curve: AppMotion.easeEntrance,
            ),
      ],
    );
  }
}

// ─── Seam Line ────────────────────────────────────────────────────────────────

class _SeamLine extends StatelessWidget {
  const _SeamLine();

  static const double _nodeH = 40.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideH = (constraints.maxHeight - _nodeH) / 2;
        return SizedBox(
          width: 1,
          child: Column(
            children: [
              Container(
                width: 1,
                height: sideH,
                color: AppColors.borderGold.withValues(alpha: 0.5),
              ),
              Container(
                width: 1,
                height: _nodeH,
                color: AppColors.gold,
              ),
              Container(
                width: 1,
                height: sideH,
                color: AppColors.borderGold.withValues(alpha: 0.5),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Login Input ──────────────────────────────────────────────────────────────

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
        Text(
          widget.label,
          style: AppTextStyles.labelSmall
              .copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppDimens.space8),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.isPassword,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onSubmitted,
          style: AppTextStyles.bodyM.copyWith(color: AppColors.textPrimary),
          cursorColor: AppColors.gold,
          autovalidateMode: _touched
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          validator: widget.validator,
          decoration: InputDecoration(
            prefixIcon: Icon(widget.icon, color: AppColors.textSecondary),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
              borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
              borderSide:
                  const BorderSide(color: AppColors.danger, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
              borderSide:
                  const BorderSide(color: AppColors.danger, width: 1.5),
            ),
            errorStyle:
                AppTextStyles.labelSmall.copyWith(color: AppColors.danger),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimens.space20,
              vertical: AppDimens.space16,
            ),
          ),
        ),
      ],
    );
  }
}
