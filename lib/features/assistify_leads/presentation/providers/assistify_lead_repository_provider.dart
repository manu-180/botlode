import 'package:botslode/core/providers/supabase_provider.dart';
import 'package:botslode/features/assistify_leads/data/repositories/assistify_lead_repository_impl.dart';
import 'package:botslode/features/assistify_leads/domain/repositories/assistify_lead_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final assistifyLeadRepositoryProvider = Provider<AssistifyLeadRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AssistifyLeadRepositoryImpl(client);
});
