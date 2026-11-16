/// DTOs for the real /api/v1/game contract. Deliberately no quote/author
/// in LevelSummary: the backend reveals them only after the author bonus.
class GameCategory {
  final String slug;
  final String title;
  final int levels;

  const GameCategory({required this.slug, required this.title, required this.levels});

  factory GameCategory.fromJson(Map<String, dynamic> json) => GameCategory(
        slug: json['slug'] as String,
        title: json['title'] as String,
        levels: (json['levels'] as num).toInt(),
      );
}

class LevelSummary {
  final String id;
  final String category;
  final int number;
  final int letters;
  final String difficulty;
  final bool completed;
  final bool preview;

  const LevelSummary({
    required this.id,
    required this.category,
    required this.number,
    required this.letters,
    required this.difficulty,
    required this.completed,
    required this.preview,
  });

  factory LevelSummary.fromJson(Map<String, dynamic> json) => LevelSummary(
        id: json['id'] as String,
        category: json['category'] as String,
        number: (json['number'] as num).toInt(),
        letters: (json['letters'] as num).toInt(),
        difficulty: json['difficulty'] as String,
        completed: json['completed'] == true,
        preview: json['preview'] == true,
      );
}

class GameWallet {
  final int coins;
  final int lives;
  final int hints;
  final int maxLives;
  final int maxHints;
  final int lifeRegenMinutes;
  final DateTime? nextLifeAt;

  const GameWallet({
    required this.coins,
    required this.lives,
    required this.hints,
    required this.maxLives,
    required this.maxHints,
    required this.lifeRegenMinutes,
    required this.nextLifeAt,
  });

  factory GameWallet.fromJson(Map<String, dynamic> json) => GameWallet(
        coins: (json['coins'] as num).toInt(),
        lives: (json['lives'] as num).toInt(),
        hints: (json['hints'] as num).toInt(),
        maxLives: (json['maxLives'] as num).toInt(),
        maxHints: (json['maxHints'] as num).toInt(),
        lifeRegenMinutes: (json['lifeRegenMinutes'] as num).toInt(),
        nextLifeAt: json['nextLifeAt'] == null
            ? null
            : DateTime.parse(json['nextLifeAt'] as String),
      );
}

class PuzzleCell {
  final int position;
  final String type;
  final int? number;
  final String? given;
  final String? letter;
  final String? separator;
  final bool hinted;

  const PuzzleCell({
    required this.position,
    required this.type,
    this.number,
    this.given,
    this.letter,
    this.separator,
    this.hinted = false,
  });

  bool get isLetter => type == 'letter';
  bool get isFilled => isLetter && (given != null || letter != null);

  factory PuzzleCell.fromJson(Map<String, dynamic> json) => PuzzleCell(
        position: (json['position'] as num).toInt(),
        type: json['type'] as String,
        number: (json['number'] as num?)?.toInt(),
        given: json['given'] as String?,
        letter: json['letter'] as String?,
        separator: json['value'] as String?,
        hinted: json['hinted'] == true,
      );
}

class PuzzleAttempt {
  final String id;
  final String levelId;
  final String category;
  final int levelNumber;
  final String status;
  final int mistakes;
  final int triesRemaining;
  final int triesPerLife;
  final List<PuzzleCell> layout;
  final List<Map<String, dynamic>> notes;
  final List<Map<String, dynamic>> bonusOptions;
  final bool bonusAnswered;

  const PuzzleAttempt({
    required this.id,
    required this.levelId,
    required this.category,
    required this.levelNumber,
    required this.status,
    required this.mistakes,
    required this.triesRemaining,
    required this.triesPerLife,
    required this.layout,
    required this.notes,
    required this.bonusOptions,
    required this.bonusAnswered,
  });

  factory PuzzleAttempt.fromJson(Map<String, dynamic> json) => PuzzleAttempt(
        id: json['id'] as String,
        levelId: json['levelId'] as String,
        category: json['category'] as String,
        levelNumber: (json['levelNumber'] as num).toInt(),
        status: json['status'] as String,
        mistakes: (json['mistakes'] as num).toInt(),
        triesRemaining: (json['triesRemaining'] as num).toInt(),
        triesPerLife: (json['triesPerLife'] as num).toInt(),
        layout: (json['layout'] as List<dynamic>)
            .map((item) => PuzzleCell.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(growable: false),
        notes: (json['notes'] as List<dynamic>? ?? [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList(growable: false),
        bonusOptions: (json['bonusOptions'] as List<dynamic>? ?? [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList(growable: false),
        bonusAnswered: json['bonusAnswered'] == true,
      );
}
