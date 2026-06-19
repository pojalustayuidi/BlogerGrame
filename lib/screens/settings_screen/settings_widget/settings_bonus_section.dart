import 'package:blogergrame/screens/settings_screen/settings_widget/settings_ui.dart';
import 'package:flutter/material.dart';


class SettingsBonusSection extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPromoTap;
  final VoidCallback? onStatsTap;

  const SettingsBonusSection({
    super.key,
    required this.isLoading,
    required this.onPromoTap,
    required this.onStatsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Бонусы и прогресс'),
        const SizedBox(height: 10),
        SettingsCard(
          children: [
            ActionTile(
              icon: Icons.card_giftcard_rounded,
              iconBg: Colors.purple.shade50,
              iconColor: Colors.purple,
              title: 'Промокод',
              subtitle: 'Введите промокод и получите награды',
              trailing: isLoading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.chevron_right_rounded),
              onTap: onPromoTap,
            ),
            const InnerDivider(),
            ActionTile(
              icon: Icons.bar_chart_rounded,
              iconBg: Colors.orange.shade50,
              iconColor: Colors.orange,
              title: 'Статистика',
              subtitle: 'Посмотреть прогресс прохождения',
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: onStatsTap,
            ),
          ],
        ),
      ],
    );
  }
}