// Archivo: lib/features/bot_engine/presentation/providers/bot_mood_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para el estado del "mood" (ánimo/estado emocional) del bot
/// 
/// Este provider controla qué animación facial debe mostrar el bot en Rive.
/// Los índices corresponden a diferentes estados:
/// - 0: Neutral
/// - 1: Enojado (angry)
/// - 2: Feliz (happy/funny)
/// - 3: Vendedor (sales/offer)
/// - 4: Confundido (confused/error)
/// - 5: Técnico (tech/code)
/// 
/// AUTO DISPOSE: Se resetea automáticamente cuando el widget se desmonta
final terminalBotMoodProvider = StateProvider.autoDispose<int>((ref) => 0);

/// Provider para la posición del cursor/pointer sobre el bot
/// 
/// Permite tracking del mouse para que el bot "siga" la mirada del usuario.
/// Null indica que no hay tracking activo.
final terminalPointerPositionProvider = StateProvider.autoDispose<Offset?>((ref) => null);
