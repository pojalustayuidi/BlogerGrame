import '../domain/game_models.dart';

/// Each physical position is independent. Repeated cipher numbers must never
/// cause multiple cells to fill when one letter is submitted.
bool canEditCell(PuzzleCell cell) => cell.isLetter && !cell.isFilled;

int? firstEditablePosition(PuzzleAttempt attempt) {
  for (final cell in attempt.layout) {
    if (canEditCell(cell)) return cell.position;
  }
  return null;
}

int? nextEditablePosition(PuzzleAttempt attempt, int? fromPosition) {
  final cells = attempt.layout;
  if (cells.isEmpty) return null;
  final index = cells.indexWhere((cell) => cell.position == fromPosition);
  final start = index < 0 ? 0 : (index + 1) % cells.length;
  for (var i = 0; i < cells.length; i++) {
    final cell = cells[(start + i) % cells.length];
    if (canEditCell(cell)) return cell.position;
  }
  return null;
}

PuzzleCell? selectedCell(PuzzleAttempt attempt, int? position) {
  if (position == null) return null;
  for (final cell in attempt.layout) {
    if (cell.position == position) return cell;
  }
  return null;
}

// Eleven keys per row: large readable keys on narrow devices. Soft sign is
// deliberately between Т and Б. All 33 Russian letters stay on screen.
const russianKeyboardRows = <String>[
  'ЙЦУКЕНГШЩЗХ',
  'ФЫВАПРОЛДЖЭ',
  'ЯЧСМИТЬБЮЁЪ',
];

String? normalizedKeyboardLetter(String value) {
  final letter = value.trim().toUpperCase();
  return RegExp(r'^[А-ЯЁ]$').hasMatch(letter) ? letter : null;
}

/// The backend does not disclose the correct letters of unfilled cells.
/// We can safely color a key only after at least one physical cell has a
/// server-confirmed letter (given, entered or hinted).
enum PrufaniKeyProgress { unknown, partial, completed }

Map<String, PrufaniKeyProgress> keyboardProgress(PuzzleAttempt attempt) {
  final totalByCipher = <int, int>{};
  final filledByCipher = <int, int>{};
  final lettersByCipher = <int, String>{};

  for (final cell in attempt.layout) {
    if (!cell.isLetter || cell.number == null) continue;
    final number = cell.number!;
    totalByCipher[number] = (totalByCipher[number] ?? 0) + 1;
    if (!cell.isFilled) continue;
    filledByCipher[number] = (filledByCipher[number] ?? 0) + 1;
    final confirmed = normalizedKeyboardLetter(cell.given ?? cell.letter ?? '');
    if (confirmed != null) lettersByCipher[number] = confirmed;
  }

  final progress = <String, PrufaniKeyProgress>{};
  for (final entry in lettersByCipher.entries) {
    final number = entry.key;
    final letter = entry.value;
    final done = filledByCipher[number] == totalByCipher[number];
    final previous = progress[letter];
    // In case of malformed/conflicting server data, never mark a letter done
    // while any mapped group is still incomplete.
    progress[letter] = !done || previous == PrufaniKeyProgress.partial
        ? PrufaniKeyProgress.partial
        : PrufaniKeyProgress.completed;
  }
  return progress;
}

/// The cipher number is only retired after *every physical cell* carrying it
/// has a server-confirmed letter. Never infer hidden answers from other cells.
Set<int> completedCipherNumbers(PuzzleAttempt attempt) {
  final totals = <int, int>{};
  final filled = <int, int>{};
  for (final cell in attempt.layout) {
    final number = cell.number;
    if (!cell.isLetter || number == null) continue;
    totals[number] = (totals[number] ?? 0) + 1;
    if (cell.isFilled) filled[number] = (filled[number] ?? 0) + 1;
  }
  return {
    for (final number in totals.keys)
      if (filled[number] == totals[number]) number,
  };
}

/// Number of distinct cipher groups still requiring at least one letter.
int remainingCipherNumberCount(PuzzleAttempt attempt) {
  final all = <int>{
    for (final cell in attempt.layout)
      if (cell.isLetter && cell.number != null) cell.number!,
  };
  return all.difference(completedCipherNumbers(attempt)).length;
}
