import 'package:attendancesystem/screens/auth/login_screen.dart';
import 'package:attendancesystem/services/login_rate_limiter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:attendancesystem/widgets/custom_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    LoginRateLimiter.lockDuration = const Duration(minutes: 5);
  });

  tearDown(() async {
    LoginRateLimiter.lockDuration = const Duration(minutes: 5);
  });

  group('LoginRateLimiter', () {
    test('five wrong passwords lock the identifier for five minutes', () async {
      for (var i = 0; i < LoginRateLimiter.maxAttempts - 1; i++) {
        expect(await LoginRateLimiter.instance.recordFailure('admin'), 0);
        expect(await LoginRateLimiter.instance.remainingLockSeconds('admin'), 0);
      }
      // 5th failure triggers the lock.
      final locked = await LoginRateLimiter.instance.recordFailure('admin');
      expect(locked, greaterThanOrEqualTo(299)); // ~5 minutes
      expect(
        await LoginRateLimiter.instance.remainingLockSeconds('admin'),
        greaterThanOrEqualTo(299),
      );
      expect(await LoginRateLimiter.instance.remainingAttempts('admin'), 0);
    });

    test('extra failures while locked do not extend the lock', () async {
      for (var i = 0; i < LoginRateLimiter.maxAttempts; i++) {
        await LoginRateLimiter.instance.recordFailure('admin');
      }
      final first = await LoginRateLimiter.instance.remainingLockSeconds('admin');
      // A failure while locked keeps the original lock (no extension).
      final stillLocked = await LoginRateLimiter.instance.recordFailure('admin');
      expect(stillLocked, lessThanOrEqualTo(first));
    });

    test('successful login clears the failure history', () async {
      for (var i = 0; i < 3; i++) {
        await LoginRateLimiter.instance.recordFailure('admin');
      }
      expect(await LoginRateLimiter.instance.remainingAttempts('admin'), 2);

      await LoginRateLimiter.instance.clear('admin');
      expect(await LoginRateLimiter.instance.remainingAttempts('admin'),
          LoginRateLimiter.maxAttempts);
      expect(await LoginRateLimiter.instance.remainingLockSeconds('admin'), 0);
    });

    test('lock expires after the duration', () async {
      LoginRateLimiter.lockDuration = const Duration(milliseconds: 50);
      for (var i = 0; i < LoginRateLimiter.maxAttempts; i++) {
        await LoginRateLimiter.instance.recordFailure('admin');
      }
      expect(
        await LoginRateLimiter.instance.remainingLockSeconds('admin'),
        greaterThan(0),
      );

      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(await LoginRateLimiter.instance.remainingLockSeconds('admin'), 0);
    });

    test('tracking is per identifier', () async {
      await LoginRateLimiter.instance.recordFailure('2026-0001');
      await LoginRateLimiter.instance.recordFailure('2026-0001');
      expect(await LoginRateLimiter.instance.remainingAttempts('2026-0001'), 3);
      expect(await LoginRateLimiter.instance.remainingAttempts('admin'),
          LoginRateLimiter.maxAttempts);
    });
  });

  group('LoginScreen', () {
    testWidgets('locked identifier shows countdown and disables the form',
        (tester) async {
      // A generous lock window absorbs wall-clock drift between the lock
      // being recorded (real time) and the fake-clock pumps below.
      LoginRateLimiter.lockDuration = const Duration(seconds: 10);
      for (var i = 0; i < LoginRateLimiter.maxAttempts; i++) {
        await LoginRateLimiter.instance.recordFailure('admin');
      }

      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).first, 'admin');
      await tester.pump(); // onChanged → _checkLock
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Too many failed attempts'), findsOneWidget);
      expect(find.text('Locked'), findsOneWidget);
      expect(
        tester.widget<CustomButton>(find.byType(CustomButton)).onPressed,
        isNull,
      );

      // Countdown ticks down…
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Too many failed attempts'), findsOneWidget);

      // …and the form unlocks once it reaches zero.
      await tester.pump(const Duration(seconds: 11));
      expect(find.textContaining('Too many failed attempts'), findsNothing);
      expect(find.text('Login'), findsOneWidget);
    });
  });
}
