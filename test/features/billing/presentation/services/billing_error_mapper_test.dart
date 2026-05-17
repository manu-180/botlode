// Archivo: test/features/billing/presentation/services/billing_error_mapper_test.dart
//
// T4·21 — Tests unitarios para BillingErrorMapper.
//
// Cobertura:
//   - parseStripeError: 1 caso por código (9 total)
//   - parseMpError: 1 caso por código (9 total)
//   - mapBillingError: SocketException, TimeoutException, MP string,
//     Stripe string, heurísticas, fallback unknown

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:botslode/features/billing/presentation/services/billing_error_mapper.dart';
import 'package:botslode/l10n/app_strings.dart';

void main() {
  // -------------------------------------------------------------------------
  // parseStripeError
  // -------------------------------------------------------------------------

  group('parseStripeError', () {
    test('card_declined', () {
      expect(
        BillingErrorMapper.parseStripeError('card_declined'),
        BillingErrorCode.cardDeclined,
      );
    });

    test('insufficient_funds', () {
      expect(
        BillingErrorMapper.parseStripeError('insufficient_funds'),
        BillingErrorCode.insufficientFunds,
      );
    });

    test('expired_card', () {
      expect(
        BillingErrorMapper.parseStripeError('expired_card'),
        BillingErrorCode.expiredCard,
      );
    });

    test('incorrect_cvc', () {
      expect(
        BillingErrorMapper.parseStripeError('incorrect_cvc'),
        BillingErrorCode.incorrectCvc,
      );
    });

    test('processing_error', () {
      expect(
        BillingErrorMapper.parseStripeError('processing_error'),
        BillingErrorCode.processingError,
      );
    });

    test('authentication_required', () {
      expect(
        BillingErrorMapper.parseStripeError('authentication_required'),
        BillingErrorCode.authenticationRequired,
      );
    });

    test('network_error', () {
      expect(
        BillingErrorMapper.parseStripeError('network_error'),
        BillingErrorCode.networkError,
      );
    });

    test('gateway_timeout', () {
      expect(
        BillingErrorMapper.parseStripeError('gateway_timeout'),
        BillingErrorCode.gatewayTimeout,
      );
    });

    test('unknown code falls back to unknown', () {
      expect(
        BillingErrorMapper.parseStripeError('do_not_honor'),
        BillingErrorCode.unknown,
      );
    });
  });

  // -------------------------------------------------------------------------
  // parseMpError
  // -------------------------------------------------------------------------

  group('parseMpError', () {
    test('cc_rejected_insufficient_amount → insufficientFunds', () {
      expect(
        BillingErrorMapper.parseMpError('cc_rejected_insufficient_amount'),
        BillingErrorCode.insufficientFunds,
      );
    });

    test('cc_rejected_bad_filled_date → expiredCard', () {
      expect(
        BillingErrorMapper.parseMpError('cc_rejected_bad_filled_date'),
        BillingErrorCode.expiredCard,
      );
    });

    test('cc_rejected_bad_filled_security_code → incorrectCvc', () {
      expect(
        BillingErrorMapper.parseMpError('cc_rejected_bad_filled_security_code'),
        BillingErrorCode.incorrectCvc,
      );
    });

    test('cc_rejected_call_for_authorize → authenticationRequired', () {
      expect(
        BillingErrorMapper.parseMpError('cc_rejected_call_for_authorize'),
        BillingErrorCode.authenticationRequired,
      );
    });

    test('cc_rejected_other_reason → processingError', () {
      expect(
        BillingErrorMapper.parseMpError('cc_rejected_other_reason'),
        BillingErrorCode.processingError,
      );
    });

    test('cc_rejected_card_disabled → processingError', () {
      expect(
        BillingErrorMapper.parseMpError('cc_rejected_card_disabled'),
        BillingErrorCode.processingError,
      );
    });

    test('cc_rejected_bad_filled_card_number → cardDeclined', () {
      expect(
        BillingErrorMapper.parseMpError('cc_rejected_bad_filled_card_number'),
        BillingErrorCode.cardDeclined,
      );
    });

    test('cc_rejected_high_risk → cardDeclined', () {
      expect(
        BillingErrorMapper.parseMpError('cc_rejected_high_risk'),
        BillingErrorCode.cardDeclined,
      );
    });

    test('unknown MP code falls back to unknown', () {
      expect(
        BillingErrorMapper.parseMpError('cc_rejected_new_future_code'),
        BillingErrorCode.unknown,
      );
    });
  });

  // -------------------------------------------------------------------------
  // describe — messages ≤ 120 chars and no raw codes
  // -------------------------------------------------------------------------

  group('describe — all codes return non-empty actionable strings', () {
    for (final code in BillingErrorCode.values) {
      test('$code', () {
        final msg = BillingErrorMapper.describe(code);
        expect(msg, isNotEmpty);
        expect(msg.length, lessThanOrEqualTo(120));
        // No debe exponer códigos técnicos al usuario
        expect(msg, isNot(contains('_error')));
        expect(msg, isNot(contains('cc_rejected')));
      });
    }
  });

  // -------------------------------------------------------------------------
  // mapBillingError
  // -------------------------------------------------------------------------

  group('mapBillingError', () {
    test('SocketException → networkError message', () {
      final result = BillingErrorMapper.mapBillingError(
        const SocketException('no connection'),
      );
      expect(result, AppStrings.billingErrNetworkError);
    });

    test('TimeoutException → gatewayTimeout message', () {
      final result = BillingErrorMapper.mapBillingError(
        TimeoutException('timeout'),
      );
      expect(result, AppStrings.billingErrGatewayTimeout);
    });

    test('MP status_detail string → correct message', () {
      final result = BillingErrorMapper.mapBillingError(
        'cc_rejected_insufficient_amount',
      );
      expect(result, AppStrings.billingErrInsufficientFunds);
    });

    test('Stripe error code string → correct message', () {
      final result = BillingErrorMapper.mapBillingError('expired_card');
      expect(result, AppStrings.billingErrExpiredCard);
    });

    test('Exception wrapping Stripe code → correct message', () {
      final result = BillingErrorMapper.mapBillingError(
        Exception('card_declined'),
      );
      expect(result, AppStrings.billingErrCardDeclined);
    });

    test('Exception wrapping MP code → correct message', () {
      final result = BillingErrorMapper.mapBillingError(
        Exception('cc_rejected_bad_filled_security_code'),
      );
      expect(result, AppStrings.billingErrIncorrectCvc);
    });

    test('text heuristic: "insufficient funds" → insufficientFunds', () {
      final result = BillingErrorMapper.mapBillingError(
        Exception('Transaction failed: insufficient funds available'),
      );
      expect(result, AppStrings.billingErrInsufficientFunds);
    });

    test('text heuristic: "network" → networkError', () {
      final result = BillingErrorMapper.mapBillingError(
        Exception('network unavailable'),
      );
      expect(result, AppStrings.billingErrNetworkError);
    });

    test('text heuristic: "timeout" → gatewayTimeout', () {
      final result = BillingErrorMapper.mapBillingError(
        Exception('Request timed out'),
      );
      expect(result, AppStrings.billingErrGatewayTimeout);
    });

    test('text heuristic: "expired" → expiredCard', () {
      final result = BillingErrorMapper.mapBillingError(
        Exception('Card expired or invalid'),
      );
      expect(result, AppStrings.billingErrExpiredCard);
    });

    test('text heuristic: "cvc" → incorrectCvc', () {
      final result = BillingErrorMapper.mapBillingError(
        Exception('Invalid cvc provided'),
      );
      expect(result, AppStrings.billingErrIncorrectCvc);
    });

    test('text heuristic: "authentication" → authenticationRequired', () {
      final result = BillingErrorMapper.mapBillingError(
        Exception('authentication required by issuer'),
      );
      expect(result, AppStrings.billingErrAuthenticationRequired);
    });

    test('text heuristic: "declined" → cardDeclined', () {
      final result = BillingErrorMapper.mapBillingError(
        Exception('Transaction declined by bank'),
      );
      expect(result, AppStrings.billingErrCardDeclined);
    });

    test('completely unknown error → unknown fallback', () {
      final result = BillingErrorMapper.mapBillingError(
        Exception('something totally unexpected happened'),
      );
      expect(result, AppStrings.billingErrUnknown);
    });

    test('fallback message contains no raw code', () {
      final result = BillingErrorMapper.mapBillingError(
        Exception('xyz_mystery_code_42'),
      );
      expect(result, isNotEmpty);
      expect(result.length, lessThanOrEqualTo(120));
    });
  });
}
