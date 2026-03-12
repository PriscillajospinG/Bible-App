/// A Bible verse selected as the spiritual focus for today,
/// based on the user's most recent journal entry emotions.
class VerseOfDay {
  const VerseOfDay({
    required this.reference,
    required this.text,
    required this.emotion,
  });

  /// Human-readable reference, e.g. 'Philippians 4:6'.
  final String reference;

  /// The verse text as stored in the KJV dataset.
  final String text;

  /// The emotion this verse was chosen to address.
  final String emotion;

  /// Returns [text] with KJV supplied-word markers (`{…}`) stripped.
  String get cleanText => text.replaceAll(RegExp(r'\{([^}]*)\}'), r'$1');
}
