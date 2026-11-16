import '../domain/catalog_models.dart';

GameCategory categoryFromJson(Map<String, dynamic> json) => GameCategory(
      slug: json['slug'] as String,
      title: json['title'] as String,
      levels: (json['levels'] as num).toInt(),
    );

LevelSummary levelFromJson(Map<String, dynamic> json) => LevelSummary(
      id: json['id'] as String,
      category: json['category'] as String,
      number: (json['number'] as num).toInt(),
      letters: (json['letters'] as num).toInt(),
      difficulty: json['difficulty'] as String,
      completed: json['completed'] == true,
      preview: json['preview'] == true,
    );
