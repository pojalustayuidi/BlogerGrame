import 'package:flutter/services.dart';

/// Lightweight game feedback without new packages, audio assets or network.
/// Sounds respect the device's system sound mode; vibration respects OS settings.
/// Failures must never affect the server-authoritative puzzle operation.
class PrufaniGameFeedback {
  const PrufaniGameFeedback();

  Future<void> selectedCell() => _quiet(HapticFeedback.selectionClick);

  Future<void> tappedLetter() => _quiet(() async {
        await SystemSound.play(SystemSoundType.click);
        await HapticFeedback.selectionClick();
      });

  Future<void> confirmedLetter() => _quiet(HapticFeedback.lightImpact);

  Future<void> rejectedLetter({required bool lostLife}) async {
    // Click works on Android even when a system alert tone is unavailable.
    await _quiet(() => SystemSound.play(SystemSoundType.click));
    await _quiet(() => SystemSound.play(SystemSoundType.alert));
    await _quiet(
        lostLife ? HapticFeedback.heavyImpact : HapticFeedback.mediumImpact);
  }

  Future<void> revealedHint() => _quiet(HapticFeedback.lightImpact);

  Future<void> _quiet(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // A missing platform sound/haptic service must never interrupt a turn.
    }
  }
}
