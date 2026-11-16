import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A single Secure Storage entry holds the token pair and their expirations.
/// Unlike SharedPreferences, this uses protected platform storage.
class StoredGuestSession {
  final String accessToken;
  final String refreshToken;
  final DateTime accessExpiresAt;
  final DateTime refreshExpiresAt;

  const StoredGuestSession({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
    required this.refreshExpiresAt,
  });

  bool get accessExpiringSoon =>
      DateTime.now().toUtc().add(const Duration(seconds: 45))
          .isAfter(accessExpiresAt.toUtc());

  factory StoredGuestSession.fromResponse(Map<String, dynamic> json) {
    final access = json['accessToken'] as String;
    final refresh = json['refreshToken'] as String;
    if (access.isEmpty || refresh.isEmpty) {
      throw const FormatException('Empty authentication tokens');
    }
    return StoredGuestSession(
      accessToken: access,
      refreshToken: refresh,
      accessExpiresAt: DateTime.parse(json['accessExpiresAt'] as String),
      refreshExpiresAt: DateTime.parse(json['refreshExpiresAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'accessExpiresAt': accessExpiresAt.toUtc().toIso8601String(),
        'refreshExpiresAt': refreshExpiresAt.toUtc().toIso8601String(),
      };

  factory StoredGuestSession.fromJson(Map<String, dynamic> json) =>
      StoredGuestSession.fromResponse(json);
}

class SecureSessionStore {
  static const _key = 'blogergrame_guest_session_v1';
  final FlutterSecureStorage _storage;

  SecureSessionStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  Future<StoredGuestSession?> read() async {
    final value = await _storage.read(key: _key);
    if (value == null) return null;
    return StoredGuestSession.fromJson(
      Map<String, dynamic>.from(jsonDecode(value) as Map),
    );
  }

  Future<void> save(StoredGuestSession session) =>
      _storage.write(key: _key, value: jsonEncode(session.toJson()));

  Future<void> clear() => _storage.delete(key: _key);
}
