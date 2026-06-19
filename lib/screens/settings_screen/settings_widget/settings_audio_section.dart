import 'package:flutter/material.dart';

import 'settings_ui.dart';

class SettingsAudioSection extends StatelessWidget {
  final dynamic settings;
  final ValueChanged<bool> onSoundChanged;
  final ValueChanged<bool> onMusicChanged;

  const SettingsAudioSection({
    super.key,
    required this.settings,
    required this.onSoundChanged,
    required this.onMusicChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Аудио'),
        const SizedBox(height: 10),
        SettingsCard(
          children: [
            SettingsSwitchTile(
              icon: Icons.volume_up_rounded,
              iconBg: Colors.blue.shade50,
              iconColor: Colors.blue,
              title: 'Звуки',
              subtitle: 'Включить или выключить игровые звуки',
              value: settings.soundEnabled,
              onChanged: onSoundChanged,
            ),
            const InnerDivider(),
            SettingsSwitchTile(
              icon: Icons.music_note_rounded,
              iconBg: Colors.green.shade50,
              iconColor: Colors.green,
              title: 'Музыка',
              subtitle: 'Фоновая музыка в игре',
              value: settings.musicEnabled,
              onChanged: onMusicChanged,
            ),
          ],
        ),
      ],
    );
  }
}