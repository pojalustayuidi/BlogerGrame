import 'package:dio/dio.dart';
import 'backend_exception.dart';
import 'secure_session_store.dart';

/// Owns a single guest session. Never silently creates a different player
/// when a stored refresh token is rejected by the backend.
class GuestSessionManager {
  final Dio _publicDio;
  final SecureSessionStore _store;
  StoredGuestSession? _current;
  bool _loaded = false;
  Future<StoredGuestSession>? _initializing;
  Future<StoredGuestSession>? _refreshing;

  GuestSessionManager(this._publicDio, this._store);

  Future<StoredGuestSession> ensureSession() {
    final active = _initializing;
    if (active != null) return active;
    final pending = _ensureSessionInternal();
    _initializing = pending;
    return pending.whenComplete(() => _initializing = null);
  }

  Future<StoredGuestSession> _ensureSessionInternal() async {
    if (!_loaded) {
      _current = await _store.read();
      _loaded = true;
    }
    final current = _current;
    if (current == null) {
      try {
        final response = await _publicDio.post('/api/v1/auth/guest', data: <String, dynamic>{});
        final session = StoredGuestSession.fromResponse(
          Map<String, dynamic>.from(response.data as Map),
        );
        await _store.save(session);
        _current = session;
        return session;
      } on DioException catch (e) {
        throw BackendException.fromDio(e);
      }
    }
    if (current.accessExpiringSoon) return _refreshSession();
    return current;
  }

  /// Used after a 401. If another request already rotated the tokens, reuse
  /// its access token instead of refreshing with an invalidated refresh token.
  Future<StoredGuestSession> refreshAfterUnauthorized(String usedAccessToken) async {
    final inFlight = _refreshing;
    if (inFlight != null) return inFlight;
    final current = _current;
    if (current != null && current.accessToken != usedAccessToken) {
      return current;
    }
    return _refreshSession();
  }

  Future<StoredGuestSession> _refreshSession() {
    final inFlight = _refreshing;
    if (inFlight != null) return inFlight;
    final pending = _rotate();
    _refreshing = pending;
    return pending.whenComplete(() => _refreshing = null);
  }

  Future<StoredGuestSession> _rotate() async {
    final previous = _current;
    if (previous == null) {
      throw const BackendException('NO_SESSION', 'Гостевая сессия отсутствует.');
    }
    try {
      final response = await _publicDio.post('/api/v1/auth/refresh',
          data: {'refreshToken': previous.refreshToken});
      final next = StoredGuestSession.fromResponse(
        Map<String, dynamic>.from(response.data as Map),
      );
      // One Secure Storage write replaces both tokens together.
      await _store.save(next);
      _current = next;
      return next;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const BackendException(
          'SESSION_EXPIRED',
          'Гостевая сессия истекла. Автоматически создавать нового игрока нельзя.',
          httpStatus: 401,
        );
      }
      throw BackendException.fromDio(e);
    }
  }

  /// Explicit-only reset for a deliberate fresh start; not called on network errors.
  Future<void> discardLocalSession() async {
    await _store.clear();
    _current = null;
    _loaded = true;
  }
}
