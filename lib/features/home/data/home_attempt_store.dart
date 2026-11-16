import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/backend_exception.dart';
import '../../game/domain/game_models.dart';
import '../../game/domain/game_repository.dart';

/// Only a pointer to the known attempt is persisted here, never token data,
/// puzzle correctness, rewards or the source quote. Tokens stay in SecureStorage.
/// The key is scoped to the actual backend player to avoid cross-account reuse.
class HomeAttemptStore {
  static const _prefix = 'prufani_active_attempt_v1_';

  Future<String?> read(String playerId) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString('$_prefix$playerId');
  }

  Future<void> save(String playerId, PuzzleAttempt attempt) async {
    if (attempt.status != 'in_progress') return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('$_prefix$playerId', attempt.id);
  }

  Future<void> clear(String playerId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('$_prefix$playerId');
  }

  /// Validates with the real server on every fresh dashboard fetch.
  /// Network/session failures must NOT erase the saved pointer.
  Future<PuzzleAttempt?> loadValidated(
      String playerId, GameRepository repository) async {
    final id = await read(playerId);
    if (id == null) return null;
    try {
      final attempt = await repository.getAttempt(id);
      if (attempt.status != 'in_progress') {
        await clear(playerId);
        return null;
      }
      return attempt;
    } on BackendException catch (error) {
      if (error.httpStatus == 404) {
        await clear(playerId);
        return null;
      }
      rethrow;
    }
  }
}
