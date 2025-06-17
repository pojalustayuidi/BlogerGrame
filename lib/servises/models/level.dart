class Level {
  final int id;
  final String quote;
  final String author;
  final List<int> revealed;
  final Map<String, int> letterMap; // 👈 Ключ - строка

  Level({
    required this.id,
    required this.quote,
    required this.author,
    required this.revealed,
    required this.letterMap,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'],
      quote: json['quote'],
      author: json['author'],
      revealed: List<int>.from(json['revealed']),
      letterMap: Map<String, int>.from(json['letterMap']),
    );
  }
}

