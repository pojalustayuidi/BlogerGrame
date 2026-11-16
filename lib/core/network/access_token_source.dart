/// Contract implemented by the auth/data layer. Networking never imports a
/// concrete guest-session manager or secure-storage plugin.
abstract class AccessTokenSource {
  Future<String> getAccessToken();
  Future<String> recoverFromUnauthorized(String usedAccessToken);
}
