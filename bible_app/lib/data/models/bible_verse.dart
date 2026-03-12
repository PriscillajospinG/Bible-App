class BibleVerse {
  final int verse;
  final String text;

  const BibleVerse({
    required this.verse,
    required this.text,
  });

  factory BibleVerse.fromJson(Map<String, dynamic> json) {
    return BibleVerse(
      verse: json['verse'] as int,
      text: json['text'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'verse': verse,
        'text': text,
      };

  @override
  String toString() => 'BibleVerse(verse: $verse, text: $text)';
}
