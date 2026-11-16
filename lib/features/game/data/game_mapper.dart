import '../../economy/data/economy_mapper.dart';
import '../../economy/domain/economy_models.dart';
import '../domain/game_models.dart';

Map<String, dynamic> _map(Object? value) => Map<String, dynamic>.from(value as Map);

GameWallet? _optionalWallet(Map<String, dynamic> json) =>
    json['wallet'] == null ? null : walletFromJson(_map(json['wallet']));

PuzzleCell cellFromJson(Map<String, dynamic> json) => PuzzleCell(
      position: (json['position'] as num).toInt(),
      type: json['type'] as String? ?? 'letter',
      number: (json['number'] as num?)?.toInt(),
      given: json['given'] as String?,
      letter: json['letter'] as String?,
      separator: json['value'] as String?,
      hinted: json['hinted'] == true,
    );

PuzzleNote noteFromJson(Map<String, dynamic> json) => PuzzleNote(
      number: (json['number'] as num).toInt(),
      letter: json['letter'] as String?,
      comment: json['comment'] as String? ?? '',
    );

BonusChoice bonusChoiceFromJson(Map<String, dynamic> json) => BonusChoice(
      id: json['id'] as String,
      name: json['name'] as String,
    );

List<BonusChoice> _choices(Map<String, dynamic> json) =>
    (json['bonusOptions'] as List<dynamic>? ?? const [])
        .map((choice) => bonusChoiceFromJson(_map(choice)))
        .toList(growable: false);

PuzzleAttempt attemptFromJson(Map<String, dynamic> json) => PuzzleAttempt(
      id: json['id'] as String,
      levelId: json['levelId'] as String,
      category: json['category'] as String,
      levelNumber: (json['levelNumber'] as num).toInt(),
      status: json['status'] as String,
      mistakes: (json['mistakes'] as num).toInt(),
      triesRemaining: (json['triesRemaining'] as num).toInt(),
      triesPerLife: (json['triesPerLife'] as num).toInt(),
      layout: (json['layout'] as List<dynamic>)
          .map((item) => cellFromJson(_map(item)))
          .toList(growable: false),
      notes: (json['notes'] as List<dynamic>? ?? const [])
          .map((item) => noteFromJson(_map(item)))
          .toList(growable: false),
      bonusOptions: _choices(json),
      bonusAnswered: json['bonusAnswered'] == true,
    );

LetterResult letterFromJson(Map<String, dynamic> json) => LetterResult(
      correct: json['correct'] == true,
      position: (json['position'] as num).toInt(),
      mistakes: (json['mistakes'] as num).toInt(),
      triesRemaining: (json['triesRemaining'] as num).toInt(),
      lostLife: json['lostLife'] == true,
      locked: json['locked'] == true,
      solved: json['solved'] == true,
      replayed: json['replayed'] == true,
      cell: json['cell'] == null ? null : cellFromJson(_map(json['cell'])),
      wallet: _optionalWallet(json),
      rewardCoins: (json['rewardCoins'] as num?)?.toInt() ?? 0,
      flawless: json['flawless'] == true,
      bonusOptions: _choices(json),
    );

HintResult hintFromJson(Map<String, dynamic> json) => HintResult(
      applied: json['applied'] == true,
      cell: cellFromJson(_map(json['cell'])),
      solved: json['solved'] == true,
      rewardCoins: (json['rewardCoins'] as num?)?.toInt() ?? 0,
      wallet: _optionalWallet(json),
      bonusOptions: _choices(json),
    );

BonusResult bonusFromJson(Map<String, dynamic> json) {
  final reveal = _map(json['reveal']);
  return BonusResult(
    result: json['result'] as String,
    rewardCoins: (json['rewardCoins'] as num?)?.toInt() ?? 0,
    wallet: _optionalWallet(json),
    reveal: BonusReveal(
      quote: reveal['quote'] as String,
      creator: reveal['creator'] as String?,
      sourceUrl: reveal['sourceUrl'] as String?,
      sourceVerified: reveal['sourceVerified'] == true,
      mediaRights: reveal['mediaRights'] as String? ?? 'unknown',
    ),
  );
}
