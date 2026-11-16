import '../../economy/domain/economy_models.dart';

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
}

class PuzzleNote {
  final int number;
  final String? letter;
  final String comment;

  const PuzzleNote({required this.number, required this.letter,
    required this.comment});
}

class BonusChoice {
  final String id;
  final String name;

  const BonusChoice({required this.id, required this.name});
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
  final List<PuzzleNote> notes;
  final List<BonusChoice> bonusOptions;
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
}

/// One response for one attempted letter. A wrong letter never has a filled cell.
class LetterResult {
  final bool correct;
  final int position;
  final int mistakes;
  final int triesRemaining;
  final bool lostLife;
  final bool locked;
  final bool solved;
  final bool replayed;
  final PuzzleCell? cell;
  final GameWallet? wallet;
  final int rewardCoins;
  final bool flawless;
  final List<BonusChoice> bonusOptions;

  const LetterResult({
    required this.correct,
    required this.position,
    required this.mistakes,
    required this.triesRemaining,
    required this.lostLife,
    required this.locked,
    required this.solved,
    required this.replayed,
    required this.cell,
    required this.wallet,
    required this.rewardCoins,
    required this.flawless,
    required this.bonusOptions,
  });
}

class HintResult {
  final bool applied;
  final PuzzleCell cell;
  final bool solved;
  final int rewardCoins;
  final GameWallet? wallet;
  final List<BonusChoice> bonusOptions;

  const HintResult({required this.applied, required this.cell,
    required this.solved, required this.rewardCoins,
    required this.wallet, required this.bonusOptions});
}

class BonusReveal {
  final String quote;
  final String? creator;
  final String? sourceUrl;
  final bool sourceVerified;
  final String mediaRights;

  const BonusReveal({required this.quote, required this.creator,
    required this.sourceUrl, required this.sourceVerified,
    required this.mediaRights});
}

class BonusResult {
  final String result;
  final BonusReveal reveal;
  final int rewardCoins;
  final GameWallet? wallet;

  const BonusResult({required this.result, required this.reveal,
    required this.rewardCoins, required this.wallet});
}
