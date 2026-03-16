import '../../data/models/bible_verse.dart';
import '../../data/repositories/bible_repository.dart';

/// Offline Bible lookup service backed by the bundled NLT dataset.
class LocalBibleService {
  LocalBibleService({
    required BibleRepository repository,
    this.translation = BibleRepository.defaultTranslation,
  }) : _repository = repository;

  final BibleRepository _repository;
  final String translation;
  final Map<String, String> _bookAliases = {};

  Future<void> loadBible() async {
    await _repository.ensureLoaded(translation);
    _seedAliases();
  }

  BibleVerse? getVerse(String book, int chapter, int verseNumber) {
    final canonicalBook = _canonicalBookName(book);
    final verse = _repository.getVerse(
      translation,
      canonicalBook,
      chapter,
      verseNumber,
    );
    if (verse == null) {
      return null;
    }

    return BibleVerse(
      reference: '$canonicalBook $chapter:$verseNumber',
      verse: verseNumber,
      text: verse.text,
      translation: translation,
      book: canonicalBook,
      chapter: chapter,
    );
  }

  BibleVerse getPassage(String reference) {
    final parsed = _parseReference(reference);
    final verses = <BibleVerse>[];

    for (var verseNumber = parsed.startVerse;
        verseNumber <= parsed.endVerse;
        verseNumber++) {
      final verse = getVerse(parsed.book, parsed.chapter, verseNumber);
      if (verse != null) {
        verses.add(verse);
      }
    }

    if (verses.isEmpty) {
      throw StateError('Verse not found for reference: $reference');
    }

    final text = verses.map((verse) => verse.text.trim()).join(' ');
    final normalizedReference = parsed.startVerse == parsed.endVerse
        ? '${parsed.book} ${parsed.chapter}:${parsed.startVerse}'
        : '${parsed.book} ${parsed.chapter}:${parsed.startVerse}-${parsed.endVerse}';

    return BibleVerse(
      reference: normalizedReference,
      verse: parsed.startVerse,
      text: text,
      translation: translation,
      book: parsed.book,
      chapter: parsed.chapter,
    );
  }

  String _canonicalBookName(String book) {
    _seedAliases();
    final canonical = _bookAliases[_normalizeBook(book)];
    if (canonical == null) {
      throw StateError('Unknown Bible book: $book');
    }
    return canonical;
  }

  void _seedAliases() {
    if (_bookAliases.isNotEmpty) {
      return;
    }

    for (final book in _repository.allBookNames) {
      _bookAliases[_normalizeBook(book)] = book;
    }

    _bookAliases['psalm'] = 'Psalms';
    _bookAliases['psalms'] = 'Psalms';
    _bookAliases['songofsongs'] = 'Song of Songs';
    _bookAliases['songofsolomon'] = 'Song of Songs';
  }

  _ParsedReference _parseReference(String reference) {
    final trimmed = reference.trim();
    final match = RegExp(r'^(.+?)\s+(\d+):(\d+)(?:-(\d+))?$').firstMatch(trimmed);
    if (match == null) {
      throw FormatException('Unsupported Bible reference: $reference');
    }

    final book = _canonicalBookName(match.group(1)!);
    final chapter = int.parse(match.group(2)!);
    final startVerse = int.parse(match.group(3)!);
    final endVerse = int.parse(match.group(4) ?? match.group(3)!);

    return _ParsedReference(
      book: book,
      chapter: chapter,
      startVerse: startVerse,
      endVerse: endVerse,
    );
  }

  String _normalizeBook(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

class _ParsedReference {
  const _ParsedReference({
    required this.book,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
  });

  final String book;
  final int chapter;
  final int startVerse;
  final int endVerse;
}