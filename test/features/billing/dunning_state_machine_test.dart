import 'package:flutter_test/flutter_test.dart';
import 'package:botslode/features/billing/domain/dunning/dunning_state.dart';
import 'package:botslode/features/billing/domain/dunning/dunning_state_machine.dart';

void main() {
  const machine = DunningStateMachine();

  final firstFailed = DateTime.utc(2026, 1, 1);

  DunningAttempt failedAttempt(DateTime at) =>
      DunningAttempt(attemptedAt: at, succeeded: false);

  group('DunningStateMachine', () {
    test('0 attempts → retry at +7 days', () {
      final ctx = DunningContext(
        firstFailedAt: firstFailed,
        attempts: [],
        now: firstFailed,
      );

      final decision = machine.decide(ctx);

      expect(decision.action, DunningAction.retry);
      expect(decision.nextRetryAt, firstFailed.add(const Duration(days: 7)));
    });

    test('1 failed attempt → retry at +14 days', () {
      final ctx = DunningContext(
        firstFailedAt: firstFailed,
        attempts: [failedAttempt(firstFailed.add(const Duration(days: 7)))],
        now: firstFailed.add(const Duration(days: 7)),
      );

      final decision = machine.decide(ctx);

      expect(decision.action, DunningAction.retry);
      expect(decision.nextRetryAt, firstFailed.add(const Duration(days: 14)));
    });

    test('2 failed attempts → notifyAndRetry at +21 days', () {
      final ctx = DunningContext(
        firstFailedAt: firstFailed,
        attempts: [
          failedAttempt(firstFailed.add(const Duration(days: 7))),
          failedAttempt(firstFailed.add(const Duration(days: 14))),
        ],
        now: firstFailed.add(const Duration(days: 14)),
      );

      final decision = machine.decide(ctx);

      expect(decision.action, DunningAction.notifyAndRetry);
      expect(decision.nextRetryAt, firstFailed.add(const Duration(days: 21)));
    });

    test('3 failed attempts → suspend', () {
      final ctx = DunningContext(
        firstFailedAt: firstFailed,
        attempts: [
          failedAttempt(firstFailed.add(const Duration(days: 7))),
          failedAttempt(firstFailed.add(const Duration(days: 14))),
          failedAttempt(firstFailed.add(const Duration(days: 21))),
        ],
        now: firstFailed.add(const Duration(days: 21)),
      );

      final decision = machine.decide(ctx);

      expect(decision.action, DunningAction.suspend);
      expect(decision.nextRetryAt, isNull);
    });

    test('3+ attempts AND 35+ days → softDelete overrides suspend', () {
      final ctx = DunningContext(
        firstFailedAt: firstFailed,
        attempts: [
          failedAttempt(firstFailed.add(const Duration(days: 7))),
          failedAttempt(firstFailed.add(const Duration(days: 14))),
          failedAttempt(firstFailed.add(const Duration(days: 21))),
        ],
        now: firstFailed.add(const Duration(days: 36)),
      );

      final decision = machine.decide(ctx);

      expect(decision.action, DunningAction.softDelete);
      expect(decision.nextRetryAt, isNull);
    });

    test('decision is deterministic given same input', () {
      final ctx = DunningContext(
        firstFailedAt: firstFailed,
        attempts: [],
        now: firstFailed,
      );

      final d1 = machine.decide(ctx);
      final d2 = machine.decide(ctx);

      expect(d1.action, d2.action);
      expect(d1.nextRetryAt, d2.nextRetryAt);
      expect(d1.reason, d2.reason);
    });

    test('exactly 35 days → softDelete boundary', () {
      final ctx = DunningContext(
        firstFailedAt: firstFailed,
        attempts: [
          failedAttempt(firstFailed.add(const Duration(days: 7))),
          failedAttempt(firstFailed.add(const Duration(days: 14))),
          failedAttempt(firstFailed.add(const Duration(days: 21))),
        ],
        now: firstFailed.add(const Duration(days: 35)),
      );

      final decision = machine.decide(ctx);
      expect(decision.action, DunningAction.softDelete);
    });
  });
}
