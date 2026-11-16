import '../../../core/network/authenticated_api_client.dart';
import '../domain/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthenticatedApiClient _client;

  const AuthRepositoryImpl(this._client);

  @override
  Future<String> getPlayerId() async {
    final json = await _client.request('GET', '/api/v1/auth/me');
    return (json['player'] as Map)['id'] as String;
  }
}
