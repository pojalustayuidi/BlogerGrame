import '../../../core/network/authenticated_api_client.dart';
import '../domain/catalog_models.dart';
import '../domain/catalog_repository.dart';
import 'catalog_mapper.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  final AuthenticatedApiClient _client;

  const CatalogRepositoryImpl(this._client);

  @override
  Future<List<GameCategory>> categories() async {
    final json = await _client.request('GET', '/api/v1/game/categories');
    return (json['categories'] as List<dynamic>)
        .map((item) => categoryFromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
  }

  @override
  Future<List<LevelSummary>> levels({String? category}) async {
    final json = await _client.request('GET', '/api/v1/game/levels',
        query: category == null ? null : {'category': category});
    return (json['levels'] as List<dynamic>)
        .map((item) => levelFromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
  }
}
