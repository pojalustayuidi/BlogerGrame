import 'catalog_models.dart';

abstract class CatalogRepository {
  Future<List<GameCategory>> categories();
  Future<List<LevelSummary>> levels({String? category});
}
