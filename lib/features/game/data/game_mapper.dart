import '../../economy/data/economy_mapper.dart';
import '../../economy/domain/economy_models.dart';
import '../domain/game_models.dart';

Map<String, dynamic> _map(Object? v) => Map<String, dynamic>.from(v as Map);
GameWallet? _wallet(Map<String, dynamic> j) =>
    j['wallet'] == null ? null : walletFromJson(_map(j['wallet']));
DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;
PuzzleCell cellFromJson(Map<String, dynamic> j) => PuzzleCell(
    position: (j['position'] as num).toInt(),
    type: j['type'] as String? ?? 'letter',
    number: (j['number'] as num?)?.toInt(),
    given: j['given'] as String?,
    letter: j['letter'] as String?,
    separator: j['value'] as String?,
    hinted: j['hinted'] == true);
PuzzleNote noteFromJson(Map<String, dynamic> j) => PuzzleNote(
    number: (j['number'] as num).toInt(),
    letter: j['letter'] as String?,
    comment: j['comment'] as String? ?? '');
BonusChoice bonusChoiceFromJson(Map<String, dynamic> j) =>
    BonusChoice(id: j['id'] as String, name: j['name'] as String);
List<BonusChoice> _choices(Map<String, dynamic> j) =>
    (j['bonusOptions'] as List<dynamic>? ?? const [])
        .map((v) => bonusChoiceFromJson(_map(v)))
        .toList(growable: false);
BonusReveal revealFromJson(Map<String, dynamic> j) => BonusReveal(
    quote: j['quote'] as String,
    creator: j['creator'] as String?,
    sourceUrl: j['sourceUrl'] as String?,
    sourceVerified: j['sourceVerified'] == true,
    mediaRights: j['mediaRights'] as String? ?? 'unknown');
PuzzleAttempt attemptFromJson(Map<String, dynamic> j) => PuzzleAttempt(
    id: j['id'] as String,
    levelId: j['levelId'] as String,
    category: j['category'] as String,
    levelNumber: (j['levelNumber'] as num).toInt(),
    status: j['status'] as String,
    mistakes: (j['mistakes'] as num).toInt(),
    triesRemaining: (j['triesRemaining'] as num).toInt(),
    triesPerLife: (j['triesPerLife'] as num).toInt(),
    layout: (j['layout'] as List<dynamic>)
        .map((v) => cellFromJson(_map(v)))
        .toList(growable: false),
    notes: (j['notes'] as List<dynamic>? ?? const [])
        .map((v) => noteFromJson(_map(v)))
        .toList(growable: false),
    bonusOptions: _choices(j),
    bonusAnswered: j['bonusAnswered'] == true,
    reveal: j['reveal'] == null ? null : revealFromJson(_map(j['reveal'])),
    startedAt: _date(j['startedAt']),
    completedAt: _date(j['completedAt']));
LetterResult letterFromJson(Map<String, dynamic> j) => LetterResult(
    correct: j['correct'] == true,
    position: (j['position'] as num).toInt(),
    mistakes: (j['mistakes'] as num).toInt(),
    triesRemaining: (j['triesRemaining'] as num).toInt(),
    lostLife: j['lostLife'] == true,
    locked: j['locked'] == true,
    solved: j['solved'] == true,
    replayed: j['replayed'] == true,
    cell: j['cell'] == null ? null : cellFromJson(_map(j['cell'])),
    wallet: _wallet(j),
    rewardCoins: (j['rewardCoins'] as num?)?.toInt() ?? 0,
    flawless: j['flawless'] == true,
    bonusOptions: _choices(j));
HintResult hintFromJson(Map<String, dynamic> j) => HintResult(
    applied: j['applied'] == true,
    cell: cellFromJson(_map(j['cell'])),
    solved: j['solved'] == true,
    rewardCoins: (j['rewardCoins'] as num?)?.toInt() ?? 0,
    wallet: _wallet(j),
    bonusOptions: _choices(j));
BonusResult bonusFromJson(Map<String, dynamic> j) => BonusResult(
    result: j['result'] as String,
    reveal: revealFromJson(_map(j['reveal'])),
    rewardCoins: (j['rewardCoins'] as num?)?.toInt() ?? 0,
    wallet: _wallet(j));
ForfeitResult forfeitFromJson(Map<String, dynamic> j) => ForfeitResult(
    abandoned: j['abandoned'] == true,
    charged: j['charged'] == true,
    wallet: walletFromJson(_map(j['wallet'])));
