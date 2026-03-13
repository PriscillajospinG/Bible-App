class BibleVerse {
  final int verse;
  final String text;
  final String? translation;
  final String? book;
  final int? chapter;

  const BibleVerse({
    required this.verse,
    required this.text,
    this.translation,
    this.book,
    this.chapter,
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
        if (translation != null) 'translation': translation,
        if (book != null) 'book': book,
        if (chapter != null) 'chapter': chapter,
      };

  @override
  String toString() =>
      'BibleVerse(translation: $translation, book: $book, chapter: $chapter, verse: $verse, text: $text)';
}
