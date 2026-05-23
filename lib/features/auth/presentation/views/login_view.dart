// Archivo: lib/features/auth/presentation/views/login_view.dart
import 'dart:async';
import 'dart:ui';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_icons.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/providers/auth_provider.dart';
import 'package:botslode/core/providers/rive_provider.dart';
import 'package:botslode/core/ui/app_background.dart';
import 'package:botslode/core/ui/hud/hud_corner_brackets.dart';
import 'package:botslode/core/ui/hud/hud_scanlines.dart';
import 'package:botslode/core/ui/responsive/breakpoints.dart';
import 'package:botslode/core/ui/toasts/toast_service.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';
import 'package:botslode/core/ui/widgets/app_text_field.dart';
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
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _emailKey = GlobalKey<AppTextFieldState>();
  final _passKey = GlobalKey<AppTextFieldState>();
  final _emailFocusNode = FocusNode();
  final _passFocusNode = FocusNode();

  bool _rememberSession = false;
  Timer? _moodTimer;

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
    // Auto-focus email after panel entry animation completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(AppMotion.durDeliberate, () {
        if (mounted) _emailFocusNode.requestFocus();
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    _emailFocusNode.dispose();
    _passFocusNode.dispose();
    _moodTimer?.cancel();
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

  void _submit() {
    final emailOk = _emailKey.currentState?.validate() ?? false;
    final passOk = _passKey.currentState?.validate() ?? false;
    if (!emailOk || !passOk) {
      if (!emailOk) {
        _emailFocusNode.requestFocus();
      } else {
        _passFocusNode.requestFocus();
      }
      return;
    }
    final email = _emailController.text.trim();
    final pass = _passController.text.trim();
    ref.read(authProvider.notifier).signIn(email, pass);
  }

  static String? _validateEmail(String? val) {
    if (val == null || val.isEmpty) return 'Requerido';
    if (!val.contains('@')) return 'Formato de correo inválido';
    return null;
  }

  static String? _validatePass(String? val) {
    if (val == null || val.isEmpty) return 'Requerido';
    if (val.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final riveFileAsync = ref.watch(riveFullBotFileProvider);
    final reduce = AppMotion.reduced(context);

    ref.listen(authProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        _moodInput?.value = 1.0;
        ToastService.show(
          context: context,
          type: ToastType.error,
          title: 'ACCESO DENEGADO',
          message: next.error!,
          duration: const Duration(seconds: 8),
        );
        _moodTimer?.cancel();
        _moodTimer = Timer(const Duration(seconds: 9), () {
          if (mounted) _moodInput?.value = 3.0;
        });
      }
    });

    final isMobile = Breakpoints.isMobile(context);

    if (isMobile) {
      // En mobile el panel cinematográfico izquierdo no aporta — el formulario
      // ocupa toda la pantalla con el fondo ambiental detrás.
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            const Positioned.fill(
              child: AppBackground(showBlobs: false, child: SizedBox()),
            ),
            Positioned.fill(child: _buildRightPanel(authState, reduce)),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
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
                      // Capa 1: fondo ambiental
                      const Positioned.fill(
                        child: AppBackground(
                          showBlobs: false,
                          child: SizedBox(),
                        ),
                      ),

                      // Capa 2: Rive Catbot
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
                                child: AppIcons.icon(
                                  Icons.broken_image_outlined,
                                  size: AppDimens.iconM,
                                  color: AppColors.textTertiary,
                                ).animate().fadeIn(duration: AppMotion.durBase),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Capa 3a: viñeta radial
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

                      // Capa 3b: gradiente inferior
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

                      // Capa 4: scanlines
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

                      // Capa 5: brackets de esquina
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
                                // Stagger delay — above durStagger(36ms) by design
                                delay: const Duration(milliseconds: 80),
                              ),
                        ),
                      ),

                      // Capa 6: bloque de marca
                      Positioned(
                        left: AppDimens.space48,
                        bottom: AppDimens.space48,
                        child: _BrandBlock(reduce: reduce),
                      ),

                      // Capa 7: costura HUD vertical
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

          // --- DERECHA: PANEL DE IDENTIFICACIÓN HUD ---
          Expanded(
            flex: 42,
            child: _buildRightPanel(authState, reduce),
          ),
        ],
      ),
    );
  }

  // ─── Panel derecho ────────────────────────────────────────────────────────

  Widget _buildRightPanel(AuthStateData authState, bool reduce) {
    final panel = Stack(
      children: [
        // Fondo con gradiente de panel
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.gradPanel),
          ),
        ),

        // Formulario central
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.space48),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Anillo HUD del candado
                  _buildLockRing(reduce),
                  const SizedBox(height: AppDimens.space24),

                  // Título
                  _maybeAnimate(
                    child: Text(
                      'IDENTIFICACIÓN REQUERIDA',
                      style: AppTextStyles.displayM,
                    ),
                    reduce: reduce,
                    delay: 200.ms,
                    moveY: 8,
                  ),
                  const SizedBox(height: AppDimens.space8),

                  // Subtítulo
                  _maybeAnimate(
                    child: Text(
                      'Ingrese sus credenciales para acceder al núcleo.',
                      style: AppTextStyles.bodyS,
                    ),
                    reduce: reduce,
                    delay: 280.ms,
                    moveY: 8,
                  ),
                  const SizedBox(height: AppDimens.space40),

                  // Campos del formulario
                  _maybeAnimate(
                    child: _buildFormFields(),
                    reduce: reduce,
                    delay: 360.ms,
                    moveY: 10,
                  ),
                  const SizedBox(height: AppDimens.space16),

                  // Recordar sesión
                  _maybeAnimate(
                    child: _buildRememberRow(),
                    reduce: reduce,
                    delay: 420.ms,
                  ),
                  const SizedBox(height: AppDimens.space32),

                  // Botón de acceso
                  _maybeAnimate(
                    child: _buildSubmitButton(authState),
                    reduce: reduce,
                    delay: 460.ms,
                    moveY: 8,
                  ),
                ],
              ),
            ),
          ),
        ),

        // HUD brackets overlay
        const Positioned.fill(
          child: IgnorePointer(
            child: Padding(
              padding: EdgeInsets.all(AppDimens.space24),
              child: HudCornerBrackets(
                armLength: 18,
                thickness: 1.5,
                color: AppColors.borderGold,
                child: SizedBox(),
              ),
            ),
          ),
        ),
      ],
    );

    if (reduce) return panel;

    return panel
        .animate()
        .fadeIn(duration: AppMotion.durSlow, curve: AppMotion.easeEntrance)
        .moveX(
          begin: 24,
          end: 0,
          duration: AppMotion.durSlow,
          curve: AppMotion.easeEntrance,
        );
  }

  Widget _buildLockRing(bool reduce) {
    final ring = SizedBox(
      width: AppDimens.space48,
      height: AppDimens.space48,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceHud,
          border: Border.all(color: AppColors.borderGold, width: 1.5),
          boxShadow: AppDimens.glowGold,
        ),
        child: Center(
          child: AppIcons.icon(AppIcons.lock, size: AppDimens.iconM, color: AppColors.gold),
        ),
      ),
    );

    if (reduce) return ring;

    return ring
        .animate(delay: 120.ms)
        .fadeIn(duration: AppMotion.durBase, curve: AppMotion.easeEntrance)
        .scaleXY(
          begin: 0.85,
          end: 1.0,
          duration: AppMotion.durBase,
          curve: AppMotion.easeEntrance,
        );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        AppTextField(
          key: _emailKey,
          controller: _emailController,
          label: 'CORREO ELECTRÓNICO',
          labelMode: AppTextFieldLabelMode.top,
          prefixIcon: AppIcons.user,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          focusNode: _emailFocusNode,
          onSubmitted: (_) => _passFocusNode.requestFocus(),
          validator: _validateEmail,
        ),
        const SizedBox(height: AppDimens.space20),
        AppTextField(
          key: _passKey,
          controller: _passController,
          label: 'CLAVE DE ACCESO',
          labelMode: AppTextFieldLabelMode.top,
          variant: AppTextFieldVariant.password,
          prefixIcon: AppIcons.lock,
          textInputAction: TextInputAction.done,
          focusNode: _passFocusNode,
          onSubmitted: (_) => _submit(),
          validator: _validatePass,
        ),
      ],
    );
  }

  Widget _buildRememberRow() {
    return Row(
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: Transform.scale(
            scale: 0.85,
            child: Checkbox(
              value: _rememberSession,
              onChanged: (val) =>
                  setState(() => _rememberSession = val ?? false),
              side: const BorderSide(
                color: AppColors.borderStrong,
                width: 1.5,
              ),
              fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) return AppColors.gold;
                return Colors.transparent;
              }),
              checkColor: AppColors.textOnGold,
              shape: RoundedRectangleBorder(borderRadius: AppDimens.brXS),
            ),
          ),
        ),
        const SizedBox(width: AppDimens.space8),
        Text('Mantener sesión iniciada', style: AppTextStyles.bodyS),
      ],
    );
  }

  Widget _buildSubmitButton(AuthStateData authState) {
    return AppButton.primary(
      label: authState.isLoading ? 'VERIFICANDO...' : 'ACCEDER AL SISTEMA',
      loading: authState.isLoading,
      onPressed: authState.isLoading ? null : _submit,
      size: AppButtonSize.lg,
      expand: true,
    );
  }

  Widget _maybeAnimate({
    required Widget child,
    required bool reduce,
    Duration? delay,
    double moveY = 0,
  }) {
    if (reduce) return child;
    var animated = child
        .animate(delay: delay ?? Duration.zero)
        .fadeIn(duration: AppMotion.durBase, curve: AppMotion.easeEntrance);
    if (moveY != 0) {
      animated = animated.moveY(
        begin: moveY,
        end: 0,
        duration: AppMotion.durBase,
        curve: AppMotion.easeEntrance,
      );
    }
    return animated;
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
          TextSpan(text: 'BotLod', style: AppTextStyles.displayXL),
          TextSpan(
            text: 'e',
            style: AppTextStyles.displayXL.copyWith(
              color: AppColors.gold,
              shadows: const [
                Shadow(color: AppColors.goldGlow, blurRadius: 16),
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
          tagWidget.animate().fadeIn(duration: AppMotion.durCrossfadeReduced),
          const SizedBox(height: AppDimens.space20),
          titleWidget.animate().fadeIn(duration: AppMotion.durCrossfadeReduced),
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
              Container(width: 1, height: _nodeH, color: AppColors.gold),
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
