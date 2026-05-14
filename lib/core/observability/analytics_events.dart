// T15·07 — Catálogo tipado de eventos PostHog para botslode.
// Los strings son los del GLOSSARY canónico — no inventar nuevos sin actualizar
// la doc y el dashboard. Tests unitarios verifican exact match.

enum AnalyticsEvent {
  botCreated,
  botPublished,
  botPaused,
  botDeleted,
  chatStarted,
  chatMessageSent,
  chatMessageReceived,
  leadScoredHot,
  leadAlertSent,
  meetingBooked,
  checkoutInitiated,
  checkoutCompleted,
  subscriptionCreated,
  subscriptionCanceled,
  planUpgraded,
  planDowngraded,
  widgetLoaded,
  widgetOpened,
  widgetClosed,
}

extension AnalyticsEventKey on AnalyticsEvent {
  /// snake_case key esperado por PostHog. Match exacto con GLOSSARY.md.
  String get key {
    switch (this) {
      case AnalyticsEvent.botCreated:
        return 'bot_created';
      case AnalyticsEvent.botPublished:
        return 'bot_published';
      case AnalyticsEvent.botPaused:
        return 'bot_paused';
      case AnalyticsEvent.botDeleted:
        return 'bot_deleted';
      case AnalyticsEvent.chatStarted:
        return 'chat_started';
      case AnalyticsEvent.chatMessageSent:
        return 'chat_message_sent';
      case AnalyticsEvent.chatMessageReceived:
        return 'chat_message_received';
      case AnalyticsEvent.leadScoredHot:
        return 'lead_scored_hot';
      case AnalyticsEvent.leadAlertSent:
        return 'lead_alert_sent';
      case AnalyticsEvent.meetingBooked:
        return 'meeting_booked';
      case AnalyticsEvent.checkoutInitiated:
        return 'checkout_initiated';
      case AnalyticsEvent.checkoutCompleted:
        return 'checkout_completed';
      case AnalyticsEvent.subscriptionCreated:
        return 'subscription_created';
      case AnalyticsEvent.subscriptionCanceled:
        return 'subscription_canceled';
      case AnalyticsEvent.planUpgraded:
        return 'plan_upgraded';
      case AnalyticsEvent.planDowngraded:
        return 'plan_downgraded';
      case AnalyticsEvent.widgetLoaded:
        return 'widget_loaded';
      case AnalyticsEvent.widgetOpened:
        return 'widget_opened';
      case AnalyticsEvent.widgetClosed:
        return 'widget_closed';
    }
  }
}
