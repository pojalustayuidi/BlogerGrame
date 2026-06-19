import 'package:flutter/material.dart';

class GameFaqWidget extends StatelessWidget {
  const GameFaqWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      const _FaqItemData(
        icon: Icons.key_rounded,
        title: 'Как работает шифр?',
        content:
        'Цифра относится к определённой букве. Например, если ты понял, '
            'что 9 — это «е», значит во всех клетках с цифрой 9 должна быть буква «е». '
            'Одинаковые цифры всегда означают одну и ту же букву.',
      ),
      const _FaqItemData(
        icon: Icons.keyboard_rounded,
        title: 'Что означает синяя буква на клавиатуре?',
        content:
        'Синяя буква означает, что эта буква уже используется во фразе где-то ещё. '
            'Это помогает быстрее находить повторяющиеся буквы и заполнять похожие места.',
      ),
      const _FaqItemData(
        icon: Icons.lightbulb_rounded,
        title: 'С чего лучше начинать?',
        content:
        'Сначала заполняй те буквы, шифр которых ты уже точно знаешь. '
            'После этого станет легче угадывать остальные буквы по словам и повторениям.',
      ),
      const _FaqItemData(
        icon: Icons.search_rounded,
        title: 'Как быстрее проходить уровни?',
        content:
        'Ищи короткие слова, повторяющиеся цифры и знакомые сочетания букв. '
            'Чем больше уже открыто, тем проще восстановить всю фразу.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FaqHeader(),
          const SizedBox(height: 14),
          ...List.generate(
            items.length,
                (index) => Padding(
              padding: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 10),
              child: _FaqTile(item: items[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqHeader extends StatelessWidget {
  const _FaqHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF4FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.help_outline_rounded,
            color: Color(0xFF5B8DEF),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FAQ',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Подсказки по правилам и прохождению',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FaqTile extends StatelessWidget {
  final _FaqItemData item;

  const _FaqTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.icon,
              color: const Color(0xFF5B8DEF),
              size: 20,
            ),
          ),
          title: Text(
            item.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
          iconColor: const Color(0xFF5B8DEF),
          collapsedIconColor: const Color(0xFF6B7280),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(
                item.content,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: Color(0xFF4B5563),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqItemData {
  final IconData icon;
  final String title;
  final String content;

  const _FaqItemData({
    required this.icon,
    required this.title,
    required this.content,
  });
}