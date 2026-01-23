// Archivo: lib/features/bot_engine/presentation/providers/chat_repository_provider.dart
import 'package:botslode/features/bot_engine/data/repositories/chat_repository_impl.dart';
import 'package:botslode/features/bot_engine/domain/repositories/chat_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl();
});