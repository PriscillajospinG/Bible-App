import '../../../data/repositories/bible_repository.dart';
import '../models/verse_of_day.dart';

/// Maps emotional states to specific KJV Bible verses.
///
/// Verse texts are fetched from [BibleRepository] (KJV). Hard-coded fallback
/// texts are used when the repository lookup fails (e.g. during cold start).
class VerseSuggestionService {
  VerseSuggestionService({required this.bibleRepo});

  final BibleRepository bibleRepo;

  // ── Emotion → verse reference mapping ────────────────────────────────────

  static const _emotionMap = <String, ({String book, int chapter, int verse})>{
    'anxiety': (book: 'Philippians', chapter: 4, verse: 6),
    'fear': (book: 'Isaiah', chapter: 41, verse: 10),
    'sadness': (book: 'Psalms', chapter: 34, verse: 18),
    'loneliness': (book: 'Matthew', chapter: 28, verse: 20),
    'anger': (book: 'James', chapter: 1, verse: 19),
    'temptation': (book: '1 Corinthians', chapter: 10, verse: 13),
    'guilt': (book: '1 John', chapter: 1, verse: 9),
    'hopelessness': (book: 'Jeremiah', chapter: 29, verse: 11),
    'confusion': (book: 'Proverbs', chapter: 3, verse: 5),
    'gratitude': (book: 'Psalms', chapter: 100, verse: 4),
    'joy': (book: 'Psalms', chapter: 32, verse: 11),
    'doubt': (book: 'Mark', chapter: 11, verse: 24),
    'exhaustion': (book: 'Isaiah', chapter: 40, verse: 31),
    'reflection': (book: 'Psalms', chapter: 46, verse: 10),
    'grief': (book: 'Romans', chapter: 8, verse: 28),
    'faithfulness': (book: 'Lamentations', chapter: 3, verse: 23),
    'endurance': (book: 'Hebrews', chapter: 12, verse: 1),
    'strength': (book: 'Psalms', chapter: 27, verse: 1),
  };

  // ── Verified KJV fallback texts (stripped of curly-brace markers) ─────────

  static const _fallbacks = <String, String>{
    'Philippians 4:6':
        'Be careful for nothing; but in every thing by prayer and supplication '
        'with thanksgiving let your requests be made known unto God.',
    'Isaiah 41:10':
        'Fear thou not; for I am with thee: be not dismayed; for I am thy God: '
        'I will strengthen thee; yea, I will help thee; yea, I will uphold thee '
        'with the right hand of my righteousness.',
    'Psalms 34:18':
        'The LORD is nigh unto them that are of a broken heart; and saveth such '
        'as be of a contrite spirit.',
    'Matthew 28:20':
        'Teaching them to observe all things whatsoever I have commanded you: '
        'and, lo, I am with you always, even unto the end of the world. Amen.',
    'James 1:19':
        'Wherefore, my beloved brethren, let every man be swift to hear, slow '
        'to speak, slow to wrath:',
    '1 Corinthians 10:13':
        'There hath no temptation taken you but such as is common to man: but '
        'God is faithful, who will not suffer you to be tempted above that ye '
        'are able; but will with the temptation also make a way to escape, that '
        'ye may be able to bear it.',
    '1 John 1:9':
        'If we confess our sins, he is faithful and just to forgive us our sins, '
        'and to cleanse us from all unrighteousness.',
    'Jeremiah 29:11':
        'For I know the thoughts that I think toward you, saith the LORD, '
        'thoughts of peace, and not of evil, to give you an expected end.',
    'Proverbs 3:5':
        'Trust in the LORD with all thine heart; and lean not unto thine own '
        'understanding.',
    'Psalms 100:4':
        'Enter into his gates with thanksgiving, and into his courts with '
        'praise: be thankful unto him, and bless his name.',
    'Psalms 32:11':
        'Be glad in the LORD, and rejoice, ye righteous: and shout for joy, '
        'all ye that are upright in heart.',
    'Mark 11:24':
        'Therefore I say unto you, What things soever ye desire, when ye pray, '
        'believe that ye receive them, and ye shall have them.',
    'Isaiah 40:31':
        'But they that wait upon the LORD shall renew their strength; they shall '
        'mount up with wings as eagles; they shall run, and not be weary; and '
        'they shall walk, and not faint.',
    'Psalms 46:10':
        'Be still, and know that I am God: I will be exalted among the heathen, '
        'I will be exalted in the earth.',
    'Romans 8:28':
        'And we know that all things work together for good to them that love '
        'God, to them who are the called according to his purpose.',
    'Lamentations 3:23':
        'They are new every morning: great is thy faithfulness.',
    'Hebrews 12:1':
        'Wherefore seeing we also are compassed about with so great a cloud of '
        'witnesses, let us lay aside every weight, and the sin which doth so '
        'easily beset us, and let us run with patience the race that is set '
        'before us.',
    'Psalms 27:1':
        'The LORD is my light and my salvation; whom shall I fear? the LORD is '
        'the strength of my life; of whom shall I be afraid?',
  };

  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns a [VerseOfDay] matched to [emotion].
  ///
  /// Falls back to the 'reflection' verse when [emotion] has no mapping.
  VerseOfDay getVerseForEmotion(String emotion) {
    final ref = _emotionMap[emotion] ?? _emotionMap['reflection']!;
    final resolvedEmotion =
        _emotionMap.containsKey(emotion) ? emotion : 'reflection';

    final reference = '${ref.book} ${ref.chapter}:${ref.verse}';

    // Attempt live lookup from repository.
    String text;
    try {
      final verse = bibleRepo.getVerse('KJV', ref.book, ref.chapter, ref.verse);
      text = verse?.text ?? _fallbacks[reference] ?? reference;
    } catch (_) {
      text = _fallbacks[reference] ?? reference;
    }

    return VerseOfDay(reference: reference, text: text, emotion: resolvedEmotion);
  }
}
