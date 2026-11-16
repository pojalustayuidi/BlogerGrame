/// Contract for the current guest identity. Token implementation stays private
/// to the data layer; UI never receives access/refresh tokens.
abstract class AuthRepository {
  Future<String> getPlayerId();
}
