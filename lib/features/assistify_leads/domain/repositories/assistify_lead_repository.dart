import 'package:botslode/features/assistify_leads/domain/models/assistify_lead.dart';

abstract class AssistifyLeadRepository {
  Future<List<AssistifyLead>> getAll({int? limit, int? offset});
}
