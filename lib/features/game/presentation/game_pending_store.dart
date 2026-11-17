import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// An idempotent letter request that may have reached the server before
/// connectivity was lost. Retrying MUST reuse the same requestId.
class PendingLetterRequest {
  final String attemptId;
  final int position;
  final String letter;
  final String requestId;

  const PendingLetterRequest({
    required this.attemptId,
    required this.position,
    required this.letter,
    required this.requestId,
  });

  Map<String, Object> toJson() => {
        'attemptId': attemptId,
        'position': position,
        'letter': letter,
        'requestId': requestId,
      };

  static PendingLetterRequest? fromJson(Object? raw, String attemptId) {
    if (raw is! Map) return null;
    if (raw['attemptId'] != attemptId ||
        raw['position'] is! int ||
        (raw['position'] as int) < 0 ||
        raw['letter'] is! String ||
        raw['requestId'] is! String) {
      return null;
    }
    final letter = raw['letter'] as String;
    if (!RegExp(r'^[А-ЯЁ]$').hasMatch(letter)) return null;
    return PendingLetterRequest(
      attemptId: attemptId,
      position: raw['position'] as int,
      letter: letter,
      requestId: raw['requestId'] as String,
    );
  }
}

class PendingLetterStore {
  static const _keyPrefix = 'prufani_pending_letter_v1_';

  Future<PendingLetterRequest?> read(String attemptId) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('$_keyPrefix$attemptId');
    if (value == null) return null;
    try {
      return PendingLetterRequest.fromJson(jsonDecode(value), attemptId);
    } on FormatException {
      return null;
    }
  }

  Future<void> save(PendingLetterRequest request) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      '$_keyPrefix${request.attemptId}',
      jsonEncode(request.toJson()),
    );
    if (!saved)
      throw StateError('Не удалось сохранить запрос перед отправкой.');
  }

  Future<void> clear(String attemptId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix$attemptId');
  }
}
