import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thrown when an account is temporarily locked out after too many failed
/// password attempts. [remainingSeconds] drives the login countdown UI.
class RateLimitException implements Exception {
  final int remainingSeconds;

  const RateLimitException(this.remainingSeconds);

  @override
  String toString() =>
      'Too many failed attempts. Try again in $remainingSeconds seconds.';
}

/// Persisted login rate limiter.
///
/// Tracks failed password attempts per identifier (admin username or student
/// ID). After [maxAttempts] consecutive wrong passwords the identifier is
/// locked for [lockDuration] (5 minutes by default). A successful login
/// clears the counter. The lock survives app restarts because the state is
/// stored in [SharedPreferences].
class LoginRateLimiter {
  LoginRateLimiter._();

  static final LoginRateLimiter instance = LoginRateLimiter._();

  /// Wrong-password attempts allowed before locking.
  static const int maxAttempts = 5;

  /// How long an identifier stays locked after hitting [maxAttempts].
  /// Mutable so tests can shrink it.
  @visibleForTesting
  static Duration lockDuration = const Duration(minutes: 5);

  static const String _key = 'login_attempts';

  /// identifier (lowercased) → { 'count': int, 'until': epoch ms }.
  Map<String, Map<String, int>> _state = {};

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      _state = {};
      return;
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _state = decoded.map(
        (id, entry) => MapEntry(id, (entry as Map).cast<String, int>()),
      );
    } catch (_) {
      _state = {};
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_state));
  }

  String _keyFor(String identifier) => identifier.trim().toLowerCase();

  /// Seconds left on the lock for [identifier] (0 = not locked).
  Future<int> remainingLockSeconds(String identifier) async {
    await _load();
    final key = _keyFor(identifier);
    final entry = _state[key];
    if (entry == null) return 0;
    final until = entry['until'] ?? 0;
    if (until <= 0) return 0; // not locked — keep the failure count
    final remaining = until - DateTime.now().millisecondsSinceEpoch;
    if (remaining <= 0) {
      // Lock expired — clean it up so the next attempt is allowed.
      _state.remove(key);
      await _save();
      return 0;
    }
    return (remaining / 1000).ceil();
  }

  /// Attempts left before the identifier locks (5 → 1; 0 while locked).
  Future<int> remainingAttempts(String identifier) async {
    await _load();
    final key = _keyFor(identifier);
    final entry = _state[key];
    if (entry == null) return maxAttempts;
    final until = entry['until'] ?? 0;
    if (until > DateTime.now().millisecondsSinceEpoch) return 0; // locked
    return maxAttempts - (entry['count'] ?? 0);
  }

  /// Registers one failed password attempt. If this attempt reaches
  /// [maxAttempts], the identifier is locked and the lock duration in
  /// seconds is returned; otherwise 0 is returned. Extra failures while
  /// locked do not extend the lock.
  Future<int> recordFailure(String identifier) async {
    await _load();
    final key = _keyFor(identifier);
    final now = DateTime.now().millisecondsSinceEpoch;
    final entry = _state[key];

    // Already locked — keep the original lock, don't extend it.
    if (entry != null && (entry['until'] ?? 0) > now) {
      return ((entry['until']! - now) / 1000).ceil();
    }

    final count = (entry?['count'] ?? 0) + 1;
    if (count >= maxAttempts) {
      _state[key] = {
        'count': 0,
        'until': now + lockDuration.inMilliseconds,
      };
      await _save();
      return lockDuration.inSeconds;
    }

    _state[key] = {'count': count, 'until': 0};
    await _save();
    return 0;
  }

  /// Clears the failure history after a successful login.
  Future<void> clear(String identifier) async {
    await _load();
    if (_state.remove(_keyFor(identifier)) != null) {
      await _save();
    }
  }
}