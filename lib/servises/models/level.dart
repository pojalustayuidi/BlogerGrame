class Level {
  final int id;
  final String phrase;
  final List<int> revealedIndices;

  Level({
    required this.id,
    required this.phrase,
    required this.revealedIndices,
  });

  factory Level.fromJson(Map<String, dynamic> json) => Level(
      id: json['id'],
      phrase: json['phrase'],
      revealedIndices: List<int>.from(json['revealedIndices']),
    );
}

