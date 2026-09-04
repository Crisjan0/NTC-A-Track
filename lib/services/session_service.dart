import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Represents the currently logged-in user.
class Session {
  final String role; // 'admin' | 'student'
  final String username;
  final String? studentId;
  final String? fullName;

  const Session({
    required this.role,
    required this.username,
    this.studentId,
    this.fullName,
  });

  bool get isAdmin => role == 'admin';
  bool get isStudent => role == 'student';

  Map<String, dynamic> toJson() => {
        'role': role,
        'username': username,
        'studentId': studentId,
        'fullName': fullName,
      };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        role: json['role'] as String,
        username: json['username'] as String,
        studentId: json['studentId'] as String?,
        fullName: json['fullName'] as String?,
      );
}

/// Persists the active session so the app re-opens into the right dashboard.
class SessionService {
  SessionService._();

  static final SessionService instance = SessionService._();

  static const _key = 'active_session';
  Session? _current;

  Session? get current => _current;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        _current = Session.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        _current = null;
      }
    }
  }

  Future<void> save(Session session) async {
    _current = session;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(session.toJson()));
  }

  Future<void> clear() async {
    _current = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}