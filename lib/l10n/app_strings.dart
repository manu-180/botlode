// Archivo: lib/l10n/app_strings.dart
//
// Source-of-truth de strings de UI para toda la app.
// Agregar claves aquí; importar desde donde se necesiten.

class AppStrings {
  AppStrings._();

  // ---------------------------------------------------------------------------
  // Billing — mensajes de error de pasarela (T4·21)
  // ---------------------------------------------------------------------------

  static const billingErrCardDeclined =
      'Tu tarjeta fue rechazada. Probá con otra o contactá a tu banco.';

  static const billingErrInsufficientFunds =
      'La tarjeta no tiene saldo suficiente.';

  static const billingErrExpiredCard = 'La tarjeta venció.';

  static const billingErrIncorrectCvc =
      'El código de seguridad es incorrecto.';

  static const billingErrProcessingError =
      'Hubo un problema procesando el pago. Reintentá en unos minutos.';

  static const billingErrAuthenticationRequired =
      'Tu banco requiere autenticación adicional.';

  static const billingErrNetworkError =
      'Sin conexión. Revisá tu internet y reintentá.';

  static const billingErrGatewayTimeout =
      'La pasarela tardó demasiado. Reintentá.';

  static const billingErrUnknown =
      'No pudimos completar el pago. Probá nuevamente o usá otro método.';

  // ---------------------------------------------------------------------------
  // Billing — BillingView (T4·28)
  // ---------------------------------------------------------------------------

  static const billingViewTitle = 'Suscripción y pagos';
  static const billingViewErrorLoad = 'Error al cargar billing';
  static const billingViewRetry = 'Reintentar';
  static const billingViewCurrentPlan = 'Plan actual';
  static const billingViewNoPlan = 'Sin suscripción activa';
  static const billingViewPaymentMethods = 'Métodos de pago';
  static const billingViewNoPaymentMethods = 'Sin métodos de pago registrados';
  static const billingViewAddCard = 'Agregar tarjeta';
  static const billingViewInvoices = 'Facturas';
  static const billingViewNoInvoices = 'Sin facturas';
  static const billingViewHistory = 'Historial';
  static const billingViewHistoryComingSoon =
      'Historial de eventos de billing próximamente.';

  // ---------------------------------------------------------------------------
  // Billing — AddCardModal (T4·28)
  // ---------------------------------------------------------------------------

  static const billingAddCardTitle = 'Agregar método de pago';
  static const billingAddCardSecurityNote = 'Datos protegidos · PCI-DSS Compliant';
  static const billingAddCardGatewayNotConfiguredTitle = 'PASARELA NO CONFIGURADA';
  static const billingAddCardGatewayNotConfiguredMsg =
      'Pasarela de pago no configurada. Contactá al soporte para resolver este problema.';
  static const billingAddCardSetDefault = 'Establecer como predeterminado';
  static const billingAddCardCancel = 'CANCELAR';
  static const billingAddCardSave = 'GUARDAR';
  static const billingAddCardSuccessTitle = 'MÉTODO DE PAGO AGREGADO';
  static const billingAddCardSuccessMsg = 'La tarjeta se vinculó exitosamente.';
  static const billingAddCardClosing = 'CERRANDO...';

  // ---------------------------------------------------------------------------
  // Billing — TrialCountdownBanner (T4·28)
  // ---------------------------------------------------------------------------

  static const billingTrialAddPaymentWarning =
      'Agregá un método de pago para no perder acceso.';
  static const billingTrialAddPaymentCta = 'Agregar método';
  static const billingTrialDaysPrefix = 'QUEDAN ';
  static const billingTrialDaysSuffix = ' DÍAS DE PRUEBA';
  static const billingTrialUpgradeCta = 'MEJORAR AHORA';
  static const billingTrialDismissTooltip = 'Cerrar aviso de prueba';

  // ---------------------------------------------------------------------------
  // Billing — CancelFlowModal (T4·28)
  // ---------------------------------------------------------------------------

  static const billingCancelSuccessPrefix = 'Suscripción cancelada — activa hasta ';
  static const billingCancelComingSoon = 'Disponible próximamente (T5)';
  static const billingCancelErrorMsg =
      'No pudimos procesar la cancelación. Intentá de nuevo.';
  static const billingCancelWhyTitle = '¿Por qué cancelás?';
  static const billingCancelFeedbackLabel = 'Contanos más';
  static const billingCancelContinue = 'Continuar';
  static const billingCancelKeepSubscription = 'Mantener mi suscripción';

  // ---------------------------------------------------------------------------
  // Billing — PlanPicker (T4·28)
  // ---------------------------------------------------------------------------

  static const billingPlanPickerIntervalLabel =
      'Seleccionar intervalo de facturación';
  static const billingPlanPickerMonthly = 'Mensual';
  static const billingPlanPickerAnnual = 'Anual';
  static const billingPlanPickerContactSupport = 'Contactar soporte';
  static const billingPlanPickerCurrentPlanBadge = 'Plan actual';

  // ---------------------------------------------------------------------------
  // Billing — DunningWarningBanner (T4·28)
  // ---------------------------------------------------------------------------

  static const billingDunningUpdatePayment = 'Actualizar método de pago';
  static const billingDunningRetryCharge = 'Reintentar cobro';
  static const billingDunningTitle = 'PAGO RECHAZADO';
  static const billingDunningBodyWithDate =
      'Actualizá tu método de pago. Tu acceso podría suspenderse el ';
  static const billingDunningBodyNoDate =
      'Actualizá tu método de pago. Tu acceso podría suspenderse pronto.';
  static const billingDunningRetryingLabel = 'Reintentando cobro...';
  static const billingDunningRetryLabel =
      'Reintentar cobro - suscripción en riesgo';

  // ---------------------------------------------------------------------------
  // Billing — ReactivateSubscriptionFlow (T4·28)
  // ---------------------------------------------------------------------------

  static const billingReactivateSuccess = 'Suscripción reactivada con éxito.';
  static const billingReactivateComingSoon = 'Disponible próximamente (T5)';

  // ---------------------------------------------------------------------------
  // Billing — ProrationPreviewModal (T4·28)
  // ---------------------------------------------------------------------------

  static const billingProrationSuccess = '¡Plan actualizado exitosamente!';
  static const billingProrationComingSoon = 'Disponible próximamente (T5)';
  static const billingProrationCancel = 'Cancelar';

  // ---------------------------------------------------------------------------
  // Billing — QuotaPaywallModal (T4·28)
  // ---------------------------------------------------------------------------

  static const billingPaywallLater = 'Más tarde';
  static const billingPaywallViewPlans = 'Ver planes';

  // ---------------------------------------------------------------------------
  // Billing — InvoiceList (T4·28)
  // ---------------------------------------------------------------------------

  static const billingInvoiceErrorLoad = 'Error al cargar facturas';
  static const billingInvoiceRetry = 'Reintentar';
  static const billingInvoiceDownloadPdf = 'Descargar PDF';
  static const billingInvoicePdfDownloaded = 'PDF descargado';
  static const billingInvoiceOpenPdf = 'Abrir';
  static const billingInvoiceNoPdf = 'Esta factura no tiene PDF disponible.';
  static const billingInvoiceErrorUnexpected = 'Error inesperado al descargar el PDF.';
  static const billingInvoiceErrUnauthorized = 'URL expirada. Intente de nuevo.';
  static const billingInvoiceErrNotFound = 'Factura no encontrada.';
  static const billingInvoiceErrNetwork = 'Error de red al descargar el PDF.';

  // ---------------------------------------------------------------------------
  // Billing — AutoPaySettingsCard (T4·28)
  // ---------------------------------------------------------------------------

  static const billingAutoPayUpdateError =
      'Error al actualizar. Intentá de nuevo.';

  // ---------------------------------------------------------------------------
  // Billing — PaymentCheckoutModal (T4·28)
  // ---------------------------------------------------------------------------

  static const billingCheckoutClose = 'CERRAR';
  static const billingCheckoutCancel = 'Cancelar';
  static const billingCheckoutAddPaymentMethod = 'Agregar método de pago';

  // ---------------------------------------------------------------------------
  // Billing — ManageCardsModal (T4·28)
  // ---------------------------------------------------------------------------

  static const billingManageCardsDelete = 'Eliminar';
  static const billingManageCardsUpdateError =
      'Error al actualizar. Intenta de nuevo.';
  static const billingManageCardsDeleteTitle = 'Eliminar tarjeta';
  static const billingManageCardsDeleteCancel = 'CANCELAR';
  static const billingManageCardsDeleteConfirm = 'ELIMINAR';
  static const billingManageCardsDeleteError =
      'Error al eliminar la tarjeta. Intenta de nuevo.';
  static const billingManageCardsAddNew = 'AGREGAR NUEVA TARJETA';
}
