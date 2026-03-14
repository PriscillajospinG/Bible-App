class BibleVerse {
  /// Human-readable reference such as "Philippians 4:6-7".
  final String reference;
  final int verse;
  final String text;
  final String? translation;
  final String? book;
  final int? chapter;

  const BibleVerse({
    required this.verse,
    required this.text,
    this.reference = '',
    this.translation,
    this.book,
    this.chapter,
  });

  /// Creates a passage verse returned from the api.bible REST endpoint.
  factory BibleVerse.fromApiPassage({
    required String reference,
    required String text,
  }) =>
      BibleVerse(verse: 0, text: text, reference: reference);

  factory BibleVerse.fromJson(Map<String, dynamic> json) {
    return BibleVerse(
      verse: (json['verse'] as num?)?.toInt() ?? 0,
      text: json['text'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      book: json['book'] as String?,
      chapter: (json['chapter'] as num?)?.toInt(),
      translation: json['translation'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'verse': verse,
        'text': text,
        'reference': reference,
        if (translation != null) 'translation': translation,
        if (book != null) 'book': book,
        if (chapter != null) 'chapter': chapter,
      };

  @override
  String toString() =>
      'BibleVerse(reference: $reference, verse: $verse, text: ${text.length > 60 ? '${text.substring(0, 60)}…' : text})';
}
