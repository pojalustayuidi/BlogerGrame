import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_provider.g.dart';

class SettingsData {
  final bool soundEnabled;
  final bool musicEnabled;

  SettingsData({
    required this.soundEnabled,
    required this.musicEnabled,
  });

  SettingsData copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
  }) {
    return SettingsData(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
    );
  }
}

@riverpod
class Settings extends _$Settings {
  @override
  Future<SettingsData> build() async {
    final prefs = await SharedPreferences.getInstance();

    return SettingsData(
      soundEnabled: prefs.getBool('soundEnabled') ?? true,
      musicEnabled: prefs.getBool('musicEnabled') ?? true,
    );
  }

  Future<void> toggleSound() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final newValue = !current.soundEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', newValue);

    state = AsyncValue.data(current.copyWith(soundEnabled: newValue));
  }

  Future<void> toggleMusic() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final newValue = !current.musicEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('musicEnabled', newValue);

    state = AsyncValue.data(current.copyWith(musicEnabled: newValue));
  }
}