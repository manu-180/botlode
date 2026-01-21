// Archivo: lib/features/settings/presentation/views/settings_view.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsView extends ConsumerStatefulWidget {
  static const String routeName = 'settings';

  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  // Estado local para los switches (luego se pueden conectar a un provider)
  bool _neuralNotifs = true;
  bool _audioFx = true;
  bool _highPerformance = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Fondo Radial Sutil (Desde abajo a la izquierda esta vez)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.8, 0.8),
                  radius: 1.5,
                  colors: [
                    AppColors.surface.withOpacity(0.8),
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER ---
                    Text(
                      "CONFIGURACIÓN DEL SISTEMA",
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      "Parámetros de enlace neural y preferencias de cuenta",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // --- TARJETA DE PERFIL (OPERADOR) ---
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.borderGlass),
                      ),
                      child: Row(
                        children: [
                          // Avatar con anillo de energía
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 20,
                                )
                              ],
                              color: Colors.black,
                            ),
                            child: const Icon(Icons.person, size: 40, color: Colors.white),
                          ),
                          const SizedBox(width: 24),
                          
                          // Info del Operador
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "OPERADOR: ADMIN",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                ),
                                child: const Text(
                                  "LICENCIA: APEX ENTERPRISE (ILIMITADA)",
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // --- SECCIONES DE CONFIGURACIÓN ---
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          const _SectionHeader(title: "INTERFAZ NEURAL"),
                          _TechSwitch(
                            title: "Notificaciones Neurales",
                            subtitle: "Recibir alertas directas sobre estado de bots.",
                            value: _neuralNotifs,
                            onChanged: (v) => setState(() => _neuralNotifs = v),
                            icon: Icons.notifications_active_outlined,
                          ),
                          _TechSwitch(
                            title: "Efectos de Audio FX",
                            subtitle: "Sonidos de interfaz y alertas de sistema.",
                            value: _audioFx,
                            onChanged: (v) => setState(() => _audioFx = v),
                            icon: Icons.volume_up_outlined,
                          ),

                          const SizedBox(height: 24),

                          const _SectionHeader(title: "RENDIMIENTO DEL NÚCLEO"),
                          _TechSwitch(
                            title: "Modo Alto Rendimiento",
                            subtitle: "Aumenta la tasa de refresco visual. Consume más batería.",
                            value: _highPerformance,
                            onChanged: (v) => setState(() => _highPerformance = v),
                            icon: Icons.speed_rounded,
                            activeColor: AppColors.error, // Rojo para indicar potencia/peligro
                          ),

                          const SizedBox(height: 40),
                          const Divider(color: AppColors.borderGlass),
                          const SizedBox(height: 20),

                          // --- BOTÓN DE CERRAR SESIÓN (PROTOCOLO DE SALIDA) ---
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.error.withOpacity(0.15),
                                    blurRadius: 30,
                                    spreadRadius: 1,
                                  )
                                ],
                              ),
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // Ejecutamos la desconexión en el AuthProvider
                                  // El AppRouter detectará el cambio y redirigirá a /login automáticamente
                                  ref.read(authProvider.notifier).signOut();
                                  GoRouter.of(context).go("/login");
                                },
                                icon: const Icon(Icons.logout_rounded), // Icono de puerta saliendo
                                label: const Text("Cerrar Sesión"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  backgroundColor: Colors.black.withOpacity(0.6),
                                  side: const BorderSide(color: AppColors.error, width: 1.5),
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  textStyle: const TextStyle(
                                    fontFamily: 'Oxanium',
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2.0,
                                    fontSize: 14,
                                  ),
                                ).copyWith(
                                  overlayColor: WidgetStateProperty.all(AppColors.error.withOpacity(0.1)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
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

// Widget Helper para los Headers de Sección
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.borderGlass),
        ],
      ),
    );
  }
}

// Widget Helper para los Switches Tecnológicos
class _TechSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;
  final Color activeColor;

  const _TechSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.icon,
    this.activeColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? activeColor.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
        inactiveThumbColor: AppColors.textSecondary,
        inactiveTrackColor: Colors.black,
        title: Text(
          title,
          style: TextStyle(
            color: value ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 12),
        ),
        secondary: Icon(
          icon,
          color: value ? activeColor : AppColors.textSecondary,
        ),
      ),
    );
  }
}