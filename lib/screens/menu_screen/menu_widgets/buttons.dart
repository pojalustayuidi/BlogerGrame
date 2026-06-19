import 'package:flutter/material.dart';

import '../../../services/models/level.dart';
import '../../settings_screen/settings_screen.dart';
import '../../store_screen/shope_screen.dart';

class MenuButtons extends StatelessWidget {
  final int lives;
  final Level currentLevel;
  final List<Level> levels;
  final VoidCallback onPressedContinue;
  final VoidCallback showNoLivesDialog;
  final VoidCallback loadStatus;

  const MenuButtons({
    super.key,
    required this.lives,
    required this.currentLevel,
    required this.levels,
    required this.onPressedContinue,
    required this.showNoLivesDialog,
    required this.loadStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PrimaryMenuButton(
          title: 'Продолжить',
          subtitle: 'Уровень ${currentLevel.id}',
          icon: Icons.play_arrow_rounded,
          enabled: lives > 0,
          onTap: lives > 0 ? onPressedContinue : showNoLivesDialog,
        ),
        const SizedBox(height: 16),
        _SecondaryMenuButton(
          title: 'Магазин',
          subtitle: 'Купить жизни и бонусы',
          icon: Icons.storefront_rounded,
          iconBg: Colors.amber.shade50,
          iconColor: Colors.orange,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShopScreen()),
            );
            loadStatus();
          },
        ),
        const SizedBox(height: 16),
        _SecondaryMenuButton(
          title: 'Настройки',
          subtitle: 'Звук, музыка и прогресс',
          icon: Icons.settings_rounded,
          iconBg: Colors.blue.shade50,
          iconColor: const Color(0xFF5B8DEF),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
            loadStatus();
          },
        ),
      ],
    );
  }
}

class _PrimaryMenuButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PrimaryMenuButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 92,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            if (enabled)
              BoxShadow(
                color: const Color(0xFF5B8DEF).withOpacity(0.28),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: enabled ? null : Colors.grey.shade400,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: enabled
                  ? const LinearGradient(
                colors: [Color(0xFF5B8DEF), Color(0xFF6FC3FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
                  : null,
              color: enabled ? null : Colors.grey.shade400,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryMenuButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  const _SecondaryMenuButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                offset: const Offset(0, 8),
                color: Colors.black.withOpacity(0.05),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}